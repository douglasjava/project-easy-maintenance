# TASK-407 — BUGFIX: mensagem enviada depois do botão "Registrar manutenção" cai na resposta genérica (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Fluxo de conversa

## Prioridade
🟠 Alto — o caminho "pelo menu" do registro falha justamente para quem segue a instrução do bot.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), item **WA-08**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
Tiago tocou em "Registrar manutenção", recebeu "Me conte o que foi feito…" e mandou "poda de jardim" →
"Por aqui eu te ajudo só com…" (resposta genérica). Foi registrado como "corrida de estado".

## Causa (verificada no código — não é corrida)
`IntentStep`, caso `REGISTRAR_MANUTENCAO` vindo de atalho (`fromShortcut`): só envia `REGISTER_HOW`,
**sem gravar nenhum estado de espera** na conversa. A mensagem seguinte ("poda de jardim") passa pelo
classificador sozinha, sem o contexto "estou registrando", e textos curtos sem verbo de execução são
classificados `FORA_DO_ESCOPO`. Mesmo problema em:
- `REGISTRAR_LANCAMENTO_FINANCEIRO` por atalho (`FIN_HOW`);
- foto/documento sem legenda (`REGISTER_HOW` sem estado).
Agravante: se o toque no botão e o texto chegarem no mesmo lote (`MessageMerger`), o texto é
descartado porque `fromShortcut=true`.

## Escopo
- Ao enviar `REGISTER_HOW`/`FIN_HOW`, gravar estado de espera curto (ex.: `AWAITING_REGISTRATION_INPUT`
  / `AWAITING_FINANCIAL_INPUT`, TTL 30 min, padrão `PendingActionHandler`): a próxima mensagem de texto,
  áudio ou foto vai direto para `registration.start` / `financialEntry.start`, sem classificador.
  Mídia sem legenda guarda as mídias no estado e usa o texto seguinte.
- "menu", "cancelar" e botões de menu continuam saindo do estado.
- Lote com botão + texto: se o atalho é de registro/financeiro e há texto, iniciar o rascunho com o texto.

## Critérios de Aceite
- [x] Botão "Registrar manutenção" → "poda de jardim" → abre o rascunho (item/data/cartão), sem resposta genérica
- [x] Foto sem legenda → "Me conte o que foi feito" → texto → rascunho **com** a foto anexada
- [x] Mesmo comportamento para lançamento financeiro
- [x] "menu" durante a espera → menu; estado limpo
- [x] Espera expirada (30 min) → mensagem segue o fluxo normal de classificação
- [x] Não consome crédito de IA na mensagem seguinte ao atalho quando o texto já basta (se o `start` usa IA para extrair campos, manter uma única chamada)
- [x] `mvn test` sem regressão — 1787/1787 (8 testes do `AwaitingInputHandler` + 4 do `IntentStep`)

## Riscos
Novo estado de espera convive com os pendentes existentes (`PendingActionStep`) — garantir precedência
correta e que um rascunho em `CONFIRM` não seja sobrescrito.

## Implementação (09/11/2026)
- Novo `AwaitingInputHandler` (`PendingActionHandler`, `awaiting = "INPUT"`, 30 min) — um só estado para
  registro e lançamento, em vez de dois (`Capability.REGISTRATION | FINANCIAL` no JSON). É despachado pelo
  `PendingActionStep` (ordem 47), **depois da transcrição de áudio (45) e antes da IA (50)**.
- Armado pelo `IntentStep` ao pedir a descrição: botão/atalho de Registrar (inclusive "3" digitado), botão de
  Lançar, e foto/documento sem legenda (a mídia fica guardada).
- Resposta: texto/áudio → `registration.start(turn, Map.of(), fotosGuardadas)` / `financialEntry.start(...)`,
  **sem chamada à IA** (zero crédito); só foto → acumula e pede o texto; lançamento sem valor → reenvia o
  exemplo e continua esperando.
- Saídas: qualquer botão, "menu"/saudação/atalho → desarma e segue o fluxo normal; "cancelar" → encerra;
  expirou → descarta em silêncio (não avisa "expirou", não é rascunho).
- Lote com botão + texto (`MessageMerger`): o texto vira a descrição (antes era descartado).
- Sem dependência circular: o handler depende dos serviços de registro/lançamento, que não dependem do pipeline.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `a7fef22`.

## Status
✅ Concluído — validado em `staging` no QA manual [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) pelo Douglas e promovida para `main` em 09/11/2026 — api [#184](https://github.com/douglasjava/easy-maintenance-api/pull/184)→[#185](https://github.com/douglasjava/easy-maintenance-api/pull/185), web [#136](https://github.com/douglasjava/easy-maintenance-web/pull/136)→[#137](https://github.com/douglasjava/easy-maintenance-web/pull/137).
