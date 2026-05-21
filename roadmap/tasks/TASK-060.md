# TASK-060 — Webhook PAYMENT_RECEIVED do PIX detached avança o ciclo da subscription

## Tipo
BACKEND

## Categoria
Backend / Billing / Webhook

## Prioridade
🔴 Crítico

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Com o PIX recorrente passando a ser uma sequência de cobranças DETACHED (TASK-058/059), 
o webhook `PAYMENT_RECEIVED` de uma cobrança DETACHED **não pertence mais a uma subscription do Asaas**. 
O handler atual provavelmente espera o vínculo `subscription` no payload — para DETACHED ele não existe.

O backend precisa identificar a subscription **internamente** via `asaasPaymentId → Payment → billingSubscriptionId` e, 
ao receber a confirmação, avançar `currentPeriodStart` e `currentPeriodEnd` da subscription para o próximo ciclo.

## Solução

Estender `PaymentReceivedHandler` (e correlatos) para:

1. Se o payment vinculado à subscription tem `paymentMethod=PIX` e `subscription.asaasSubscriptionId IS NULL`, tratar como ciclo manual.
2. Avançar `currentPeriodStart = previousPeriodEnd` e `currentPeriodEnd = currentPeriodStart + 1 month`.
3. Garantir transição de status: `PAST_DUE → ACTIVE` quando aplicável.
4. Disparar evento de domínio (`SubscriptionCycleAdvanced`) para projeções/notificações.
5. Idempotência: se `Payment.status` já é `RECEIVED`, no-op.

## Escopo

- Modificar `PaymentReceivedHandler.handle()`.
- Função auxiliar `BillingSubscriptionService.advanceCycle(subscription, payment)`.
- Garantir que, se o evento de PAYMENT_OVERDUE para o mesmo ciclo chegou antes, o RECEIVED corretamente reverte para ACTIVE.
- Não tocar no fluxo de PAYMENT_RECEIVED para cartão (subscription do Asaas — comportamento existente).

## Critérios de Aceite

- [x] PAYMENT_RECEIVED com `billingType=PIX` + sem `asaasSubscriptionId` avança o ciclo da subscription local
- [x] Idempotente: receber o mesmo webhook duas vezes não avança duas vezes
- [x] Subscription em `PAST_DUE` volta para `ACTIVE` após pagamento
- [x] Logs auditáveis com `oldPeriodEnd`, `newPeriodEnd`, `cycleNumber`
- [x] Testes: happy path, evento duplicado, evento fora de ordem (RECEIVED chega depois de OVERDUE), evento para subscription cancelada (não avança)

## Dependências
- TASK-058 e TASK-059 (modelo de ciclos manuais precisa estar em produção)

## Esforço
Pequeno-Médio (1 dia)

## Risco de não fazer
Pagamento entra no Asaas mas a subscription não avança internamente → usuário paga e continua bloqueado.

## Status
Em Validação

## Implementação (16/05/2026)

- `PaymentReceivedHandler` (novo `@Component` em `webhooks/asaas/strategy/impl/`) — handler para evento `"PAYMENT_RECEIVED"`, estendendo `AbstractAsaasWebhookStrategy`.
  - `resolvePayment`: busca por `externalReference` primeiro, depois por `externalPaymentId` (fallback).
  - Guarda `PaymentGatewayEvent` antes de qualquer decisão (auditoria sempre).
  - Idempotência: se `payment.status == RECEIVED || PAID` → no-op.
  - Marca `status=RECEIVED`, `paidAt` (usa `confirmedDate` com fallback para `paymentDate`), `gatewayStatus`, `rawPayloadJson`.
  - Persiste payment e marca invoice como `PAID`.
  - `shouldAdvanceCycle`: `methodType == PIX && subscription.externalSubscriptionId == null` → delega para `BillingSubscriptionService.advanceCycle`.
  - Cartão (`CREDIT_CARD`) ou PIX com `externalSubscriptionId` não-nulo: ciclo gerenciado pelo Asaas, não avança localmente.
- `BillingSubscriptionService.advanceCycle(BillingSubscription, Payment)` — novo método `@Transactional`:
  - Guard: `status == CANCELED` → no-op com log.
  - `newPeriodStart = oldPeriodEnd` se futuro, senão `now` (out-of-order recovery).
  - `newPeriodEnd = newPeriodStart + 1 month` (MONTHLY) ou `+ 1 year` (YEARLY).
  - Seta `status = ACTIVE`, salva subscription.
  - Log estruturado: `subscriptionId`, `cycleNumber`, `paymentId`, `previousStatus`, `oldPeriodEnd`, `newPeriodEnd`.

## Testes

- `PaymentReceivedHandlerTest` (10 cenários, todos verdes):
  - `getEventType_isPaymentReceived` — garante chave de roteamento correta.
  - `handle_happyPath_pixDetached_advancesCycleAndMarksPaid` — PIX detached: payment=RECEIVED, invoice=PAID, `advanceCycle` chamado.
  - `handle_duplicateEvent_paymentAlreadyReceived_noOp` — idempotência status RECEIVED.
  - `handle_duplicateEvent_paymentAlreadyPaid_noOp` — idempotência status PAID.
  - `handle_outOfOrderReceivedAfterOverdue_advancesCycleAndActivates` — OVERDUE → RECEIVED avança ciclo.
  - `handle_canceledSubscription_marksPaymentReceivedButDoesNotAdvanceLocally` — CANCELED: payment salvo, delega `advanceCycle` (guard interno no service).
  - `handle_creditCardSubscription_doesNotAdvanceCycleViaThisHandler` — CC + externalSubscriptionId: `advanceCycle` não chamado.
  - `handle_pixWithExternalSubscriptionId_doesNotAdvanceLocally` — PIX com externalSubscriptionId: não avança localmente.
  - `handle_paymentNotFound_persistsGatewayEventAndReturns` — referência desconhecida: apenas gateway event salvo.
  - `handle_nullPaymentObject_persistsGatewayEventAndReturns` — payload nulo: apenas gateway event salvo.
- Regressão: `PaymentCreatedHandlerPixTest` (9) + `PaymentOverdueHandlerPixTest` (7) + `TrialExpirationServiceTest` (4) + `BillingDashboardServicePendingPaymentTest` (4) + `PixRenewalServiceTest` (8) → 32/32 verdes.

## Observações para validação humana

- Evento de domínio `SubscriptionCycleAdvanced` (item 4 da Solução) **não implementado** nesta iteração — sem consumidores ativos. Pode ser adicionado em tarefa dedicada quando notificações pós-ciclo forem necessárias.
- O discriminador PIX-manual (`externalSubscriptionId == null`) é consistente com o identificador usado em `PixRenewalService` (TASK-059).
- A reconciliação noturna (TASK-063) cobrirá o edge case de "Asaas confirmou mas DB save falhou".
