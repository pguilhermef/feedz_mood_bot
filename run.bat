@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "PROJECT_DIR=%~dp0"
set "BOOTSTRAP_PS1=%~dp0bootstrap.ps1"
set "LOGS_DIR=%PROJECT_DIR%logs"
set "TASK_NAME=FeedzMoodBot"
set "TASK_TIME=08:30"
set "TASK_SCRIPT=%~f0"

call :ensure_logs_dir "%LOGS_DIR%"
if errorlevel 1 (
    set "LOGS_DIR=%TEMP%\FeedzMoodBotLogs"
    call :ensure_logs_dir "%LOGS_DIR%"
)

if errorlevel 1 (
    echo [ERRO] Nao foi possivel preparar pasta de logs.
    echo        Verifique permissao de escrita em "%PROJECT_DIR%" e em "%TEMP%".
    call :pause_on_error
    exit /b 1
)

set "LAUNCHER_LOG=%LOGS_DIR%\launcher_latest.log"

set "RUN_ID=%DATE%_%TIME%"
set "RUN_ID=%RUN_ID: =0%"
set "RUN_ID=%RUN_ID:/=-%"
set "RUN_ID=%RUN_ID::=-%"
set "RUN_ID=%RUN_ID:.=-%"
set "RUN_ID=%RUN_ID:,=-%"
set "FEEDZ_RUN_ID=%RUN_ID%"

>"%LAUNCHER_LOG%" (
    echo ============================================
    echo Feedz Mood Bot - Launcher
    echo Run ID: %RUN_ID%
    echo Data/Hora: %date% %time%
    echo Computador: %COMPUTERNAME%
    echo Usuario: %USERNAME%
    echo Pasta do projeto: %PROJECT_DIR%
    echo ============================================
)

echo [..] Iniciando Feedz Mood Bot...
echo [..] Log do launcher: "%LAUNCHER_LOG%"
>>"%LAUNCHER_LOG%" echo CMD version: %CMDEXTVERSION%
>>"%LAUNCHER_LOG%" echo COMSPEC: %COMSPEC%
>>"%LAUNCHER_LOG%" echo FEEDZ_RUN_ID: %FEEDZ_RUN_ID%

call :resolve_powershell
if errorlevel 1 (
    echo [ERRO] PowerShell nao encontrado nesta maquina.
    echo        Nao foi possivel iniciar o bootstrap.
    >>"%LAUNCHER_LOG%" echo [ERRO] PowerShell nao encontrado.
    call :pause_on_error
    exit /b 1
)

>>"%LAUNCHER_LOG%" echo PowerShell detectado: %PS_EXE%

if not exist "%PS_EXE%" (
    echo [ERRO] Executavel do PowerShell nao existe no caminho detectado.
    >>"%LAUNCHER_LOG%" echo [ERRO] Caminho invalido para PowerShell: %PS_EXE%
    call :pause_on_error
    exit /b 1
)

call :ensure_daily_task

if not exist "%BOOTSTRAP_PS1%" (
    echo [ERRO] Arquivo bootstrap.ps1 nao encontrado.
    >>"%LAUNCHER_LOG%" echo [ERRO] bootstrap.ps1 nao encontrado.
    >>"%LAUNCHER_LOG%" echo Caminho esperado: %BOOTSTRAP_PS1%
    call :pause_on_error
    exit /b 1
)

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%"
set "BOOTSTRAP_EXIT=%ERRORLEVEL%"
>>"%LAUNCHER_LOG%" echo Codigo de saida do bootstrap: %BOOTSTRAP_EXIT%

if errorlevel 1 (
    echo.
    echo [ERRO] Fluxo automatico falhou.
    echo        Consulte os logs em: "%LOGS_DIR%"
    echo        Se necessario, mova a pasta do projeto para "Documentos" e rode de novo.
    call :show_failure_summary
    call :pause_on_error
    exit /b %BOOTSTRAP_EXIT%
)

echo.
echo [OK] Processo concluido.
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

:show_failure_summary
set "SUMMARY_LOG=%LOGS_DIR%\summary_latest.txt"
set "ERROR_LOG=%LOGS_DIR%\error_latest.log"

if exist "%SUMMARY_LOG%" (
    echo.
    echo ===== RESUMO DA ULTIMA EXECUCAO =====
    type "%SUMMARY_LOG%"
)

if exist "%ERROR_LOG%" (
    echo.
    echo ===== ERRO TECNICO DETALHADO =====
    type "%ERROR_LOG%"
)

exit /b 0

:pause_on_error
echo.
echo [..] O terminal ficara aberto para voce revisar o erro.
pause
exit /b 0

:ensure_daily_task
echo [..] Verificando agendamento diario...
>>"%LAUNCHER_LOG%" echo Verificando tarefa agendada: %TASK_NAME%

schtasks /query /tn "%TASK_NAME%" >nul 2>nul
if not errorlevel 1 (
    echo [OK] Tarefa agendada ja existe: %TASK_NAME%
    >>"%LAUNCHER_LOG%" echo Tarefa ja existe: %TASK_NAME%
    call :ensure_task_start_when_available
    exit /b 0
)

schtasks /create /tn "%TASK_NAME%" /tr "\"%TASK_SCRIPT%\"" /sc daily /st %TASK_TIME% /f >nul 2>nul
if errorlevel 1 (
    echo [AVISO] Nao foi possivel criar tarefa agendada automaticamente.
    echo         O bot vai continuar a execucao normal.
    >>"%LAUNCHER_LOG%" echo Falha ao criar tarefa %TASK_NAME% em %TASK_TIME%
    exit /b 0
)

echo [OK] Tarefa agendada criada: %TASK_NAME% (%TASK_TIME% diario)
>>"%LAUNCHER_LOG%" echo Tarefa criada com sucesso: %TASK_NAME% (%TASK_TIME% diario)
call :ensure_task_start_when_available
exit /b 0

:ensure_task_start_when_available
set "FEEDZ_TASK_NAME=%TASK_NAME%"
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$taskName = $env:FEEDZ_TASK_NAME; try { $service = New-Object -ComObject 'Schedule.Service'; $service.Connect(); $root = $service.GetFolder('\\'); $task = $root.GetTask($taskName); $def = $task.Definition; if (-not $def.Settings.StartWhenAvailable) { $def.Settings.StartWhenAvailable = $true; $null = $root.RegisterTaskDefinition($taskName, $def, 6, $null, $null, $def.Principal.LogonType, $null) }; exit 0 } catch { exit 1 }" >nul 2>nul
if errorlevel 1 (
    echo [AVISO] Nao foi possivel ativar execucao apos horario perdido.
    echo         O bot continua funcionando, mas sem recuperacao automatica.
    >>"%LAUNCHER_LOG%" echo Falha ao ativar StartWhenAvailable na tarefa %TASK_NAME%
    exit /b 0
)

echo [OK] Recuperacao apos horario perdido ativada para %TASK_NAME%.
>>"%LAUNCHER_LOG%" echo StartWhenAvailable ativo para %TASK_NAME%
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
