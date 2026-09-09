# TASK-247 — BACKEND: Endpoint `GET /dashboard/series` (séries pros gráficos)

## Tipo
BACKEND

## Categoria
Dashboard / Compliance

## Prioridade
🟠 Alto

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — confirmar contagem exata de buckets (13 semanas, 12 meses), ordenação de `unitsRanking`, e
que o cache de 5min não serve dado stale depois de uma ação (completar/adiar manutenção).

---

## Contexto

Renumerada de TASK-131 do documento original. Um único endpoint retorna 4 séries pro painel
renderizar tudo numa chamada só — decisão de design correta e alinhada com o padrão já usado no
dashboard atual (`DashboardResponse` já agrega KPIs + atenção + calendário + breakdowns numa
resposta só).

## Escopo

- `GET /easy-maintenance/api/v1/dashboard/series` — mesmos params da TASK-246.
- 4 séries numa resposta: `next90Days` (13 buckets semanais), `plannedVsDone` (12 buckets
  mensais), `costByCategory`, `unitsRanking` (só em `PORTFOLIO`).

## Critérios de Aceite

- [ ] `next90Days` com exatamente 13 buckets semanais, começando na segunda-feira da semana atual
- [ ] `plannedVsDone` com exatamente 12 buckets mensais; mês atual marcado `partial: true`
- [ ] `unitsRanking` só em escopo `PORTFOLIO`, ordenado ascendente por índice (pior primeiro)
- [ ] `costByCategory` ordenado descendente por valor, categorias com custo zero omitidas
- [ ] Uma query por série (SQL), sem N+1; resposta cacheada por tenant+filtro por 5 minutos

## Viabilidade Técnica

**Reaproveitável direto:**
- Cache: `DashboardService` já instancia `Caffeine.newBuilder()` in-process (TTL 15min pro bloco
  de IA) — mesmo mecanismo, TTL diferente, sem precisar avaliar/introduzir Redis ou outra
  dependência nova. O documento original já previa isso ("if none exists, use Spring's
  @Cacheable... and tell me") — a resposta é: existe, é Caffeine, já em uso no mesmo módulo.
- `Maintenance.costCents` existe por registro — soma por período/categoria é agregação SQL
  direta, sem entidade nova.

**Não existe e precisa ser criado:**
- `costByCategory` por categoria de exibição (ex. "Incêndio") não tem de onde vir — `itemType` é
  string livre (`MaintenanceItem.itemType`), `ItemCategory` só distingue `REGULATORY`/
  `OPERACIONAL` (não é a mesma coisa). Precisa de um dicionário `itemType → categoria de exibição`
  novo, mesmo espírito de `SupplierCategoryKeywords` (que existe mas é só pra fornecedores/Google
  Places, não cobre isso). Ver decisão #7 do épico.
- `unitsRanking` por organização depende do índice de conformidade por org (TASK-246) já estar
  pronto — não pode ser implementado isoladamente antes dela.

**Requer cuidado extra:**
- Mesma observação da TASK-246 sobre `TenantContext.runCrossOrg(...)` pro escopo `PORTFOLIO` —
  `unitsRanking` por natureza faz uma query por organização (ou uma agregação cross-org), então é
  o ponto mais sensível desta task pra isolamento multi-tenant.
- Cache por tenant+filtro de 5min precisa ser invalidado (ou aceitar staleness) quando uma ação da
  TASK-248 muda o estado de um item — decidir explicitamente: invalidação ativa ou só aceitar até
  5min de atraso (mais simples, mas contradiz "refetch imediato" que a TASK-251 pede na UI depois
  de uma ação).

## Dependências
TASK-246 (índice de conformidade precisa existir pro `unitsRanking`). Decisão #7 do épico
(taxonomia de categoria) bloqueia `costByCategory`.

## Riscos
Médio — a parte de séries/buckets é rotina de agregação SQL; o risco real está em `unitsRanking`
(mesma classe de bug cross-tenant da TASK-246) e na ausência da taxonomia de categoria.

## Esforço
Médio, condicionado a TASK-246 e à decisão #7 já estarem resolvidas.

## Status
🔴 Não iniciada — bloqueada por TASK-246.
