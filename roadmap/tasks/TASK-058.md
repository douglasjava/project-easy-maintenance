# TASK-058 — Refatorar job de expiração de TRIAL: PIX via cobrança avulsa (DETACHED)

## Tipo
BUG / BACKEND

## Categoria
Backend / Billing / Job Agendado

## Prioridade
🔴 Crítico

## Fase
2 — Pós-lançamento (correção urgente)

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Quando o job de expiração de TRIAL tenta gerar a cobrança da subscription para um usuário que escolheu PIX, o Asaas rejeita o payload com os erros:

```
"O método de pagamento CREDIT_CARD é obrigatório para as operações RECURRENT e INSTALLMENT"
"O método de pagamento CREDIT_CARD é o único método de pagamento permitido para operações RECURRENT"
"O tipo de cobrança DETACHED é obrigatório para o método de pagamento PIX"
"O campo subscription é inválido."
```

A causa raiz é arquitetural: o endpoint `/subscriptions` do Asaas só aceita `billingType=CREDIT_CARD`. Para PIX, 
é obrigatório usar cobranças `DETACHED` (avulsas). A regra de recorrência precisa ser gerenciada **internamente** pela aplicação — não há "subscription PIX" no Asaas.

## Solução

Refatorar `TrialExpirationJob` (ou o componente equivalente) para bifurcar o fluxo por método de pagamento:

1. **Se método = CREDIT_CARD**: comportamento atual — criar subscription no Asaas com `billingType=CREDIT_CARD`.
2. **Se método = PIX**: criar uma única cobrança `DETACHED` no Asaas via `POST /payments` (`billingType=PIX`, `dueDate=now+N`). 
Não criar subscription no Asaas. A recorrência mensal será disparada por job interno (ver TASK-059 e TASK-060).

## Escopo

- Identificar o ponto de entrada do job atual (provável: `TrialExpirationService` / `BillingSubscriptionService.activateSubscription`).
- Criar `PixDetachedChargeGateway.createMonthlyCharge(subscriptionId)` — chamada explícita ao endpoint `/payments` do Asaas.
- Bifurcação por `paymentMethod` na ativação pós-trial.
- Persistir o `asaasPaymentId` retornado em `payments` com `status=PENDING`, vinculado à `billingSubscriptionId`.
- Não tocar no fluxo de cartão.

## Critérios de Aceite

- [X] Job de expiração de TRIAL não chama mais `POST /subscriptions` quando método é PIX
- [X] Para usuários PIX, é criada uma cobrança DETACHED com `dueDate` configurável (default: data da expiração do trial)
- [X] `Payment` é persistido localmente com referência à subscription antes do retorno do Asaas (idempotência)
- [X] Em caso de erro do Asaas, a subscription permanece em `TRIAL` + `PENDING_PAYMENT_METHOD` (não cair em estado órfão)
- [X] Logs estruturados com `subscriptionId`, `orgId`, `paymentMethod`, `asaasPaymentId`
- [X] Testes unitários cobrindo: PIX happy path, CC happy path, falha do Asaas, retry idempotente

## Dependências
- Nenhuma bloqueante. TASK-046, TASK-047, TASK-048 já fornecem o handler de PAYMENT_CREATED, lembrete por e-mail e exibição do QR code.

## Esforço
Médio (1–2 dias)

## Risco de não fazer
Conversão de trial→pago via PIX **completamente quebrada**. Perda direta de receita por churn de trial.

## Status
Concluido
