# TASK-217 — BUGFIX: Webhooks do Asaas perdem o pagamento quando chegam fora de ordem

## Tipo
BUGFIX

## Categoria
Backend / Webhooks Asaas

## Prioridade
🔴 Alto — afeta consistência de fatura (`invoices.status`) e vínculo de assinatura recorrente
(`billing_subscriptions.external_subscription_id`) em qualquer transição PIX→CC, CC→CC ou
recuperação de inadimplência via checkout.

## Épico
Sem épico — achado ao investigar um caso real em PRD (subscriptionId=2, 31/08/2026): checkout pago
de verdade, mas `invoices.status` ficou preso em `OPEN` e `billing_subscriptions.external_subscription_id`
ficou vazio. Dado de produção já corrigido manualmente (ver Contexto); esta task é a correção da
causa raiz no código.

## QA obrigatório
Sim — QA manual: repetir uma transição PIX→CC ou CC→CC completa em ambiente de teste e confirmar que
`invoices.status = PAID` e `billing_subscriptions.external_subscription_id`/`next_due_date` são
preenchidos corretamente ao final, independente da ordem de chegada dos webhooks.

---

## Contexto

Douglas migrou a assinatura (subscriptionId=2) de PIX pra Cartão de Crédito. O checkout foi criado e
pago normalmente (confirmado no painel do Asaas). Webhooks recebidos, em ordem real de chegada
(31/08/2026, ~12:54h):

1. `PAYMENT_CREATED` (12:54:51) — `PaymentCreatedHandler` acha o `Payment` (pelo checkout) e
   sobrescreve `payments.external_payment_id` do id do checkout (`89690738-...`) pro id real da
   cobrança (`pay_ub6qpsk6hmvp2u4n`).
2. `CHECKOUT_PAID` (12:54:56) — `CheckoutPaidHandler` busca o `Payment` via
   `findByExternalPaymentId(event.checkout().id())`, ou seja, procura pelo id do checkout. A coluna
   já não tem mais esse valor (foi trocada 5s antes) → não encontra → `invoice.status` nunca vira
   `PAID`.
3. `SUBSCRIPTION_CREATED` (12:54:56) — `SubscriptionCreatedHandler` faz a mesma busca frágil
   (`findByExternalPaymentId(asaasSub.checkoutSession())`) → também não encontra → `subscription.activate(...)`
   nunca roda → `external_subscription_id`/`next_due_date` ficam vazios. Esse handler não loga erro
   nenhum quando não encontra (diferença do `CheckoutPaidHandler`), por isso o bug ficou invisível
   até Douglas notar o campo vazio numa query manual.

Dado de produção já corrigido manualmente via `UPDATE` direto (validado em transação antes do
commit): `invoices.id=2` → `PAID`; `billing_subscriptions.id=2` → `external_subscription_id =
'sub_691xr4oh1yugsv5u'`, `next_due_date = '2026-09-30'` (valores reais extraídos do payload salvo em
`webhook_event`).

## Causa raiz

`payments.external_payment_id` é usada como chave de busca por handlers que chegam **depois** do
`PaymentCreatedHandler`, mas esse é o handler que sobrescreve a coluna — do id do checkout pro id da
cobrança. Quem procura pelo id do checkout depois disso não acha mais nada. Levantamento de todos os
handlers que fazem `findByExternalPaymentId`:

| Handler | Busca por | Correto hoje? |
|---|---|---|
| `PaymentCreatedHandler` | `externalReference` → `checkoutSession` → `id` (cadeia com fallback) | ✅ sim |
| `PaymentReceivedHandler` | id da cobrança | ✅ sim (mesmo espaço de id que `external_payment_id` tem depois do `PAYMENT_CREATED`) |
| `PaymentRefusedHandler` | id da cobrança | ✅ sim |
| `PaymentOverdueHandler` | id da cobrança | ✅ sim |
| `CheckoutPaidHandler` | id do **checkout** | ❌ frágil — mesmo bug desta task |
| `CheckoutExpiredHandler` | id do **checkout** | ❌ frágil — mesmo bug, ainda não visto quebrar em PRD |
| `SubscriptionCreatedHandler` | id do **checkout** (via `checkoutSession`) | ❌ frágil — mesmo bug, e sem log de erro |

O id do checkout nasce em só 2 pontos do código, onde um `Payment` é criado a partir de uma resposta
de checkout do Asaas: `PaymentMethodTransitionService.initiateCardUpdate` (PIX→CC e CC→CC) e
`BillingRecoveryService.recoverWithCheckout` (recuperação de inadimplência via checkout).

## Escopo (proposto, a confirmar no `/execute-task`)

