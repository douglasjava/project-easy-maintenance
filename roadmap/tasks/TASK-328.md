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

Teste de UI real: login via `loginViaUi` (`helpers/frontend-login.ts`) com a fixture
`TENANT_D_OPERATING`, navega até `/financeiro`, lança receita e despesa, confere refletido na lista
e na Prestação de Contas, cancela um lançamento e confirma que some.

**Nota de execução**: durante a implementação, uma leitura do working tree logo após o
`git checkout -b` (antes do filesystem sincronizar o conteúdo da nova branch) deu a falsa impressão
de que a fixture `TENANT_D_OPERATING` e o helper `loginViaUi` não existiam neste repositório — levou
a reescrever a task uma primeira vez como teste nível API. Investigação melhor (lendo os arquivos de
novo, já com a branch estabilizada) confirmou que ambos existem e que o plano original estava
correto. O teste final usa o fluxo de UI real, como planejado desde o início.

**Prompt**: `execute a TASK-328 (EPIC-032): e2e do módulo financeiro, seguindo a Task 7 do plano
docs/superpowers/plans/2026-10-04-financial-entries-plan.md (loginViaUi + TENANT_D_OPERATING).`

## Critérios de aceite
- [x] Lança receita e despesa via UI, confere refletido em `/financeiro` e na Prestação de Contas.
- [x] Cancelar remove da listagem ativa.
- [ ] **Executado contra API/banco e2e reais** — não foi possível nesta sessão (API/frontend não
      estavam de pé localmente, portas 9000/3000 fechadas — mesma limitação já documentada em
      outros specs deste repositório). Rodar `npm run setup:db` + subir a API e o frontend antes de
      promover.

## Execução (05/10/2026)
`tests/frontend/finance-entries.spec.ts` criado (projeto `ui` do Playwright). `npx tsc --noEmit`
limpo. `npx playwright test --list` reconhece os 2 testes corretamente, no projeto certo (`[ui]`).
Execução real contra ambiente vivo pendente (ver critério de aceite acima).

## Status
In Validation — falta rodar contra ambiente e2e real antes de promover.
