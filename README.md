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
4. Pronto! ✅

> O instalador faz tudo: cria ambiente, instala dependências, configura credenciais e testa.

---

## ▶️ Uso diário

Dê duplo clique em **`run.bat`** — ou deixe agendado e não faça nada.

---

## ⏰ Agendamento automático

Durante a instalação, o bot pergunta se quer agendar execução diária.

Se quiser agendar depois:
1. Abra o **Agendador de Tarefas** (`Win + R` → `taskschd.msc`)
2. Criar Tarefa Básica → Nome: `FeedzMoodBot`
3. Disparador: **Diariamente** no horário desejado
4. Ação: **Iniciar programa** → selecione `run.bat`

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
| Bot não encontra o humor | Rode `python calibrate.py` |
| Erro de login | Confira email/senha no `.env` |
| Quer ver o navegador | Mude `HEADLESS=false` no `.env` |

---

## 📁 Arquivos importantes

| Arquivo | O que faz |
|---------|-----------|
| `instalar.bat` | Instalação completa (rode uma vez) |
| `run.bat` | Executa o bot (uso diário) |
| `.env` | Suas credenciais (nunca é commitado) |

---

## 🔒 Segurança

- Suas credenciais ficam **apenas no seu computador** (arquivo `.env`)
- O `.env` está no `.gitignore` — nunca será enviado para o GitHub
- O bot usa um perfil de navegador local para manter a sessão
