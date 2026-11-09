# TASK-364 — Backend: job de reconciliação fiscal

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
TASK-361, TASK-363

## QA obrigatório
Sim — mesmo padrão de job periódico já usado em `BillingReconciliationService`/`TrialExpirationService`.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`](../../docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md) (Task 5).

`FiscalInvoiceReconciliationService.reconcile()` roda diariamente (`FiscalInvoiceReconciliationJob`,
`@SchedulerLock`, cron configurável) e faz duas coisas: (1) busca `BillingSubscription` ativas com
`fiscalInvoiceConfigured=false` e `externalSubscriptionId` preenchido, tenta configurar de novo; (2)
busca `FiscalInvoice` em `ERROR`/`PENDING` há mais de N dias (`stuckThresholdDays`, default 3) e
loga alerta — **sem retry automático de emissão**, decisão manual/contábil.

**Prompt**: `execute a TASK-364 (EPIC-037): job de reconciliação fiscal, seguindo a Task 5 do plano
docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md.`

## Critérios de aceite
- [ ] Assinatura ativa sem config de NF dispara nova tentativa via `FiscalInvoiceConfigurationService`.
- [ ] Nenhuma assinatura pendente: não chama o serviço de configuração.
- [ ] `FiscalInvoice` travado em `ERROR`/`PENDING` há mais de `stuckThresholdDays` gera alerta de log,
      sem tentar reemitir.
- [ ] `mvn test` sem regressão (inclusive suíte completa de billing/webhooks/jobs).

## Status
Em Validação — implementado em `feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api), `FiscalInvoiceReconciliationServiceTest` (3 testes) verde. Suíte completa (`billing`/`webhooks`/`jobs`, 415 testes) e suíte inteira do repo (1475 testes) verdes após essa task. PR não aberta ainda.
