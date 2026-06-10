@echo off
cd /d "%~dp0"

:: Se nao tem venv ou .env, rodar setup primeiro
if not exist "venv\Scripts\activate.bat" goto :run_setup
if not exist ".env" goto :run_setup
goto :run_main

:run_setup
echo [..] Primeira execucao detectada. Rodando setup...
echo.
call "%~dp0setup.bat"
if errorlevel 1 (
    echo [ERRO] Setup falhou.
    pause
    exit /b 1
)
echo.

:run_main
:: Ativar o venv
call venv\Scripts\activate.bat

:: Verificar se o venv realmente ativou (VIRTUAL_ENV é setado pelo activate)
if "%VIRTUAL_ENV%"=="" (
    echo [ERRO] Falha ao ativar o ambiente virtual.
    echo        Tente deletar a pasta venv e rodar novamente.
    pause
    exit /b 1
)

echo [OK] Ambiente virtual ativo.
python main.py
