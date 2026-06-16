@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "BOOTSTRAP_PS1=%~dp0bootstrap.ps1"

if not exist "%BOOTSTRAP_PS1%" (
    echo [ERRO] Arquivo bootstrap.ps1 nao encontrado.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" -SetupOnly
if errorlevel 1 (
    echo.
    echo [ERRO] Setup automatico falhou.
    echo        Consulte a pasta logs para detalhes.
    pause
    exit /b 1
)

echo.
echo [OK] Setup concluido.
pause
