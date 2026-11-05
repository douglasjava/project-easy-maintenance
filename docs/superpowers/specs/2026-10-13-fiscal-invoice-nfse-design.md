# Emissão de NFS-e para assinaturas de organização (Asaas nativo)

**Data:** 13/10/2026
**Status:** Aprovado por Douglas (brainstorm conduzido 12-13/10/2026)

## Motivação

Hoje não existe nenhuma emissão de nota fiscal para as cobranças de assinatura (STARTER R$149,
BUSINESS R$299, ENTERPRISE R$899). Verificado no código: `Invoice` (`billing/domain/Invoice.java`)
é só um registro financeiro interno — sem CNPJ emitente, série, número de NF, chave de acesso ou
XML. Isso é um gap fiscal real: cobranças confirmadas sem contrapartida fiscal.

## Escopo

- **Só assinatura de organização** (condomínio/administradora). O módulo de cadastro de
  fornecedores (R$15,99/mês, Pix Automático próprio) **não** entra neste escopo — ver
  [[project-epic027-028-future-ideas]] / `2026-09-20-supplier-pix-automatico-design.md`. Pode ser
  tratado depois, como extensão do mesmo padrão.
- Cobre só emissão de NFS-e (nota fiscal de serviço); não cobre NF-e de produto nem NFC-e.

## Contexto levantado antes do desenho

- Provedores terceiros avaliados e descartados: Focus NFe (R$94,90–119,90/mês), eNotas (API só a
  partir do plano Plus, R$247/mês), NFE.io (R$190/mês). Todos exigem um fornecedor novo a integrar
  e mensalidade fixa.
