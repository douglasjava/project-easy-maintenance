# TASK-059 — Subscription PIX recorrente "manual": ciclo gerenciado internamente

## Tipo
BACKEND

## Categoria
Backend / Billing / Job Agendado

## Prioridade
🔴 Crítico

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Como o Asaas não suporta subscriptions com `billingType=PIX`, a recorrência mensal precisa ser orquestrada por nós. 
Hoje não existe um job interno que, dado um ciclo encerrado, emita a próxima cobrança DETACHED PIX.

## Solução

Criar um job agendado `PixRenewalJob` (com ShedLock) que:

1. Roda diariamente.
2. Consulta `billing_subscription` com `paymentMethod=PIX` e `status=ACTIVE` cujo `currentPeriodEnd` esteja a até N dias do vencimento (default: 5 dias antes).
3. Para cada subscription elegível, verifica se já existe um `Payment` PENDING/RECEIVED para o próximo ciclo (idempotência por `(subscriptionId, cycleNumber)`).
4. Se não existir, cria uma cobrança DETACHED PIX no Asaas com `dueDate = currentPeriodEnd`.
5. Dispara e-mail de aviso ao usuário (reaproveitar template existente de TASK-047).

## Escopo

- Nova entidade ou campo: `Payment.cycleNumber` (inteiro incremental por subscription) para garantir idempotência.
- Migration `V66__payment_cycle_number.sql` (ou número apropriado): adiciona `cycle_number INT NULL` em `payments` + índice único `(billing_subscription_id, cycle_number)`.
- Backfill: para pagamentos existentes, derivar `cycle_number` a partir de `created_at` vs `current_period_start`.
- Novo job `PixRenewalJob` em `src/main/java/.../billing/scheduling/`.
- ShedLock configurado para evitar execução duplicada em múltiplas instâncias.
- E-mail de "nova cobrança PIX disponível" — reaproveitar template e fila assíncrona.

## Critérios de Aceite

- [x] Coluna `cycle_number` criada com índice único por subscription
- [x] Job roda diariamente sob ShedLock
- [x] Não cria duas cobranças para o mesmo `cycleNumber` mesmo em execuções paralelas
- [x] E-mail de notificação é enviado uma única vez por ciclo
- [x] Logs estruturados com `subscriptionId`, `cycleNumber`, `asaasPaymentId`
- [x] Testes: cenário sem ciclo pendente (no-op), ciclo gerado, dupla execução não duplica, falha do Asaas → retry no próximo dia

## Dependências
- TASK-058 (mudança do fluxo de expiração de trial precisa estar consistente com o esquema de `cycleNumber`)

## Esforço
Médio (1–2 dias)

## Risco de não fazer
Sem este job, usuários PIX pagam o primeiro mês e nunca mais recebem nova cobrança → churn 100% no segundo mês.

## Status
Em Validação

## Implementação (16/05/2026)

- Migration `V66__payment_cycle_number.sql` — adiciona `cycle_number INT NULL` em `payments`, backfill via `ROW_NUMBER() OVER (PARTITION BY billing_subscription_id ORDER BY created_at, id)` e índice único `uk_payments_subscription_cycle` em `(billing_subscription_id, cycle_number)`.
- `Payment.cycleNumber` adicionado (Integer, nullable).
- `PaymentRepository.findByBillingSubscriptionIdAndCycleNumber` + `findMaxCycleNumberByBillingSubscriptionId` para idempotência por ciclo.
- `BillingSubscriptionRepository.findPixSubscriptionsDueForRenewal(Instant)` — query JPQL filtrando `status=ACTIVE`, `billingAccount.paymentMethod=PIX`, `currentPeriodEnd <= upperBound`.
- `PixRenewalService` (em `jobs/service/`) com:
  - Loop externo não-transacional + iteração por subscription, com try/catch para isolar falhas.
  - `@Transactional` por subscription via self-injection `@Lazy` (uma falha não derruba as demais).
  - Idempotência: pre-check `findByBillingSubscriptionIdAndCycleNumber(subId, nextCycle)`; `externalReference = "BILLING-{subId}-CYCLE-{n}"` evita duplicidade no lado Asaas.
  - Geração de invoice via `InvoiceService.generateInvoiceForPayer`.
  - Cobrança DETACHED PIX (`AsaasDTO.BillingType.PIX`, sem subscription) via `AsaasClient.createPayment`.
  - E-mail reaproveitando `EmailTemplateHelper.generateSubscriptionExpirationHtml` (template de TASK-047), enviado via `BillingNotificationService.sendPixRenewalEmail` → fila/retry de `CriticalEmailDispatchService`.
- `PixRenewalJob` (em `jobs/`) com `@Scheduled(cron="${billing.pix.renewal.cron:0 30 1 * * *}")` e `@SchedulerLock(name="PixRenewalJob", lockAtMostFor=PT30M, lockAtLeastFor=PT15M)`. Janela de antecedência configurável via `billing.pix.renewal.days-ahead` (default 5).
- Logs estruturados: prefixo `[PixRenewal]` / `[PixRenewalJob]` com `subscriptionId`, `cycleNumber`, `asaasPaymentId`, `externalReference`.

## Testes
- `PixRenewalServiceTest` (8 cenários, todos verdes):
  - Sem subscriptions elegíveis → no-op
  - Várias subscriptions elegíveis → delega para `self.renewSubscription` por ID
  - Falha em uma subscription não interrompe as demais
  - Happy path: cria DETACHED PIX, persiste `Payment` com `cycleNumber`, dispara e-mail
  - Ciclo já existe → pula sem chamar Asaas nem enviar e-mail
  - Asaas falha → não persiste Payment, não envia e-mail (retry no próximo dia)
  - Invoice não pode ser gerada → pula Asaas
  - `cycleNumber` é incrementado a partir do `MAX` atual
- Regressão: `TrialExpirationServiceTest` (4) + `PaymentCreatedHandlerPixTest` (9) + `PaymentOverdueHandlerPixTest` (7) + `BillingDashboardServicePendingPaymentTest` (4) → 24/24 verdes.
- `mvn compile` limpo.

## Observações para validação humana
- Configuração de cron (`billing.pix.renewal.cron`) e janela (`billing.pix.renewal.days-ahead`) podem ser ajustadas por ambiente sem novo deploy.
- A reconciliação noturna (TASK-063) cobrirá o cenário raro de "Asaas criou cobrança mas DB save falhou" (orfão).
- O webhook `PAYMENT_RECEIVED` de DETACHED PIX recorrente é responsabilidade da TASK-060 (avançar ciclo).
