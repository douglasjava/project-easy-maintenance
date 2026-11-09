# TASK-363 — Backend: webhook de nota fiscal — endpoint e processamento (`INVOICE_AUTHORIZED`/`INVOICE_ERROR`)

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
TASK-360

## QA obrigatório
Sim — idempotência e correlação de webhook, mesmo risco de classe já visto em TASK-318 (webhook de
pagamento).

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`](../../docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md) (Task 4).

Endpoint novo e **separado** do `AsaasWebhookController` existente (payload de NF é uma forma
diferente da de pagamento/assinatura): `AsaasFiscalInvoiceWebhookController`
(`POST /easy-maintenance/api/v1/public/webhooks/asaas/fiscal-invoices`), validado pelo mesmo token
(`asaas-access-token`) já usado no webhook de billing. `AsaasFiscalInvoiceWebhookService.processEvent`
resolve o `FiscalInvoice` local por `externalFiscalInvoiceId` (cria se não existir), idempotente por
`event.id()` via `WebhookEventService`, e tenta correlacionar com `Payment`/`BillingSubscription`
sem lançar exceção quando não encontra.

**Prompt**: `execute a TASK-363 (EPIC-037): webhook de nota fiscal (endpoint + processamento),
seguindo a Task 4 do plano docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md.`

## Critérios de aceite
- [ ] `INVOICE_AUTHORIZED` cria `FiscalInvoice` novo com `status=AUTHORIZED`, `pdfUrl`, `xmlUrl`,
      `authorizedAt`, quando ainda não existe local.
- [ ] `INVOICE_ERROR` em nota existente atualiza para `status=ERROR` com `errorMessage`.
- [ ] Evento duplicado (mesmo `event.id()`) é ignorado, sem salvar de novo.
- [ ] Tipo de evento desconhecido é ignorado sem erro.
- [ ] Payment não resolvido: salva `FiscalInvoice` sem vínculo, não lança.
- [ ] `mvn test` sem regressão.

## Status
Em Validação — implementado em `feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api), `AsaasFiscalInvoiceWebhookServiceTest` (5 testes) verde. PR não aberta ainda.
