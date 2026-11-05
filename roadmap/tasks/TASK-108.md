# TASK-108 — Full-Stack: Troca de método de pagamento em PAST_DUE

## Tipo
FULL_STACK

## Categoria
Billing / Recuperação de Pagamento / Asaas Integration

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Hoje o endpoint `PATCH /me/billing/payment-method` aceita troca em PAST_DUE mas **não tem efeito real**:
salva o campo `paymentMethod` na `BillingAccount` e para por aí. Nenhum job cria nova cobrança com o
novo método. O usuário troca o método, continua em PAST_DUE para sempre, sem saber que nada aconteceu.

## Contexto técnico levantado

- `updatePaymentMethod` em `BillingAccountService` é um simples `account.setPaymentMethod(method) + save`.
- `BillingReconciliationService` só sincroniza status de pagamentos existentes — não cria novos.
- `PixRenewalService` só processa subscriptions ACTIVE PIX.
- Não existe endpoint de "pagar agora" / "retry" no `BillingController`.
- `POST /payments` Asaas não aceita dados de cartão na requisição — CC sempre passa por checkout.
- `CheckoutPaidHandler` + `SubscriptionCreatedHandler` já existem e tratam o fluxo CC completo.

## Solução

### Caso A — PAST_DUE + PIX

Criar endpoint `POST /me/billing/recover/pix` que:

1. Valida que subscription está em `PAST_DUE`
2. Verifica se já existe `Payment PENDING` para a subscription (evitar duplicata)
3. Gera invoice para o período devido (reusa `InvoiceService.generateInvoiceForPayer`)
4. Cria cobrança PIX detached no Asaas via `POST /payments`:
   ```json
   {
     "customer": "{externalCustomerId}",
     "billingType": "PIX",
     "value": {valorDevido},
     "dueDate": "{hoje}",
     "externalReference": "RECOVERY-{subscriptionId}-{timestamp}"
   }
   ```
5. Salva `Payment` com status `PENDING` + `externalReference` único
6. Retorna `{ pixQrCode, pixQrCodeBase64, pixExpiresAt, paymentLink }`
7. Webhook `PAYMENT_RECEIVED` → handler existente avança ciclo → subscription volta a `ACTIVE`

### Caso B — PAST_DUE + CC

Criar endpoint `POST /me/billing/recover/checkout` que:

1. Valida que subscription está em `PAST_DUE`
2. Cancela subscription antiga no Asaas se ainda existir (`DELETE /subscriptions/{externalSubscriptionId}`)
   - Se não existir, ignora (pode já ter sido cancelada via reconciliação)
3. Gera invoice para o período devido
4. Cria novo checkout Asaas com recorrência (mesmo fluxo do `TrialExpirationService`):
   - `billingType: CREDIT_CARD`
   - `ChargeTypes.RECURRENT`
   - Período de vencimento = hoje
5. Salva `Payment` com status `PENDING` + `externalPaymentId` do checkout
6. Retorna `{ checkoutLink }`
7. Webhook `CHECKOUT_PAID` → `PENDING_ACTIVATION` (handler existente)
8. Webhook `SUBSCRIPTION_CREATED` → `ACTIVE` + novo `externalSubscriptionId` (handler existente)

### Mudança no `updatePaymentMethod`

Remover PAST_DUE da validação do `updatePaymentMethod` — a troca de método agora
é feita implicitamente pelos novos endpoints de recover (o método é inferido pelo endpoint chamado).
Manter apenas TRIAL:

```java
if (subscription.getStatus() != SubscriptionStatus.TRIAL) {
    throw new RuleException("Método de pagamento só pode ser alterado durante o período de TRIAL.");
}
```

### Frontend

Integrar os novos endpoints na tela `/billing/recover` (TASK-065):
- CTA "Pagar agora via PIX" → chama `POST /me/billing/recover/pix` → exibe QR code
- CTA "Pagar com Cartão" → chama `POST /me/billing/recover/checkout` → redireciona para `checkoutLink`

## Arquivos impactados

### Backend
- `billing/infrastructure/web/BillingController.java` — novos endpoints `POST /recover/pix` e `POST /recover/checkout`
- `billing/application/service/BillingRecoveryService.java` — novo serviço (extraído de `BillingAccountService`)
- `billing/application/service/BillingAccountService.java` — remover PAST_DUE da validação
- `jobs/service/TrialExpirationService.java` — extrair lógica de criação de checkout para método reutilizável

### Frontend
- `app/billing/recover/page.tsx` — integrar novos endpoints (depende de TASK-065)

## Critérios de Aceite

- [ ] `POST /me/billing/recover/pix` retorna QR code válido quando subscription está PAST_DUE
- [ ] `POST /me/billing/recover/pix` retorna erro 409 se já existe Payment PENDING para a subscription
- [ ] `POST /me/billing/recover/pix` retorna erro 422 se subscription não está PAST_DUE
- [ ] Após pagamento PIX confirmado (webhook), subscription volta a `ACTIVE`
- [ ] `POST /me/billing/recover/checkout` retorna link de checkout válido quando subscription PAST_DUE
- [ ] Após checkout CC pago (webhooks), subscription volta a `ACTIVE` com novo `externalSubscriptionId`
- [ ] `PATCH /me/billing/payment-method` não aceita mais PAST_DUE (apenas TRIAL)
- [ ] Nenhum Payment duplicado criado se endpoint for chamado duas vezes
- [ ] Testes unitários: BillingRecoveryServiceTest (cenários happy path + erros)

## Dependências
- TASK-065 (frontend da tela `/billing/recover` — integração visual)

## Esforço
Médio-alto (2 dias)

## Risco de não fazer
Usuário em PAST_DUE não consegue se recuperar sem intervenção manual de suporte.
Churn direto de receita por falta de caminho de recuperação funcional.

## Implementação

### Arquivos criados
- `billing/application/service/BillingRecoveryService.java` — novo serviço com `recoverWithPix` e `recoverWithCheckout`
- `billing/application/service/BillingRecoveryServiceTest.java` — 18 cenários (happy path + erros + parametrizados)

### Arquivos modificados
- `infrastructure/saas/client/AsaasClient.java` — adicionado `getPixQrCode(paymentId)` via `GET /payments/{id}/pixQrCode`
- `billing/application/dto/BillingAccountDTO.java` — adicionados `RecoveryPixResponse` e `RecoveryCheckoutResponse`
- `billing/infrastructure/web/BillingController.java` — adicionados `POST /recover/pix` e `POST /recover/checkout`
- `billing/application/service/BillingAccountService.java` — removido `PAST_DUE` da validação do `updatePaymentMethod` (apenas `TRIAL` agora)
- `billing/application/service/BillingAccountServiceUpdatePaymentMethodTest.java` — teste `pastDue_savesNewMethod` invertido para `pastDue_throwsRuleException`; `@EnumSource` inclui `PAST_DUE`

### Resultado dos testes
- 499/499 testes backend green ✅

## Status
Em Validação
