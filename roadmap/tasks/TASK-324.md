# TASK-324 — Backend: endpoints REST /finance

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-323

## QA obrigatório
Sim — rotas tenant-scoped (`@RequireTenant`), código de status precisa bater com a documentação
OpenAPI.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 3).

`POST/GET /finance/entries`, `POST /finance/entries/{id}/cancel`, `GET /finance/summary`.

**Prompt**: `execute a TASK-324 (EPIC-032): endpoints REST /finance, seguindo a Task 3 do plano
docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] Todas as rotas com `@RequireTenant`.
- [x] `mvn test` sem regressão na suíte completa.

## Execução (05/10/2026)
`FinancialEntryController` criado. `mvn test` completo: 1425/1425, sem regressão.

**Achado durante a TASK-328 (e2e)**: `cancel()` devolvia 200 em vez de 204 — faltava
`@ResponseStatus(HttpStatus.NO_CONTENT)` (um método `void` sem essa anotação responde 200 por
default no Spring MVC, mesmo com a doc OpenAPI dizendo 204). Corrigido pra bater com o precedente
real de `MaintenancesController.cancel`.

## Status
Done
