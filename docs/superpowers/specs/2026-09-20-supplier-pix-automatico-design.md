# EPIC-028 Fase 2 — Pix Automático pra assinatura de fornecedor

**Data:** 20/09/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Douglas identificou, ainda durante o QA da Fase 2 do marketplace (TASK-QA-MAN-022), um risco de
produto: PIX manual (o fornecedor precisa entrar todo mês e pagar via QR Code/link) é um ponto de
atrito que pode fazer o fornecedor simplesmente parar de pagar e sumir do marketplace — justo o
oposto do objetivo do épico (fornecedores cadastrados/pontuados como case de monetização, ver
[[project-epic027-028-future-ideas]]). A Asaas expõe um produto de Pix Automático (mandato
regulamentado pelo Banco Central) que resolve exatamente isso.

Esse mesmo problema já tinha sido levantado antes pro billing de **organização** (TASK-066,
EPIC-010) e adiado — ver [[project-pix-recurring-strategy]]. A diferença que destrava esse escopo
agora: `supplier_billing` é um domínio isolado, sem FK nenhuma pra `billing_subscriptions`/
`payments`/`invoices` de organização (verificado no schema — só referencia `suppliers`), a
assinatura é fixa (R$15,99/mês, sem planos/itens/comissão de afiliado), e o marketplace ainda não
está em PRD — sem necessidade de compatibilidade retroativa. Escopo bem menor que o TASK-066
original, que continua adiado pro billing de organização.

## Contexto (levantado antes do desenho)

- Fluxo atual (TASK-264/267, `SupplierRegistrationService` + `SupplierBillingJob`): cadastro gera
  uma cobrança PIX avulsa (`DETACHED`, `POST /payments`) com `invoiceUrl` como link de pagamento;
  `PaymentReceivedHandler` (branch `externalReference` iniciando com `SUPPLIER-`) ativa a
  assinatura; job diário gera uma cobrança nova a cada ciclo.
- Lacuna já existente no fluxo atual: nada seta `PAST_DUE` automaticamente quando uma cobrança de
  renovação não é paga — no QA (C7) isso foi simulado via SQL direto. Não há
  `PaymentOverdueHandler` com branch `SUPPLIER-`.
