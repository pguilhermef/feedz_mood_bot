@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ╔══════════════════════════════════════════╗
echo ║     Feedz Mood Bot - Instalador         ║
echo ║     Um clique e pronto!                 ║
echo ╚══════════════════════════════════════════╝
echo.

:: --------------------------------------------------
:: 1. Verificar Python
:: --------------------------------------------------
where python >nul 2>nul
if errorlevel 1 (
    echo ❌ Python nao encontrado!
    echo.
    echo    Instale em: https://www.python.org/downloads/
    echo    IMPORTANTE: Marque "Add Python to PATH" durante a instalacao.
    echo.
    echo    Depois de instalar, rode este arquivo novamente.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo ✅ %PYVER% encontrado.

:: --------------------------------------------------
:: 2. Criar ambiente virtual
:: --------------------------------------------------
if not exist "venv\" (
    echo.
    echo [..] Criando ambiente virtual...
    python -m venv venv
    if errorlevel 1 (
        echo ❌ Falha ao criar ambiente virtual.
        pause
        exit /b 1
    )
    echo ✅ Ambiente virtual criado.
) else (
    echo ✅ Ambiente virtual ja existe.
)

call venv\Scripts\activate.bat

:: --------------------------------------------------
:: 3. Instalar dependencias
:: --------------------------------------------------
echo.
echo [..] Instalando dependencias...
pip install -q -r requirements.txt
if errorlevel 1 (
    echo ❌ Falha ao instalar dependencias.
    pause
    exit /b 1
)
echo ✅ Dependencias instaladas.

:: --------------------------------------------------
:: 4. Instalar navegador Chromium
:: --------------------------------------------------
echo [..] Instalando navegador (pode demorar na primeira vez)...
playwright install chromium >nul 2>nul
echo ✅ Navegador instalado.

:: --------------------------------------------------
:: 5. Configurar credenciais
:: --------------------------------------------------
if exist ".env" (
    echo.
    echo ✅ Configuracao (.env) ja existe.
    goto :config_done
)

echo.
echo ══════════════════════════════════════════
echo   Configure suas credenciais do Feedz
echo ══════════════════════════════════════════
echo.

set /p "USER_EMAIL=📧 Seu email do Feedz: "
set /p "USER_PASSWORD=🔑 Sua senha do Feedz: "
echo.
echo 😊 Escolha seu humor padrao:
echo    1 = Muito triste
echo    2 = Triste
echo    3 = Neutro
echo    4 = Feliz
echo    5 = Muito feliz
echo.
set /p "USER_MOOD=Escolha [1-5] (padrao: 4): "

if "!USER_MOOD!"=="" set "USER_MOOD=4"

echo FEEDZ_EMAIL=!USER_EMAIL!> .env
echo FEEDZ_PASSWORD=!USER_PASSWORD!>> .env
echo FEEDZ_MOOD=!USER_MOOD!>> .env
echo HEADLESS=true>> .env

echo.
echo ✅ Configuracao salva!

:config_done

:: --------------------------------------------------
:: 6. Agendar execucao diaria (opcional)
:: --------------------------------------------------
echo.
echo ══════════════════════════════════════════
echo   Agendamento automatico (opcional)
echo ══════════════════════════════════════════
echo.
set /p "SCHEDULE=Quer que o bot rode sozinho todo dia? (S/N): "

if /i "!SCHEDULE!" neq "S" goto :skip_schedule

set /p "HORA=Horario de execucao (ex: 08:30): "
if "!HORA!"=="" set "HORA=08:30"

set "TASK_NAME=FeedzMoodBot"
set "SCRIPT_PATH=%~dp0run.bat"

schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\"" /sc daily /st !HORA! /f >nul 2>nul

if errorlevel 1 (
    echo.
    echo ⚠️  Nao foi possivel agendar automaticamente.
    echo    Pode ser necessario rodar como Administrador.
    echo    Ou agende manualmente: Agendador de Tarefas ^> run.bat as !HORA!
) else (
    echo ✅ Agendado! O bot vai rodar todo dia as !HORA!.
    echo    Para remover: schtasks /delete /tn "%TASK_NAME%" /f
)

:skip_schedule

:: --------------------------------------------------
:: 7. Primeiro teste
:: --------------------------------------------------
echo.
echo ══════════════════════════════════════════
echo   Testando o bot...
echo ══════════════════════════════════════════
echo.
echo O bot vai rodar agora para confirmar que tudo funciona.
echo.

python main.py

echo.
echo ══════════════════════════════════════════
echo   Instalacao concluida!
echo ══════════════════════════════════════════
echo.
echo   Para rodar manualmente: clique duas vezes em run.bat
echo.
pause
