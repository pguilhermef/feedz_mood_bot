@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "APP_DIR=%~dp0.."
set "VENV_ACTIVATE=%APP_DIR%\venv\Scripts\activate.bat"
set "MAIN_FILE=%APP_DIR%\main.py"
set "DIST_DIR=%APP_DIR%\dist"

if not exist "%VENV_ACTIVATE%" (
    echo ❌ Ambiente virtual nao encontrado em "%APP_DIR%\venv".
    echo    Rode run.bat uma vez para preparar o ambiente.
    pause
    exit /b 1
)

echo.
echo ══════════════════════════════════════════
echo   Gerando executavel (.exe)
echo ══════════════════════════════════════════
echo.

:: Ativar venv
call "%VENV_ACTIVATE%"

:: Instalar PyInstaller se necessario
pip show pyinstaller >nul 2>nul
if errorlevel 1 (
    echo [..] Instalando PyInstaller...
    pip install pyinstaller
)

:: Gerar o .exe
echo [..] Gerando feedz_mood_bot.exe...
pyinstaller --onefile --name feedz_mood_bot --console "%MAIN_FILE%"

if errorlevel 1 (
    echo ❌ Falha ao gerar o executavel.
    pause
    exit /b 1
)

echo.
echo ✅ Executavel gerado em: "%DIST_DIR%\feedz_mood_bot.exe"
echo.
echo Para distribuir, envie:
echo   - "%DIST_DIR%\feedz_mood_bot.exe"
echo   - O usuario precisa criar um .env na mesma pasta
echo.
pause
