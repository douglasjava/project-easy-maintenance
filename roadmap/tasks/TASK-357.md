# TASK-357 — Pedido de aprovação com até 3 orçamentos + regras por condomínio

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-036](../epics/EPIC-036.md) — Conselho e aprovação de orçamentos · **Fase 4**

## Depende de
TASK-356

## QA obrigatório
Sim.

## Contexto
Evoluir `SupplierBudgetRequest` para cotação múltipla com regras configuráveis.
Base: `staging` · branch `feature/TASK-357-<descricao-curta>`.

## Escopo
- Quando exige conselho (valor, categoria), quórum (maioria, unanimidade, número fixo), prazo com lembrete.
- Síndico não marca como aprovado o que exige conselho.
- Fornecedor bloqueado não entra na cotação.

## Critérios de aceite
- [ ] Regras padrão aplicadas (maioria, 72 h, limite)
- [ ] Pedido sem conselheiros ativos fica aguardando atualização do conselho

## Status
Backlog
