param(
    [switch]$SetupOnly
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$primaryLogsDir = Join-Path $projectRoot "logs"
$fallbackLogsDir = Join-Path $env:TEMP "FeedzMoodBotLogs"
$logsDir = $primaryLogsDir

try {
    if (-not (Test-Path $primaryLogsDir)) {
        New-Item -Path $primaryLogsDir -ItemType Directory | Out-Null
    }

    $probe = Join-Path $primaryLogsDir ".write_test"
    "ok" | Set-Content -Path $probe -Encoding ASCII
    Remove-Item $probe -Force -ErrorAction SilentlyContinue
}
catch {
    $logsDir = $fallbackLogsDir
    if (-not (Test-Path $logsDir)) {
        New-Item -Path $logsDir -ItemType Directory | Out-Null
    }
}

$runIdRaw = $env:FEEDZ_RUN_ID
if ([string]::IsNullOrWhiteSpace($runIdRaw)) {
    $runIdRaw = Get-Date -Format "yyyyMMdd_HHmmss"
}

$runId = ($runIdRaw -replace "[^a-zA-Z0-9_-]", "_")
$env:FEEDZ_RUN_ID = $runId

$logFile = Join-Path $logsDir "run_$runId.log"
$errorLogFile = Join-Path $logsDir "error_latest.log"
$summaryLogFile = Join-Path $logsDir "summary_latest.txt"

$transcriptStarted = $false
try {
    Start-Transcript -Path $logFile -Append | Out-Null
    $transcriptStarted = $true
}
catch {
    Write-Host "[AVISO] Nao foi possivel iniciar transcript em $logFile"
}

function Write-Step {
    param([string]$Message)
    Write-Host "[..] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[AVISO] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Write-RunSummary {
    param(
        [string]$Status,
        [string]$Message,
        [int]$ExitCode = 0
    )

    try {
        @(
            "status=$Status"
            "run_id=$runId"
            "timestamp=$((Get-Date).ToString('o'))"
            "exit_code=$ExitCode"
            "message=$Message"
            "bootstrap_log=$logFile"
            "error_log=$errorLogFile"
            "app_log=$(Join-Path $logsDir ('app_' + $runId + '.log'))"
            "launcher_log=$(Join-Path $logsDir 'launcher_latest.log')"
        ) | Set-Content -Path $summaryLogFile -Encoding UTF8
    }
    catch {
        Write-Warn "Nao foi possivel escrever resumo em $summaryLogFile"
    }
}

function Invoke-WithRetry {
    param(
        [string]$Description,
        [scriptblock]$Command,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 3
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if ($MaxAttempts -gt 1) {
            Write-Step "$Description (tentativa $attempt/$MaxAttempts)"
        }
        else {
            Write-Step $Description
        }

        & $Command
        if ($LASTEXITCODE -eq 0) {
            return
        }

        if ($attempt -lt $MaxAttempts) {
            Write-Warn "$Description falhou com codigo $LASTEXITCODE. Tentando novamente em $DelaySeconds s..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw "$Description falhou apos $MaxAttempts tentativa(s)."
}

function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($machinePath)) { $machinePath = "" }
    if ([string]::IsNullOrWhiteSpace($userPath)) { $userPath = "" }
    $env:Path = "$machinePath;$userPath"
}

function Ensure-ProjectWritable {
    $probe = Join-Path $projectRoot ".write_test"

    try {
        "ok" | Set-Content -Path $probe -Encoding ASCII
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
    }
    catch {
        throw "Sem permissao de escrita na pasta do projeto. Mova a pasta para Documents/Desktop e tente novamente."
    }
}

function Test-PythonExe {
    param([string]$PythonExe)

    if ([string]::IsNullOrWhiteSpace($PythonExe)) {
        return $false
    }

    if (-not (Test-Path $PythonExe)) {
        return $false
    }

    try {
        $versionOutput = (& $PythonExe --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) {
            return $false
        }

        return $versionOutput -match "^Python\s+\d+\.\d+"
    }
    catch {
        return $false
    }
}

function Get-PythonExe {
    $candidates = New-Object System.Collections.Generic.List[string]

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $candidates.Add($pythonCmd.Source)
    }

    $pyCmd = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCmd) {
        try {
            $pyExe = (& py -3 -c "import sys; print(sys.executable)" 2>$null)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($pyExe)) {
                $candidates.Add($pyExe.Trim())
            }
        }
        catch {
            # Fallback para busca por caminho abaixo.
        }
    }

    $candidateRoots = @(
        "$env:LocalAppData\Programs\Python",
        "$env:ProgramFiles\Python"
    )

    foreach ($root in $candidateRoots) {
        if (Test-Path $root) {
            $executables = Get-ChildItem -Path $root -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending

            foreach ($exe in $executables) {
                if ($exe -and $exe.FullName) {
                    $candidates.Add($exe.FullName)
                }
            }
        }
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-PythonExe -PythonExe $candidate) {
            return $candidate
        }
    }

    return $null
}

