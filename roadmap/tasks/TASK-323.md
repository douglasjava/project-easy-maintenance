# TASK-323 — Backend: FinancialEntryService (criar/cancelar/listar/resumir)

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-322

## QA obrigatório
Sim — permissão (`ADMIN`/`SYNDIC`), validações de negócio (categoria×tipo, valor, data) e combinação
com custo de manutenção automático precisam de teste real, não só "parece certo".

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 2).

`create`/`cancel`/`listByPeriod`/`summarize`. `summarize` combina a soma de `FinancialEntry` com
`MaintenanceRepository.sumCostCentsByOrgsInAndPerformedBetween` (já existente) — sem duplicar a
lógica de custo de manutenção.

**Prompt**: `execute a TASK-323 (EPIC-032): FinancialEntryService, seguindo a Task 2 do plano
docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] Permissão `ADMIN`/`SYNDIC` pra criar/cancelar, com teste cobrindo os dois papéis e a negação
      pros demais (`TECH`/`READER`).
- [x] Categoria incompatível com o tipo, valor ≤ 0, e data futura rejeitados com `RuleException`.
- [x] Cancelamento idempotente: 409 se já cancelado, 404 se nunca existiu, 403 se de outra organização.
- [x] `summarize` combina receita/despesa manual com despesa de manutenção automática corretamente.

## Execução (05/10/2026)
`FinancialEntryServiceTest`: 15/15 testes.

## Status
Done
