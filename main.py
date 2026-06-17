"""
Feedz Mood Bot - Preenche o humor diário na plataforma Feedz automaticamente.
Usa perfil persistente do navegador para manter a sessão (evita CAPTCHA).
"""

import os
import sys
import shutil
import logging
from pathlib import Path
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

load_dotenv()

FEEDZ_EMAIL = os.getenv("FEEDZ_EMAIL")
FEEDZ_PASSWORD = os.getenv("FEEDZ_PASSWORD")
FEEDZ_MOOD = os.getenv("FEEDZ_MOOD", "4")  # 1=Muito Mal, 2=Mal, 3=Neutro, 4=Bem, 5=Muito Bem
HEADLESS = os.getenv("HEADLESS", "true").lower() == "true"

FEEDZ_URL = "https://app.feedz.com.br"
PROFILE_DIR = Path(__file__).parent / "browser_profile"
LOGS_DIR = Path(__file__).parent / "logs"

RUN_ID_RAW = os.getenv("FEEDZ_RUN_ID", "manual")
RUN_ID = "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in RUN_ID_RAW)
APP_LOG_FILE = LOGS_DIR / f"app_{RUN_ID}.log"
APP_LOG_LATEST = LOGS_DIR / "app_latest.log"


def init_logger() -> logging.Logger:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger("feedz_mood_bot")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    file_handler = logging.FileHandler(APP_LOG_FILE, encoding="utf-8")
    formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    logger.propagate = False

    return logger


LOGGER = init_logger()


def sync_latest_log():
    try:
        shutil.copyfile(APP_LOG_FILE, APP_LOG_LATEST)
    except Exception:
        # Se falhar para atualizar o atalho do ultimo log, o arquivo principal ja existe.
        pass


def validate_env():
    try:
        mood = int(FEEDZ_MOOD)
    except (ValueError, TypeError):
        print("❌ FEEDZ_MOOD inválido no .env. Use um número de 1 a 5.")
        print("   Edite o arquivo .env e corrija o valor de FEEDZ_MOOD.")
        LOGGER.error("FEEDZ_MOOD invalido no .env: %s", FEEDZ_MOOD)
        sys.exit(1)

    if mood < 1 or mood > 5:
        print("❌ FEEDZ_MOOD deve ser entre 1 e 5")
        print("   Edite o arquivo .env e corrija o valor de FEEDZ_MOOD.")
        LOGGER.error("FEEDZ_MOOD fora do intervalo permitido: %s", FEEDZ_MOOD)
        sys.exit(1)


def is_logged_in(page) -> bool:
    """Verifica se já estamos logados checando se o formulário de login está visível."""
    try:
        # Se o botão de login existe e está visível, ainda não logou
        if page.locator('#enter-login').is_visible(timeout=2000):
            return False
    except Exception:
        pass
    # Confirma que estamos no Feedz e não numa página de erro
    return "app.feedz.com.br" in page.url


def _fill_first_visible(page, selectors: list[str], value: str, label: str) -> bool:
    """Preenche o primeiro campo visível entre os seletores informados."""
    for selector in selectors:
        try:
            field = page.locator(selector).first
            if field.is_visible(timeout=1200):
                field.click()
                field.fill("")
                field.type(value, delay=20)
                LOGGER.info("Campo %s preenchido com seletor: %s", label, selector)
                return True
        except Exception:
            continue

    LOGGER.warning("Nenhum campo visivel encontrado para %s", label)
    return False


def _click_first_visible(page, selectors: list[str], label: str) -> bool:
    """Clica no primeiro elemento visível entre os seletores informados."""
    for selector in selectors:
        try:
            element = page.locator(selector).first
            if element.is_visible(timeout=1200):
                element.click()
                LOGGER.info("Elemento %s clicado com seletor: %s", label, selector)
                return True
        except Exception:
            continue

    LOGGER.warning("Nenhum elemento visivel encontrado para %s", label)
    return False


