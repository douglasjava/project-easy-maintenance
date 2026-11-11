# TASK-447 — Financeiro v2: competência do lançamento + visão mensal por competência

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟡 Médio

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.1 e D1), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- Campo `competence` (YYYY-MM), obrigatório na criação, com padrão no mês da `entry_date`; migração preenche os existentes.
- `/summary/monthly` aceita `groupBy=PAYMENT|COMPETENCE` (padrão PAYMENT).
- Web: campo no formulário e seletor "Agrupar por" no resumo mensal.

## Critérios de Aceite
- [ ] Lançamento novo nasce com a competência do mês da data
- [ ] Lançamentos antigos migrados
- [ ] Visão por competência soma pelo mês de referência

## Dependências
—

## Riscos
Mudar a soma padrão do resumo (D1: o padrão continua pagamento).

## Status
⬜ Backlog
