# TASK-360 — Backend: `FiscalInvoice` — entidade, enum, migration V124 e repositório

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
—

## QA obrigatório
Sim — nova tabela/entidade, FKs opcionais (payment/billing_subscription nullable) precisam de teste
com banco real.

## Contexto
Desenho completo em [`docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md`](../../docs/superpowers/specs/2026-10-13-fiscal-invoice-nfse-design.md)
e plano de implementação em [`docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`](../../docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md) (Task 1).

Nova entidade `FiscalInvoice` (migration V124), enum `FiscalInvoiceStatus`
(`PENDING, AUTHORIZED, ERROR, CANCELED`), repository com
`findByExternalFiscalInvoiceId` e `findByStatusInAndCreatedAtBefore`. Campo novo
`fiscalInvoiceConfigured` em `BillingSubscription`. `payment` e `billing_subscription` são
nullable de propósito — um webhook de NF pode chegar antes de resolvermos a correlação (ver
TASK-363).

**Prompt**: `execute a TASK-360 (EPIC-037): FiscalInvoice entity, enum, migration V124 e
repository, seguindo a Task 1 do plano docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md.`

## Critérios de aceite
- [ ] `FiscalInvoicePersistenceTest` (banco real) prova round-trip por `externalFiscalInvoiceId`,
      busca por status+data e persistência sem `billingSubscription` (nullable).
- [ ] `mvn test` sem regressão.

## Status
Em Validação — implementado em `feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api), `FiscalInvoicePersistenceTest` (3 testes, banco real) verde. PR não aberta ainda — Douglas vai testar a branch antes.
