@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "PROJECT_DIR=%~dp0"
set "BOOTSTRAP_PS1=%~dp0bootstrap.ps1"
set "LOGS_DIR=%PROJECT_DIR%logs"

call :ensure_logs_dir "%LOGS_DIR%"
if errorlevel 1 (
    set "LOGS_DIR=%TEMP%\FeedzMoodBotLogs"
    call :ensure_logs_dir "%LOGS_DIR%"
)

if errorlevel 1 (
    echo [ERRO] Nao foi possivel preparar pasta de logs.
    echo        Verifique permissao de escrita em "%PROJECT_DIR%" e em "%TEMP%".
    pause
    exit /b 1
)

set "INSTALLER_LOG=%LOGS_DIR%\installer_latest.log"

>"%INSTALLER_LOG%" (
    echo ============================================
    echo Feedz Mood Bot - Instalador
    echo Data/Hora: %date% %time%
    echo Computador: %COMPUTERNAME%
    echo Usuario: %USERNAME%
    echo Pasta do projeto: %PROJECT_DIR%
    echo ============================================
)

echo ============================================
echo   Feedz Mood Bot - Instalador
echo ============================================
echo.
echo [..] Executando setup automatico...
echo [..] Log do instalador: "%INSTALLER_LOG%"

if not exist "%BOOTSTRAP_PS1%" (
    echo [ERRO] Arquivo bootstrap.ps1 nao encontrado.
    >>"%INSTALLER_LOG%" echo [ERRO] bootstrap.ps1 nao encontrado.
    >>"%INSTALLER_LOG%" echo Caminho esperado: %BOOTSTRAP_PS1%
    pause
    exit /b 1
)

call :resolve_powershell
if errorlevel 1 (
    echo [ERRO] PowerShell nao encontrado nesta maquina.
    echo        Nao foi possivel iniciar o setup automatico.
    >>"%INSTALLER_LOG%" echo [ERRO] PowerShell nao encontrado.
    pause
    exit /b 1
)

>>"%INSTALLER_LOG%" echo PowerShell detectado: %PS_EXE%

if not exist "%PS_EXE%" (
    echo [ERRO] Executavel do PowerShell nao existe no caminho detectado.
    >>"%INSTALLER_LOG%" echo [ERRO] Caminho invalido para PowerShell: %PS_EXE%
    pause
    exit /b 1
)

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" -SetupOnly
set "SETUP_EXIT=%ERRORLEVEL%"
>>"%INSTALLER_LOG%" echo Codigo de saida do bootstrap (setup): %SETUP_EXIT%

if errorlevel 1 (
    echo.
    echo [ERRO] Setup automatico falhou.
    echo        Consulte os logs em: "%LOGS_DIR%"
    pause
    exit /b %SETUP_EXIT%
)

echo.
echo [OK] Setup concluido com sucesso.
echo [..] Agora clique em run.bat para executar o bot.
pause
exit /b 0

:ensure_logs_dir
set "TARGET_LOGS_DIR=%~1"
if not exist "%TARGET_LOGS_DIR%" mkdir "%TARGET_LOGS_DIR%" >nul 2>nul
if not exist "%TARGET_LOGS_DIR%" exit /b 1

set "PROBE_FILE=%TARGET_LOGS_DIR%\.write_test"
(echo ok>"%PROBE_FILE%") >nul 2>nul
if not exist "%PROBE_FILE%" exit /b 1
del "%PROBE_FILE%" >nul 2>nul
exit /b 0

:resolve_powershell
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%PS_EXE%" exit /b 0

for %%P in (powershell.exe pwsh.exe) do (
    for /f "delims=" %%I in ('where %%P 2^>nul') do (
        set "PS_EXE=%%I"
        exit /b 0
    )
)

exit /b 1
