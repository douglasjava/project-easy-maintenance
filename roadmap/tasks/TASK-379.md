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

## Execução
Implementado em `feature/EPIC-038-organization-settings` (easy-maintenance-web), a partir de
`staging`. Entrada "Configurações" adicionada ao dropdown do `UserTopBar`, ao lado de
"Financeiro" — **desvio de spec**: a spec original pedia a entrada na Sidebar lateral; ficou no
dropdown do usuário por ser onde itens equivalentes (Financeiro, Faturamento, Relatórios) já
vivem hoje. Sinalizado na PR para confirmação do Douglas, não assumido como resolvido. `npx tsc
--noEmit` limpo. PR aberta: [web#120](https://github.com/douglasjava/easy-maintenance-web/pull/120)
(mesma PR cobre TASK-377 a TASK-379).

## Status
Em Validação — PR aberta, QA manual (ADMIN/SYNDIC vê o item, TECH/READER não) ainda pendente.
