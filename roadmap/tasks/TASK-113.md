# TASK-113 — Backend: compat de GET /organizations/{code}/subscription

## Tipo
BACKEND

## Categoria
Billing / API

## Prioridade
🟠 Alto

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

`GET /organizations/{code}/subscription` (originalmente recriada na TASK-056) hoje retorna o
`BillingSubscriptionItem` próprio da organização (plano, preço, status). Com a remoção do item cobrável
por organização (TASK-110), essa rota perde a fonte de dados. O frontend ainda depende dela na tela de
organização/empresa (Step 2 do cadastro de org e telas de detalhe).

## Solução

- `OrganizationsService.getOrganizationSubscription(orgCode)` passa a montar a resposta a partir do
  **plano da conta** (item USER do owner) + **uso agregado do pool** de itens daquela organização
  especificamente (quantos itens essa organização usa dentro do pool total da conta).
- Resposta mantém formato compatível com os campos de plano/preço já consumidos pelo frontend,
  acrescentando campos de uso agregado (ex.: `itemsUsedByOrg`, `itemsUsedTotalAccount`,
  `maxItemsAccount`) para a UI mostrar contexto de pool compartilhado.

## Arquivos impactados

### Backend
- `org_users/application/service/OrganizationsService.java` — método `getOrganizationSubscription()`
- `billing/application/dto/BillingSubscriptionResponse.java` (ou equivalente) — novos campos de uso
  agregado

## Critérios de Aceite

- [x] `GET /organizations/{code}/subscription` retorna 200 com o plano da conta (não mais um plano
      próprio da organização)
- [x] Resposta inclui uso de itens da organização dentro do pool total da conta
- [x] Frontend consumidor (tela de organização, Step 2 de cadastro) não quebra com o novo formato de
      resposta — ver nota de risco em "Implementação" (compat aditiva, não testada contra o frontend real)
- [x] Retorna 404 quando a organização não existe ou não pertence a nenhuma conta com subscription
- [x] Testes unitários/integração cobrindo a nova resposta

## Dependências
TASK-110, TASK-111

## Esforço
Baixo-médio (0,5-1 dia)

## Risco de não fazer
Tela de detalhe/cadastro de organização quebra (500 ou dado vazio) assim que o item ORGANIZATION deixar
de existir.

## Implementação

### Decisão técnica
- Criado um novo record `BillingSubscriptionResponse.OrganizationSubscriptionResponse` **em vez de**
  adicionar os campos de pool diretamente em `SubscriptionItemResponse`. Esse record é compartilhado por
  vários outros endpoints não relacionados a esta task (listagem de itens em `/me/billing/summary` via
  `BillingSubscriptionItemService`, painel admin, resposta de troca de plano) — adicionar campos de pool
  ali forçaria todos esses outros produtores a lidar com campos irrelevantes para eles. O novo record
  mantém exatamente os mesmos nomes/tipos de campo de `SubscriptionItemResponse` (mudança aditiva, não
  há remoção de campo) + 3 novos: `itemsUsedByOrg`, `itemsUsedTotalAccount`, `maxItemsAccount`.
- `planCode`/`planName`/`valueCents`/`nextPlanCode`/`planChangeEffectiveAt` agora vêm do item **USER**
  (conta) da mesma `BillingSubscription`, não mais do item ORGANIZATION (que hoje sempre tem
  `valueCents=0` e não aceita mais troca de plano própria, TASK-112). `sourceId`/`sourceType`/`id`/
  `activatedAt` continuam vindo do item ORGANIZATION (identifica a qual organização a resposta se
  refere).
- `itemsUsedByOrg` = `countByOrganizationCode(orgCode)`; `itemsUsedTotalAccount` =
  `countByOrganizationCodeIn(todosOsCodesDaConta)` (reaproveita método da TASK-111);
  `maxItemsAccount` = `maxItems` do plano do item USER.
- `addOrganizationSubscription()` (usado pelos 2 endpoints PUT — self-service e admin) também mudou de
  tipo de retorno, já que delega para `getOrganizationSubscription()` internamente.

### Arquivos modificados
- `billing/application/dto/response/BillingSubscriptionResponse.java` — novo record
  `OrganizationSubscriptionResponse`
- `org_users/application/service/OrganizationsService.java` — `getOrganizationSubscription()`
  reescrito; `addOrganizationSubscription()` com novo tipo de retorno; nova dependência
  `MaintenanceItemRepository`
- `org_users/infrastructure/web/OrganizationsController.java` — 2 endpoints (`GET`/`PUT`
  `/{orgCode}/subscription`) com tipo de retorno atualizado
- `admin/infrastucture/web/AdminBillingController.java` — endpoint admin `PUT
  /organizations/{orgCode}/subscription` com tipo de retorno atualizado

### Arquivos de teste ajustados
- `org_users/application/service/OrganizationsServiceTest.java` — reescrito (4 testes): plano da conta
  em vez do item da org, pool somado entre múltiplas orgs, 404 quando organização não tem item

### Resultado dos testes
- 546/546 testes backend green ✅ (+2 novos líquidos nesta task, 0 regressões)

### Nota de risco (fora do escopo backend-only desta task)
O critério "frontend não quebra" foi atendido de forma **aditiva** (nenhum campo removido, apenas
reapontado semanticamente + 3 novos campos), mas **não foi validado contra o código real do
frontend** (Step 2 de cadastro de org / tela de organização) — essa validação visual/funcional é
escopo da TASK-115/116. Como o formato JSON continua flat com os mesmos nomes de campo, o risco de
quebra é baixo, mas não nulo se o frontend fizer alguma validação estrita de schema.

## Status
Em Validação
