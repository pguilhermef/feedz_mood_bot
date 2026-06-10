"""Cria o arquivo .env interativamente (evita problemas de caracteres especiais no .bat)."""
import sys

print()
print("══════════════════════════════════════════")
print("  Configure suas credenciais do Feedz")
print("══════════════════════════════════════════")
print()

email = input("📧 Seu email do Feedz: ").strip()

if not email:
    print("❌ Email não pode ser vazio.")
    sys.exit(1)

print("🔑 Digite sua senha do Feedz abaixo:")
password = input("   Senha: ").strip()

if not password:
    print("❌ Senha não pode ser vazia.")
    sys.exit(1)
print()
print("😊 Escolha seu humor padrão:")
print("   1 = Muito triste")
print("   2 = Triste")
print("   3 = Neutro")
print("   4 = Feliz")
print("   5 = Muito feliz")
print()
mood = input("Escolha [1-5] (padrão: 4): ").strip()

if not mood:
    mood = "4"
if mood not in ("1", "2", "3", "4", "5"):
    print("❌ Valor inválido. Usando 4 (Feliz).")
    mood = "4"

with open(".env", "w", encoding="utf-8") as f:
    f.write(f"FEEDZ_EMAIL={email}\n")
    f.write(f"FEEDZ_PASSWORD={password}\n")
    f.write(f"FEEDZ_MOOD={mood}\n")
    f.write(f"HEADLESS=true\n")

print()
print(f"✅ Configuração salva! (humor: {mood}/5)")
