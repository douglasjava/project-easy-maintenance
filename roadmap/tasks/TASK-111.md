# TASK-111 — Backend: pool compartilhado de maxItems entre organizações do owner

## Tipo
BACKEND

## Categoria
Billing / Limites de Plano

## Prioridade
🔴 Crítico

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

`MaintenanceItemService.validateItemLimit(orgId)` hoje lê o limite `maxItems` do
`BillingSubscriptionItem` com `sourceType=ORGANIZATION` daquela organização especificamente — cada
organização tem seu próprio teto independente (ex.: 500 itens no BUSINESS).

Com a remoção do item cobrável por organização (TASK-110), essa checagem perde a fonte de dados. Além
disso, por decisão de produto, `maxItems` passa a ser um **pool compartilhado entre todas as
organizações do mesmo usuário pagador**, não um teto por organização isolado.

## Solução

- `validateItemLimit(orgId)` passa a:
  1. Resolver o owner/payer da organização
  2. Buscar o plano do item USER desse owner (`BillingSubscriptionItem sourceType=USER`)
  3. Somar a contagem de `maintenance_items` em **todas** as organizações desse owner
  4. Comparar a soma contra `maxItems` do plano da conta
- Nova query/repositório para contagem agregada de itens por owner (join
  `Organization → owner → maintenance_items`), evitando N+1 — usar `COUNT` agregado no banco, não
  iteração em memória.
- Mensagem de erro ao atingir o limite deve deixar claro que o teto é da conta (soma de todas as
  organizações), não da organização atual sendo editada.

## Arquivos impactados

### Backend
- `assets/application/service/MaintenanceItemService.java` (linhas 293-317 — `validateItemLimit`)
- Novo método de repositório (contagem agregada por owner) — provavelmente em
  `MaintenanceItemRepository` ou `OrganizationRepository`

## Critérios de Aceite

- [x] Criar item em qualquer organização do usuário valida contra a soma de itens de todas as suas
      organizações
- [x] Usuário com 2 organizações, cada uma com itens, é bloqueado ao atingir o `maxItems` somado do
      plano da conta, mesmo que uma única organização individualmente esteja abaixo do teto
- [x] Mensagem de erro reflete que o limite é da conta (não da organização)
- [x] Testes unitários: cenário com múltiplas organizações do mesmo owner, cenário de borda exatamente
      no limite, cenário de organização isolada (owner com 1 org só)

## Dependências
TASK-110

## Esforço
Médio-alto (1-2 dias)

## Risco de não fazer
Limite de itens fica sem fonte de dados válida após TASK-110, quebrando o enforcement de plano
(usuários poderiam cadastrar itens ilimitados).

## Implementação

### Decisão técnica
`validateItemLimit(orgId)` passou a resolver o "owner/conta" através da própria `BillingSubscription`
à qual o item `ORGANIZATION` daquela organização pertence — em vez de introduzir um novo conceito de
"ownership" (via `UserOrganization`/role), reaproveita a estrutura de billing já existente: 1
`BillingSubscription` = 1 conta. Fluxo:
1. Busca o item `ORGANIZATION` da org (`findBySourceTypeAndSourceId`) → obtém a `BillingSubscription`
2. Busca todos os itens dessa mesma subscription (`findAllByBillingSubscriptionId`)
3. O item `USER` dentro desse conjunto fornece o plano da conta (`maxItems`)
4. Os `sourceId` de todos os itens `ORGANIZATION` desse conjunto formam a lista de orgs do pool
5. `MaintenanceItemRepository.countByOrganizationCodeIn(orgCodes)` (novo método) soma os itens de todas
   elas, comparando contra `maxItems` da conta

### Arquivos modificados
- `assets/application/service/MaintenanceItemService.java` — `validateItemLimit()` reescrito
- `assets/infrastructure/persistence/MaintenanceItemRepository.java` — novo método
  `countByOrganizationCodeIn(Collection<String>)`

### Arquivos de teste ajustados
- `assets/application/service/MaintenanceItemPlanLimitTest.java` — reescrito para o novo mecanismo de
  resolução (9 testes: limite exato, acima do limite, sem assinatura, sem item USER, abaixo do limite,
  primeiro item, ilimitado, pool com múltiplas orgs bloqueando, pool com múltiplas orgs permitindo)
- `assets/application/service/MaintenanceItemAuditTest.java` — `stubSubscriptionUnlimited()` atualizado
  para o novo mecanismo de resolução (não é o alvo do teste, apenas infraestrutura de stub)

### Resultado dos testes
- 539/539 testes backend green ✅ (0 regressões; contagem líquida da suíte inalterada porque os testes
  de `MaintenanceItemPlanLimitTest` foram substituídos 1:1, não somados)

## Status
Em Validação
