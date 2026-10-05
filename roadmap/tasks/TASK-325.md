# TASK-325 — Frontend: tela /financeiro

## Tipo
FRONTEND

## Prioridade
🟠 Alto

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle Financeiro Simples por Organização

## Depende de
TASK-324

## QA obrigatório
Sim — formulário de lançamento, estados de loading/erro, visibilidade condicional por papel
(`ADMIN`/`SYNDIC`).

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-04-financial-entries-plan.md`](../../docs/superpowers/plans/2026-10-04-financial-entries-plan.md) (Task 4).

Lista de lançamentos (filtro por período), botões "Nova receita"/"Nova despesa" (só pra
`ADMIN`/`SYNDIC`, mesmo padrão de leitura de `userRole` do localStorage/sessionStorage já usado em
`app/maintenances/page.tsx`), cancelamento com motivo obrigatório via `ConfirmModal`.

**Prompt**: `execute a TASK-325 (EPIC-032): tela /financeiro, seguindo a Task 4 do plano
docs/superpowers/plans/2026-10-04-financial-entries-plan.md.`

## Critérios de aceite
- [x] Lançar receita/despesa com categoria filtrada pelo tipo escolhido.
- [x] Cancelar lançamento exige motivo com pelo menos 5 caracteres.
- [x] Botões de lançar/cancelar só visíveis pra `ADMIN`/`SYNDIC`.
- [x] `tsc --noEmit` e `eslint` limpos.

## Execução (05/10/2026)
`src/app/financeiro/page.tsx` criado. Desvio do plano: usado o helper `mapError` (`lib/errorMapper.ts`,
já existente) em vez de `err: any` pra extrair a mensagem de erro — o eslint do projeto proíbe `any`
explícito.

## Status
Done