- Documentação da Asaas consultada (fetch direto, 20/09/2026):
  [Pix Automático](https://docs.asaas.com/docs/pix-automatico),
  [guia de implementação](https://docs.asaas.com/docs/pix-automatico-implementacao),
  [criar autorização](https://docs.asaas.com/reference/criar-uma-autorizacao-pix-automatico),
  [fluxos de webhook](https://docs.asaas.com/docs/fluxos-de-webhook).
  - Autorização (`POST /v3/pix/automatic/authorizations`) tem status real `CREATED → ACTIVE`
    (após o primeiro pagamento confirmar) `→ CANCELLED / REFUSED / EXPIRED`.
  - A criação já inclui um QR Code imediato (`immediateQrCode`) que cobra o primeiro ciclo **e**
    ativa o mandato ao mesmo tempo — não é um passo de "só autorizar" separado do primeiro
    pagamento.
  - Dois modos de cobrança recorrente: `MANUAL` (nossa aplicação cria cada cobrança via
    `POST /payments` com `pixAutomaticAuthorizationId`) ou `SUBSCRIPTION` (Asaas gera sozinho).
  - Webhooks de autorização: `PIX_AUTOMATIC_RECURRING_AUTHORIZATION_CREATED/ACTIVATED/CANCELLED/
    EXPIRED`.
  - **Risco assumido conscientemente**: a doc não especifica um evento distinto pra revogação
    feita pelo pagador direto no banco dele (fora do fluxo normal Asaas) — assumindo que cai como
    `CANCELLED`, a confirmar em sandbox durante a implementação.

## Decisões de escopo (brainstorm, 20/09/2026)

1. **Modo `MANUAL`, não `SUBSCRIPTION`.** Reaproveita o `SupplierBillingJob` (cron diário) que já
   existe — só troca "criar PIX avulso" por "criar cobrança referenciando a autorização". Mantém
   controle total do timing no nosso lado, sem abrir um caminho novo de sincronização com o
   agendamento do Asaas.
2. **Sem migração dos fornecedores já em PIX manual.** Marketplace ainda não está em PRD — não
   existe assinante real pra migrar. Se algum dado de QA precisar ser recriado em staging, tudo
   bem.
3. **Substitui de vez o PIX manual, não mantém os dois caminhos em paralelo.** Menos código pra
   manter, sem caminho morto. `SupplierRegistrationService`/`SupplierBillingService` passam a criar
   autorização/cobrança-com-autorização diretamente — não existe mais opção de "PIX avulso" pra
   fornecedor novo.
4. **QR Code em vez de link de pagamento na UI.** A resposta da autorização não traz uma
   `invoiceUrl` equivalente — vem `payload` (copia-e-cola) e `encodedImage` (imagem base64). Tela
   de sucesso do cadastro e `/fornecedores/gerenciar/[token]` passam a renderizar o QR Code +
   botão "copiar código Pix", no lugar do botão de link atual.

---

## Arquitetura

### Modelo de dado (`supplier_subscriptions`)

Migration nova, alterando a tabela existente (`V112__create_supplier_billing_tables.sql` já em
`staging`/`main` — isso é uma migration aditiva, não uma edição da V112):

| Campo | Tipo | Observação |
|---|---|---|
| `external_authorization_id` | VARCHAR(60) NULL | Novo — id da autorização Pix Automático no Asaas |
| `authorization_status` | VARCHAR(20) NULL | Novo — espelha o status bruto do Asaas (`CREATED`/`ACTIVE`/`CANCELLED`/`REFUSED`/`EXPIRED`), só pra observabilidade/debug |
| `qr_code_payload` | TEXT NULL | Novo — código copia-e-cola da cobrança pendente atual |
| `qr_code_image` | MEDIUMTEXT NULL | Novo — imagem do QR em base64 da cobrança pendente atual |
| `payment_link` | — | **Removido** — não existe mais link de pagamento nesse fluxo |
| `external_payment_id` | VARCHAR(60) NULL | Mantido — id do `Payment` do ciclo atual (primeiro ciclo ou renovação), como já é hoje |

`status` (`SupplierSubscriptionStatus`: `ACTIVE`/`PAST_DUE`/`CANCELED`) continua sendo o campo de
negócio que o resto do sistema já lê (admin, gating de busca, e-mail) — `authorization_status` é
só o espelho técnico do lado Asaas, não substitui.

### Fluxo 1 — Cadastro (`SupplierRegistrationService`)

Troca `asaasClient.createPayment(...)` por um novo `asaasClient.createPixAuthorization(...)`
(`POST /pix/automatic/authorizations`, `frequency=MONTHLY`, `contractId="SUPPLIER-" + supplierId`,
`startDate=hoje`, `paymentCreationMode=MANUAL`, `value=15.99`,
`immediateQrCode={originalValue: 15.99, expirationSeconds: <mesma janela de 3 dias de hoje>}`).
Guarda `externalAuthorizationId`, `qrCodePayload`, `qrCodeImage`, `authorizationStatus=CREATED`.
Mesma lógica de idempotência de hoje (não gera autorização nova se já existe uma pendente e não
vencida) se aplica igual.

### Fluxo 2 — Ativação (`PaymentReceivedHandler` + `SupplierPaymentActivationService`)

**Não muda.** A sequência real de eventos da Asaas é `PAYMENT_CREATED → PAYMENT_RECEIVED →
PIX_AUTOMATIC_RECURRING_AUTHORIZATION_ACTIVATED` — o `PAYMENT_RECEIVED` chega primeiro e já é quem
aciona `activateFromWebhook` hoje (branch `externalReference` = `SUPPLIER-{id}`, que continua
existindo já que a cobrança do primeiro ciclo também é um `Payment` normal). O evento de
autorização `ACTIVATED` só é usado pra atualizar `authorization_status` (observabilidade).

### Fluxo 3 — Ciclos recorrentes (`SupplierBillingService.chargeNextCycle`)

Quase não muda: continua criando a cobrança do próximo ciclo via `POST /payments`, só que agora
inclui `pixAutomaticAuthorizationId` no request (referencia a autorização ativa). Guarda
`qrCodePayload`/`qrCodeImage` da nova cobrança pra exibir se o fornecedor reabrir o link de gestão
antes de pagar. **Atenção na implementação**: a doc recomenda criar a instrução entre 2 e 10 dias
úteis antes do vencimento — o `PIX_DUE_DAYS = 3` atual (dias corridos) deve ser revisto nesse
momento.

### Fluxo 4 — Novo: mandato cancelado/expirado

Dois handlers novos em `webhooks/asaas/strategy/impl/` (mesmo padrão dos handlers existentes):

- `PixAutomaticAuthorizationCancelledHandler` (evento `PIX_AUTOMATIC_RECURRING_AUTHORIZATION_
  CANCELLED`)
- `PixAutomaticAuthorizationExpiredHandler` (evento `..._EXPIRED`)

Ambos: resolvem `supplierId` via `contractId` (mesmo padrão `SUPPLIER-{id}` já usado em
`externalReference`), marcam `SupplierSubscription.status = PAST_DUE`, `authorizationStatus`
atualizado, e disparam a geração de uma **autorização nova** (reaproveita a lógica do Fluxo 1) pro
fornecedor reautorizar — o mandato cancelado não pode ser "reativado", precisa de um novo QR.
Fecha a lacuna que já existia no fluxo manual (nada setava `PAST_DUE` automaticamente).

### Frontend

- `fornecedores/cadastro/page.tsx` (tela de sucesso): troca o botão "Pagar assinatura" por
  `<img src="data:image/png;base64,...">` do QR + botão "copiar código Pix" (usa a
  `qrCodePayload`).
- `fornecedores/gerenciar/[token]/page.tsx`: mesma troca no card de "Pagamento pendente".
- `publicSupplierApi.ts`: `SelfRegisterResponse`/`SupplierManageResponse` trocam `paymentLink` por
  `qrCodePayload`/`qrCodeImage`.

---

## Fora de Escopo (v1)

- Migração/upgrade de assinantes já ativos no PIX manual (não existem em PRD ainda).
- Pix Automático pro billing de **organização** — continua adiado (TASK-066).
- Modo `SUBSCRIPTION` (Asaas gerando cobrança sozinho).
- Tratamento diferenciado se a doc revelar, durante a implementação, um evento distinto pra
  revogação feita direto no banco do pagador — trata como `CANCELLED` até prova em contrário.

## Riscos

- **Evento de revogação pelo banco não confirmado na doc** — mitigar testando esse cenário
  explicitamente no sandbox Asaas durante a implementação, não só no happy path.
- **Janela de "2 a 10 dias úteis antes do vencimento"** pra criar a instrução de cobrança recorrente
  — se não respeitada, a cobrança pode ser rejeitada pelo Asaas; ajustar `SupplierBillingJob`
  quando o comportamento real for confirmado em sandbox.
- Baixo risco pro resto do sistema — domínio `supplier_billing` já é isolado (confirmado sem FK
  cruzada com billing de organização), nenhuma tabela/fluxo de organização é tocado.

## Referências
- [[project-pix-recurring-strategy]] — por que o billing de organização usa PIX detached e não
  Pix Automático ainda.
- TASK-QA-MAN-022 (C4-C9) — QA manual do fluxo atual de PIX manual, que motivou essa decisão.
