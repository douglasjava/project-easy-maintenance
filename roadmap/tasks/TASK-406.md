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
- [ ] Item só com `lastPerformedAt` → mostra a data e a observação
- [ ] Item com registros → comportamento atual
- [ ] Item sem nada → "Ainda não há manutenções…"
- [ ] Teste unitário dos três casos; `mvn test` sem regressão
