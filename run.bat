@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "IS_SCHEDULED_RUN=0"
if /i "%~1"=="--scheduled" set "IS_SCHEDULED_RUN=1"

set "PROJECT_DIR=%~dp0"
set "APP_DIR=%PROJECT_DIR%app"
set "BOOTSTRAP_PS1=%APP_DIR%\bootstrap.ps1"
set "ENSURE_TASK_PS1=%APP_DIR%\ensure_task.ps1"
set "LOGS_DIR=%APP_DIR%\logs"
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
>>"%LAUNCHER_LOG%" echo APP_DIR: %APP_DIR%
>>"%LAUNCHER_LOG%" echo IS_SCHEDULED_RUN: %IS_SCHEDULED_RUN%

if not exist "%APP_DIR%" (
    echo [ERRO] Pasta interna "app" nao encontrada.
    >>"%LAUNCHER_LOG%" echo [ERRO] Pasta app nao encontrada em: %APP_DIR%
    call :pause_on_error
    exit /b 1
)

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
if "%IS_SCHEDULED_RUN%"=="1" exit /b 0
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
if "%IS_SCHEDULED_RUN%"=="1" exit /b 0
echo.
echo [..] O terminal ficara aberto para voce revisar o erro.
pause
exit /b 0

:ensure_daily_task
echo [..] Verificando agendamento diario...
>>"%LAUNCHER_LOG%" echo Verificando tarefa agendada: %TASK_NAME%

if not exist "%ENSURE_TASK_PS1%" (
    echo [AVISO] Script de agendamento robusto nao encontrado: "%ENSURE_TASK_PS1%"
    >>"%LAUNCHER_LOG%" echo Falha: ensure_task.ps1 nao encontrado em %ENSURE_TASK_PS1%
    exit /b 0
)

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%ENSURE_TASK_PS1%" -TaskName "%TASK_NAME%" -TaskScript "%TASK_SCRIPT%" -TaskTime "%TASK_TIME%" >nul 2>nul
if errorlevel 1 (
    echo [AVISO] Nao foi possivel aplicar politica forte da tarefa agendada.
    echo         O bot continua funcionando, mas sem garantia total de recuperacao.
    >>"%LAUNCHER_LOG%" echo Falha ao aplicar politica forte na tarefa %TASK_NAME%
    exit /b 0
)

echo [OK] Tarefa %TASK_NAME% validada com recuperacao, bateria e gatilhos de backup.
>>"%LAUNCHER_LOG%" echo Politica valida: StartWhenAvailable=ON, bateria=permitido, triggers=daily/startup/logon
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
