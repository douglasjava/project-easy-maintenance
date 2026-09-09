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

- [x] `next90Days` com exatamente 13 buckets semanais, começando na segunda-feira da semana atual
- [x] `plannedVsDone` com exatamente 12 buckets mensais; mês atual marcado `partial: true`
- [x] `unitsRanking` só em escopo `PORTFOLIO`, ordenado ascendente por índice (pior primeiro)
- [x] `costByCategory` ordenado descendente por valor, categorias com custo zero omitidas
- [x] Uma query por série (SQL), sem N+1; resposta cacheada por tenant+filtro por 5 minutos

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
  `OPERACIONAL` (não é a mesma coisa). Decisão #7 do épico (respondida 09/09/2026): criar o
  dicionário `itemType → categoria de exibição` — taxonomia inicial já proposta no EPIC-030,
  mesmo espírito de `SupplierCategoryKeywords`.
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
TASK-246 (índice de conformidade precisa existir pro `unitsRanking`).

## Riscos
Médio — a parte de séries/buckets é rotina de agregação SQL; o risco real está em `unitsRanking`
(mesma classe de bug cross-tenant da TASK-246).

## Esforço
Médio.

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `dashboard/application/DashboardScopeResolver.java` | extraído da TASK-246 pra ser compartilhado (agora 3 consumidores: summary, series, e a TASK-248 vai usar também) — resolve `COMPANY`/`PORTFOLIO` a partir do usuário autenticado, valida `companyCode` |
| `dashboard/application/CostCategoryTaxonomy.java` | dicionário `itemType → categoria de exibição` (decisão #7) |
| `dashboard/application/DashboardSeriesService.java` | monta as 4 séries, cache Caffeine 5min por `scope:orgCodes` |
| `dashboard/infrastructure/persistence/DashboardSeriesRepository.java` | query nativa dos 13 buckets semanais (`GREATEST`/`LEAST`/`FLOOR`/`DATEDIFF`) |
| `dashboard/infrastructure/persistence/{WeeklyBucketRow,MonthCountRow,ItemTypeCostRow}.java` | projeções das queries nativas |
| `dashboard/infrastructure/web/dto/DashboardSeriesResponse.java` | DTO da resposta |
| `test/.../DashboardScopeResolverTest.java` | 5 testes (movidos/expandidos a partir do que antes vivia dentro de `DashboardSummaryServiceTest`) |
| `test/.../DashboardSeriesServiceTest.java` | 7 testes: sem organização, 13 buckets sempre, 12 buckets mensais com `partial` correto, `costByCategory` soma por categoria + ordena + omite zero, `unitsRanking` só em portfolio e ordenado pior-primeiro, `unitsRanking` vazio em escopo `COMPANY`, cache evita segunda chamada ao repositório |

### Arquivos modificados
| Arquivo | Operação |
|---|---|
| `dashboard/application/DashboardSummaryService.java` | refatorado pra usar `DashboardScopeResolver` em vez de resolver organização inline (elimina duplicação com a lógica nova da TASK-247) |
| `assets/infrastructure/persistence/MaintenanceRepository.java` | `countPlannedByMonth`/`countDoneByMonth`/`costByItemType` (queries nativas, `organization_code IN (:orgs)` direto — não precisam de `TenantContext.runCrossOrg`, mesma razão da TASK-246) |
| `dashboard/infrastructure/web/DashboardController.java` | novo `GET /dashboard/series` |

### Decisões tomadas durante a implementação
- **`DashboardScopeResolver` extraído da TASK-246** — a lógica de resolver `COMPANY`/`PORTFOLIO` e
  validar `companyCode` é sensível a segurança e agora tem 2 consumidores reais (3 depois da
  TASK-248); manter em um lugar só evita uma cópia divergente vazar dado cross-tenant.
- **Achado real testando contra o MySQL do docker local**: `Maintenance.nextDueAt` (a coluna usada
  como sinal de "planejado" pro gráfico `plannedVsDone`) está **majoritariamente NULL** nos dados
  reais — o código (`MaintenanceService.java:287`) só grava esse campo quando o usuário sobrescreve
  manualmente o próximo vencimento de um item `REGULATORY`; a maioria das manutenções (inclusive
  toda `OPERACIONAL`) nunca preenche esse valor. Na prática, `planned` vai aparecer **zerado ou
  quase zerado** na maior parte dos meses até que mais dado real se acumule com esse padrão de uso
  — não é bug (a query está correta pro que o campo realmente significa), é limitação de dado que o
  documento original não previa (ele assumia um histórico de agendamento que não existe). Registrado
  aqui explicitamente em vez de escondido — vale uma decisão do Douglas se isso for aceitável pra v1
  ou se merece um sinal melhor (ex.: projetar "planejado" a partir da periodicidade do item, não
  implementado nesta task por complexidade/tempo).
- **`costByCategory`/`plannedVsDone` usam o mês corrente inteiro (1º dia até hoje) como período**,
  não uma janela de 30 dias — mesma convenção já usada em `monthlyCost` da TASK-246.

### Verificação
- `mvn clean test` → **976/976, 0 falhas** (965 da TASK-246 + 11 testes novos/reorganizados desta
  task).
- As 4 queries nativas (`next90DaysBuckets`, `countPlannedByMonth`, `countDoneByMonth`,
  `costByItemType`) validadas diretamente contra o MySQL real do docker local — sintaxe
  `GREATEST`/`LEAST`/`FLOOR`/`DATEDIFF`/`DATE_FORMAT` confirmada compatível com MySQL 8.0.33 (mesmo
  cuidado da TASK-230/241/246; essas queries usam função MySQL-específica o suficiente que não
  tentei replicar em H2 — validação ficou só contra o banco real).

Branch `feature/EPIC-030-compliance-dashboard` (mesma da TASK-246, decisão do Douglas de consolidar
o épico numa branch/PR só).

## Status
🟢 Implementado e testado (`mvn test` 976/976) — achado de qualidade de dado em `plannedVsDone`
documentado acima, aguardando decisão do Douglas se é aceitável pra v1.
