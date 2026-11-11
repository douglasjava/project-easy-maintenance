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
- [x] Lançamento novo nasce com a competência do mês da data
- [x] Lançamentos antigos migrados
- [x] Visão por competência soma pelo mês de referência

## Dependências
—

## Riscos
Mudar a soma padrão do resumo (D1: o padrão continua pagamento).

## Implementação (11/11/2026)
[api#222](https://github.com/douglasjava/easy-maintenance-api/pull/222) e [web#155](https://github.com/douglasjava/easy-maintenance-web/pull/155), mergeadas em `staging`.
- A migração V153 cria `competence` (YYYY-MM) e preenche os lançamentos existentes com o mês da `entry_date`. ⚠️ Ainda não foi executada num MySQL; a primeira execução será no deploy da staging.
- Na criação e na edição, a competência é opcional: sem ela, vale o mês da data. A faixa aceita vai de 10 anos antes até 12 meses depois da data, e a mudança fica na auditoria.
- `/summary/monthly?groupBy=PAYMENT|COMPETENCE`, com padrão PAYMENT (D1). O custo da manutenção entra pelo mês da execução.
- Web: campo de competência no formulário, "ref. mês" na lista e seletor "Agrupar por" no resumo.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
