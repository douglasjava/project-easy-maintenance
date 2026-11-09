# TASK-356 — Cadastro de conselheiros com mandato

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-036](../epics/EPIC-036.md) — Conselho e aprovação de orçamentos · **Fase 4**

## Depende de
TASK-355

## QA obrigatório
Sim.

## Contexto
O conselho passa a ser um papel do sistema, com vigência.
Base: `staging` · branch `feature/TASK-356-<descricao-curta>`.

## Escopo
- Campos: nome, WhatsApp (validado com aceite), unidade, função, início e fim do mandato, ata (opcional), e-mail.
- Acesso expira sozinho; aviso 30 dias antes do fim.

## Critérios de aceite
- [ ] Mandato vencido bloqueia novas ações e mantém o histórico
- [ ] Dados de conselheiros não aparecem para fornecedores

## Status
Backlog
