@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo ══════════════════════════════════════════
echo   Gerando executavel (.exe)
echo ══════════════════════════════════════════
echo.

:: Ativar venv
call venv\Scripts\activate.bat

:: Instalar PyInstaller se necessario
pip show pyinstaller >nul 2>nul
if errorlevel 1 (
    echo [..] Instalando PyInstaller...
    pip install pyinstaller
)

:: Gerar o .exe
echo [..] Gerando feedz_mood_bot.exe...
pyinstaller --onefile --name feedz_mood_bot --console main.py

if errorlevel 1 (
    echo ❌ Falha ao gerar o executavel.
    pause
    exit /b 1
)

echo.
echo ✅ Executavel gerado em: dist\feedz_mood_bot.exe
echo.
echo Para distribuir, envie:
echo   - dist\feedz_mood_bot.exe
echo   - O usuario precisa criar um .env na mesma pasta
echo.
pause
