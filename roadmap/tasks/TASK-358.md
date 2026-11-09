# TASK-358 — Voto do conselheiro (WhatsApp ou link) com auditoria

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-036](../epics/EPIC-036.md) — Conselho e aprovação de orçamentos · **Fase 4**

## Depende de
TASK-355, TASK-357

## QA obrigatório
Sim.

## Contexto
Conselheiro vê os orçamentos lado a lado e aprova, recusa ou comenta.
Base: `staging` · branch `feature/TASK-358-<descricao-curta>`.

## Escopo
- Valida mandato e conflito de interesse.
- Cada voto guarda conselheiro, horário, decisão e comentário; exportável para ata.
- Fornecedor escolhido recebe o pedido após aprovação.

## Critérios de aceite
- [ ] Conselheiro com mandato vencido não vota
- [ ] Voto duplicado é ignorado
- [ ] Histórico exportável

## Status
Backlog
