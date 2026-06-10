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

python criar_env.py
if errorlevel 1 (
    echo ❌ Falha ao configurar credenciais.
    pause
    exit /b 1
)

:config_done

:: --------------------------------------------------
:: 6. Agendar execucao diaria (opcional)
:: --------------------------------------------------
echo.
echo ══════════════════════════════════════════
echo   Agendamento automatico (opcional)
echo ══════════════════════════════════════════
echo.
echo Como quer executar o bot?
echo   1 = Rodar automaticamente ao ligar/logar no PC
echo   2 = Rodar em um horario fixo todo dia
echo   3 = Nao agendar (vou rodar manualmente)
echo.
set /p "SCHEDULE_OPT=Escolha [1/2/3]: "

if "!SCHEDULE_OPT!"=="1" (
    set "TASK_NAME=FeedzMoodBot"
    set "SCRIPT_PATH=%~dp0run.bat"
    schtasks /create /tn "!TASK_NAME!" /tr "\"!SCRIPT_PATH!\"" /sc onlogon /delay 0001:00 /f >nul 2>nul
    if errorlevel 1 (
        echo.
        echo ⚠️  Nao foi possivel agendar automaticamente.
        echo    Tente rodar este instalador como Administrador.
    ) else (
        echo ✅ Agendado! O bot vai rodar 1 min apos voce logar no PC.
        echo    Para remover: schtasks /delete /tn "!TASK_NAME!" /f
    )
    goto :skip_schedule
)

if "!SCHEDULE_OPT!"=="2" (
    set /p "HORA=Horario de execucao (ex: 08:30): "
    if "!HORA!"=="" set "HORA=08:30"
    set "TASK_NAME=FeedzMoodBot"
    set "SCRIPT_PATH=%~dp0run.bat"
    schtasks /create /tn "!TASK_NAME!" /tr "\"!SCRIPT_PATH!\"" /sc daily /st !HORA! /f >nul 2>nul
    if errorlevel 1 (
        echo.
        echo ⚠️  Nao foi possivel agendar automaticamente.
        echo    Tente rodar este instalador como Administrador.
    ) else (
        echo ✅ Agendado! O bot vai rodar todo dia as !HORA!.
        echo    Para remover: schtasks /delete /tn "!TASK_NAME!" /f
    )
    goto :skip_schedule
)

echo OK, sem agendamento. Rode run.bat quando quiser.

:skip_schedule

:: --------------------------------------------------
:: 7. Primeiro login (navegador visivel)
:: --------------------------------------------------
echo.
echo ══════════════════════════════════════════
echo   Primeiro login
echo ══════════════════════════════════════════
echo.
echo O navegador vai abrir VISIVEL para o primeiro login.
echo Se aparecer CAPTCHA, resolva manualmente.
echo A sessao sera salva para as proximas execucoes.
echo.

set "HEADLESS=false"
python main.py
set "HEADLESS="

echo.
echo ══════════════════════════════════════════
echo   Instalacao concluida!
echo ══════════════════════════════════════════
echo.
echo   Nas proximas vezes, o bot roda em segundo plano (sem abrir navegador).
echo   Para rodar manualmente: clique duas vezes em run.bat
echo.
pause
