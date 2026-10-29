# TASK-378 — Frontend: aba de Áreas Comuns (listar, criar, editar)

## Tipo
FRONTEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
[TASK-376](TASK-376.md), [TASK-377](TASK-377.md)

## QA obrigatório
Sim — CRUD completo numa tela nova, incluindo o toggle de `active` e o campo de taxa opcional.

## Contexto
Desenho completo na spec/plano citados na TASK-373 (Task 6 do plano).

`CommonAreasTab.tsx` (segunda aba de `/configuracoes`, criada na TASK-377): lista áreas via
`GET /organizations/common-areas` (TASK-376), botão "Nova área" e "Editar" por linha abrindo
`CommonAreaFormModal.tsx` — formulário com nome, capacidade, taxa opcional (usando
`formatCurrencyInput`/`parseCurrencyInputToCents` de `@/lib/formatters`, mesmo helper já usado em
`financeiro/page.tsx` para dinheiro) e as 4 regras de reserva, mais toggle de `active` em modo
edição. `POST` para criar, `PUT /organizations/common-areas/{id}` para editar (incluindo
desativar).

**Prompt**: `execute a TASK-378 (EPIC-038): aba de Áreas Comuns, seguindo a Task 6 do plano
docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `npx tsc --noEmit` e `npm run build` limpos.
- [ ] QA manual: criar área com taxa e regras, confirmar na lista, editar (incluindo desativar),
      confirmar que persiste após recarregar.

## Status
Backlog
