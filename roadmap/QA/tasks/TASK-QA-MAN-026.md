# TASK-QA-MAN-026 — QA Manual: emissão de NFS-e via Asaas nativo (EPIC-037, branch local → staging)

## Tipo
QA Manual — **execução manual** local (perfil `local`, Asaas sandbox), antes de abrir PR e promover
pra `staging`

## Categoria
Backend / Billing / Fiscal

## Prioridade
🔴 Alto — toca o caminho de ativação de toda assinatura nova (`SubscriptionCreatedHandler`) e tem um
flag de segurança novo que precisa ficar comprovadamente fail-closed antes de qualquer merge.

## Tasks cobertas

| Task | O que entrega | Status |
|---|---|---|
| [TASK-360](../../tasks/TASK-360.md) | `FiscalInvoice`, enum `FiscalInvoiceStatus`, migration V125, repositório | Em Validação |
| [TASK-361](../../tasks/TASK-361.md) | DTOs + `AsaasClient.createInvoiceConfiguration` + `FiscalInvoiceConfigurationService` (+ flag `asaas.fiscal-invoice.enabled`) | Em Validação |
| [TASK-362](../../tasks/TASK-362.md) | `SubscriptionCreatedHandler` aciona a configuração de NF na ativação | Em Validação |
| [TASK-363](../../tasks/TASK-363.md) | Webhook dedicado `INVOICE_AUTHORIZED`/`INVOICE_ERROR` | Em Validação |
| [TASK-364](../../tasks/TASK-364.md) | Job diário de reconciliação fiscal | Em Validação |

Branch: `feature/EPIC-037-fiscal-invoice-nfse` (`easy-maintenance-api`, a partir de `staging`), 5
commits, PR não aberta ainda. [TASK-365](../../tasks/TASK-365.md) é a própria task de QA/rollout do
épico — este roteiro é o bloco funcional dela, feito pela Claude; o checklist de rollout
(CNPJ/certificado A1/alíquotas reais) continua **não marcado como pronto** e fora do escopo aqui.

---

## Pré-condições

- Checkout de `feature/EPIC-037-fiscal-invoice-nfse` no `easy-maintenance-api`, rodando local
  (perfil `local`).
- Credenciais **sandbox** da Asaas configuradas no `.env`/variáveis locais (mesmas já usadas pra
  billing/PIX). **Nunca** usar credenciais de produção aqui — o épico inteiro existe pra evitar
  chamada real antes do certificado A1.
- `asaas.fiscal-invoice.enabled=true` já vem configurado no `application-local.properties` por
  padrão desta branch — confirmar antes de começar (`grep fiscal-invoice.enabled` no arquivo).
- Uma assinatura de teste que ainda vá passar pela ativação (`SubscriptionCreatedHandler`) — pode
  ser um cadastro novo completo (onboarding → checkout CC) ou, se já tiver uma assinatura
  `TRIAL`/pendente num cliente de teste, forçar a ativação via webhook `PAYMENT_CONFIRMED`/
  `SUBSCRIPTION_CREATED` como já era feito em QAs anteriores de billing.
- Acesso ao painel do Asaas **sandbox** (seção de assinaturas, pra conferir a configuração de NF
  criada) e ao banco local (MySQL/console) pras consultas de apoio.
- `mvn test` já rodado nesta sessão contra o commit `8b60031` (HEAD da branch): **1475/1475, 0
  falhas** (suíte completa do módulo, inclui as novas: `FiscalInvoicePersistenceTest`,
  `FiscalInvoiceConfigurationServiceTest`, `AsaasFiscalInvoiceWebhookServiceTest`,
  `FiscalInvoiceReconciliationServiceTest`, mais os ajustes em `SubscriptionCreatedHandlerTest`).
- Nomes/descrições de teste prefixados com `QA-026-` pra facilitar limpeza.

**Ordem sugerida:** Bloco A (regressão de suíte, rápido) → B (flag de segurança) → C (configuração
na ativação) → D (webhook de NF) → E (reconciliação) → F (segurança/produção).

---

## Bloco A — Suíte automatizada, sem regressão 🔴 CRÍTICO

### A1 — Suíte completa do módulo

