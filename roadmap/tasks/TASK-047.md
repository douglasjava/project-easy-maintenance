# TASK-047 — PIX: e-mail de lembrete no PAYMENT_OVERDUE

## Tipo
Funcionalidade / Notificação

## Categoria
Backend / Billing / Notificação

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional

## Descrição
O `PaymentOverdueHandler` já existe e já processa o evento `PAYMENT_OVERDUE` do Asaas: marca o `Payment` como `OVERDUE` e a `Invoice` como `OVERDUE`. O que está faltando é a notificação ao usuário — quando a cobrança PIX vence sem pagamento, o usuário não recebe nenhum aviso pelo app e só descobre que foi bloqueado depois que a assinatura já está `BLOCKED` (3 dias após vencimento, via `SubscriptionBlockingJob`).

## Problema
- `PaymentOverdueHandler` não envia nenhum e-mail
- Usuário PIX não tem visibilidade de que a cobrança venceu
- O bloqueio chega como surpresa 3 dias depois
- Ausência de e-mail de lembrete aumenta o churn involuntário por PIX

## Dependências
- `PaymentOverdueHandler` já existe — é incremento no handler existente
- TASK-046: endpoint de pending payment (para gerar link de pagamento no e-mail)
- Template de e-mail de cobrança vencida (criar novo template)

## Critérios de Aceite
- [x] `PaymentOverdueHandler` injeta `BillingNotificationService`
- [x] Quando `payment.methodType == PIX`: envia e-mail de lembrete ao `payment.payer`
- [x] E-mail contém: valor da cobrança formatado, botão/link "Pagar com PIX" (`payment.paymentLink`)
- [x] E-mail NÃO é enviado para pagamentos em estado final — guarda existente no handler respeita isso
- [x] Template de e-mail em português, consistente com os demais e-mails do produto
- [~] Envio registrado no `AuditService` — `AuditAction` é enum (sem ação customizada); envio coberto por `log.info` no `BillingNotificationService`

## Subtasks
- [x] Adicionar injeção de `BillingNotificationService` no `PaymentOverdueHandler`
- [x] Criar método `sendPixOverdueEmail(Payment payment)` em `BillingNotificationService`
- [x] Criar template HTML `generatePixOverdueHtml(userName, amountFormatted, paymentLink)` em `EmailTemplateHelper`
- [x] Notificação in-app adicionada junto ao e-mail (tipo `SUBSCRIPTION_BLOCKED`)
- [x] Testes unitários em `PaymentOverdueHandlerPixTest` (5 testes: PIX envia e-mail, CARD não envia, estado final ignora, pagamento não encontrado ignora, payload null ignora)

## Esforço
Pequeno (2-4h)

## Risco de não fazer
Usuário PIX recebe bloqueio silencioso. Alta taxa de churn involuntário por falta de comunicação.

## Status
Concluído