### Backend
- Migration `V104`: nova coluna `payments.checkout_session_id VARCHAR(120) NULL` (sem backfill —
  pagamentos históricos ficam `NULL`, resolvidos pelo fallback abaixo).
- `Payment.java`: novo campo `checkoutSessionId`.
- `PaymentMethodTransitionService.initiateCardUpdate` e `BillingRecoveryService.recoverWithCheckout`:
  preencher `checkoutSessionId(resp.id())` / `checkoutSessionId(checkoutResp.id())` ao criar o
  `Payment`, além do `externalPaymentId` que já é setado hoje (comportamento desse campo não muda).
- `PaymentRepository`: novo `findByCheckoutSessionId(String checkoutSessionId)`.
- `CheckoutPaidHandler`, `CheckoutExpiredHandler`, `SubscriptionCreatedHandler`: trocar a busca por
  cadeia com fallback — `findByCheckoutSessionId(id)`, se vazio cai pra `findByExternalPaymentId(id)`
  (compatibilidade com pagamentos criados antes da migration).
- `SubscriptionCreatedHandler`: adicionar log de erro quando o pagamento não é encontrado (mesmo
  padrão do `CheckoutPaidHandler`), pra não ficar mais silencioso.
- Nenhuma mudança em `PaymentCreatedHandler`, `PaymentReceivedHandler`, `PaymentRefusedHandler`,
  `PaymentOverdueHandler` — já buscam pelo id correto.

## Critérios de Aceite

- [ ] `checkout_session_id` preenchido em todo `Payment` criado a partir de um checkout Asaas, e
      nunca sobrescrito depois
- [ ] `CheckoutPaidHandler`, `CheckoutExpiredHandler`, `SubscriptionCreatedHandler` encontram o
      `Payment` corretamente mesmo quando `PAYMENT_CREATED` chega antes e já sobrescreveu
      `external_payment_id`
- [ ] Fallback pra `external_payment_id` preserva o comportamento pra pagamentos criados antes da
      migration (sem `checkout_session_id` preenchido)
- [ ] `SubscriptionCreatedHandler` loga erro claro quando não encontra o pagamento
- [ ] Teste reproduzindo a race condition real (ordem de chegada `PAYMENT_CREATED` antes de
      `CHECKOUT_PAID`/`SUBSCRIPTION_CREATED`), confirmado falhando sem o fix antes de reaplicar
- [ ] `mvn clean test` sem regressão

## Dependências
Nenhuma. Independente das tasks 209-216 (mesma área de código, causa raiz diferente).

## Riscos
Baixo — coluna nova nullable, sem migração de dado obrigatória, sem mudar comportamento dos handlers
que já funcionam. Risco principal é esquecer algum outro ponto de criação de `Payment` via checkout
no futuro (mitigado por só existir esses 2 pontos hoje, mapeados acima).

## Esforço
Baixo-Médio

## Status
✅ Implementada, PR aberta contra `staging`:
[api#65](https://github.com/douglasjava/easy-maintenance-api/pull/65). Branch
`bugfix/TASK-217-webhook-out-of-order-checkout-lookup`. Migration `V104` adiciona
`payments.checkout_session_id`; `CheckoutPaidHandler`, `CheckoutExpiredHandler` e
`SubscriptionCreatedHandler` passam a buscar por ela (com fallback pro `external_payment_id`) via
novo helper `AbstractAsaasWebhookStrategy.findPaymentByCheckoutId`. `SubscriptionCreatedHandler`
ganhou log de erro quando não encontra o pagamento.

**Correção pós-revisão (mesma PR, 2º commit)**: o desenho inicial só cobria
`PaymentMethodTransitionService.initiateCardUpdate` (transição manual) e
`BillingRecoveryService.recoverWithCheckout` (recuperação de inadimplência). Ao ser questionado se o
fluxo normal (entrar em CC e continuar, ou PIX e continuar) tinha algum impacto, achamos 2 pontos que
também criam `Payment` a partir de checkout e ficaram de fora: `TrialExpirationService` (primeira
cobrança real após o trial, contas não-PIX) e `CardTransitionService` (job automático de transição
PIX→CC por ciclo). Comparando o `external_reference` do incidente real de produção
(`CARD-UPDATE-2-CYCLE-...`) com o padrão de cada serviço, o `-CYCLE-` só existe em
`CardTransitionService` — **esse job automático foi o que causou o bug real, não o
`initiateCardUpdate` corrigido no 1º commit**. Ambos os pontos corrigidos, com testes provando
`checkoutSessionId` preenchido nos fluxos de checkout e `null` no fluxo PIX puro (onde não se
aplica). 7 testes novos/atualizados no total. `mvn clean test`: 868/868, 0 falhas. Falta QA manual em
staging pós-deploy.
