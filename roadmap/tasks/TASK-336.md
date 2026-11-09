# TASK-336 — Piloto acompanhado de 30 dias (extensão de trial pelo admin)

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 0**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
O trial de 14 dias é menor que o ciclo de qualquer manutenção. Para contas acompanhadas, o piloto deve ter 30 dias.
Base: `staging` · branch `feature/TASK-336-<descricao-curta>`.

## Escopo
- Verificar se o admin já permite estender o fim do trial; se não, ação no painel admin com motivo e auditoria.
- Não mudar o trial do autosserviço público nesta task.

## Critérios de aceite
- [ ] Admin estende o trial de uma conta para 30 dias
- [ ] Ação auditada
- [ ] Jobs de bloqueio respeitam a nova data

## Status
Backlog
