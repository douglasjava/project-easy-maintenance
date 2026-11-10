# TASK-444 — Financeiro: visão mensal e acumulado

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟡 Médio — FI-02.

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
FI-02 do [registro](../QA/registro-usabilidade-producao.md). O `/summary` já existe; falta agrupar por mês e mostrar o acumulado.

## Escopo
- Endpoint de resumo por mês (receita, despesa, saldo) e acumulado do período.
- Web: tabela/gráfico mensal com acumulado.

## Critérios de Aceite
- [ ] Totais mensais batem com a soma dos lançamentos
- [ ] Lançamentos cancelados fora da conta

## Dependências
Nenhuma.

## Riscos
Performance do agrupamento: índice por organização e data.

## Status
⬜ Backlog
