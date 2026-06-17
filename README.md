# Feedz Mood Bot

[PT-BR](#pt-br) | [EN](#en)

---

## PT-BR

Bot para preencher automaticamente o humor diario no Feedz.

### Fluxo recomendado (1 clique)

1. Baixe/clone o projeto e extraia em uma pasta local comum (Documents ou Desktop).
2. Clique duas vezes em run.bat.
3. Na primeira execucao, ele faz tudo sozinho:
   - instala Python automaticamente (se faltar),
   - cria ambiente virtual,
   - instala dependencias,
   - instala Chromium do Playwright,
   - pede email/senha/humor e cria o .env.

Depois disso, basta clicar em run.bat quando quiser rodar novamente.

Observacao: evite rodar em pasta de rede, ZIP sem extrair, OneDrive bloqueado ou local sem permissao de escrita.

### Escala de humor

| Valor | Humor     |
| ----- | --------- |
| 1     | Muito mal |
| 2     | Mal       |
| 3     | Neutro    |
| 4     | Bem       |
| 5     | Muito bem |

### Scripts principais

- run.bat: fluxo completo de clique unico (setup + execucao).
- setup.bat: somente setup (sem rodar o bot).
- calibrate.py: utilitario de calibracao quando o Feedz mudar layout.
- instalar.bat: alias de setup (mesmo fluxo automatico robusto).

### Troubleshooting rapido

| Problema                         | O que fazer                                         |
| -------------------------------- | --------------------------------------------------- |
| run.bat nao abre / fecha rapido  | Abrir logs/launcher_latest.log                      |
| Falha ao instalar pacote/browser | Rodar run.bat novamente (ha tentativas automaticas) |
| Erro de permissao em arquivo     | Mover pasta para Documents/Desktop                  |
| Bot nao encontra widget de humor | Rodar python calibrate.py                           |
| Erro de login                    | Recriar .env rodando run.bat novamente              |

Se nao aparecer log em `logs/`, verifique o fallback em `%TEMP%\FeedzMoodBotLogs`.

Para debug visual, use HEADLESS=false no .env.

### Logs

- logs/launcher_latest.log: problemas para iniciar o launcher.
- logs/run\_<RUN_ID>.log: log tecnico completo do bootstrap/execucao.
- logs/app\_<RUN_ID>.log e logs/app_latest.log: log tecnico do Python (bot).
- logs/error_latest.log: ultimo erro detalhado de bootstrap.
- logs/summary_latest.txt: resumo final da ultima execucao (status, exit code e caminhos de log).
- Fallback: `%TEMP%\FeedzMoodBotLogs` quando a pasta do projeto nao permite escrita.

---

## EN

Bot to auto-submit your daily mood on Feedz.

### Recommended flow (one click)

1. Clone/download the project into a regular local folder (Documents or Desktop).
2. Double-click run.bat.
3. On first run, it handles everything automatically:
   - installs Python if missing,
   - creates virtual environment,
   - installs dependencies,
   - installs Playwright Chromium,
   - asks credentials/mood and creates .env.

After that, just double-click run.bat whenever you want to run it.

### Main scripts

- run.bat: full one-click flow (setup + run).
- setup.bat: setup only.
- calibrate.py: calibration helper if Feedz UI changes.
- instalar.bat: setup alias (same robust automatic flow).

### Quick troubleshooting

- If run.bat closes immediately: check logs/launcher_latest.log.
- If package/browser install fails: run run.bat again (auto-retry enabled).
- If permission issues occur: move project to Documents/Desktop.
- If mood widget is not found: run python calibrate.py.
- If no log appears in `logs/`, check `%TEMP%\FeedzMoodBotLogs`.

### Logs

- logs/launcher_latest.log: launcher startup failures.
- logs/run\_<RUN_ID>.log: detailed bootstrap/runtime failures.
- logs/app\_<RUN_ID>.log and logs/app_latest.log: Python bot technical logs.
- logs/error_latest.log: latest detailed bootstrap error.
- logs/summary_latest.txt: last execution summary (status, exit code, and log paths).
- Fallback: `%TEMP%\FeedzMoodBotLogs` when project folder is not writable.
