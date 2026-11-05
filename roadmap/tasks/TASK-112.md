# TASK-112 — Backend: downgrade validation com pool de itens + depreciar OrganizationPlanChangeService

## Tipo
BACKEND

## Categoria
Billing / Troca de Plano

## Prioridade
🟠 Alto

## Épico
EPIC-014 — Consolidação de Billing: Plano Único por Conta

## Fase
1 — Pré-lançamento

## Problema

`UserPlanChangeService.validateDowngradeLimits()` hoje só valida `organizationCount` (e `maxUsers`)
contra o novo plano; não considera o pool de itens introduzido na TASK-111. Além disso,
`OrganizationPlanChangeService` permite trocar o plano de uma organização isoladamente do plano da
conta — conceito que deixa de fazer sentido no modelo de plano único por conta.

## Solução

- `UserPlanChangeService.validateDowngradeLimits()`: adicionar validação de que a soma de itens
  (`maintenance_items`) de todas as organizações do usuário não excede o `maxItems` do plano-alvo do
  downgrade, além das validações já existentes de `organizationCount` e `maxUsers`.
- Remover (ou depreciar e desligar do controller) `OrganizationPlanChangeService` e qualquer endpoint
  que permita trocar o plano de uma organização isoladamente.
- Atualizar `OrganizationsController`/`AdminBillingController` removendo rotas de troca de plano por
  organização, se existirem expostas publicamente.

## Arquivos impactados

### Backend
- `billing/application/service/UserPlanChangeService.java` — método `validateDowngradeLimits()`
- `billing/application/service/OrganizationPlanChangeService.java` — remover ou depreciar
- Controllers que expõem troca de plano por organização (verificar `OrganizationsController`,
  `AdminBillingController`)

## Critérios de Aceite

- [x] Downgrade bloqueado com mensagem clara quando a soma de itens das organizações excede `maxItems`
      do novo plano
- [x] Downgrade bloqueado quando `organizationCount` excede o novo plano (comportamento já existente,
      preservado). **Nota**: `maxUsers` nunca foi de fato validado em `validateDowngradeLimits()` — a
      premissa do problema estava incorreta; ver seção "Implementação" abaixo
- [x] Endpoint de troca de plano por organização removido ou retorna 404/410
- [x] Testes unitários: `UserPlanChangeServiceTest` cobrindo o novo cenário de bloqueio por itens

## Dependências
TASK-111

## Esforço
Médio (1 dia)

## Risco de não fazer
Usuário pode dar downgrade e ficar com um plano cujo `maxItems` já foi ultrapassado pela soma real de
itens cadastrados, gerando inconsistência entre o que foi pago e o que está em uso.

## Implementação

### Decisão técnica
- `UserPlanChangeService.validateDowngradeLimits()` ganhou uma segunda validação, após a de
  `organizationCount`: resolve as organizações do usuário (`OrganizationRepository.findAllByUserId`),
  soma os itens de todas via `MaintenanceItemRepository.countByOrganizationCodeIn` (mesmo método criado
  na TASK-111) e compara com `maxItems` do plano-alvo. `maxItems <= 0` continua significando ilimitado.
- **Achado durante a implementação**: a premissa do problema ("hoje só valida organizationCount e
  maxUsers") estava parcialmente incorreta — `validateDowngradeLimits()` nunca validou `maxUsers`, só
  `organizationCount`. Não implementei validação de `maxUsers` aqui por estar fora do escopo original
  da task (não foi pedido adicionar uma validação nova, só preservar a existente); registrado como nota
  para eventual task futura caso o produto queira essa checagem.
- `SubscriptionItemChangePlanAdapter`: removida a ramificação que roteava itens `ORGANIZATION` para
  `OrganizationPlanChangeService` — agora lança `NotFoundException` (404) explicando que a troca de
  plano por organização não é mais suportada. Itens `USER` continuam funcionando normalmente.
- `OrganizationPlanChangeService.java` **removida por completo** (não apenas depreciada) — após checar
  que seu único consumidor era o adapter, não fazia sentido manter uma classe morta.

### Arquivos modificados
- `billing/application/service/UserPlanChangeService.java` — validação de pool de itens no downgrade
- `billing/application/adapter/SubscriptionItemChangePlanAdapter.java` — bloqueia troca de plano por
  item ORGANIZATION com `NotFoundException`

### Arquivos removidos
- `billing/application/service/OrganizationPlanChangeService.java`

### Arquivos de teste criados/ajustados
- `billing/application/adapter/SubscriptionItemChangePlanAdapterTest.java` (novo, 3 testes) — roteamento
  USER, bloqueio ORGANIZATION (404), item de outro usuário (404)
- `billing/application/service/UserPlanChangeServiceTest.java` — 2 testes novos (bloqueio por pool de
  itens excedido, downgrade permitido dentro do pool) + 2 testes existentes ajustados (`maxItems(0)`
  explícito para não disparar a nova validação em cenários que não a exercitam)

### Resultado dos testes
- 544/544 testes backend green ✅ (+5 novos: 3 do adapter, 2 do UserPlanChangeService)

## Status
Em Validação
