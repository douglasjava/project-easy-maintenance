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
- [x] Totais mensais batem com a soma dos lançamentos
- [x] Lançamentos cancelados fora da conta

## Dependências
Nenhuma.

## Riscos
Performance do agrupamento: índice por organização e data.

## Implementação (11/11/2026)
[api#220](https://github.com/douglasjava/easy-maintenance-api/pull/220) e [web#153](https://github.com/douglasjava/easy-maintenance-web/pull/153), mergeadas em `staging`.
- `GET /finance/summary/monthly` devolve, por mês, receita, despesa manual, despesa de manutenção, saldo e acumulado, mais os totais no formato do `/summary`.
- Usa a mesma conta do `/summary`: a despesa vinculada a manutenção não conta duas vezes e os cancelados ficam fora.
- Agrupa por dia no SQL e junta em meses no service, usando o índice `(organization_code, entry_date)`. O período vai até 36 meses.
- Web: cartão "Resumo por mês" com os totais e uma tabela com o acumulado.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