| Passo | Ação | Resultado esperado |
|---|---|---|
| 1 | `mvn clean test` na branch `feature/EPIC-037-fiscal-invoice-nfse` (lembrar de usar JDK 21, não o `java` padrão do PATH) | **1475/1475**, 0 falhas, 0 erros |

Já executado e confirmado nesta sessão (ver histórico de commits da branch).

---

## Bloco B — Flag de segurança `asaas.fiscal-invoice.enabled` 🔴 CRÍTICO

Este é o ponto que a Claude adicionou por fora do plano original: sem ele, toda ativação de
assinatura chamaria a Asaas **de produção** assim que isso fosse pra `main`, antes do certificado
A1 existir. Este bloco prova que o flag realmente bloqueia a chamada quando `false`.

### B1 — Com `enabled=false`, nenhuma chamada à Asaas

1. Em `application-local.properties`, trocar temporariamente `asaas.fiscal-invoice.enabled=true`
   para `false` e reiniciar a aplicação.
2. Ativar uma assinatura de teste (ver Pré-condições).

**Esperado:** log `[FiscalInvoice] Configuração de NF desabilitada (asaas.fiscal-invoice.enabled=false)
— pulando BillingSubscription <id>...`; **nenhuma** chamada ao endpoint `/subscriptions/{id}/invoiceConfig`
no Asaas (confirmar no painel sandbox: assinatura sem configuração de NF); `fiscal_invoice_configured`
continua `false` no banco para essa `billing_subscriptions`.

### B2 — Confirmar que `enabled` está ausente (⇒ `false`) em `application.properties` e `application-prod.properties`

```bash
grep -n "fiscal-invoice" src/main/resources/application.properties src/main/resources/application-prod.properties
```

**Esperado:** nenhuma ocorrência de `asaas.fiscal-invoice.enabled` nesses dois arquivos — o
`@DefaultValue("false")` do record garante fail-closed. Só `application-local.properties`,
`application-e2e.properties` e `application-hml.properties` têm o bloco com `enabled=true`.

3. Reverter o `application-local.properties` para `enabled=true` antes de seguir pros próximos
   blocos.

**Evidência:** print do log do B1 + saída do `grep` do B2.

---

## Bloco C — Configuração de NF na ativação (TASK-362) 🟠 ALTO

Com `enabled=true` (padrão da branch).

### C1 — Ativação cria a configuração de NF na Asaas

1. Ativar uma assinatura de teste nova (`QA-026-...`).
2. Consultar o banco:

```sql
SELECT id, external_subscription_id, fiscal_invoice_configured
FROM billing_subscriptions
WHERE id = <subscription_id>;
```

**Esperado:** log `[FiscalInvoice] Configuração de NF criada para BillingSubscription <id>
(externalSubscriptionId=...)`; `fiscal_invoice_configured = 1`; no painel do Asaas sandbox, a
assinatura mostra a configuração de nota fiscal ativa (`effectiveDatePeriod = ON_PAYMENT_CONFIRMATION`).

### C2 — Falha na Asaas não bloqueia a ativação

1. Forçar uma falha controlada (ex.: derrubar a conectividade com o sandbox momentaneamente, ou
   usar um `externalSubscriptionId` inválido se for mais simples reproduzir via teste de
   integração) durante a ativação de outra assinatura de teste.

**Esperado:** a assinatura ativa normalmente (status `ACTIVE`, usuário consegue seguir o fluxo);
log `[FiscalInvoice] Falha ao configurar NF para BillingSubscription <id> ...: <mensagem>`;
`fiscal_invoice_configured` continua `false` — fica para o job de reconciliação (Bloco E) tentar de
novo.

### C3 — Troca de cartão (`handleCardUpdate`) também aciona a configuração

Repetir C1 usando o fluxo de atualização de cartão de uma assinatura existente (gera um novo
`externalSubscriptionId`), em vez de uma ativação nova.

**Esperado:** mesmo comportamento do C1 — nova configuração de NF criada para o novo
`externalSubscriptionId`.

**Evidência:** prints do painel Asaas sandbox (C1 e C3) + log da falha controlada (C2).

---

## Bloco D — Webhook de nota fiscal (TASK-363) 🟠 ALTO

Endpoint: `POST /easy-maintenance/api/v1/public/webhooks/asaas/fiscal-invoices`, header
`asaas-access-token` com o mesmo token do webhook de billing existente (`WEBHOOK-TOKEN`).