function Install-Python {
    Write-Step "Python nao encontrado. Tentando instalar automaticamente..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.ServicePointManager]::SecurityProtocol
    }
    catch {
        # Ignorar se a plataforma nao suportar ajuste explicito de TLS.
    }

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Step "Instalando Python via winget..."
        & winget install --id Python.Python.3.12 -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Refresh-Path
            $installedPython = Get-PythonExe
            if ($installedPython) {
                Write-Ok "Python instalado via winget."
                return
            }

            Write-Warn "winget concluiu, mas o Python nao ficou disponivel. Tentando instalacao direta..."
        }

        Write-Warn "winget retornou codigo $LASTEXITCODE. Tentando instalacao direta..."
    }
    else {
        Write-Warn "winget nao encontrado. Tentando instalacao direta..."
    }

    $installerPath = Join-Path $env:TEMP "python-installer.exe"
    $installerUrl = "https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe"

    Invoke-WithRetry -Description "Baixando instalador oficial do Python" -MaxAttempts 2 -DelaySeconds 4 -Command {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    }

    Write-Step "Executando instalador silencioso do Python..."
    $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Instalador do Python retornou codigo $($process.ExitCode)."
    }

    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    Refresh-Path

    Write-Ok "Python instalado via instalador oficial."
}

function Ensure-Venv {
    param(
        [string]$PythonExe,
        [string]$VenvDir,
        [string]$VenvPython
    )

    if (Test-Path $VenvPython) {
        if (Test-PythonExe -PythonExe $VenvPython) {
            Write-Ok "Ambiente virtual ja existe."
            return
        }

        Write-Warn "Ambiente virtual existente esta inconsistente. Recriando automaticamente..."
    }

    if (Test-Path $VenvDir) {
        try {
            Remove-Item -Path $VenvDir -Recurse -Force
        }
        catch {
            throw "Nao foi possivel remover o venv antigo. Feche terminais/programas usando essa pasta e tente novamente."
        }
    }

    Write-Step "Criando ambiente virtual..."
    & $PythonExe -m venv $VenvDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-PythonExe -PythonExe $VenvPython)) {
        throw "Falha ao criar ambiente virtual funcional."
    }

    Write-Ok "Ambiente virtual criado."
}

function Ensure-EnvFile {
    param([string]$EnvPath)

    if (Test-Path $EnvPath) {
        Write-Ok "Arquivo .env ja existe."
        return
    }

    Write-Host ""
    Write-Host "============================================"
    Write-Host "  Configuracao inicial de credenciais"
    Write-Host "============================================"
    Write-Host ""

    $email = Read-Host "Seu email do Feedz"

    $securePassword = Read-Host "Sua senha do Feedz" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    $mood = Read-Host "Humor padrao [1-5] (padrao 4)"
    if ([string]::IsNullOrWhiteSpace($mood)) {
        $mood = "4"
    }

    if ($mood -notmatch "^[1-5]$") {
        Write-Warn "Valor de humor invalido. Usando 4."
        $mood = "4"
    }

    @(
        "FEEDZ_EMAIL=$email"
        "FEEDZ_PASSWORD=$password"
        "FEEDZ_MOOD=$mood"
        "HEADLESS=true"
    ) | Set-Content -Path $EnvPath -Encoding UTF8

    Write-Ok "Arquivo .env criado."
}

