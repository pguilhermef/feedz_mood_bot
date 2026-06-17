# Feedz Mood Bot

Automacao para preencher o humor diario no Feedz com o minimo de friccao.

## Objetivo

Voce precisa clicar em `run.bat`.
O script prepara o ambiente e executa o bot.

Estrutura esperada para reduzir erros de uso:

- Na raiz do projeto: somente `run.bat`.
- Arquivos tecnicos internos: pasta `app/`.

## Como usar (fluxo principal)

1. Baixe/clone o projeto para uma pasta local comum (exemplo: Desktop ou Documents).
2. Execute `run.bat` com duplo clique.
3. Na primeira execucao, o script:
   - instala Python automaticamente, se necessario;
   - cria o ambiente virtual;
   - instala dependencias do projeto;
   - instala o Chromium do Playwright;
   - cria o arquivo `.env` pedindo email, senha e humor;
   - cria automaticamente a tarefa agendada diaria `FeedzMoodBot` (se ainda nao existir).

Depois da primeira execucao, continue usando somente `run.bat`.

## Agendamento automatico

- Nome da tarefa: `FeedzMoodBot`
- Frequencia: diaria
- Horario padrao: `08:30`
- Comportamento: `run.bat` sempre verifica a tarefa; se nao existir, cria automaticamente.
- Se o PC estiver desligado no horario, a tarefa roda assim que possivel quando o computador voltar.

Observacao:

- Se nao houver permissao para criar tarefa, a execucao do bot continua normalmente.
- O aviso de falha de agendamento aparece no terminal e no log do launcher.

## Arquivos principais

- `run.bat`: fluxo completo (setup + execucao + verificacao de agendamento).
- `app/setup.bat`: setup somente.
- `app/instalar.bat`: alias de setup (mesmo comportamento do setup).
- `app/main.py`: automacao de login e envio de humor.
- `app/calibrate.py`: suporte para recalibrar seletores quando o layout do Feedz mudar.

## Escala de humor

| Valor | Humor     |
| ----- | --------- |
| 1     | Muito mal |
| 2     | Mal       |
| 3     | Neutro    |
| 4     | Bem       |
| 5     | Muito bem |

## Logs e diagnostico

Quando algo falha, o terminal nao fecha automaticamente.
Ele exibe resumo e erro tecnico antes do `pause`.

Logs principais:

- `app/logs/launcher_latest.log`: falhas de inicio do launcher (`run.bat`).
- `app/logs/installer_latest.log`: falhas de inicio do instalador (`app/instalar.bat`).
- `app/logs/run_<RUN_ID>.log`: log tecnico completo do bootstrap.
- `app/logs/app_<RUN_ID>.log`: log tecnico da automacao Python.
- `app/logs/app_latest.log`: ultimo log da automacao Python.
- `app/logs/error_latest.log`: ultimo erro detalhado do bootstrap.
- `app/logs/summary_latest.txt`: resumo final da ultima execucao (status, mensagem, exit code e caminhos de log).

Fallback de logs:

- Se a pasta do projeto nao permitir escrita, os logs vao para `%TEMP%\FeedzMoodBotLogs`.

## Problemas comuns

| Problema                                        | O que fazer                                                         |
| ----------------------------------------------- | ------------------------------------------------------------------- |
| `run.bat` nao abre ou fecha rapido              | Abrir `app/logs/launcher_latest.log` (ou `%TEMP%\FeedzMoodBotLogs`) |
| Falha para instalar Python/dependencias/browser | Rodar `run.bat` novamente (ha tentativas automaticas)               |
| Erro de permissao de arquivo                    | Mover o projeto para Desktop/Documents e tentar de novo             |
| Login nao preenche automaticamente              | Verificar `app/logs/app_latest.log`, fazer login manual e seguir    |
| Widget de humor nao encontrado                  | Rodar `app/venv/Scripts/python.exe app/calibrate.py`                |

## Dicas de estabilidade

- Evite executar o projeto direto de ZIP sem extrair.
- Evite pasta de rede e sincronizacao corporativa restrita.
- Para depurar visualmente, use `HEADLESS=false` no `.env`.
