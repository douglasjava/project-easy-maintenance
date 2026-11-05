# TASK-109 — Full-Stack: Troca de método de pagamento em ACTIVE

## Tipo
FULL_STACK

## Categoria
Billing / Gestão de Assinatura / Asaas Integration

## Prioridade
🟡 Médio

## Fase
3 — Maturidade

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Usuários ACTIVE não conseguem trocar o método de pagamento. A restrição atual faz sentido
porque a troca do campo `paymentMethod` não tem efeito no mecanismo real de cobrança:
- CC ativo: Asaas gerencia a subscription recorrente — mudar o campo não atualiza o Asaas
- PIX ativo: `PixRenewalService` lê `paymentMethod` — trocar para CC não cria checkout CC

Cada transição precisa de lógica específica para garantir que o próximo ciclo seja cobrado corretamente.

## Contexto técnico levantado

- CC subscriptions: gerenciadas pelo Asaas via `externalSubscriptionId` (cobranças automáticas)
- PIX subscriptions: gerenciadas internamente via `PixRenewalService` (cobranças manuais por ciclo)
- `POST /payments` Asaas não aceita dados de cartão — CC sempre usa checkout
- Troca CC→PIX exige cancelar subscription no Asaas; troca PIX→CC exige criar checkout CC
- `PixRenewalService` pode já ter criado PIX PENDING para o próximo ciclo com antecedência

## Solução por caso

### Caso 1 — ACTIVE CC → PIX (efeito no próximo ciclo)

Endpoint: `PATCH /me/billing/payment-method` com `{ method: "PIX" }` quando ACTIVE CC

1. Valida status ACTIVE + método atual CC
2. Cancela subscription no Asaas: `DELETE /subscriptions/{externalSubscriptionId}`
3. Limpa `externalSubscriptionId` na `BillingSubscription`
4. Salva `paymentMethod = PIX` na `BillingAccount`
5. Retorna `{ message: "PIX ativo a partir do próximo ciclo em {currentPeriodEnd}" }`

No vencimento: `PixRenewalService` detecta subscription PIX sem externalSubscriptionId → cria PIX normalmente.

### Caso 2 — ACTIVE CC → CC (atualização de cartão)

Endpoint: `POST /me/billing/update-card` (ação explícita, não PATCH payment-method)

1. Valida status ACTIVE + método atual CC
2. Cria novo checkout Asaas (CC, recorrente) com `nextDueDate = currentPeriodEnd`
   - **Não cancela a subscription antiga ainda**
3. Retorna `{ checkoutLink }` — usuário entra com novo cartão
4. Webhook `SUBSCRIPTION_CREATED`:
   - Cancela subscription antiga no Asaas (`DELETE /subscriptions/{externalSubscriptionId}`)
   - Salva novo `externalSubscriptionId`
   - Subscription permanece ACTIVE

A ordem garante que nunca haja janela sem subscription ativa.

### Caso 3 — ACTIVE PIX → CC (efeito no próximo ciclo livre)

Endpoint: `PATCH /me/billing/payment-method` com `{ method: "CARD" }` quando ACTIVE PIX

1. Valida status ACTIVE + método atual PIX
2. Verifica se já existe `Payment PENDING` para o próximo ciclo (cycleNumber = maxCycle + 1)
   - **SE SIM:** retorna aviso:
     ```json
     {
       "warning": "Existe um PIX pendente de R$ X com vencimento em {dueDate}. 
                   O cartão será utilizado a partir do ciclo seguinte.",
       "effectiveCycle": 2
     }
     ```
     Salva `paymentMethod = CARD` (o `PixRenewalService` deve respeitar — ver abaixo)
   - **SE NÃO:** salva `paymentMethod = CARD` normalmente
3. No próximo ciclo sem PIX pendente:
   - `PixRenewalService` verifica `account.getPaymentMethod()` — se `CARD`, skip (não cria PIX)
   - Novo job/path em `TrialExpirationService` (reutilizando lógica existente) cria checkout CC recorrente
   - Webhook `SUBSCRIPTION_CREATED` → ACTIVE com `externalSubscriptionId`

**Mudança no `PixRenewalService`:** adicionar guard antes de criar PIX:
```java
if (account.getPaymentMethod() != PaymentMethodType.PIX) {
    log.info("[PixRenewal] Subscription {} method changed to {}, skipping PIX renewal.",
            subscriptionId, account.getPaymentMethod());
    return;
}
```

**Novo path de renovação CC:** extrair de `TrialExpirationService` um método
`createRecurringCcCheckout(BillingSubscription, Invoice, LocalDate)` reutilizável no ciclo PIX→CC.

## Arquivos impactados

