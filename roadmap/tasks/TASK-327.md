# TASK-327 — Frontend: item "Financeiro" no menu

## Tipo
FRONTEND

## Prioridade
🟡 Médio

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-325

## QA obrigatório
Não — mudança visual simples, sem lógica de negócio.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 6).

Item novo em `UserTopBar.tsx`, sem gate de plano (decisão da EPIC-032 de liberar pra todos).

**Prompt**: `execute a TASK-327 (EPIC-032): item "Financeiro" no menu, seguindo a Task 6 do plano
docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] Item visível no dropdown do usuário, levando pra `/financeiro`.
- [x] `tsc --noEmit` e `eslint` limpos.

## Execução (05/10/2026)
Ícone `Wallet` (lucide-react) + item adicionado após "Relatórios". 1 warning pré-existente e não
relacionado (`no-unused-vars`), sem erros.

## Status
Done
