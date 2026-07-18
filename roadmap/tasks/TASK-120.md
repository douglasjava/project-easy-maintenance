# TASK-120 — BUGFIX Backend: filtro de tenant zera contagem de itens cross-org (afeta pool da EPIC-014)

## Tipo
BACKEND / BUGFIX

## Categoria
Billing / Multi-tenant

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Reportado por Douglas em teste manual: na tela `/billing`, a lista de organizações mostra "itens usados"
por organização, mas só a organização **ativa no TopBar** aparecia com contagem correta — as demais
apareciam com 0 itens, mesmo tendo itens reais cadastrados (exemplo relatado: Sofia com 3 itens, Ricardo
com 2, Brain com 4 — só Brain, a ativa no momento, aparecia certo).

### Causa raiz

`TenantFilterAspect` (`kernel/tenant/TenantFilterAspect.java`) é um `@Around` que intercepta **todo**
método de `MaintenanceItemRepository` e habilita um filtro Hibernate `@Filter` (definido em
`MaintenanceItem.java`) escopado ao `X-Org-Id` da requisição atual (`TenantContext.get()`). Esse filtro
é aplicado a **qualquer** query contra `MaintenanceItem`, inclusive queries derivadas que já recebem um
`organizationCode` explícito como parâmetro — o Hibernate faz um AND silencioso:

```sql
WHERE organization_code = :parametroExplicito AND organization_code = :orgAtivoNaSessao
```

Ou seja, `countByOrganizationCode("ORG-SOFIA")` enquanto a sessão está com `ORG-BRAIN` ativa sempre
retorna `0`, e `countByOrganizationCodeIn([...])` colapsa para contar só a organização ativa,
independente de quantos códigos forem passados na lista.

Esse já era um bug de classe conhecida no projeto — `TASK-QA-BUG-012` corrigiu o mesmo problema em
`ReportsService.listMaintenances` usando o padrão `TenantContext.setSystemContext()` /
`clearSystemContext()` (contexto de sistema temporário, que desliga o filtro).

### Impacto real (não é só exibição)

Uma investigação (agente Explore) mapeou **todos** os pontos da EPIC-014 afetados pelo mesmo bug:

| Local | Efeito |
|---|---|
| `BillingDashboardService.getBillingSummary()` — `itemsUsedByOrgCode` | Bug relatado por Douglas: contagem por org zerada em `/billing` |
| `BillingDashboardService.mapToSubscriptionSummary()` — `itemsUsedTotalAccount` | Total do pool da conta em `/billing` também errado |
| `OrganizationsService.getOrganizationSubscription()` — `itemsUsedByOrg`/`itemsUsedTotalAccount` | Mesma questão em `GET /organizations/{code}/subscription` (TASK-113) |
| `UserPlanChangeService.validateDowngradeLimits()` | **Downgrade podia passar** mesmo com pool de itens acima do novo limite (contagem subestimada) |
| `MaintenanceItemService.validateItemLimit()` | 🔴 **Mais grave**: o enforcement real do limite de itens (TASK-111) checava só a organização sendo escrita, não a soma real entre organizações — usuário podia ultrapassar o limite real da conta criando itens em organizações diferentes |
| `BillingSubscriptionService.listSubscriptions()` (admin, TASK-116) | Falha diferente: `/private/admin` nunca seta `TenantContext`, então a aspect lançava `TenantException` (403) ao tentar ler o uso do pool na listagem admin |

## Solução

- Adicionado `TenantContext.runCrossOrg(Supplier<T>)` — helper reutilizável que liga
  `setSystemContext()`, executa a query cross-org, e restaura o estado anterior em `finally`
  (não desliga se o chamador já estava em system context, evitando quebrar contexto externo).
- Aplicado em todos os 6 pontos da tabela acima, envolvendo especificamente as chamadas a
  `MaintenanceItemRepository.countByOrganizationCode(In)` que legitimamente precisam somar/contar
  através de múltiplas organizações já pertencentes à mesma conta autorizada.
- Segurança preservada: em todos os pontos, a lista/código de organizações usada já vinha de dados de
  billing (organizações da própria conta do usuário autenticado) antes de entrar no bloco cross-org —
  não há entrada de usuário não validada sendo usada para escapar do isolamento de tenant.

## Arquivos impactados

### Backend
- `kernel/tenant/TenantContext.java` — novo método `runCrossOrg()`
- `billing/application/service/BillingDashboardService.java`
- `org_users/application/service/OrganizationsService.java`
- `billing/application/service/UserPlanChangeService.java`
- `assets/application/service/MaintenanceItemService.java`
- `billing/application/service/BillingSubscriptionService.java`

## Critérios de Aceite

- [x] `TenantContext.runCrossOrg()` implementado e testado isoladamente (4 testes)
- [x] Todos os 6 call sites afetados corrigidos
- [x] 558/558 testes backend green (sem regressão)
- [ ] **Verificação visual pendente** — Douglas precisa reiniciar o backend local e conferir que as 3
      organizações do exemplo (Sofia/Ricardo/Brain) mostram a contagem correta simultaneamente em
      `/billing`, independente de qual está ativa no TopBar

## Nota — bug relacionado NÃO corrigido (fora do escopo desta task)

O mesmo agente de investigação encontrou que `ReportsService.getOverview()` (`/me/reports/overview`,
TASK-081, área de Relatórios) tem o **mesmo bug**, aparentemente não coberto pela correção original da
TASK-QA-BUG-012 (que só cobriu `listMaintenances`, não `getOverview`). Isso é anterior à EPIC-014 e não
foi tocado aqui — registrar como task separada se Douglas quiser corrigir.

## Dependências
TASK-111, TASK-112, TASK-113, TASK-115, TASK-116 (todos os pontos corrigidos foram introduzidos por
essas tasks)

## Esforço
Médio (investigação + correção em ~1h)

## Risco de não fazer
- UX confusa/incorreta em `/billing` (bug relatado)
- **Risco de negócio real**: limite de itens por conta (TASK-111, um dos pilares da EPIC-014) não era
  de fato aplicado corretamente entre múltiplas organizações — usuários podiam exceder a cota real do
  plano
- Painel admin de assinaturas (TASK-116) provavelmente retornava erro 403 ao listar organizações

## Status
Em Validação — aguardando confirmação visual do Douglas
