# TASK-362 — Backend: acionar configuração de NF na ativação da assinatura

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
TASK-361

## QA obrigatório
Sim — mexe no caminho de ativação de toda assinatura nova; não pode quebrar nem bloquear o fluxo
existente.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`](../../docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md) (Task 3).

`SubscriptionCreatedHandler` ganha `FiscalInvoiceConfigurationService` no construtor e chama
`configureForSubscription(subscription)` logo depois de `billingSubscriptionRepository.save(subscription)`,
nos dois pontos de ativação (`handle()` principal e `handleCardUpdate(...)`).

**Prompt**: `execute a TASK-362 (EPIC-037): acionar FiscalInvoiceConfigurationService na ativação
da assinatura, seguindo a Task 3 do plano docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md.`

## Critérios de aceite
- [ ] Ativação de assinatura (happy path) chama `configureForSubscription` com a assinatura certa.
- [ ] Testes existentes de `SubscriptionCreatedHandlerTest` continuam passando.
- [ ] `mvn test` sem regressão.

## Status
Em Validação — implementado em `feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api), `SubscriptionCreatedHandlerTest` (12 testes, incluindo os 11 pré-existentes) verde. PR não aberta ainda.