- **Decisão: usar a emissão de NFS-e nativa do Asaas** (nosso provedor de pagamento atual). Custo:
  R$0,49 por nota emitida, sem mensalidade. Fontes: [asaas.com/nota-fiscal](https://www.asaas.com/nota-fiscal),
  [docs.asaas.com/reference/emitir-uma-nota-fiscal](https://docs.asaas.com/reference/emitir-uma-nota-fiscal).
- **Mecanismo real** (não é "chamar a API a cada pagamento"): é uma configuração feita **uma vez
  por assinatura** via `POST` de configuração de NF (`docs.asaas.com/reference/criar-configuracao-para-emissao-de-notas-fiscais`),
  com alíquotas (`iss`, `pis`, `cofins`, `csll`, `inss`, `ir`), `municipalServiceCode` e
  `effectiveDatePeriod`. Depois de configurada, a Asaas emite a NFS-e automaticamente a cada
  cobrança mensal paga da assinatura — sem chamada adicional nossa por pagamento.
- `effectiveDatePeriod` escolhido: **`ON_PAYMENT_CONFIRMATION`** (emite só depois do pagamento
  confirmado — consistente com a decisão de não emitir antes do pagamento).
- Webhooks relevantes da Asaas: `INVOICE_AUTHORIZED` (nota autorizada pela prefeitura) e
  `INVOICE_ERROR` (falha no processamento). Fonte: `docs.asaas.com/reference/emitir-uma-nota-fiscal`.
- **Colisão de nome**: a Asaas chama o objeto fiscal de "invoice" também, mas isso é diferente do
  nosso `Invoice` (cobrança). A entidade local nova se chama `FiscalInvoice` para não confundir.
- Pontos de integração já existentes a reaproveitar:
  - `AsaasClient` (`infrastructure/saas/client/AsaasClient.java`) — já tem `createSubscription`,
    `getSubscription`, `updateSubscription`, `cancelSubscription` via `WebClient`. Novo método
    `createInvoiceConfiguration` segue o mesmo padrão.
  - `AsaasWebhookStrategy` / `AbstractAsaasWebhookStrategy` (`webhooks/asaas/strategy/`) — padrão
    de registro de handlers por `getEventType()`, usado hoje por `PaymentReceivedHandler`,
    `PaymentConfirmedHandler`, `SubscriptionCreatedHandler` etc. Novos handlers seguem o mesmo
    padrão.
  - `BillingReconciliationService` / `TrialExpirationService` (`jobs/service/`) — padrão de job
    periódico de reconciliação já estabelecido no código; o job de reconciliação fiscal segue o
    mesmo modelo.

## Dependência externa (bloqueador de rollout, não de engenharia)

O onboarding de NF no portal da Asaas (`asaas.com/customerInvoiceOnboarding`) exige **Certificado
Digital A1** para autenticar com o portal da prefeitura — passo manual, feito uma vez, fora da
nossa API. Douglas confirmou (12/10/2026) que isso **depende da abertura de um novo CNPJ**, ainda
em andamento.

**Implicação:** este spec e o plano de implementação derivado dele podem ser escritos e o código
pode ser desenvolvido/testado contra sandbox normalmente. Mas **a configuração de NF não deve ser
ativada numa assinatura real em produção até o CNPJ existir e o certificado A1 estar emitido** —
confirmar esse ponto com Douglas de novo antes do rollout, não assumir que já foi resolvido.

## Arquitetura

1. **Criação de assinatura** (fluxo atual, local a identificar em `BillingSubscriptionService` /
   quem chama `AsaasClient.createSubscription` hoje): logo após a assinatura ser criada com
   sucesso no Asaas, chamar `AsaasClient.createInvoiceConfiguration(subscriptionId, config)` uma
   única vez, com as alíquotas fiscais e `effectiveDatePeriod = ON_PAYMENT_CONFIRMATION`.
   - Em caso de falha nessa chamada, **não falhar a criação da assinatura** — logar o erro e
     deixar o job de reconciliação (item 3) detectar e tentar novamente. A assinatura em si não
     deve ficar bloqueada por um problema fiscal.
2. **Dois novos webhook handlers**, seguindo o padrão `AsaasWebhookStrategy`:
   - `InvoiceAuthorizedHandler` (`getEventType() = "INVOICE_AUTHORIZED"`): resolve o
     `FiscalInvoice` local pelo id externo da nota (criando o registro se ainda não existir —
     pode ser a primeira vez que vemos essa nota), seta `status = AUTHORIZED`, `pdfUrl`, `xmlUrl`,
     `authorizedAt`.
   - `InvoiceErrorHandler` (`getEventType() = "INVOICE_ERROR"`): mesma resolução, seta
     `status = ERROR` e `errorMessage`. Loga em nível `WARN` para visibilidade operacional.
3. **Job de reconciliação fiscal** (mesmo padrão de `BillingReconciliationService`), rodando
   periodicamente (frequência a definir no plano — diário é suficiente, não é um fluxo de alta
   urgência como pagamento):
   - Busca `BillingSubscription` ativas com `fiscalInvoiceConfigured = false` e tenta criar a
     configuração de novo (cobre falha transitória do passo 1).
   - Busca `FiscalInvoice` em `status = ERROR` há mais de N dias sem nova tentativa, ou em
     `status = PENDING` há mais tempo do que o esperado para autorização — loga alerta para
     Douglas revisar manualmente (sem retry automático de emissão em si; a nova tentativa de
     emissão, se necessária, é uma decisão manual/contábil, não só técnica).

## Modelo de dados

Nova entidade `FiscalInvoice`:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `payment` | FK → `Payment` | nullable — pode não estar resolvido ainda no momento do webhook |
| `billingSubscription` | FK → `BillingSubscription` | permite reconciliar por assinatura mesmo sem `payment` resolvido |
| `externalFiscalInvoiceId` | String | id da nota na Asaas |
| `status` | enum (`PENDING`, `AUTHORIZED`, `ERROR`, `CANCELED`) | espelha o ciclo de vida reportado via webhook |
| `pdfUrl` | String | preenchido só em `AUTHORIZED` |
| `xmlUrl` | String | preenchido só em `AUTHORIZED` |
| `errorMessage` | String | preenchido só em `ERROR` |
| `authorizedAt` | Instant | |
| `createdAt` / `updatedAt` | Instant | `@CreationTimestamp`/`@UpdateTimestamp`, mesmo padrão de `Invoice` |

Novo campo em `BillingSubscription`: `fiscalInvoiceConfigured: boolean` (default `false`) — marca
se a configuração de NF já foi criada com sucesso para essa assinatura; usado pelo job de
reconciliação do passo 3.

## Tratamento de erro

- Falha ao criar a configuração de NF na criação da assinatura: não bloqueia a assinatura, loga,
  fica pro job de reconciliação resolver.
- `INVOICE_ERROR`: não há retry automático de emissão — fica registrado e visível para decisão
  manual (pode ser erro de dado fiscal, não só transitório).
- Webhook chegando para uma nota cujo `FiscalInvoice` local ainda não existe: criar o registro a
  partir do webhook mesmo assim (idempotente por `externalFiscalInvoiceId`), não descartar o
  evento.

## Testes

Seguir o padrão de teste já usado nos handlers de webhook existentes (ex:
`PaymentCreatedHandlerTest`, `PaymentConfirmedHandlerTest`) e nos jobs de reconciliação
(`BillingReconciliationServiceTest`, `TrialExpirationServiceTest`):

- Unit test de `InvoiceAuthorizedHandler` e `InvoiceErrorHandler`: idempotência, criação de
  `FiscalInvoice` quando não existe, atualização quando já existe.
- Unit test do método novo em `AsaasClient` (mock do `WebClient`, request/response shape).
- Unit test do job de reconciliação: assinatura sem config é detectada e retry é disparado;
  `FiscalInvoice` em `ERROR`/`PENDING` antigo gera alerta sem retry automático de emissão.
- Sem teste de integração real com a Asaas em produção antes do CNPJ/certificado A1 estarem
  prontos (ver dependência externa) — testar contra sandbox da Asaas, se disponível para esse
  fluxo.

## Rollout

1. Implementar e testar tudo contra sandbox.
2. Confirmar com Douglas que o CNPJ novo existe e o certificado A1 foi emitido.
3. Completar o onboarding manual no portal da Asaas
   (`asaas.com/customerInvoiceOnboarding`) com o certificado.
4. Ativar a configuração de NF nas assinaturas reais (pode ser gradual, por organização, ou em
   lote via o próprio job de reconciliação assim que `fiscalInvoiceConfigured` passar a fazer
   sentido ser ativado de verdade).
