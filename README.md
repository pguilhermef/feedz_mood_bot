# 🤖 Feedz Mood Bot

Automação simples que preenche seu humor diário na plataforma **Feedz** automaticamente.

---

## 📋 Pré-requisitos

- Windows 10/11
- Conexao com internet na primeira execucao

> O script principal tenta instalar Python automaticamente (sem abrir link) e prepara tudo sozinho.

---

## 🚀 Setup e execução (1 clique)

1. Clique duas vezes em `run.bat`.
2. Na primeira vez, o script vai:
   - instalar Python automaticamente (se faltar);
   - criar o ambiente virtual;
   - instalar os pacotes do `requirements.txt`;
   - instalar o Chromium do Playwright;
   - pedir email/senha/humor e criar `.env`.
3. Depois disso, ele executa o bot.

> Dica importante: execute o projeto em uma pasta local comum (ex: `Documentos` ou `Desktop`).
> Evite rede corporativa, OneDrive bloqueado, ZIP aberto sem extrair ou pasta sem permissao de escrita.

Nas próximas execucoes, basta clicar em `run.bat` novamente.

Se quiser somente preparar o ambiente sem rodar o bot, use `setup.bat`.

### Escala de Humor

| Valor | Humor     |
| ----- | --------- |
| 1     | Muito Mal |
| 2     | Mal       |
| 3     | Neutro    |
| 4     | Bem       |
| 5     | Muito Bem |

---

## ▶️ Como usar

Execute `run.bat`.

O bot vai:

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
2. Executar `run.bat` uma vez para preparar o ambiente
3. Criar seu próprio `.env` com suas credenciais
4. Agendar a tarefa no seu computador

> ⚠️ O arquivo `.env` está no `.gitignore` — suas credenciais **nunca** serão commitadas.

---

## 🐛 Troubleshooting

| Problema                           | Solução                                                 |
| ---------------------------------- | ------------------------------------------------------- |
| `run.bat` nao abre / fecha na hora | Veja `logs/launcher_latest.log` e execute pelo terminal |
| Erro de permissao ao criar arquivos | Mova a pasta para `Documentos` e execute novamente      |
| Falha intermitente ao instalar pacote | Rode `run.bat` de novo (agora existe tentativa automatica) |
| Bot não encontra o widget de humor | Rode `python calibrate.py` e ajuste os seletores        |
| Erro de timeout                    | O Feedz pode estar lento. Aumente os timeouts no código |
| Erro de login                      | Verifique email/senha no `.env`                         |
| Navegador não instalado            | Rode `playwright install chromium`                      |

Para debug, mude `HEADLESS=false` no `.env` para ver o navegador em ação.

### Onde ver o erro exato

Agora cada execucao gera log em `logs/` (arquivo `run_YYYYMMDD_HHMMSS.log`).

Se der erro no computador de outro usuario, basta abrir esse arquivo para ver o detalhe tecnico completo.

Se o `run.bat` nao abrir ao dar duplo clique:

1. Abra `cmd` e rode o script por la para ver a mensagem de erro.
2. Abra `logs/launcher_latest.log` (erro de inicializacao do launcher).
3. Abra o log mais recente `logs/run_YYYYMMDD_HHMMSS.log` (erro detalhado do bootstrap).
