# TASK-406 — BUGFIX: histórico pelo WhatsApp diz "sem manutenções" para item com última data cadastrada (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Consultas

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), item **WA-09**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
"Última manutenção dos extintores" → "Ainda não há manutenções registradas para Extintor", embora o
item esteja em dia no painel (data informada só no cadastro do item, sem registro em `maintenances`).

## Causa (verificada no código)
`AssistantQueryService.historyOf` lê só `maintenanceService.listByItem`; vazio → `HISTORY_EMPTY`,
ignorando `ItemResponse.lastPerformedAt`.

## Escopo
- Sem registros e com `lastPerformedAt` → "Última manutenção: dd/MM/yyyy (informada no cadastro do
  item, sem registro detalhado)" + próximo vencimento + link. Mensagem nova em `AssistantMessages`.
- Sem registros e sem `lastPerformedAt` → mensagem atual.

## Critérios de Aceite
- [x] Item só com `lastPerformedAt` → mostra a data e a observação
- [x] Item com registros → comportamento atual
- [x] Item sem nada → "Ainda não há manutenções…"
- [x] Teste unitário dos três casos (2 novos + o de registros já existente); `mvn test` sem regressão — 1798/1798

## Implementação (09/11/2026)
`AssistantQueryService.historyOf`: sem registros e com `lastPerformedAt` → "🔧 *Extintor*: última manutenção em
10/03/2026 (informada no cadastro do item, sem registro detalhado)." + próximo vencimento + link do histórico.
Sem registros e sem data → mensagem atual. Com registros → sem mudança.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `1efb353`.

## Status
✅ Concluído — validado em `staging` no QA manual [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) pelo Douglas e promovida para `main` em 09/11/2026 — api [#184](https://github.com/douglasjava/easy-maintenance-api/pull/184)→[#185](https://github.com/douglasjava/easy-maintenance-api/pull/185), web [#136](https://github.com/douglasjava/easy-maintenance-web/pull/136)→[#137](https://github.com/douglasjava/easy-maintenance-web/pull/137).
