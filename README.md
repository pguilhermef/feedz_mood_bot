# 🤖 Feedz Mood Bot

Automação simples que preenche seu humor diário na plataforma **Feedz** automaticamente.

---

## 📋 Pré-requisitos

- **Python 3.9+** instalado ([python.org](https://www.python.org/downloads/))

---

## 🚀 Setup (uma vez só)

```bash
# 1. Entrar na pasta do projeto
cd feedz-mood-bot

# 2. Criar ambiente virtual
python -m venv venv

# 3. Ativar o ambiente
# Windows:
venv\Scripts\activate
# Linux/Mac:
# source venv/bin/activate

# 4. Instalar dependências
pip install -r requirements.txt

# 5. Instalar o navegador do Playwright
playwright install chromium

# 6. Criar seu arquivo de configuração
copy .env.example .env
# (Linux/Mac: cp .env.example .env)
```

Edite o `.env` com seus dados:

```env
FEEDZ_EMAIL=seu.email@sysmanager.com.br
FEEDZ_PASSWORD=sua_senha
FEEDZ_MOOD=4
HEADLESS=true
```

### Escala de Humor

| Valor | Humor      |
|-------|------------|
| 1     | Muito Mal  |
| 2     | Mal        |
| 3     | Neutro     |
| 4     | Bem        |
| 5     | Muito Bem  |

---

## ▶️ Como usar

```bash
python main.py
```

Pronto. O bot vai:
1. Abrir o Feedz (sem janela visível)
2. Fazer login com seu email/senha
3. Preencher o humor
4. Fechar

---

## 🔧 Primeiro uso — Calibração

Como o Feedz pode mudar a interface, rode a **calibração** na primeira vez para garantir que os seletores estão corretos:

```bash
python calibrate.py
```

Isso vai:
- Abrir o navegador **visível** e logar no Feedz
- Listar os elementos encontrados na página
- Salvar screenshots e o HTML para análise
- Manter o navegador aberto 60s para você inspecionar com F12

Se o `main.py` não conseguir clicar no humor automaticamente, use as informações da calibração para ajustar os seletores no `main.py`.

---

## ⏰ Agendar execução diária (opcional)

### Windows (Agendador de Tarefas)

1. Abra o **Agendador de Tarefas** (`taskschd.msc`)
2. **Criar Tarefa Básica**
3. Nome: `Feedz Mood Bot`
4. Disparador: **Diariamente** no horário desejado (ex: 08:30)
5. Ação: **Iniciar um programa**
   - Programa: `C:\Users\SEU_USUARIO\SysRepos\feedz-mood-bot\venv\Scripts\python.exe`
   - Argumentos: `main.py`
   - Iniciar em: `C:\Users\SEU_USUARIO\SysRepos\feedz-mood-bot`
6. Concluir

### Linux/Mac (cron)

```bash
# Editar crontab
crontab -e

# Rodar todo dia às 8:30
30 8 * * 1-5 cd /caminho/para/feedz-mood-bot && venv/bin/python main.py
```

---

## 👥 Para o time

Cada pessoa do time precisa:

1. **Clonar** este repositório (ou copiar a pasta)
2. Rodar o **setup** acima
3. Criar seu próprio `.env` com suas credenciais
4. Agendar a tarefa no seu computador

> ⚠️ O arquivo `.env` está no `.gitignore` — suas credenciais **nunca** serão commitadas.

---

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| Bot não encontra o widget de humor | Rode `python calibrate.py` e ajuste os seletores |
| Erro de timeout | O Feedz pode estar lento. Aumente os timeouts no código |
| Erro de login | Verifique email/senha no `.env` |
| Navegador não instalado | Rode `playwright install chromium` |

Para debug, mude `HEADLESS=false` no `.env` para ver o navegador em ação.