### Backend
- `billing/infrastructure/web/BillingController.java` — novo endpoint `POST /update-card`; ajuste no `PATCH /payment-method`
- `billing/application/service/BillingAccountService.java` — lógica de troca CC→PIX
- `billing/application/service/BillingRecoveryService.java` — novo método `initCardUpdate`
- `jobs/service/PixRenewalService.java` — guard `paymentMethod != PIX`
- `jobs/service/TrialExpirationService.java` — extrair `createRecurringCcCheckout` para reutilização
- `webhooks/asaas/strategy/impl/SubscriptionCreatedHandler.java` — cancelar subscription antiga quando é uma atualização de cartão (identificar pelo `externalReference` ou flag na subscription)

### Frontend
- `app/billing/page.tsx` — botão "Atualizar cartão" (ativo somente para ACTIVE CC)
- `app/billing/page.tsx` — botão "Trocar para PIX" / "Trocar para Cartão"
- Feedback de "efeito no próximo ciclo" para PIX→CC com PIX pendente

## Critérios de Aceite

- [ ] ACTIVE CC→PIX: subscription Asaas cancelada + `PixRenewalService` cria PIX no próximo ciclo
- [ ] ACTIVE CC→PIX: `externalSubscriptionId` limpo após cancelamento
- [ ] ACTIVE CC→CC: checkout retornado; após pagamento, `externalSubscriptionId` atualizado e subscription antiga cancelada
- [ ] ACTIVE CC→CC: não existe janela onde subscription fica sem `externalSubscriptionId` ativo no Asaas
- [ ] ACTIVE PIX→CC sem PIX pendente: próximo ciclo usa checkout CC
- [ ] ACTIVE PIX→CC com PIX pendente: warning retornado + CC usado no ciclo seguinte ao pendente
- [ ] `PixRenewalService` não cria PIX para subscriptions com `paymentMethod = CARD`
- [ ] PIX→PIX e CC→CC (sem troca real) retornam 422 ou no-op gracioso
- [ ] Testes unitários: todos os casos de transição

## Dependências
- TASK-108 (lógica de PAST_DUE resolve; TASK-109 depende da refatoração do `updatePaymentMethod`)
- TASK-065 (frontend `/billing/recover` — base para os novos CTAs de troca)

## Notas de implementação

- `SubscriptionCreatedHandler` precisa distinguir "nova subscription pós-trial/recover" de "atualização de cartão":
  usar `externalReference` da payment para identificar o contexto (ex: prefixo `CARD-UPDATE-{subscriptionId}`)
- A lógica de `PixRenewalService` já possui idempotência por `cycleNumber` — o guard PIX→CC não quebra esse contrato
- Não implementar PIX Automático aqui — isso é escopo de TASK-066

## Esforço
Alto (3-4 dias)

## Risco de não fazer
Usuários ACTIVE ficam presos no método de pagamento escolhido no onboarding.
Impossibilidade de atualizar cartão vencido em conta ativa sem passar por PAST_DUE primeiro.

## Implementação

### Novos arquivos
- `billing/application/service/PaymentMethodTransitionService.java` — três transições: CC→PIX, CC→CC (checkout), PIX→CC (com warning)
- `jobs/service/CardTransitionService.java` — cria CC checkout para subscriptions PIX→CC no ciclo seguinte ao PIX pendente
- `billing/application/service/PaymentMethodTransitionServiceTest.java` — 17 cenários
- `jobs/service/CardTransitionServiceTest.java` — 6 cenários

### Arquivos modificados
- `billing/application/dto/BillingAccountDTO.java` — adicionados `PaymentMethodTransitionResponse` e `CardUpdateResponse`
- `billing/infrastructure/persistence/BillingSubscriptionRepository.java` — adicionado `findPendingCardTransitions`
- `billing/infrastructure/web/BillingController.java` — 3 novos endpoints: `POST /transition/pix`, `POST /update-card`, `POST /transition/card`
- `webhooks/asaas/strategy/impl/SubscriptionCreatedHandler.java` — detecta prefix `CARD-UPDATE-` para CC→CC card update; cancela sub antiga + vincula nova
- `jobs/PixRenewalJob.java` — após PIX renewal, chama `CardTransitionService.processCardTransitions(daysAhead)`
- `webhooks/asaas/strategy/impl/SubscriptionCreatedHandlerTest.java` — adicionados 2 cenários CC→CC card update

### Notas de implementação
- `PixRenewalService` **não precisou** de guard explícito — `findPixSubscriptionsDueForRenewal` já filtra `ba.paymentMethod = PIX`
- CC→CC idempotência preservada: o prefix `CARD-UPDATE-` distingue update de ativação normal
- CC→PIX cancela a subscription antiga no Asaas (fail-safe — ignora 404)
- PIX→CC warning: `effectiveCycle = pendingPix.cycleNumber + 1`
- `CardTransitionService` pula subscriptions com PENDING payment (PIX ainda ativo naquele ciclo)

### Resultado dos testes
- 527/527 testes backend green ✅ (+28 novos)

## Status
Em Validação
