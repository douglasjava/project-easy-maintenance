# TASK-276 — BUGFIX: trial vencido não gera cobrança/e-mail (checkout Asaas rejeitado) e invoice duplica a cada retry

## Tipo
BUGFIX

## Categoria
Backend / Billing / Jobs (trial → cobrança)

## Prioridade
🔴 Crítico — cliente em trial vencido não recebe cobrança nem e-mail de renovação (perda de receita
e de conversão trial→pago), e o job gera uma invoice `OPEN` nova a cada dia em que reprocessa o
mesmo trial sem sucesso (lixo de dados/relatório de faturamento incorreto).

## Épico
Sem épico — reportado por Douglas em 14/09/2026: cliente real (Rogério Dantas, Grupo Automec,
subscriptionId 5) com trial vencido em 13/09, duas invoices `OPEN` geradas (13/09 e 14/09) e nenhum
e-mail/checkout. Query de varredura confirmou um segundo caso idêntico no mesmo dia (Aparecida,
`cond.butantaii@gmail.com`, subscriptionId 6).

## QA obrigatório
Sim — QA manual: reprocessar os dois casos reais em ambiente com Asaas sandbox e confirmar
checkout/e-mail gerados sem erro; confirmar que reexecutar o job em dias diferentes para o mesmo
trial vencido não cria uma segunda invoice.

---

## Contexto

Investigação (sessão `claude.ai/code/session_011bBTc9wgy8JTu1cf4A2DAU`) a partir de dados colados por
Douglas: `billing_subscriptions.id=5` (payer 7, Rogério) com `status=TRIAL`, `current_period_end`
13/09/2026, sem nenhuma linha em `payments`, e duas `invoices` (`id=7`, período 13/09→12/10, e `id=8`,
período 14/09→13/10 — um dia deslocado).

### Causa raiz nº 1 — checkout Asaas rejeitado (bloqueia e-mail e cobrança)

Log de produção (`DailyTrialJob`, 14/09 01:15) confirmou a falha real:

```
Asaas API error: status=400 BAD_REQUEST body={"errors":[{"code":"invalid_object","description":"O campo value deve ser informado."}]}
Failed to create Asaas checkout for payer 7
Failed to create Asaas checkout for payer 10
```

Mesma causa raiz já corrigida pela **TASK-215** (30/08/2026) em `PaymentMethodTransitionService` e
`BillingRecoveryService`, mas **nunca portada** para `TrialExpirationService.mapToAsaasCheckoutRequest`
— criado depois (TASK-236/244, 08-09/09/2026), reaproveitando o padrão de checkout itemizado por
cópia, sem o filtro. Todo item `sourceType=ORGANIZATION` tem `amountCents=0` por design (EPIC-014,
plano único por conta — `BillingSubscriptionService.addItem:374-380`); mandar esse item pro array
`items` do checkout Asaas quebra o request inteiro. Como `createProviderSubscriptionAndPayment` falha
antes de `paymentRepository.save()`, nenhum `Payment` é criado e `sendTrialExpirationEmail` nunca é
chamado — por isso não teve e-mail `TRIAL_EXPIRING` nem cobrança para nenhum dos dois usuários.

### Causa raiz nº 2 — período da invoice não é estável entre reexecuções (duplica invoice)

`resolveDueDate(subscription)` (linha 137-144, inalterada desde a TASK-236) cai para `LocalDate.now()`
sempre que `currentPeriodEnd` já passou — que é o caso normal deste job. O valor devolvido era usado
tanto como `periodStart`/`periodEnd` da invoice (chave de dedup de
`InvoiceService.processPayerInvoice`) quanto como vencimento cobrado/exibido. Como a guarda do
TASK-244 (`paymentRepository.existsByBillingSubscriptionId`) só bloqueia depois que um `Payment` é
criado com sucesso, e a causa raiz nº 1 impedia exatamente isso, cada execução diária do job (13/09 e
14/09) recalculava `LocalDate.now()` — um dia diferente — e o dedup por período nunca reconhecia a
invoice já existente: gerou `Invoice #7` (período correto, 13/09→12/10) e depois `Invoice #8`
(período deslocado, 14/09→13/10).

## Escopo

`jobs/service/TrialExpirationService.java`:

1. `mapToAsaasCheckoutRequest`: filtrar `invoiceItem.getAmountCents() != null && amountCents > 0`
   antes de mapear os itens da invoice pro array `CheckoutItem` do checkout — idêntico ao fix da
   TASK-215.
