# TASK-394 — BUGFIX: Ciclos 2+ de assinatura CARD nativa Asaas não têm `Payment`/`Invoice` local — webhook descartado, 3ª remediação manual na mesma conta

## Tipo
BUGFIX

## Categoria
Backend / Webhooks Asaas / Billing recorrente CARD

## Prioridade
🔴 Crítico — toda organização em assinatura CARTÃO nativa Asaas (`/subscriptions`) para de gerar
histórico de fatura/pagamento local a partir do 2º ciclo, de forma silenciosa (só um `WARN` no log).
Hoje só existe 1 cliente pagante em produção (subscriptionId=2, Douglas), por isso o impacto ainda
é restrito — mas é estrutural, não vai se limitar a essa conta.

## Épico
Sem épico — 3ª ocorrência do mesmo problema de fundo na mesma assinatura (subscriptionId=2).

## QA obrigatório
Sim.
- Backend: reproduzir o cenário exato do incidente (abaixo) com teste automatizado, mais regressão
  dos fluxos que `TASK-217`/`TASK-321` já cobrem (checkout CC normal, card update, PIX→CC).
- Manual: confirmar em PRD, na primeira cobrança recorrente real pós-deploy, que `Payment`+`Invoice`
  aparecem sozinhos (sem intervenção manual) e que a tela de billing do cliente mostra o ciclo novo.

---

## Contexto — histórico dessa mesma assinatura (subscriptionId=2)

Esta é a **3ª vez** que essa conta precisa de reparo manual de dados de billing, sempre no mesmo
ponto de fragilidade (match de webhook de pagamento com o registro local):

1. **[TASK-217](TASK-217.md)** (31/08/2026) — `CardTransitionService` (job de transição PIX→CC)
   criava o `Payment` do checkout, mas `CheckoutPaidHandler`/`SubscriptionCreatedHandler` buscavam
   pelo id do checkout numa coluna (`external_payment_id`) que o `PaymentCreatedHandler` já tinha
   sobrescrito antes. Corrigido com coluna dedicada `checkout_session_id` + cadeia de fallback.
   **Essa correção só vale para pagamentos nascidos de um checkout** (`CardTransitionService`,
   `PaymentMethodTransitionService.initiateCardUpdate`, `BillingRecoveryService.recoverWithCheckout`,
   `TrialExpirationService`) — em todos esses, um `Payment` é pré-criado *antes* do webhook chegar.

