# 🤖 Feedz Mood Bot

Preenche seu humor diário na plataforma **Feedz** automaticamente. Um clique por dia (ou zero, se agendar).

---

## 🚀 Instalação (1 minuto)

### Pré-requisito
- **Python 3.9+** → [Baixar aqui](https://www.python.org/downloads/)
  - ⚠️ Na instalação, marque **"Add Python to PATH"**

### Passos

1. [Baixe o bot](https://github.com/pguilhermef/feedz_mood_bot/archive/refs/heads/main.zip) e extraia a pasta
2. Dê **duplo clique** em `instalar.bat`
3. Preencha seu email, senha e humor quando pedido
4. O navegador vai abrir para o primeiro login — resolva o CAPTCHA se aparecer
5. Escolha se quer agendamento automático (no login do PC ou horário fixo)
6. Pronto! ✅

> O instalador faz tudo: instala dependências, configura credenciais, faz o primeiro login com navegador visível (para CAPTCHA) e agenda. Nas próximas execuções, roda em segundo plano.

---

## ▶️ Uso diário

Dê duplo clique em **`run.bat`** — ou deixe agendado e não faça nada.

---

## ⏰ Agendamento automático

Durante a instalação, você escolhe:
- **Opção 1** — Rodar ao ligar/logar no PC (recomendado)
- **Opção 2** — Rodar em horário fixo todo dia
- **Opção 3** — Sem agendamento (rodar manualmente)

Para remover o agendamento:
```
schtasks /delete /tn "FeedzMoodBot" /f
```

---

## 😊 Escala de Humor

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

## 🐛 Problemas?

| Problema | Solução |
|----------|---------|
| "Python não encontrado" | Instale Python e marque "Add to PATH" |
| Bot não encontra o humor | Rode `python dev/calibrate.py` |
| Erro de login | Rode `instalar.bat` e reconfigure |
| Quer ver o navegador | Mude `HEADLESS=false` no `.env` |
| "Sem conexão com internet" | Conecte à internet e tente de novo |

---

## 📁 Arquivos importantes

| Arquivo | O que faz |
|---------|-----------|
| `instalar.bat` | Instalação completa (rode uma vez, ou de novo para reconfigurar) |
| `run.bat` | Executa o bot (uso diário) |
| `.env` | Suas credenciais (nunca é commitado) |
| `dev/` | Ferramentas de desenvolvimento (ignore) |

---

## 🔒 Segurança

- Suas credenciais ficam **apenas no seu computador** (arquivo `.env`)
- O `.env` está no `.gitignore` — nunca será enviado para o GitHub
- O bot usa um perfil de navegador local para manter a sessão