try {
    Write-Host "============================================"
    Write-Host "  Feedz Mood Bot - Bootstrap"
    Write-Host "============================================"
    Write-Host ""
    Write-Host "Run ID: $runId"
    Write-Host "Log: $logFile"
    Write-Host ""

    Ensure-ProjectWritable

    $pythonExe = Get-PythonExe
    if (-not $pythonExe) {
        Install-Python
        $pythonExe = Get-PythonExe
    }

    if (-not $pythonExe) {
        throw "Nao foi possivel localizar um Python funcional apos a tentativa de instalacao."
    }

    $pythonVersion = (& $pythonExe --version 2>&1 | Out-String).Trim()
    Write-Ok "Python encontrado em: $pythonExe"
    Write-Ok "Versao detectada: $pythonVersion"

    $venvDir = Join-Path $projectRoot "venv"
    $venvPython = Join-Path $venvDir "Scripts\python.exe"

    Ensure-Venv -PythonExe $pythonExe -VenvDir $venvDir -VenvPython $venvPython

    Invoke-WithRetry -Description "Atualizando pip" -MaxAttempts 3 -DelaySeconds 3 -Command {
        & $venvPython -m pip install --upgrade pip --disable-pip-version-check --retries 5 --timeout 60
    }

    Invoke-WithRetry -Description "Instalando dependencias do requirements.txt" -MaxAttempts 3 -DelaySeconds 4 -Command {
        & $venvPython -m pip install -r (Join-Path $projectRoot "requirements.txt") --disable-pip-version-check --retries 5 --timeout 60
    }
    Write-Ok "Dependencias instaladas."

    Invoke-WithRetry -Description "Garantindo instalacao do Chromium do Playwright" -MaxAttempts 2 -DelaySeconds 5 -Command {
        & $venvPython -m playwright install chromium
    }
    Write-Ok "Chromium pronto."

    Ensure-EnvFile -EnvPath (Join-Path $projectRoot ".env")

    if ($SetupOnly) {
        Write-Ok "Setup concluido com sucesso."
        Write-Host "Log completo em: $logFile"
        Write-RunSummary -Status "success" -Message "Setup concluido com sucesso" -ExitCode 0
        exit 0
    }

    Write-Step "Executando bot..."
    & $venvPython (Join-Path $projectRoot "main.py")
    if ($LASTEXITCODE -ne 0) {
        throw "Execucao do bot falhou com codigo $LASTEXITCODE."
    }

    Write-Ok "Execucao concluida."
    Write-Host "Log completo em: $logFile"
    Write-RunSummary -Status "success" -Message "Execucao concluida" -ExitCode 0
    exit 0
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    Write-Fail "Consulte o log para detalhes: $logFile"

    try {
        @(
            "=================================================="
            "Feedz Mood Bot - Ultimo erro"
            "timestamp=$((Get-Date).ToString('o'))"
            "run_id=$runId"
            "message=$($_.Exception.Message)"
            "exception_type=$($_.Exception.GetType().FullName)"
            "script_stack_trace=$($_.ScriptStackTrace)"
            "position_message=$($_.InvocationInfo.PositionMessage)"
            "bootstrap_log=$logFile"
            "=================================================="
            ""
        ) | Set-Content -Path $errorLogFile -Encoding UTF8
    }
    catch {
        Write-Fail "Nao foi possivel salvar detalhes em: $errorLogFile"
    }

    Write-RunSummary -Status "failed" -Message $_.Exception.Message -ExitCode 1
    exit 1
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
}