def do_login(page):
    """Tenta fazer login automático. Se falhar (CAPTCHA etc), pede login manual."""
    print("🔑 Fazendo login...")

    try:
        page.wait_for_timeout(1500)

        email_ok = _fill_first_visible(
            page,
            [
                'input[name="login_email"]',
                'input[id="login_email"]',
                'input[type="email"]',
                'input[name*="email" i]',
                'input[id*="email" i]',
                'input[type="text"]',
            ],
            FEEDZ_EMAIL,
            "email",
        )

        password_ok = _fill_first_visible(
            page,
            [
                'input[name="login_password"]',
                'input[id="login_password"]',
                'input[type="password"]',
                'input[name*="password" i]',
                'input[id*="password" i]',
                'input[name*="senha" i]',
                'input[id*="senha" i]',
            ],
            FEEDZ_PASSWORD,
            "senha",
        )

        if not (email_ok and password_ok):
            LOGGER.warning("Preenchimento automatico incompleto: email_ok=%s, password_ok=%s", email_ok, password_ok)
            return

        submit_ok = _click_first_visible(
            page,
            [
                '#enter-login',
                'button[type="submit"]',
                'input[type="submit"]',
                'button:has-text("Entrar")',
                'button:has-text("Login")',
            ],
            "botao_login",
        )

        if not submit_ok:
            LOGGER.warning("Nao foi possivel clicar no botao de login automaticamente")
            return

        page.wait_for_load_state("networkidle", timeout=15000)

        if is_logged_in(page):
            print("✅ Login automático realizado!")
            LOGGER.info("Login automatico concluido")
            return
    except (PlaywrightTimeout, Exception):
        LOGGER.exception("Erro durante tentativa de login automatico")

    # Login automático falhou (CAPTCHA, mudança de interface, etc)
    print("⚠️  Login automático falhou (possível CAPTCHA).")
    LOGGER.warning("Login automatico falhou; pode ser CAPTCHA ou mudanca de layout")


def run():
    validate_env()

    print(f"🤖 Iniciando bot (humor: {FEEDZ_MOOD}/5)")
    LOGGER.info("Inicio da execucao | run_id=%s | humor=%s | headless_env=%s", RUN_ID, FEEDZ_MOOD, HEADLESS)

    # Na primeira vez ou quando o login expirar, abre visível para o usuário logar
    # Nas próximas vezes, a sessão já está salva no perfil
    first_run = not PROFILE_DIR.exists()
    use_headless = HEADLESS and not first_run
    LOGGER.info("Configuracao de execucao | first_run=%s | use_headless=%s", first_run, use_headless)

    if first_run:
        print("🆕 Primeiro uso! O navegador vai abrir visível para você logar.")
        print("   Nas próximas vezes, a sessão será reutilizada.")

    logged_in = _run_with_headless(use_headless)

    # Se falhou em headless, reabre visível para o usuário resolver
    if not logged_in and use_headless:
        print("")
        print("🔄 Reabrindo navegador visível para você resolver...")
        print("   (Sessão expirou ou CAPTCHA detectado)")
        print("")
        LOGGER.warning("Fallback para modo visivel apos falha de login em headless")
        _run_with_headless(False)