### D1 — `INVOICE_AUTHORIZED` cria `FiscalInvoice` local

```bash
curl -i -X POST -H "Content-Type: application/json" -H "asaas-access-token: <WEBHOOK_TOKEN>" \
  -d '{
    "id": "evt_qa026_1",
    "event": "INVOICE_AUTHORIZED",
    "invoice": {
      "id": "inv_qa026_1",
      "status": "AUTHORIZED",
      "payment": "<externalPaymentId_de_um_payment_real_de_teste>",
      "pdfUrl": "https://sandbox.asaas.com/qa026.pdf",
      "xmlUrl": "https://sandbox.asaas.com/qa026.xml"
    }
  }' \
  http://localhost:8080/easy-maintenance/api/v1/public/webhooks/asaas/fiscal-invoices
```

**Esperado:** `200 ok`;

```sql
SELECT external_fiscal_invoice_id, status, pdf_url, xml_url, authorized_at, payment_id
FROM fiscal_invoices WHERE external_fiscal_invoice_id = 'inv_qa026_1';
```

mostra `status = AUTHORIZED`, `pdf_url`/`xml_url` preenchidos, `authorized_at` preenchido e
`payment_id` apontando para o `Payment` real usado no `payment`.

### D2 — `INVOICE_ERROR` atualiza nota existente

Repetir o D1 com `"id": "evt_qa026_2"`, `"event": "INVOICE_ERROR"`, mesmo `invoice.id` (`inv_qa026_1`)
e um `"statusDescription": "CNPJ não habilitado para emissão"`.

**Esperado:** `200 ok`; a mesma linha de `fiscal_invoices` passa para `status = ERROR` com
`error_message` preenchido.

### D3 — Evento duplicado é ignorado

Reenviar exatamente o mesmo corpo do D1 (`"id": "evt_qa026_1"`).

**Esperado:** `200 ok`; **nenhuma** linha nova nem alteração em `fiscal_invoices` — idempotência via
`WebhookEventService.findByProviderEventId`.

### D4 — Tipo de evento desconhecido é ignorado sem erro

Repetir com `"event": "INVOICE_CANCELLED"` (ou outro tipo não tratado) e um `id` novo.

**Esperado:** `200 ok`; nenhuma linha criada/alterada em `fiscal_invoices`.

### D5 — Payment não resolvido não trava o webhook

Repetir o D1 com `"id": "evt_qa026_5"`, `invoice.id` novo e `"payment": "pay_inexistente_123"`.

**Esperado:** `200 ok`; `FiscalInvoice` salvo com `status = AUTHORIZED` mas `payment_id = NULL`; log
de warning sobre payment não encontrado.

### D6 — Token inválido/ausente é rejeitado

Repetir o D1 sem o header `asaas-access-token` e depois com um token errado.

**Esperado:** `401` nos dois casos; nenhuma linha criada em `fiscal_invoices`.

**Evidência:** saída dos 6 `curl` (D1–D6) com status code e, para D1–D2, o `SELECT` confirmando o
estado em `fiscal_invoices`.

---

## Bloco E — Reconciliação (TASK-364) 🟡 MÉDIO

Não existe endpoint de disparo manual tipo `/run-jobs/execute-...` para este job ainda (diferente
dos outros jobs do projeto) — ver gap no final. Pra testar sem esperar o cron (`0 30 3 * * *`),
chamar `FiscalInvoiceReconciliationService.reconcile()` diretamente (ex.: endpoint de teste
temporário, breakpoint, ou um teste de integração ad-hoc local) ou aguardar a execução noturna.

### E1 — Assinatura ativa sem config de NF é retentada

1. A partir do estado do C2 (uma `billing_subscriptions` `ACTIVE` com `fiscal_invoice_configured = 0`
   e `external_subscription_id` preenchido), disparar `reconcile()`.

**Esperado:** log `[FiscalInvoiceReconciliation] Subscriptions sem configuração de NF: <N>` com
`N >= 1`; a assinatura do C2 recebe uma nova tentativa de `configureForSubscription` — se a falha
controlada não se repetir, `fiscal_invoice_configured` passa para `1`.

### E2 — `FiscalInvoice` travada em `ERROR`/`PENDING` gera alerta, sem retry de emissão

