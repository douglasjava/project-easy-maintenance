# TASK-215 — BUGFIX Backend: checkout Asaas rejeitado por item ORGANIZATION de valor zero

## Tipo
BUGFIX

## Categoria
Backend / Billing (checkout Asaas, transição PIX→Cartão)

## Prioridade
🔴 Crítico

## Épico
Sem épico — bug crítico de receita, achado em produção por Douglas, 30/08/2026. Bloqueava a
assinatura de teste (subscriptionId=2) desde a TASK-209, agora com causa raiz diferente e final.

## QA obrigatório
Sim — QA manual: confirmar no próximo run do `PixRenewalJob` (01:30) que a assinatura 2 finalmente
gera o checkout/link de pagamento, sem `400 BAD_REQUEST` no log.

---

## Contexto

Depois das TASK-209/210 (idempotência de fatura + lazy loading), o job passou a achar a fatura e
tentar criar o checkout no Asaas — mas quebrava com:

```
Asaas API error: status=400 BAD_REQUEST body={"errors":[{"code":"invalid_object","description":"O campo value deve ser informado."}]}
```

## Causa raiz

Confirmado via query em produção (payer_user_id=2, período 2026-08-31/2026-09-29):

```
id=3  Assinatura Usuário - Plano: Business (2)                              amount_cents=29900
id=4  Assinatura Organização - Plano: Business (51d7648e-...)               amount_cents=0
```

`PaymentMethodTransitionService.buildCheckoutRequest` (e a cópia quase idêntica em
`BillingRecoveryService.buildCheckoutRequest`) mapeia **todos** os itens da fatura pro array
`items` do checkout, sem filtrar por valor. Desde a EPIC-014 (plano único por conta,
`BillingSubscriptionService.addItem` linha 374-380), todo item `sourceType=ORGANIZATION` tem
`valueCents=0` de propósito — é só registro de vínculo/limite por organização, não é cobrado
separadamente. `InvoiceService.processPayerInvoice` cria um `InvoiceItem` pra cada
`BillingSubscriptionItem` da assinatura sem filtrar isso, então a fatura de uma conta com mais de
uma organização sempre tem um item de R$0 junto do item real.

O total da fatura sempre esteve certo (R$0 não afeta a soma) — só o array `items` enviado ao Asaas
que carregava a linha fantasma, e o Asaas rejeita o request inteiro por causa dela.

**Fluxos afetados:** `CardTransitionService.processTransition` (o que apareceu no log),
`PaymentMethodTransitionService.initiateCardUpdate`/`transitionToCardFromPix`, e
`BillingRecoveryService.recoverWithCheckout` — todos usam checkout itemizado. `PixRenewalService` e
`BillingRecoveryService.recoverWithPix` **não são afetados** — cobram o total da fatura direto, sem
itemizar.

## Objetivo

`items` enviado ao Asaas exclui itens de valor zero — o total cobrado não muda (o item de R$0 já
não contribuía pra soma).

## Escopo

`PaymentMethodTransitionService.buildCheckoutRequest` e `BillingRecoveryService.buildCheckoutRequest`
(duplicado, mesmo fix nos dois): filtro `amountCents != null && amountCents > 0` antes de mapear
`invoice.getItems()` pro array de `CheckoutItem`.

**Fora de escopo (registrado, não corrigido agora):** as duas implementações de
`buildCheckoutRequest` são quase idênticas — poderia virar um helper compartilhado. Não mexi agora
pra manter o fix cirúrgico (um problema por vez); vale um follow-up se aparecer um terceiro lugar
com o mesmo padrão.

## Critérios de Aceite

- [x] `buildCheckoutRequest` (nos dois serviços) exclui itens de `amountCents <= 0` do array
      enviado ao Asaas
- [x] Teste novo em cada serviço reproduz o caso real de produção (item USER + item ORGANIZATION
      zerado) e comprova que só o item real vai pro checkout — falha sem o fix, passa com ele
- [x] `mvn clean test` sem regressão
- [ ] QA manual: assinatura 2 gera checkout com sucesso no próximo run do `PixRenewalJob` (01:30) —
      pendente de deploy em produção

## Dependências
Nenhuma (causa raiz diferente da TASK-209/210, mesma assinatura de teste).

## Riscos
Baixo — filtro puramente aditivo no que é enviado ao Asaas; não toca no cálculo do total da fatura
nem na lógica de criação de itens.

## Esforço
Baixo

## Status
✅ Implementado, PR aberta contra `staging`:
[api#62](https://github.com/douglasjava/easy-maintenance-api/pull/62). Branch
`bugfix/TASK-215-asaas-checkout-zero-value-item`, commit `b381b48`. Suíte completa: 861/861, 0
falhas. QA final (assinatura 2 desbloqueada) pendente do merge, deploy em produção e do próximo run
do `PixRenewalJob` (01:30).
