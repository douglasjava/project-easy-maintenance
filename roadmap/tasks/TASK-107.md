# TASK-107 — BUGFIX: advanceCycle() não preenche next_due_date em assinaturas PIX

## Tipo
BACKEND (BUGFIX)

## Categoria
Bug / Billing / PIX

## Prioridade
🔴 Crítico

## Fase
3 — Produto

---

## Contexto

Toda assinatura ativada via PIX tem `next_due_date = NULL` no banco de dados.

O método `BillingSubscriptionService.advanceCycle()` — chamado pelo `PaymentReceivedHandler` quando um pagamento PIX é confirmado — seta `status=ACTIVE`, `currentPeriodStart` e `currentPeriodEnd`, mas **nunca preenche `nextDueDate`**.

O fluxo CARD preenche `nextDueDate` via `SubscriptionCreatedHandler → subscription.activate(externalId, nextDueDate)`, evento que não existe para PIX.

## Impacto

`processSubscriptionCycle()` filtra assinaturas por `nextDueDate == hoje`. Com `nextDueDate = NULL`, **nenhuma assinatura PIX é processada pelo job**, nunca. Consequências:

- Cancelamentos agendados (`cancelAtPeriodEnd=true`) nunca são executados para assinantes PIX
- Remoção de itens de organização cancelados nunca é aplicada
- Recálculo de `totalCents` nunca ocorre
- Front exibe "encerrado em breve" indefinidamente sem data

## Causa Raiz

`BillingSubscriptionService.advanceCycle()` (`linha 365`) não propaga `newPeriodEnd` para `nextDueDate`.

## Arquivos Impactados

- `billing/application/service/BillingSubscriptionService.java` — fix em `advanceCycle()`
- `billing/application/service/AdvanceCycleNextDueDateTest.java` — teste novo

## Correção de Dados (SQL)

Para assinaturas PIX já existentes no banco:
```sql
UPDATE billing_subscriptions
SET next_due_date = DATE(current_period_end)
WHERE status = 'ACTIVE'
  AND next_due_date IS NULL
  AND external_subscription_id IS NULL;
```

## Critérios de Aceitação

- [ ] `advanceCycle()` preenche `nextDueDate` com a data local de `newPeriodEnd` (UTC)
- [ ] Assinaturas MONTHLY: `nextDueDate` = 1 mês à frente
- [ ] Assinaturas YEARLY: `nextDueDate` = 1 ano à frente
- [ ] Assinatura com status CANCELED: `advanceCycle()` faz early return, `nextDueDate` não é alterado
- [ ] Testes passando (sem regressão)
