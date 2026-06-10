# 🤖 Feedz Mood Bot

**[🇧🇷 Português](#-português)** | **[🇺🇸 English](#-english)**

---

## 🇺🇸 English

Auto-submit your daily mood on Feedz — set up once, forget forever.

---

### 🚀 Installation (1 minute)

#### Prerequisite
- **Python 3.9+** → [Download here](https://www.python.org/downloads/)
  - ⚠️ Check **"Add Python to PATH"** during installation

#### Steps

1. [Download the bot](https://github.com/pguilhermef/feedz_mood_bot/archive/refs/heads/main.zip) and extract the folder
2. **Double-click** `instalar.bat`
3. Enter your email, password, and mood when prompted
4. The browser will open for first login — solve CAPTCHA if needed
5. Choose automatic scheduling (on PC login or fixed time)
6. Done! ✅

> The installer does everything: installs dependencies, configures credentials, performs the first login with a visible browser (for CAPTCHA), and schedules. Next runs are silent.

---

### ▶️ Daily use

Double-click **`run.bat`** — or leave it scheduled and do nothing.

---

### ⏰ Automatic scheduling

During installation, you choose:
- **Option 1** — Run on PC login (recommended)
- **Option 2** — Run at a fixed time daily
- **Option 3** — No scheduling (run manually)

To remove scheduling:
```
schtasks /delete /tn "FeedzMoodBot" /f
```

---

### 😊 Mood scale

| Value | Mood |
|-------|------|
| 1 | Very sad |
| 2 | Sad |
| 3 | Neutral |
| 4 | Happy |
| 5 | Very happy |

To change the default mood, edit `.env`:
```
FEEDZ_MOOD=4
```

---

### 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Python not found" | Install Python and check "Add to PATH" |
| Bot can't find mood widget | Run `python dev/calibrate.py` |
| Login error | Run `instalar.bat` and reconfigure |
| Want to see the browser | Set `HEADLESS=false` in `.env` |
| "No internet connection" | Connect to internet and try again |

---

### 📁 Important files

| File | Purpose |
|------|---------|
| `instalar.bat` | Full installation (run once, or again to reconfigure) |
| `run.bat` | Runs the bot (daily use) |
| `.env` | Your credentials (never committed) |
| `dev/` | Development tools (ignore) |

---

### 🔒 Security

- Your credentials stay **only on your computer** (`.env` file)
- `.env` is in `.gitignore` — never pushed to GitHub
- The bot uses a local browser profile to keep the session

---
---

## 🇧🇷 Português

Preenche seu humor diário na plataforma **Feedz** automaticamente. Um clique por dia (ou zero, se agendar).

---

### 🚀 Instalação (1 minuto)

#### Pré-requisito
- **Python 3.9+** → [Baixar aqui](https://www.python.org/downloads/)
  - ⚠️ Na instalação, marque **"Add Python to PATH"**

#### Passos

1. [Baixe o bot](https://github.com/pguilhermef/feedz_mood_bot/archive/refs/heads/main.zip) e extraia a pasta
2. Dê **duplo clique** em `instalar.bat`
3. Preencha seu email, senha e humor quando pedido
4. O navegador vai abrir para o primeiro login — resolva o CAPTCHA se aparecer
5. Escolha se quer agendamento automático (no login do PC ou horário fixo)
6. Pronto! ✅

> O instalador faz tudo: instala dependências, configura credenciais, faz o primeiro login com navegador visível (para CAPTCHA) e agenda. Nas próximas execuções, roda em segundo plano.

---

### ▶️ Uso diário

Dê duplo clique em **`run.bat`** — ou deixe agendado e não faça nada.

---

### ⏰ Agendamento automático

Durante a instalação, você escolhe:
- **Opção 1** — Rodar ao ligar/logar no PC (recomendado)
- **Opção 2** — Rodar em horário fixo todo dia
- **Opção 3** — Sem agendamento (rodar manualmente)

Para remover o agendamento:
```
schtasks /delete /tn "FeedzMoodBot" /f
```

---

### 😊 Escala de Humor

| Valor | Humor |
|-------|-------|
| 1 | Muito triste |
| 2 | Triste |
| 3 | Neutro |
| 4 | Feliz |
| 5 | Muito feliz |

Para mudar o humor padrão, edite o arquivo `.env`:
```
FEEDZ_MOOD=4
```

---

### 🐛 Problemas?

| Problema | Solução |
|----------|---------|
| "Python não encontrado" | Instale Python e marque "Add to PATH" |
| Bot não encontra o humor | Rode `python dev/calibrate.py` |
| Erro de login | Rode `instalar.bat` e reconfigure |
| Quer ver o navegador | Mude `HEADLESS=false` no `.env` |
| "Sem conexão com internet" | Conecte à internet e tente de novo |

---

### 📁 Arquivos importantes

| Arquivo | O que faz |
|---------|-----------|
| `instalar.bat` | Instalação completa (rode uma vez, ou de novo para reconfigurar) |
| `run.bat` | Executa o bot (uso diário) |
| `.env` | Suas credenciais (nunca é commitado) |
| `dev/` | Ferramentas de desenvolvimento (ignore) |

---

### 🔒 Segurança

- Suas credenciais ficam **apenas no seu computador** (arquivo `.env`)
- O `.env` está no `.gitignore` — nunca será enviado para o GitHub
- O bot usa um perfil de navegador local para manter a sessão
