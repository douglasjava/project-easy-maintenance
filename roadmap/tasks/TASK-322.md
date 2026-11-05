# TASK-322 — Backend: FinancialEntry — domain, migration V122, repository

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## QA obrigatório
Sim — nova tabela/entidade, isolamento multi-tenant e soft-delete precisam de teste com banco real
(não só mockado).

## Contexto
Desenho completo em [`docs/superpowers/specs/2026-10-04-financial-entries-design.md`](../../docs/superpowers/specs/2026-10-04-financial-entries-design.md)
e plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 1).

Entidade `FinancialEntry` (migration V122), enums `FinancialEntryType`/`FinancialEntryCategory`,
repository com soft-delete (`@SQLDelete`/`@SQLRestriction`, mesmo padrão de `Maintenance`/TASK-137).

**Prompt**: `execute a TASK-322 (EPIC-032): FinancialEntry entity, migration V122 e repository,
seguindo a Task 1 do plano docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] `FinancialEntryPersistenceTest` (H2 real) prova soft-delete + isolamento por organização.
- [x] `mvn test` sem regressão.

## Execução (05/10/2026)
Implementado na branch `feature/EPIC-032-financial-entries` (api). `FinancialEntryPersistenceTest`:
5/5 testes (soft-delete + cancelReason/cancelledBy persistidos, `existsCancelledByIdAndOrgCode` não
vaza existência cross-org, `findByOrgAndPeriod` isola por organização e respeita filtro de tipo,
`sumAmountByOrgAndTypeAndPeriod` exclui cancelados e soma zero quando vazio).

## Status
Done
