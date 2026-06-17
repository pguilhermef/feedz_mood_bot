@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "PROJECT_DIR=%~dp0"
set "BOOTSTRAP_PS1=%~dp0bootstrap.ps1"
set "LOGS_DIR=%PROJECT_DIR%logs"
set "LAUNCHER_LOG=%LOGS_DIR%\launcher_latest.log"

set "RUN_ID=%DATE%_%TIME%"
set "RUN_ID=%RUN_ID: =0%"
set "RUN_ID=%RUN_ID:/=-%"
set "RUN_ID=%RUN_ID::=-%"
set "RUN_ID=%RUN_ID:.=-%"
set "RUN_ID=%RUN_ID:,=-%"
set "FEEDZ_RUN_ID=%RUN_ID%"

if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%" >nul 2>nul

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

if not exist "%BOOTSTRAP_PS1%" (
    echo [ERRO] Arquivo bootstrap.ps1 nao encontrado.
    >>"%LAUNCHER_LOG%" echo [ERRO] bootstrap.ps1 nao encontrado.
    >>"%LAUNCHER_LOG%" echo Caminho esperado: %BOOTSTRAP_PS1%
    pause
    exit /b 1
)

call :resolve_powershell
if errorlevel 1 (
    echo [ERRO] PowerShell nao encontrado nesta maquina.
    echo        Nao foi possivel iniciar o bootstrap.
    >>"%LAUNCHER_LOG%" echo [ERRO] PowerShell nao encontrado.
    pause
    exit /b 1
)

>>"%LAUNCHER_LOG%" echo PowerShell detectado: %PS_EXE%

if not exist "%PS_EXE%" (
    echo [ERRO] Executavel do PowerShell nao existe no caminho detectado.
    >>"%LAUNCHER_LOG%" echo [ERRO] Caminho invalido para PowerShell: %PS_EXE%
    pause
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
    pause
    exit /b %BOOTSTRAP_EXIT%
)

echo.
echo [OK] Processo concluido.
pause
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
