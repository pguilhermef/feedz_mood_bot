@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: ============================================
:: Feedz Mood Bot - Executar
:: ============================================

:: Se nao tem venv ou .env, orientar a rodar instalar.bat
if not exist "venv\Scripts\activate.bat" (
    echo ❌ Bot nao instalado ainda.
    echo    Rode o "instalar.bat" primeiro.
    goto :error_exit
)
if not exist ".env" (
    echo ❌ Arquivo .env nao encontrado.
    echo    Rode o "instalar.bat" primeiro.
    goto :error_exit
)

:: Ativar o venv
call venv\Scripts\activate.bat

:: Verificar se o venv realmente ativou
if "%VIRTUAL_ENV%"=="" (
    echo ❌ Falha ao ativar o ambiente virtual.
    echo    Tente deletar a pasta venv e rodar instalar.bat novamente.
    goto :error_exit
)

python main.py

:: Mostrar resultado
if errorlevel 1 (
    echo.
    echo ⚠️  O bot encontrou um problema. Veja as mensagens acima.
) else (
    echo.
    echo ✅ Bot finalizado.
)

:: Só dar pause se rodou manualmente (não pelo Task Scheduler)
echo %cmdcmdline% | find /i "/c" >nul
if errorlevel 1 (
    timeout /t 5 >nul
)
exit /b 0

:error_exit
echo %cmdcmdline% | find /i "/c" >nul
if errorlevel 1 (
    pause
)
exit /b 1
