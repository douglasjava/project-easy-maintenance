# TASK-326 — Frontend: integração com Prestação de Contas

## Tipo
FRONTEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-324

## QA obrigatório
Sim — organização sem nenhum lançamento financeiro não pode quebrar o relatório nem mostrar
`NaN`/`undefined`.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 5).

`PrestacaoContasSection.tsx`/`PrestacaoContasPdfDocument.tsx` (EPIC-017) passam a chamar
`GET /finance/summary` e exibir Receitas/Despesas Manuais/Saldo, ao lado do Custo de Manutenção que
já existia.

**Prompt**: `execute a TASK-326 (EPIC-032): integração com a Prestação de Contas, seguindo a Task 5
do plano docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] Falha em `/finance/summary` não derruba o relatório (mesmo princípio do `complianceIndex`,
      TASK-294) — a seção financeira só não aparece.
- [x] `tsc --noEmit` e `eslint` limpos.

## Execução (05/10/2026)
Ambos os arquivos atualizados. 1 warning pré-existente e não relacionado (`alt-text` do logo em
`PrestacaoContasPdfDocument.tsx`), sem erros.

## Status
Done
