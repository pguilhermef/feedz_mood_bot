"""
Feedz Mood Bot - Script de calibração.
Roda com navegador visível para você identificar os seletores corretos do widget de humor.
Usa perfil persistente do navegador para manter a sessão (evita CAPTCHA).
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

load_dotenv()

FEEDZ_EMAIL = os.getenv("FEEDZ_EMAIL")
FEEDZ_PASSWORD = os.getenv("FEEDZ_PASSWORD")
FEEDZ_URL = "https://app.feedz.com.br"
PROFILE_DIR = Path(__file__).parent / "browser_profile"


def is_logged_in(page) -> bool:
    """Verifica se já estamos logados checando se o formulário de login está visível."""
    try:
        if page.locator('#enter-login').is_visible(timeout=2000):
            return False
    except Exception:
        pass
    return "app.feedz.com.br" in page.url


def do_login(page):
    """Tenta fazer login automático. Se falhar (CAPTCHA etc), pede login manual."""
    print("🔑 Fazendo login...")

    try:
        page.fill('input[type="text"], input[name="login_email"]', FEEDZ_EMAIL)
        page.fill('input[type="password"], input[name="login_password"]', FEEDZ_PASSWORD)
        page.click('#enter-login')
        page.wait_for_load_state("networkidle", timeout=15000)

        if is_logged_in(page):
            print("✅ Login automático realizado!")
            return
    except (PlaywrightTimeout, Exception):
        pass

    print("⚠️  Login automático falhou (possível CAPTCHA).")
    print("👉 Faça login manualmente no navegador que abriu.")
    print("   Aguardando você logar (máximo 120s)...")

    for _ in range(60):
        page.wait_for_timeout(2000)
        if is_logged_in(page):
            print("✅ Login manual detectado!")
            return

    print("❌ Timeout aguardando login. Tente novamente.")
    sys.exit(1)


def calibrate():
    print("🔧 Modo calibração - navegador visível")
    print("   Vamos logar e você poderá inspecionar a página.")
    print()

    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=str(PROFILE_DIR),
            headless=False,
            slow_mo=500,
            accept_downloads=False,
        )
        page = context.pages[0] if context.pages else context.new_page()

        # 1. Navegar e Login
        page.goto(FEEDZ_URL, wait_until="networkidle", timeout=30000)

        if not is_logged_in(page):
            if FEEDZ_EMAIL and FEEDZ_PASSWORD:
                do_login(page)
            else:
                print("⚠️  Sessão expirada e FEEDZ_EMAIL/FEEDZ_PASSWORD não configurados.")
                print("👉 Faça login manualmente no navegador (120s)...")
                for _ in range(60):
                    page.wait_for_timeout(2000)
                    if is_logged_in(page):
                        print("✅ Login manual detectado!")
                        break
                else:
                    print("❌ Timeout aguardando login.")
                    sys.exit(1)
        else:
            print("✅ Sessão ativa! Login não necessário.")

        print("✅ Logado! Aguardando 5s para a página carregar...")
        page.wait_for_timeout(5000)

        # 2. Fechar popup de avaliação da plataforma, se aparecer
        try:
            close_btn = page.locator('button.close[data-dismiss="modal"][aria-label="close"]')
            if close_btn.is_visible(timeout=3000):
                close_btn.click()
                print("✅ Popup de avaliação fechado.")
                page.wait_for_timeout(1000)
        except (PlaywrightTimeout, Exception):
            pass

        # 3. Tirar screenshot da tela principal
        page.screenshot(path="calibration_home.png", full_page=True)
        print("📸 Screenshot da home salvo: calibration_home.png")

        # 3. Buscar possíveis elementos de humor na página
        print()
        print("🔍 Procurando elementos de humor na página...")

        search_terms = [
            "Muito triste", "Triste", "Neutro", "Feliz", "Muito feliz", "mood-select-image"
        ]

        for term in search_terms:
            elements = page.query_selector_all(f'[class*="{term}"], [alt*="{term}"], [id*="{term}"], [data-testid*="{term}"]')
            if elements:
                print(f"   ✅ Encontrado '{term}': {len(elements)} elemento(s)")
                for i, el in enumerate(elements):
                    tag = el.evaluate("e => e.tagName")
                    classes = el.evaluate("e => e.className")
                    text = el.evaluate("e => e.textContent?.substring(0, 80)")
                    print(f"      [{i}] <{tag}> class=\"{classes}\" text=\"{text}\"")

        # 4. Buscar todos os botões e elementos clicáveis
        print()
        print("🔍 Listando botões visíveis na página:")
        buttons = page.query_selector_all("button, [role='button'], a.btn")
        for i, btn in enumerate(buttons[:20]):
            text = btn.evaluate("e => e.textContent?.trim().substring(0, 60)")
            classes = btn.evaluate("e => e.className")
            visible = btn.is_visible()
            if visible and text:
                print(f"   [{i}] \"{text}\" class=\"{classes}\"")

        # 5. Buscar imagens (emojis do humor são frequentemente imgs)
        print()
        print("🔍 Listando imagens visíveis (possíveis emojis de humor):")
        imgs = page.query_selector_all("img, svg")
        for i, img in enumerate(imgs[:30]):
            alt = img.evaluate("e => e.alt || e.getAttribute('aria-label') || ''")
            src = img.evaluate("e => e.src || ''")
            visible = img.is_visible()
            if visible:
                print(f"   [{i}] alt=\"{alt}\" src=\"{src[:80]}\"")

        # Dump da estrutura HTML relevante
        print()
        print("📄 Salvando HTML da página para análise...")
        html = page.content()
        with open("calibration_page.html", "w", encoding="utf-8") as f:
            f.write(html)
        print("   Salvo em: calibration_page.html")

        print()
        print("⏸️  O navegador ficará aberto por 60 segundos para você inspecionar.")
        print("   Use F12 para abrir o DevTools e encontrar os seletores.")
        print("   Pressione Ctrl+C para fechar antes.")

        try:
            page.wait_for_timeout(60000)
        except KeyboardInterrupt:
            pass

        context.close()
        print("🔧 Calibração finalizada.")


if __name__ == "__main__":
    calibrate()