1. Usar a nota do D2 (`inv_qa026_1`, em `ERROR`) e, via SQL, antecipar o `created_at` pra mais de 3
   dias atrás:

```sql
UPDATE fiscal_invoices SET created_at = NOW() - INTERVAL 4 DAY WHERE external_fiscal_invoice_id = 'inv_qa026_1';
```

2. Disparar `reconcile()` de novo.

**Esperado:** log `[FiscalInvoiceReconciliation] FiscalInvoice inv_qa026_1 travado em ERROR há mais
de 3 dias — revisão manual necessária (errorMessage=...)`; **nenhuma** tentativa de reemitir a nota
(não chama a Asaas de novo pra essa invoice) — só o alerta de log.

**Evidência:** log completo de E1 e E2; `SELECT` antes/depois do E1 confirmando
`fiscal_invoice_configured`.

---

## Bloco F — Segurança / regressão geral 🔴 CRÍTICO

### F1 — Multi-tenant: `FiscalInvoice` não exposta por API nenhuma ainda

Confirmar (via `grep`) que não existe nenhum `@RestController`/endpoint autenticado que devolva
`FiscalInvoice` pro frontend nesta branch — o épico até aqui só cobre o pipeline interno
(configuração + webhook + reconciliação), sem tela/endpoint de consulta ainda.

**Esperado:** nenhum resultado — confirma que não há superfície de API nova pra validar
isolamento de tenant nesta rodada (ficará para uma task futura de exibir notas fiscais ao
usuário, se vier a existir).

### F2 — Regressão dos dois testes de persistência afetados

```bash
mvn test -Dtest=BillingAccountRepositoryPersistenceTest,InvoiceRepositoryPersistenceTest
```

**Esperado:** verde — confirma que o `@EntityScan` ampliado com `Payment.class` (necessário porque
`FiscalInvoice` passou a referenciar `Payment`) não quebrou os dois testes pré-existentes que
tiveram que ser ajustados.

**Evidência:** saída do comando do F2.

---

## Limpeza

```sql
DELETE FROM fiscal_invoices WHERE external_fiscal_invoice_id LIKE 'inv_qa026%';
-- reverter fiscal_invoice_configured/current_period_end de qualquer billing_subscriptions reaproveitada de teste
```

Revogar/cancelar no painel Asaas sandbox qualquer assinatura e configuração de NF criadas
exclusivamente para este QA (`QA-026-*`).

## Critério de aprovação pra abrir a PR e promover pra `staging`
Blocos **A**, **B** e **D1–D3, D6** são obrigatórios — são o que garante que o flag de segurança
funciona e que o webhook não duplica nem quebra com payload inesperado. C1–C3 e E1–E2 podem ser
aprovados com uma passada funcional simples no sandbox, já que a lógica de negócio em si está
coberta pela suíte automatizada (Bloco A) — o objetivo aqui é só confirmar que o comportamento
documentado aparece de fato contra o Asaas sandbox real, não repetir a suíte manualmente.

## Riscos conhecidos / Gaps
- **Sem endpoint de disparo manual para `FiscalInvoiceReconciliationJob`** (diferente de
  `execute-trial-expiration`, `execute-supplier-billing` etc.) — testar o Bloco E exige esperar o
  cron das 03:30 ou acionar o serviço manualmente (teste de integração/debug). Vale avaliar se
  compensa adicionar um `GET /run-jobs/execute-fiscal-invoice-reconciliation` numa próxima task,
  seguindo o padrão já usado nos outros jobs — não implementado agora para não expandir o escopo
  das 5 tasks de código.
- **TASK-365 (checklist de rollout) continua bloqueada**: mesmo com este QA funcional aprovado, o
  épico **não ativa nada em produção** até o novo CNPJ existir, o certificado A1 estar emitido, o
  onboarding manual no portal da Asaas estar completo e as alíquotas fiscais reais serem
  confirmadas com o contábil (hoje são placeholder de sandbox).
- Nenhuma tela/endpoint autenticado expõe `FiscalInvoice` ao usuário final ainda — fora do escopo
  das TASK-360 a 364 (ver F1). Se o Douglas quiser visibilidade no app antes do rollout, é uma task
  nova.

## Status
Backlog — aguardando execução manual pelo Douglas, local contra Asaas sandbox, antes de abrir a PR
da branch `feature/EPIC-037-fiscal-invoice-nfse`.