2. `processTrialSubscription`: desacoplar o período da invoice (agora `resolvePeriodStart`, ancorado
   sempre em `subscription.getCurrentPeriodEnd()`, nunca em "hoje") do vencimento efetivamente
   cobrado/exibido ao cliente (`resolveDueDate`, comportamento inalterado — continua podendo virar
   "hoje" quando o trial já venceu).

**Fora de escopo (registrado, não corrigido agora):**
- `AbstractSubscriptionChangePlanService.createProrataCheckout` tem o mesmo gap do item 1 (sem o
  filtro de item zerado) — não é o caminho do incidente atual (upgrade de plano, não trial), fica
  como follow-up.
- `PixRenewalService.resolveDueDate` tem o mesmo padrão da causa raiz nº 2 (período e vencimento
  vêm da mesma variável) — latente, ainda não observado em produção porque falhas consecutivas de
  renovação PIX pro mesmo ciclo são raras; vale um follow-up se acontecer.

## Critérios de Aceite

- [x] Checkout Asaas de trial com item `ORGANIZATION` (`amountCents=0`) exclui esse item do array
      enviado — teste novo reproduz o caso real (payer 7/10), falha sem o fix, passa com ele
- [x] `currentPeriodEnd` no passado: período passado a `InvoiceService.generateInvoiceForPayer` fica
      ancorado nesse valor, não em `LocalDate.now()` — teste novo prova que o período independe do
      dia em que o job roda, enquanto o vencimento cobrado/exibido continua podendo virar "hoje"
- [x] Testes existentes da TASK-236/244 (`whenCurrentPeriodEndIsInThePast_thenDueDateFallsBackToToday`,
      guardas de idempotência) continuam passando sem alteração de comportamento
- [x] `mvn clean test` sem regressão

## Dependências
TASK-215 (fix original do item zerado, replicado aqui) e TASK-244 (guarda de idempotência por
`Payment`, cujo efeito esta task restaura ao corrigir o motivo real de o `Payment` nunca ser criado).

## Riscos
Baixo — mudança isolada em `TrialExpirationService`; não toca `PixRenewalService`,
`SubscriptionAccessService` nem fluxo de assinatura paga. `resolveDueDate` (vencimento
cobrado/exibido) permanece com o mesmo comportamento já testado; só o período da invoice muda de
fonte.

## Esforço
Pequeno (~1-2h: dois fixes cirúrgicos + testes de regressão).

## Implementação

### Arquivos modificados

| Arquivo | Operação |
|---|---|
| `jobs/service/TrialExpirationService.java` | `mapToAsaasCheckoutRequest`: filtro de itens `amountCents > 0` antes do array `CheckoutItem` (TASK-215 portada). `processTrialSubscription`: novo `resolvePeriodStart(subscription)` (ancorado em `currentPeriodEnd`, nunca "hoje") usado para `periodStart`/`periodEnd` da invoice; `resolveDueDate` continua existindo, mas passa a alimentar só o vencimento cobrado/exibido (`dueDate`), não mais o período. |
| `test/.../TrialExpirationServiceTest.java` | 2 testes novos: `whenInvoiceHasZeroValueOrganizationItem_thenCheckoutExcludesItFromAsaasRequest` e `whenCurrentPeriodEndIsInThePast_thenInvoicePeriodStaysAnchoredRegardlessOfToday`. |

### Verificação
- Testes novos rodados **sem** o fix (via `git stash` do arquivo de produção): os 2 falham,
  reproduzindo exatamente o incidente (`expected: <1> but was: <2>` no array de itens do checkout;
  `expected: <2026-09-12> but was: <2026-09-14>` no período da invoice).
- Com o fix: `mvn clean test` → **992/992, 0 falhas** (`TrialExpirationServiceTest` 11/11), sem
  regressão nos testes já existentes da TASK-236/244.

Branch `bugfix/TASK-276-trial-checkout-zero-value-and-period-drift` (a partir de `staging`).

### Remediação manual (dados de produção, fora do código)
- Cancelar `invoices.id=8` (duplicada; `invoices.id=7` já tem o período correto e deve ser mantida).
- Após o deploy, disparar `GET /run-jobs/execute-trial-expiration` (ou aguardar o próximo cron
  01:15) reprocessa as duas assinaturas (5 e 6) normalmente — a guarda de `Payment` inexistente
  ainda deixa passar, e agora o checkout não deve mais ser rejeitado.

## Status
🟡 Implementado e testado localmente (`mvn test` 992/992). Aguardando confirmação de Douglas para
commit/push/PR contra `staging`, e aguardando ele rodar a limpeza manual (`invoices.id=8`) antes do
reprocessamento.