2. **[TASK-321](TASK-321.md)** (02/10/2026) — Bug de payload na criação/atualização da assinatura
   recorrente CARD fazia a assinatura se encerrar sozinha na Asaas após o 1º ciclo; além disso,
   não existia handler para `PAYMENT_CONFIRMED` (equivalente de cartão do `PAYMENT_RECEIVED`), e a
   invoice não era sincronizada no fast-path do `PAYMENT_CREATED` quando o checkout já confirmava na
   hora. Corrigido (api#146-153, web#110/111). Remediação manual pontual da invoice 13 feita nesse
   momento (mesma invoice que serviu de modelo pro reparo desta vez).

3. **Este incidente (02/11/2026)** — O pagamento `pay_eetfmjwv3qrx6q4o` (evento `PAYMENT_CONFIRMED`,
   `evt_15e444ff9b9ab9ec29294aa1abe68025&1599617817`) é a cobrança automática do **2º ciclo da
   assinatura nativa Asaas atual** (`sub_yd7q42kjnia7o0is`, criada em 02/10 pelo fluxo de card-update
   da TASK-321). Diferente dos 3 pagamentos anteriores dessa conta, **este não nasceu de nenhum
   checkout do nosso lado** — foi gerado e cobrado 100% pela recorrência nativa da própria Asaas, sem
   `externalReference`, sem `checkoutSession`, sem nenhum `Payment` local pré-existente pra casar:

   ```
   WARN PaymentReceivedHandler - PAYMENT_RECEIVED: Payment not found for external id
        pay_eetfmjwv3qrx6q4o or reference null
   ```

   `PaymentConfirmedHandler` (que reaproveita a lógica de `PaymentReceivedHandler`, só muda a chave
   de evento) tentou achar o `Payment` por `externalReference` (nulo) e depois por
   `externalPaymentId` (nunca existiu) — e nenhum dos dois achou, porque **não existe mecanismo
   algum no código que cria o `Payment`/`Invoice` de um ciclo gerado puramente pela recorrência
   nativa da Asaas**. Diferente do PIX, que tem `PixRenewalService` criando o `Payment` do próximo
   ciclo *antes* do vencimento, não existe equivalente para CARD.

   Reparado manualmente via SQL direto em produção (nova `invoice`+`invoice_items`+`payment`,
   espelhando a invoice 13 como modelo, mais `UPDATE` em `billing_subscriptions.next_due_date`).
   Durante esse reparo, outro achado: o campo `nextDueDate` do objeto `subscription` na Asaas (usado
   no webhook `SUBSCRIPTION_UPDATED`, que hoje **não tem handler registrado**) fica **um ciclo
   adiantado** em relação à próxima cobrança real — ele reflete o próximo pagamento que a Asaas
   ainda vai *gerar*, não o próximo que vai *cobrar* (o de dezembro já estava gerado e visível no
   extrato de recorrentes da Asaas quando o campo already apontava pra janeiro). Confirmado olhando
   o extrato "Recorrentes (Assinaturas)" do painel Asaas.

### Padrão comum aos 3 incidentes
Em todos os casos, quando um webhook de pagamento chega e o `Payment` local não é encontrado pelos
critérios de busca, **o evento é silenciosamente descartado** (log `WARN`, `webhook_event` marcado
`PROCESSED` normalmente, nada mais acontece). As correções anteriores resolveram casos onde o
`Payment` existia mas a busca falhava por motivo pontual (coluna sobrescrita, handler faltando). Elas
nunca cobriram o caso em que **o `Payment` nunca existiu porque ninguém o criou** — que é exatamente
o que acontece em todo ciclo 2+ de uma assinatura nativa Asaas.

## Causa raiz

1. `PaymentReceivedHandler.resolvePayment()`/`PaymentCreatedHandler` só **buscam** um `Payment` já
   existente (por `externalReference` → `checkoutSessionId`/`checkoutSession` → `externalPaymentId`).
   Nenhum dos dois **cria** um `Payment`/`Invoice` quando a busca falha — mesmo tendo, no próprio
   payload (`paymentObj.subscription()`), o id da `BillingSubscription` (`externalSubscriptionId`)
   que permitiria resolver o caso.
2. `BillingSubscriptionService.advanceCycle` (que mantém `current_period_start`/`current_period_end`
   em dia) só é chamado quando `payment.getMethodType() == PIX` — para `CARD`,
   `current_period_start/end` ficam congelados desde a última vez que algo os tocou (nesta conta,
   desde 17/07/2026) e nunca mais avançam, porque a suposição original era de que a própria
   assinatura Asaas cuidaria disso — suposição que não tem nenhum código que a sustente.
3. Não existe handler para `SUBSCRIPTION_UPDATED` — o evento onde a Asaas informa o `nextDueDate`
   atualizado. Mesmo que existisse, confirmamos que esse campo **não é uma fonte confiável** para
   "próxima cobrança real" (vem um ciclo adiantado).
4. `payments.idx_payments_provider_ext (provider, external_payment_id)` é um índice comum, não um
   `UNIQUE` — não há proteção no banco contra duplicar o mesmo pagamento Asaas em dois `Payment` rows
   diferentes (relevante para o fallback de criação proposto abaixo, que precisa ser idempotente).

## Solução proposta (definitiva, não mais um patch pontual)

Mudar a postura do sistema: nenhum webhook de pagamento confirmado pode ser descartado
silenciosamente por falta de `Payment` local — se a busca normal falhar, o sistema deve ser capaz de
**provisionar** o registro local a partir dos dados do próprio evento.

### Backend
1. **`AbstractAsaasWebhookStrategy`**: novo método `resolveOrProvisionPayment(AsaasDTO.PaymentObject paymentObj)`:
   - Mantém a cadeia de busca atual (`externalReference` → `checkoutSessionId` com fallback pra
     `externalPaymentId`, já existente desde a TASK-217).
   - Se não achar **e** `paymentObj.subscription() != null`: busca `BillingSubscription` por
     `findByExternalSubscriptionId`. Se achar, com status diferente de `CANCELED`, e **não existir
     já** um `Payment` com esse `externalPaymentId` (idempotência — reentrega de webhook não deve
     duplicar):
     - Cria `Invoice` nova: `period_start` = `current_period_end` atual da subscription (ou
       `paymentObj.dueDate()` quando o período estiver vazio/zerado), `period_end` conforme
       `BillingCycle` da subscription, `due_date` seguindo o mesmo padrão já usado nas invoices
       existentes (`period_end + 5 dias`, confirmado nas invoices 1/2/13 desta conta), `status PAID`
       (o evento só chega quando já está confirmado).
     - Clona `InvoiceItem`s a partir dos `BillingSubscriptionItem`s ativos da subscription.
     - Cria `Payment`: `provider ASAAS`, `methodType` a partir do `billingType` do payload,
       `externalPaymentId`, valores (`amountCents`/`netAmountCents`/`gatewayFeeCents`) do próprio
       evento, `status RECEIVED`.
     - Loga em nível que chame atenção (ex.: `WARN` ou métrica dedicada, não só `INFO`) que esse
       fallback foi usado — é sinal de que o caminho normal (`Payment` pré-criado) não se aplicou, e
       precisa ser monitorado enquanto a base de clientes crescer.
2. **`PaymentCreatedHandler`** e **`PaymentReceivedHandler`/`PaymentConfirmedHandler`**: passam a
   usar `resolveOrProvisionPayment` no lugar da busca atual.
3. **`shouldAdvanceCycle`**: remover a exclusão de `CARD`. Qualquer pagamento que resultou do
   provisionamento de um ciclo novo (seja PIX, seja CARD) deve chamar `advanceCycle`, mantendo
   `current_period_start/current_period_end` vivos pros dois métodos de pagamento.
4. **Não** criar handler para `SUBSCRIPTION_UPDATED` copiando `nextDueDate` — decisão explícita,
   esse campo não é confiável pra "próxima cobrança real" (ver Contexto). `next_due_date` local deve
   ser atualizado a partir do `period_end` calculado no passo 1, nunca do `nextDueDate` da Asaas.
5. **Banco**: adicionar `UNIQUE` real em `payments (provider, external_payment_id)` (hoje é só
   `KEY`), para que o fallback do passo 1 tenha uma garantia de banco contra duplicação em race
   condition — mesma classe de proteção que a TASK-217 já usa pra `webhook_event`.
6. **Rede de segurança**: estender a reconciliação noturna (criada na TASK-321) para também detectar
   `billing_subscriptions` `ACTIVE` com `external_subscription_id` preenchido cujo `next_due_date`
   já passou sem nenhum `Payment` novo desde então — hoje a reconciliação só olha `Payment`s
   `PENDING`, que neste cenário nem chegam a existir.
7. **Testes**: reproduzir o cenário exato deste incidente — `PAYMENT_CONFIRMED` para uma
   `BillingSubscription` com `externalSubscriptionId` ativo, sem nenhum `Payment` casável por
   `externalReference`/`checkoutSessionId`/`externalPaymentId` — e confirmar que `Invoice`+`Payment`
   são criados, `current_period_end` avança, e reentrega do mesmo evento não duplica. Cobrir também
   os fluxos já existentes (checkout CC normal, card update, PIX→CC) sem regressão.

### Frontend
Nenhuma mudança de código esperada a princípio — a tela de billing já lê `Invoice`/`Payment` via
serviços existentes. **QA manual obrigatório**: hoje, sem esse fix, o cliente não vê o ciclo 2+ na
tela de faturas (porque a invoice nunca existe) — confirmar pós-fix que o histórico aparece completo.

## Critérios de Aceite
- [x] Teste automatizado reproduzindo o incidente real (webhook `PAYMENT_CONFIRMED`/`PAYMENT_CREATED`
      pra ciclo 2+ de assinatura CARD nativa, sem `Payment` pré-existente) — falha sem o fix, passa
      depois (`PaymentReceivedHandlerTest.handle_nativeCardRenewal_noExistingPayment_...`)
- [x] `Invoice`+`InvoiceItem`s+`Payment` criados automaticamente nesse cenário, sem intervenção manual
- [x] `current_period_start`/`current_period_end`/`next_due_date` avançam corretamente pra CARD,
      usando o período calculado localmente (nunca o `nextDueDate` da Asaas) — `shouldAdvanceCycle`
      não exclui mais CARD
- [x] Reentrega do mesmo evento (`provider_event_id` repetido, e também `external_payment_id`
      repetido por outro motivo) não duplica `Payment`/`Invoice` — teste de idempotência +
      `UNIQUE (provider, external_payment_id)` (V135) como rede de segurança contra race condition
- [x] Regressão: fluxos já cobertos por TASK-217 (checkout out-of-order) e TASK-321 (PAYMENT_CONFIRMED
      com Payment pré-existente) continuam passando
- [x] Reconciliação noturna passa a sinalizar assinatura CARD `ACTIVE` sem pagamento novo após
      `next_due_date` vencido (`BillingReconciliationService.flagStaleCardSubscriptions`)
- [ ] QA manual: tela de billing do cliente mostra o histórico de fatura completo após uma cobrança
      recorrente real pós-deploy, sem reparo manual — pendente (depende de deploy + próxima cobrança
      real da conta, 02/12/2026)
- [x] `mvn clean test` sem regressão — 1669/1669, 0 falhas

## Dependências
Nenhuma bloqueante. É sucessora direta de [TASK-217](TASK-217.md) e [TASK-321](TASK-321.md) — mesma
área de código, mesmo subscriptionId afetado nas 3 vezes.

## Riscos
Médio — toca em todos os handlers de pagamento de cartão recorrente (`PaymentCreatedHandler`,
`PaymentReceivedHandler`, `PaymentConfirmedHandler`) e no gate de `advanceCycle`, que hoje é
deliberadamente restrito a PIX. Precisa de teste de regressão cobrindo os três fluxos que as tasks
anteriores já corrigiram, pra não reabrir nenhum dos dois bugs anteriores. Mitigado por ser hoje a
única conta pagante em produção — qualquer problema remanescente ainda é tratável manualmente antes
de haver uma base maior de clientes.

## Esforço
Médio

## Status
🟣 Em Validação — implementado e mergeado em `staging` (easy-maintenance-api PR
[#176](https://github.com/douglasjava/easy-maintenance-api/pull/176), squash-merge de
`bugfix/TASK-394-card-recurring-webhook-provision`), `mvn clean test` 1669/1669 sem regressão.
Falta QA manual na primeira cobrança recorrente real pós-deploy em produção (próxima prevista:
02/12/2026) antes de fechar a task.
