# TASK-288 — Fornecedor com débito do Pix Automático falho nunca é suspenso

## Tipo
BACKEND

## Categoria
Marketplace de Fornecedores / Cobrança

## Prioridade
🟠 Alto — vazamento de receita + regra de cobrança não aplicada

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## QA obrigatório
Sim — testes automatizados do ciclo de cobrança + QA com débito recusado no sandbox Asaas.

---

## Problema

Achado na revisão final da TASK-285 (24/09/2026), confirmado por grep:

- `SupplierBillingService.suspendOverdueSubscriptions` só suspende assinaturas em `PAST_DUE`
  (`GRACE_PERIOD_DAYS = 3`), mas **nenhum código grava `SupplierSubscriptionStatus.PAST_DUE`** —
  os únicos status escritos são `PENDING`, `ACTIVE` e `CANCELED`. O comentário do próprio enum
  já registra o gap ("depende de `PIX_AUTOMATIC_RECURRING_PAYMENT_INSTRUCTION_REFUSED`").
- `PaymentOverdueHandler`/`PaymentRefusedHandler` só tratam `BillingSubscription` (organizações),
  sem ramo de fornecedor.
- `chargeNextCycle` avança `currentPeriodEnd` +1 mês ao **criar** a cobrança, independente de ela
  ser paga.

Efeito: fornecedor cujo débito falha (sem revogar a autorização) continua visível no marketplace
indefinidamente e recebe nova tentativa de cobrança todo mês.

## Ideia

Marcar `PAST_DUE` quando o débito do ciclo de fornecedor for recusado/vencer (evento Asaas do
Pix Automático recorrente ou `PAYMENT_OVERDUE` correlacionado à assinatura de fornecedor) e só
avançar `currentPeriodEnd` na confirmação do pagamento — o job existente de suspensão passa a
funcionar.

## ⚠️ Ao implementar
A página `/para-fornecedores` (TASK-285) hoje diz só que o perfil "pode ser retirado do
marketplace" — sem prazo, porque a regra não existia. Quando esta task entrar, dá pra voltar a
prometer o prazo de tolerância: atualizar `content.ts`, o teste "não promete prazo de tolerância
automático" em `content.test.ts` e a tabela de rastreabilidade do spec
`2026-09-24-pagina-para-fornecedores-design.md`.

## Causa raiz (confirmada 24/09/2026)
1. Nenhum código gravava `SupplierSubscription.PAST_DUE`: `PAYMENT_OVERDUE`/`PAYMENT_REFUSED` só
   resolvem `payments` de organização; o `PAYMENT_RECEIVED` de ciclo (`SUPPLIER-{id}`) caía no
   `activateFromWebhook`, no-op pra `ACTIVE`.
2. `chargeNextCycle` avançava `currentPeriodEnd` +1 mês ao criar a cobrança, pago ou não.

## Critérios de Aceite
- [x] Ciclo cobrado e não pago além de vencimento (+3d) + tolerância (+3d) → `PAST_DUE` e fora do
      marketplace (teste de regressão)
- [x] `currentPeriodEnd` só avança quando o pagamento do ciclo chega; `PAST_DUE` que paga volta ao
      marketplace sem reenviar e-mail de ativação (testes)
- [x] Sem cobrança dupla do mesmo ciclo; webhook duplicado não renova duas vezes (testes)
- [x] Ciclo nunca cobrado (falha nossa) não suspende (teste)
- [x] Assinaturas existentes sem efeito retroativo (`last_charged_period_end` nulo)
- [x] Copy da `/para-fornecedores` volta a prometer 3 dias de tolerância (teste de copy invertido)
- [x] `mvn test` 1095/1095; V116 aplicada no MySQL real; `npm test` sem falha nova

## Implementação
- api: `V116` (`supplier_subscriptions.last_charged_period_end`), `SupplierBillingService`
  (`processDueCycles` sem avançar período e sem cobrança dupla; `suspendOverdueSubscriptions` reescrito),
  `SupplierPaymentActivationService.activateFromWebhook(supplierId, paymentId)` (renovação/reativação),
  `PaymentReceivedHandler` repassando o id da cobrança
- web: política "Se o débito falhar" em `content.ts` + teste
- Branch `bugfix/TASK-288-supplier-past-due-suspension` (api e web)
- PRs: [api#117](https://github.com/douglasjava/easy-maintenance-api/pull/117) ·
  [web#96](https://github.com/douglasjava/easy-maintenance-web/pull/96) (`staging`) — web depende do api

## Status
🟡 Em Validação — implementado, testado, PRs abertas contra `staging`. Efeito real só no próximo
ciclo de cada fornecedor (job 02:15).
