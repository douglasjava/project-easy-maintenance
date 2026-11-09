# TASK-361 — Backend: configuração de NF na Asaas — DTOs, `AsaasClient`, `FiscalInvoiceConfigurationService`

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-037](../epics/EPIC-037.md) — Emissão de NFS-e para Assinaturas (Asaas Nativo)

## Depende de
TASK-360

## QA obrigatório
Sim — falha na chamada à Asaas nunca pode propagar exceção para quem chama.

## Contexto
Plano de implementação em [`docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md`](../../docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md) (Task 2).

Novos DTOs em `AsaasDTO` (`FiscalInvoiceTaxes`, `CreateFiscalInvoiceConfigurationRequest`,
`FiscalInvoiceConfigurationResponse`); `AsaasClient.createInvoiceConfiguration(subscriptionId, req)`
(`POST /subscriptions/{id}/invoiceConfig`); `AsaasFiscalInvoiceProperties` (alíquotas
iss/pis/cofins/csll/inss/ir + `municipalServiceCode`, valores de sandbox/placeholder até o contábil
confirmar os reais); `FiscalInvoiceConfigurationService.configureForSubscription(subscription)` —
**nunca lança**, loga e retorna em caso de falha (o job de reconciliação, TASK-364, tenta de novo
depois).

**Prompt**: `execute a TASK-361 (EPIC-037): configuração de NF na Asaas (AsaasClient +
FiscalInvoiceConfigurationService), seguindo a Task 2 do plano
docs/superpowers/plans/2026-10-13-fiscal-invoice-nfse.md.`

## Critérios de aceite
- [ ] Sucesso: seta `fiscalInvoiceConfigured=true` e salva a assinatura.
- [ ] Request enviado usa `effectiveDatePeriod=ON_PAYMENT_CONFIRMATION` e as alíquotas configuradas.
- [ ] Assinatura sem `externalSubscriptionId`: não chama a Asaas, não lança.
- [ ] Falha na chamada à Asaas: não lança, flag continua `false`, assinatura não é salva.
- [ ] `mvn test` sem regressão.

## Status
Em Validação — implementado em `feature/EPIC-037-fiscal-invoice-nfse` (easy-maintenance-api), `FiscalInvoiceConfigurationServiceTest` (5 testes) verde. Flag extra `asaas.fiscal-invoice.enabled` (fail-closed, default false) adicionado para garantir que nenhuma chamada real saia antes do rollout (ver TASK-365) — não estava no plano original. PR não aberta ainda.
