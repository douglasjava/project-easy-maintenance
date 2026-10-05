# TASK-328 — QA: E2E fluxo completo do módulo financeiro

## Tipo
QA

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-324, TASK-325, TASK-326

## QA obrigatório
Sim (é a própria task de QA).

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 7).

**Achado real durante a execução**: o plano original presumia um helper de login via browser
(`loginViaUi`) e fixtures (`TENANT_D_OPERATING`) que **não existem** na branch `staging` real desse
repositório — vieram de uma leitura de contexto equivocada (outro worktree/branch). O padrão real
de e2e aqui é nível API (`loginAs` + `api.get/post` de `fixtures/auth.ts`/`fixtures/api-client.ts`,
ver `tests/auth/multi-tenant-isolation.spec.ts`), sem automação de navegador. O spec foi reescrito
nesse padrão real.

**Prompt**: `execute a TASK-328 (EPIC-032): e2e do módulo financeiro nível API, usando loginAs +
api fixture (ver tests/auth/multi-tenant-isolation.spec.ts como referência), não browser UI.`

## Critérios de aceite
- [x] Lança receita e despesa, confere refletido em `/finance/entries` e `/finance/summary`.
- [x] Cancelar remove da listagem ativa e do resumo; cancelar de novo dá 409.
- [ ] **Executado contra API/banco e2e reais** — não foi possível nesta sessão (API/frontend não
      estavam de pé localmente, portas 9000/3000 fechadas — mesma limitação já documentada em
      outros specs deste repositório). Rodar `npm run setup:db` + subir a API antes de promover.

## Execução (05/10/2026)
`tests/billing/finance-entries.spec.ts` criado. `npx tsc --noEmit` limpo. `npx playwright test
--list` reconhece os 2 testes corretamente. Execução real pendente (ver critério de aceite acima).

## Status
In Validation — falta rodar contra ambiente e2e real antes de promover.
