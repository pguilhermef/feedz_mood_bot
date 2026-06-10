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
    pause
    exit /b 1
)
if not exist ".env" (
    echo ❌ Arquivo .env nao encontrado.
    echo    Rode o "instalar.bat" primeiro.
    pause
    exit /b 1
)

:: Ativar o venv
call venv\Scripts\activate.bat

:: Verificar se o venv realmente ativou
if "%VIRTUAL_ENV%"=="" (
    echo ❌ Falha ao ativar o ambiente virtual.
    echo    Tente deletar a pasta venv e rodar instalar.bat novamente.
    pause
    exit /b 1
)

python main.py
