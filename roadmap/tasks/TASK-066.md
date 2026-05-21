# TASK-066 — Implementar Pix Automático (mandato no banco do payer)

## Tipo
FULL_STACK

## Categoria
Backend / Frontend / Billing / Integração Asaas

## Prioridade
🟡 Médio

## Fase
3 — Escala / Pós-MVP de PIX manual

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

O PIX manual (TASK-058..060) funciona, mas tem UX inferior ao cartão: o usuário precisa pagar **ativamente** todo mês 
via QR Code. Para reduzir churn e operacionalmente competir com cartão, o caminho ideal é o **Pix Automático** 
(mandato regulamentado pelo Banco Central — autodebit autorizado no banco do payer).

Asaas expõe o produto Pix Automático com:
- Endpoint de criação de **autorização** (`pixAutomaticPayments`).
- Fluxo de redirect / QR Code para o payer aprovar o mandato no app do banco dele.
- Webhooks de status da autorização (PENDING → AUTHORIZED → ACTIVE → REVOKED/EXPIRED).
- Debits agendados pelo backend contra a autorização ativa.

Referências:
- https://docs.asaas.com/docs/pix-automatico
- https://docs.asaas.com/docs/pix-automatico-implementacao

## Solução (Visão Geral)

Introduzir o conceito de `BillingAgreement` (mandato/autorização) como entidade explícita, 
com subtipos `CardToken` e `PixConsent`. Implementar o fluxo de captura de consentimento, persistência, e disparo de débito por ciclo.

> **Nota arquitetural:** este é o momento adequado para introduzir o aggregate `BillingAgreement` — adiado nas TASK-058..061 para não atrasar o MVP. Aqui a abstração se paga.

## Escopo

### Backend
- Migration: nova tabela `billing_agreement` (id, subscription_id, type, status, asaas_authorization_id, authorized_at, expires_at, revoked_at).
- Adapter `AsaasPixAutomaticGateway` (criar autorização, agendar débito, cancelar).
- Webhook handlers para eventos de autorização (status do mandato).
- Estado da subscription respeitando o ciclo de vida do mandato.

### Frontend
- Opção "Pix Automático" na seleção de método (TASK-061).
- Tela "Aguardando autorização" com polling/SSE até receber `AUTHORIZED`.
- Tela de "Autorizar no banco" com QR Code / deep link.

### Operação
- Tratar revogação do mandato pelo payer (vinda do banco) → mover para PAST_DUE + abrir fluxo TASK-065.
- Reconciliação (TASK-063) precisa cobrir status do agreement.

## Critérios de Aceite

- [ ] Usuário consegue escolher "Pix Automático" no fluxo de upgrade
- [ ] Fluxo de autorização no banco completa e o mandato fica em AUTHORIZED
- [ ] Primeiro débito acontece automaticamente após aprovação
- [ ] Renovações mensais acontecem sem intervenção do usuário
- [ ] Revogação no banco → backend recebe webhook → subscription PAST_DUE
- [ ] Cobertura de testes: happy path, autorização negada, revogação no meio do ciclo
- [ ] Documentação no runbook

## Dependências
- TASK-058..061 prontos (MVP de PIX manual funcionando)
- TASK-062 (classificador de erros — útil para mapear refusals do Pix Automático)
- TASK-063 (reconciliação) — estender para cobrir agreement

## Esforço
Grande (3–5 dias)

## Risco de não fazer
Sem isso, PIX continua manual mensal — UX inferior a cartão, conversão de PIX abaixo do potencial.

## Status
Backlog
