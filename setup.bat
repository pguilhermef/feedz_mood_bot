@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ============================================
echo   Feedz Mood Bot - Setup
echo ============================================
echo.

:: --------------------------------------------------
:: 1. Verificar Python
:: --------------------------------------------------
where python >nul 2>nul
if errorlevel 1 (
    echo [ERRO] Python nao encontrado. Instale em https://www.python.org/downloads/
    echo        Marque "Add Python to PATH" durante a instalacao.
    pause
    exit /b 1
)

echo [OK] Python encontrado.

:: --------------------------------------------------
:: 2. Criar venv
:: --------------------------------------------------
if not exist "venv\" (
    echo [..] Criando ambiente virtual...
    python -m venv venv
    echo [OK] Ambiente virtual criado.
) else (
    echo [OK] Ambiente virtual ja existe.
)

call venv\Scripts\activate.bat

:: --------------------------------------------------
:: 3. Instalar dependencias
:: --------------------------------------------------
echo [..] Instalando dependencias...
pip install -q -r requirements.txt
echo [OK] Dependencias instaladas.

:: --------------------------------------------------
:: 4. Instalar navegador do Playwright
:: --------------------------------------------------
echo [..] Instalando navegador Chromium (pode demorar na primeira vez)...
playwright install chromium
echo [OK] Chromium instalado.

:: --------------------------------------------------
:: 5. Configurar .env
:: --------------------------------------------------
if exist ".env" (
    echo [OK] Arquivo .env ja existe.
    goto :env_done
)

echo.
echo ============================================
echo   Configuracao de credenciais
echo ============================================
echo.

set /p "USER_EMAIL=Seu email do Feedz: "
set /p "USER_PASSWORD=Sua senha do Feedz: "
echo.
echo Humor padrao: 1=Muito triste, 2=Triste, 3=Neutro, 4=Feliz, 5=Muito feliz
set /p "USER_MOOD=Escolha [1-5] - padrao 4: "

if "!USER_MOOD!"=="" set "USER_MOOD=4"

echo FEEDZ_EMAIL=!USER_EMAIL!> .env
echo FEEDZ_PASSWORD=!USER_PASSWORD!>> .env
echo FEEDZ_MOOD=!USER_MOOD!>> .env
echo HEADLESS=true>> .env

echo [OK] Arquivo .env criado com humor=!USER_MOOD!

:env_done

:: --------------------------------------------------
:: 6. Primeiro login (navegador visivel para resolver CAPTCHA)
:: --------------------------------------------------
echo.
echo ============================================
echo   Primeiro login
echo ============================================
echo O navegador vai abrir para voce logar pela primeira vez.
echo Isso salva a sessao para as proximas execucoes.
echo.
pause

python main.py

:: --------------------------------------------------
:: 7. Agendar execucao diaria
:: --------------------------------------------------
echo.
echo ============================================
echo   Agendamento diario
echo ============================================
echo.
set /p "SCHEDULE=Quer agendar execucao diaria? (S/N): "

if /i "!SCHEDULE!" neq "S" (
    echo.
    echo [OK] Setup completo! Rode "run.bat" quando quiser executar manualmente.
    pause
    exit /b 0
)

set /p "HORA=Horario de execucao (ex: 08:30): "

if "!HORA!"=="" set HORA=08:30

:: Criar tarefa no Agendador do Windows
set "TASK_NAME=FeedzMoodBot"
set "SCRIPT_PATH=%~dp0run.bat"

schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\"" /sc daily /st !HORA! /f >nul 2>nul

if errorlevel 1 (
    echo.
    echo [AVISO] Nao foi possivel criar a tarefa automaticamente.
    echo         Pode ser necessario rodar o setup como Administrador.
    echo.
    echo         Alternativa manual:
    echo         1. Abra o Agendador de Tarefas (taskschd.msc)
    echo         2. Criar Tarefa Basica
    echo         3. Nome: FeedzMoodBot
    echo         4. Disparador: Diariamente as !HORA!
    echo         5. Acao: Iniciar programa: "%SCRIPT_PATH%"
) else (
    echo [OK] Tarefa agendada! O bot vai rodar todo dia as !HORA!.
    echo     Nome da tarefa: %TASK_NAME%
    echo     Para remover: schtasks /delete /tn "%TASK_NAME%" /f
)

echo.
echo ============================================
echo   Setup completo!
echo ============================================
echo.
pause