def _run_with_headless(use_headless: bool) -> bool:
    """Executa o fluxo do bot. Retorna True se logou com sucesso."""
    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=str(PROFILE_DIR),
            headless=use_headless,
            accept_downloads=False,
        )
        page = context.pages[0] if context.pages else context.new_page()

        try:
            # 1. Navegar para o Feedz
            print("🌐 Abrindo Feedz...")
            LOGGER.info("Abrindo URL do Feedz: %s", FEEDZ_URL)
            page.goto(FEEDZ_URL, wait_until="networkidle", timeout=30000)

            # 2. Login (só se necessário)
            if not is_logged_in(page):
                if FEEDZ_EMAIL and FEEDZ_PASSWORD:
                    do_login(page)

                # Verificar se login funcionou
                if not is_logged_in(page):
                    if use_headless:
                        print("⚠️  Login falhou em modo invisível.")
                        LOGGER.warning("Login falhou em modo headless")
                        context.close()
                        return False

                    print("⚠️  Login automático falhou.")
                    print("👉 Faça login manualmente no navegador (120s)...")
                    for _ in range(60):
                        page.wait_for_timeout(2000)
                        if is_logged_in(page):
                            print("✅ Login manual detectado!")
                            break
                    else:
                        print("❌ Timeout aguardando login.")
                        LOGGER.error("Timeout aguardando login manual")
                        context.close()
                        return False
            else:
                print("✅ Sessão ativa! Login não necessário.")
                LOGGER.info("Sessao ativa detectada")

            # 3. Aguardar página carregar e verificar popup de pesquisa
            print("⏳ Aguardando página carregar...")
            page.wait_for_timeout(10000)

            try:
                close_btn = page.locator('button.close[data-dismiss="modal"][aria-label="close"]')
                if close_btn.is_visible(timeout=3000):
                    close_btn.click()
                    print("✅ Popup de pesquisa fechado.")
                    page.wait_for_timeout(1000)
            except (PlaywrightTimeout, Exception):
                pass

            # 4. Tentar encontrar e clicar no widget de humor
            print("⏳ Aguardando widget de humor...")
            page.wait_for_timeout(3000)

            mood_selectors = [
                f'.mood-rating input[name="mood"][value="{FEEDZ_MOOD}"]',
                f'img.mood-select-image[src$="mood-{FEEDZ_MOOD}.png"]',
                f'.mood-rating label:nth-child({FEEDZ_MOOD}) img.mood-select-image',
            ]

            clicked = False
            for selector in mood_selectors:
                try:
                    element = page.locator(selector).first
                    if element.is_visible(timeout=2000):
                        element.click()
                        clicked = True
                        print(f"✅ Humor selecionado! (seletor: {selector})")
                        break
                except (PlaywrightTimeout, Exception):
                    continue

            if not clicked:
                # Verificar se o humor já foi enviado hoje (widget não aparece)
                try:
                    mood_widget = page.locator('.mood-rating')
                    if not mood_widget.is_visible(timeout=2000):
                        print("✅ Humor já foi enviado hoje! Nada a fazer.")
                        LOGGER.info("Humor ja enviado anteriormente; encerrando sem acao")
                        context.close()
                        return True
                except (PlaywrightTimeout, Exception):
                    print("✅ Humor já foi enviado hoje! Nada a fazer.")
                    LOGGER.info("Humor ja enviado (detecao por excecao na leitura do widget)")
                    context.close()
                    return True

                screenshot_path = "debug_screenshot.png"
                page.screenshot(path=screenshot_path)
                print("❌ Não foi possível encontrar o widget de humor.")
                print(f"📸 Screenshot salvo em: {screenshot_path}")
                LOGGER.error("Nao foi possivel encontrar o widget de humor | screenshot=%s", screenshot_path)
                if HEADLESS:
                    print("   Rode novamente com HEADLESS=false no .env para ver o navegador.")
            else:
                # 5. Verificar popup de pesquisa novamente após clicar no humor
                page.wait_for_timeout(2000)
                try:
                    close_btn = page.locator('button.close[data-dismiss="modal"][aria-label="close"]')
                    if close_btn.is_visible(timeout=3000):
                        close_btn.click()
                        print("✅ Popup de pesquisa fechado.")
                        page.wait_for_timeout(1000)
                except (PlaywrightTimeout, Exception):
                    pass

                # 6. Clicar no botão "Enviar humor"
                try:
                    btn = page.locator('#fdz-btn-send-mood')
                    btn.wait_for(state="visible", timeout=5000)
                    btn.click()
                    print("✅ Botão 'Enviar humor' clicado!")
                    LOGGER.info("Botao 'Enviar humor' clicado")
                except (PlaywrightTimeout, Exception):
                    print("❌ Não encontrou o botão 'Enviar humor'.")
                    LOGGER.error("Nao encontrou o botao 'Enviar humor'")

                # 7. Aguardar 10s e verificar se os emojis sumiram
                page.wait_for_timeout(10000)

                try:
                    if page.locator('.mood-rating').is_visible(timeout=2000):
                        print("❌ ERRO: Os emojis ainda estão visíveis. O humor pode não ter sido enviado.")
                        page.screenshot(path="error_screenshot.png")
                        print("📸 Screenshot salvo em: error_screenshot.png")
                        LOGGER.error("Widget ainda visivel apos envio | screenshot=error_screenshot.png")
                    else:
                        print("🎉 Humor enviado com sucesso!")
                        LOGGER.info("Humor enviado com sucesso")
                except (PlaywrightTimeout, Exception):
                    print("🎉 Humor enviado com sucesso!")
                    LOGGER.info("Humor enviado com sucesso (confirmacao por timeout ao reler widget)")

        except PlaywrightTimeout as e:
            print(f"❌ Timeout: {e}")
            page.screenshot(path="error_screenshot.png")
            print("📸 Screenshot de erro salvo.")
            LOGGER.exception("Timeout no fluxo Playwright")
        except Exception as e:
            print(f"❌ Erro: {e}")
            LOGGER.exception("Erro inesperado no fluxo principal")
            try:
                page.screenshot(path="error_screenshot.png")
                print("📸 Screenshot de erro salvo.")
                LOGGER.error("Screenshot de erro salvo em error_screenshot.png")
            except Exception:
                LOGGER.exception("Falha ao salvar screenshot de erro")
                pass
        finally:
            context.close()

    return True


if __name__ == "__main__":
    try:
        run()
    except Exception:
        LOGGER.exception("Erro nao tratado no entrypoint")
        print(f"❌ Erro inesperado. Veja o log tecnico: {APP_LOG_FILE}")
        sys.exit(1)
    finally:
        sync_latest_log()
