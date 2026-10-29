# TASK-379 — Frontend: entrada "Configurações" no menu do usuário

## Tipo
FRONTEND

## Prioridade
🟡 Médio

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
[TASK-377](TASK-377.md)

## QA obrigatório
Sim — garantir que TECH/READER não veem a entrada, mesmo que acessem a rota direto (guard já
coberto pela TASK-377).

## Contexto
Desenho completo na spec/plano citados na TASK-373 (Task 7 do plano).

Novo item "Configurações" no dropdown de `UserTopBar.tsx`, mesmo padrão do item "Financeiro" já
existente lá — gated por um novo flag `canManageSettings` (ADMIN ou SYNDIC), calculado no mesmo
efeito que hoje calcula `isAdmin` a partir de `userRole` em `localStorage`/`sessionStorage`.

**Prompt**: `execute a TASK-379 (EPIC-038): entrada Configurações no menu do usuário, seguindo a
Task 7 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `npx tsc --noEmit` limpo.
- [ ] QA manual: TECH/READER não veem "Configurações" no menu; ADMIN/SYNDIC veem e navegam
      corretamente para `/configuracoes`.

## Status
Backlog
