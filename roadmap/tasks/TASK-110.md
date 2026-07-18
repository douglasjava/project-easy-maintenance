# TASK-110 — Backend: parar de criar item ORGANIZATION cobrável

## Tipo
BACKEND

## Categoria
Billing / Onboarding

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

Hoje, tanto no onboarding (`OnboardingService.createUser` + `createOrganization`) quanto na criação de
2ª/3ª organização (`OrganizationsService.addOrganizationSubscription`), cada organização criada gera um
`BillingSubscriptionItem` próprio com `sourceType=ORGANIZATION` e `valueCents` igual ao preço cheio do
plano, somado ao item `USER` na mesma `BillingSubscription`.

Isso duplica a cobrança por organização — ex.: onboarding cria 1 item USER + 1 item ORGANIZATION, ambos
BUSINESS (R$299), totalizando R$598/mês — contrariando o modelo de plano único por conta já desenhado no
TASK-053, onde "Organizações" e "Itens/Org" são limites embutidos no mesmo tier, não produtos separados.

## Solução

- `OnboardingService.createOrganization()` (linhas 114-117): remover a chamada
  `billingSubscriptionService.addItem(billingSubscription, ORGANIZATION, orgCode, trialPlan)`. A
  organização passa a ser vinculada ao usuário sem gerar item cobrável.
- `OrganizationsService.addOrganizationSubscription()` (linhas 298-313): mesma remoção para o fluxo de
  criação de 2ª/3ª organização (usuário ou admin adicionando mais orgs dentro do `maxOrganizations` do
  seu plano).
- Avaliar se `BillingSubscriptionItem(sourceType=ORGANIZATION)` deixa de ser criado por completo, ou se
  passa a ser criado com `valueCents=0` como registro de vínculo não-cobrável (necessário para TASK-113
  — decidir durante implementação, priorizando o caminho mais simples que não quebre consultas
  existentes).
- `BillingSubscriptionService.recalculateTotal()` não muda de lógica (continua somando itens), mas o
  `totalCents` resultante passa a refletir apenas o item USER.

## Arquivos impactados

### Backend
- `onboarding/application/service/OnboardingService.java`
- `org_users/application/service/OrganizationsService.java`
- `billing/application/service/BillingSubscriptionService.java` (se necessário ajustar `addItem`)

## Critérios de Aceite

- [x] Onboarding completo (createUser + createOrganization) gera `BillingSubscription` com
      `totalCents` = preço de um único plano (ex.: R$299 BUSINESS), não R$598
- [x] Adicionar 2ª/3ª organização (dentro do limite `maxOrganizations`) não altera `totalCents` da
      subscription
- [x] `maxOrganizations` continua sendo validado e bloqueando criação além do limite do plano do usuário
      (lógica não tocada; `OrganizationPlanLimitTest`/`UserPlanLimitTest` continuam verdes)
- [x] Testes unitários: `OnboardingServiceTest` e `OrganizationsServiceTest` cobrindo `totalCents` após
      criação de múltiplas organizações

## Dependências
Nenhuma — task inicial da epic.

## Esforço
Médio (1 dia)

## Risco de não fazer
Todo novo cadastro continua sendo cobrado ~2x o valor do plano, distorcendo pricing e prejudicando
conversão de trial em pago.

## Implementação

### Decisão técnica
Em vez de remover a criação do item `ORGANIZATION` nos dois pontos de chamada (como cogitado na seção
"Solução"), a correção foi centralizada em `BillingSubscriptionService.addItem()` — único ponto real de
criação de `BillingSubscriptionItem` no sistema (3 call sites: `OnboardingService.createUser`,
`OnboardingService.createOrganization`, `OrganizationsService.addOrganizationSubscription`). O item
`ORGANIZATION` continua sendo criado normalmente (com `plan` associado), mas com `valueCents = 0`;
apenas o item `USER` carrega o preço cheio do plano. Isso corrige a causa raiz sem duplicar lógica nos
call sites e sem quebrar `getOrganizationSubscription`, `listUserOrganizations` ou
`MaintenanceItemService.validateItemLimit` (que ainda leem `item.getPlan()` normalmente — serão
migrados para o pool compartilhado na TASK-111).

### Arquivos modificados
- `billing/application/service/BillingSubscriptionService.java` — `addItem()`: `valueCents` passa a ser
  `plan.getPriceCents()` apenas quando `sourceType == USER`; `0L` para `ORGANIZATION`

### Arquivos criados (testes)
- `billing/application/service/BillingSubscriptionServiceTest.java` — 4 testes cobrindo `addItem`
  (USER cobrável, ORGANIZATION não-cobrável, `totalCents` com múltiplas orgs, `plan` preservado no item)
- `onboarding/application/service/OnboardingServiceTest.java` — 2 testes de integração leve
  (`BillingSubscriptionService` real + demais dependências mockadas) cobrindo `createUser` +
  `createOrganization` x3
- `org_users/application/service/OrganizationsServiceTest.java` — 2 testes cobrindo
  `addOrganizationSubscription` (sourceType correto) e `getOrganizationSubscription` (compat)

### Resultado dos testes
- 539/539 testes backend green ✅ (+8 novos, 0 regressões)

### Nota de risco conhecida (não corrigida nesta task)
`BillingSubscriptionService.applyPendingPlans()` (troca de plano por item) ainda pode reintroduzir
`valueCents > 0` num item `ORGANIZATION` se um usuário trocar o plano de uma organização isoladamente
— esse caminho só é removido/depreciado na TASK-112 (`OrganizationPlanChangeService`), conforme
sequenciamento da EPIC-014.

## Status
Em Validação
