# TASK-355 — Spec de segurança: identidade por telefone com escopo restrito

## Tipo
ANÁLISE / SEGURANÇA

## Prioridade
🔴 Crítico

## Épico
[EPIC-036](../epics/EPIC-036.md) — Conselho e aprovação de orçamentos · **Fase 4**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Pré-requisito de qualquer papel que não seja usuário autenticado (conselheiro, zelador, fornecedor) agir pelo WhatsApp.
Base: `staging` · branch `feature/TASK-355-<descricao-curta>`.

## Escopo
- Modelo de identidade, vínculo e expiração por papel.
- Matriz do que cada papel pode fazer; número desconhecido nunca altera dados.
- Revisão de segurança antes de implementar.

## Critérios de aceite
- [ ] Spec aprovada com matriz de permissões
- [ ] Ameaças mapeadas (troca de chip, número compartilhado)

## Status
Backlog
