# TASK-342 — Relatório mensal de prova enviado automaticamente

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 1**

## Depende de
TASK-310, TASK-341

## QA obrigatório
Sim.

## Contexto
O valor do produto só aparece em sinistro, assembleia ou troca de síndico. O relatório mensal torna esse valor visível todo mês.
Base: `staging` · branch `feature/TASK-342-<descricao-curta>`.

## Escopo
- Job (ShedLock) no dia 1: PDF + link com % de críticas em dia, evidências, pendências e custos do mês.
- Envio ao síndico (e-mail e WhatsApp); opcional para o conselho.
- Opt-out por organização.

## Critérios de aceite
- [ ] Relatório gerado sem ação manual no dia 1
- [ ] Conteúdo bate com a prestação de contas do período
- [ ] Sem envio duplicado

## Status
Backlog
