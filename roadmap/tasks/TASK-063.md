# TASK-063 — Job de reconciliação noturna: Asaas vs estado local

## Tipo
BACKEND

## Categoria
Backend / Billing / Job Agendado

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Webhooks podem ser perdidos (timeout, instância derrubada, bug no handler), ficar parados em DLQ, ou chegar fora de ordem. 
Hoje não há mecanismo para detectar divergência entre o estado no Asaas e o estado local.

Cenários reais:
- Pagamento confirmado no Asaas, mas `Payment.status` local ainda `PENDING`.
- Subscription cancelada no Asaas (por chargeback, p. ex.), mas local ainda `ACTIVE`.
- Cobrança refundada no Asaas sem revogação local de acesso.

## Solução

Job noturno `BillingReconciliationJob`:

1. Para cada subscription ACTIVE/PAST_DUE criada nos últimos 90 dias, consultar Asaas:
   - CC subscriptions: `GET /subscriptions/{id}` para detectar cancelamento
   - Pagamentos PENDING com externalPaymentId: `GET /payments/{id}` para detectar recebimento
2. Comparar status do Asaas vs local; aplicar correções idempotentes.
3. Emitir relatório (log + métricas) com divergências encontradas.

## Escopo

- Novo job em `jobs/`.
- ShedLock para idempotência cluster-wide.
- Configurável: janela (default 90 dias), intervalo.
- Métrica `billing.reconciliation.divergence.count{type=payment_received|subscription_canceled}`.

## Critérios de Aceite

- [x] Job roda diariamente fora do horário de pico
- [x] Detecta e corrige: pagamento RECEIVED no Asaas mas PENDING local
- [x] Detecta e corrige: subscription cancelada no Asaas mas ACTIVE local
- [x] Não cria duplicidade (idempotência via `asaasPaymentId`)
- [x] Relatório resumido em log + métrica
- [x] Testes: divergência detectada, divergência corrigida, sem divergência (no-op)

## Dependências
- Nenhuma bloqueante.

## Esforço
Médio (1–2 dias)

## Risco de não fazer
Webhook perdido = receita perdida silenciosamente OU acesso indevido perdurando. Sem reconciliação, é invisível.

## Implementação

### Arquivos criados
- `jobs/BillingReconciliationJob.java` — `@Scheduled(cron = "${billing.reconciliation.cron:0 0 3 * * *}")`, `@SchedulerLock(lockAtMostFor = "PT1H")`, delega para `BillingReconciliationService`
- `jobs/service/BillingReconciliationService.java` — lógica de reconciliação:
  - Busca subscriptions ACTIVE/PAST_DUE criadas nos últimos `${billing.reconciliation.window-days:90}` dias
  - CC subscriptions: chama `AsaasClient.getSubscription()` → se INACTIVE, cancela localmente
  - Para cada Payment PENDING com `externalPaymentId`: chama `AsaasClient.getPayment()` → se RECEIVED/CONFIRMED, marca RECEIVED local
  - Métrica: `billing.reconciliation.divergence.count{type=subscription_canceled|payment_received}`

### Arquivos modificados
- `infrastructure/saas/client/AsaasClient.java` — adicionado `getPayment(String paymentId)`: `GET /payments/{id}`
- `billing/infrastructure/persistence/BillingSubscriptionRepository.java` — adicionado `findReconciliationCandidates(statuses, createdAfter)`
- `payment/infrastructure/persistence/PaymentRepository.java` — adicionado `findByBillingSubscriptionIdAndStatus(Long, PaymentStatus)`

### Testes criados
- `jobs/service/BillingReconciliationServiceTest.java` — 10 cenários:
  - Sem candidatos → no-op
  - CC sub INACTIVE no Asaas → cancela local + incrementa métrica
  - CC sub ACTIVE no Asaas → no-op
  - Payment PENDING, Asaas RECEIVED → marca RECEIVED + métrica
  - Payment PENDING, Asaas CONFIRMED → marca RECEIVED
  - Payment PENDING, Asaas PENDING → no-op
  - Payment sem externalPaymentId → skipped
  - Asaas lança exception em payment → loga erro, continua próximo
  - CC sub cancelada → skip do check de payments
  - PIX sub (sem externalSubscriptionId) → skip do check de subscription

### Resultado dos testes
- 348/348 testes green ✅

## Status
Em Validação
