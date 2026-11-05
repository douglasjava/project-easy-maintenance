# EPIC-028 Fase 2 — Marketplace de Fornecedores (monetização)

**Data:** 11/09/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Em 07/09/2026, ao fechar o [EPIC-023](../../../roadmap/epics/EPIC-023.md), Douglas registrou que o
cadastro de fornecedores (depois desenhado como [EPIC-028](../../../roadmap/epics/EPIC-028.md), já
implementado e em `main`) **"não abre mão do case futuro de capitalizar por essa porta"** — o
desenho original deixou `Supplier` como entidade própria e extensível de propósito, exatamente pra
essa conversa acontecer sem precisar refazer a base de dado. Esta é essa conversa.

**Ideia central**: hoje um fornecedor cadastrado por uma organização já aparece de graça pra outras
organizações na busca por região, com telefone visível. Fase 2 transforma isso num marketplace de
verdade — só fornecedores que **pagam uma assinatura simbólica** (R$15,99/mês) ficam visíveis pra
organizações que não foram quem os cadastrou, e ganham um canal de contato estruturado
("Solicitar Orçamento") com as organizações que os encontram.

## Contexto (levantado antes do desenho)

- `Supplier`/`SupplierOrganizationLink` já existem (`suppliers`, dedup por `cnpj` único,
  `registration_count` como pontuação). Módulo `supplier`, autenticado (`X-Org-Id`), sem superfície
  pública hoje.
- Todo o billing de organização (`BillingAccount`/`BillingSubscription`/`Invoice`/`Payment`) é
  amarrado a `User` → `Organization`. Fornecedor não é usuário de organização — não há hoje nenhum
  jeito de cobrar uma entidade que não seja uma organização.
- O produto já tem **dois padrões de cobrança recorrente via Asaas** em produção:
  - **Cartão**: assinatura nativa do Asaas (`AsaasDTO.CheckoutSubscription`, ciclo `MONTHLY`) — o
    Asaas gera a cobrança sozinho todo ciclo, avisa via webhook.
  - **PIX**: sem assinatura nativa no Asaas — o padrão já usado (`TrialExpirationService`,
    renovação de trial/PIX) é um job mensal que gera uma cobrança PIX **detached** nova por ciclo
    (`createPixDetachedCharge`), manda o link, espera o webhook `PAYMENT_RECEIVED`.
- **Pix Automático** (mandato recorrente regulamentado pelo BACEN) está listado como
  [TASK-066](../../../roadmap/tasks/TASK-066.md), "próxima fase", **não implementado** — fora de
  cogitação pra esta fase.
- Já existe um validador `@Doc` (`commons/validation/Doc.java`) que valida CPF **ou** CNPJ num campo
  só (composição OR dos validadores `@CPF`/`@CNPJ` do Hibernate Validator, já usado no cadastro
  público de chamados do EPIC-027) — reaproveitável direto, sem criar validação nova.
- O EPIC-027 (chamados de moradores) já estabeleceu o precedente de um fluxo **público, sem conta
  tradicional**, autenticado por posse de um dado (CPF) em vez de login — mesmo espírito do "link
  mágico" desta fase.

## Decisões de escopo (brainstorm, 11/09/2026)

1. **Gatilho da cobrança**: fornecedor cadastrado por organização (fluxo já existente, gratuito)
   continua funcionando exatamente como hoje — soma pontuação, fica com dado salvo — mas **só fica
   visível pra outras organizações na busca por região se `marketplace_enabled = true`**. A própria
   organização que cadastrou continua vendo o que ela mesma registrou, sempre (é dado dela).
2. **Fornecedores cadastrados por organização viram lead de vendas**: Douglas/equipe pode contatar
   esses fornecedores por fora da plataforma e ativá-los manualmente (sem checkout), como uma forma
   inicial de popular o marketplace sem depender só de auto-cadastro orgânico.
3. **Documento aceita CPF ou CNPJ** — fornecedor pequeno/informal frequentemente não tem CNPJ.
   `Supplier.cnpj` generaliza pra `Supplier.document`, validado por `@Doc` (CPF ou CNPJ). Dedup
   continua pela mesma coluna, agora aceitando os dois formatos.
4. **"Solicitar Orçamento" é o mecanismo de contato**, não uma mensageria própria: botão de ação no
   grid de busca (ao lado de nome/categorias/pontuação) abre um modal pequeno (resumo do que a
   organização precisa), grava um `SupplierBudgetRequest` (histórico — vira dado real de demanda,
   pode alimentar ranking futuro), e monta a URL `wa.me` com a mensagem pronta, abrindo o WhatsApp
   do fornecedor. Nenhuma mensageria in-app — o canal de conversa real continua sendo o WhatsApp.
5. **Cobrança do fornecedor fica num domínio isolado do billing de organização** —
   `SupplierSubscription` nova, fora de `billing/`, reaproveitando só o `AsaasClient` (wrapper HTTP
   sem estado). Decisão explícita de não tocar em `BillingAccount`/`BillingSubscription` (área
   crítica, já responsável por bugs reais corrigidos nesta mesma sessão — TASK-209/210/244/245) só
   pra encaixar um tipo de pagador completamente diferente.
6. **Só PIX no v1** — público-alvo (fornecedor pequeno/informal) é o perfil que mais usa PIX no dia
   a dia; cartão fica pra uma fase futura, se fizer falta (o padrão de assinatura nativa do Asaas já
   existe pronto pra isso quando for a hora). Reaproveita o padrão de job mensal + cobrança PIX
   detached já usado no billing de organização.
7. **Acesso do fornecedor ao próprio cadastro é via link mágico, sem conta tradicional** — depois de
   pagar, recebe por WhatsApp/e-mail um link com token único e persistente (sem expiração por uso)
   pra editar categorias/contato e ver o status da assinatura. Mesmo espírito leve do EPIC-027, sem
   construir login/senha/JWT novo só pra fornecedor.

---

## Arquitetura

### Modelo de dado

**`Supplier`** (existente) — mudanças:

| Campo | Tipo | Observação |
|---|---|---|
| ~~`cnpj`~~ → `document` | String, único, obrigatório | Migration renomeia a coluna; validação `@Doc` (CPF ou CNPJ) no lugar de `@CNPJ` |
| `marketplace_enabled` | boolean, default `false` | Gate de visibilidade pra outras organizações |
| `activated_at` | Instant, nullable | Quando ficou `marketplace_enabled = true` |
| `activation_source` | Enum (`SELF_REGISTERED`, `MANUALLY_ACTIVATED`), nullable | Rastreia se veio de auto-cadastro pago ou ativação manual da equipe |

**`SupplierSubscription`** (nova, domínio próprio — não dentro de `billing/`):

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `supplier_id` | Long (FK, único) | 1:1 com `Supplier` |
| `status` | Enum (`ACTIVE`, `PAST_DUE`, `CANCELED`) | — |
| `external_customer_id` | String | Cliente Asaas do fornecedor |
| `external_payment_id` | String, nullable | Cobrança PIX do ciclo atual |
| `current_period_end` | LocalDate | Quando vence o ciclo atual |
| `created_at`/`updated_at` | Instant | — |

**`SupplierAccessToken`** (nova):

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `supplier_id` | Long (FK) | — |
| `token` | String, único, longo/aleatório | Sem expiração por uso — revogável manualmente se preciso |
| `created_at` | Instant | — |

**`SupplierBudgetRequest`** (nova — o log de "Solicitar Orçamento"):

| Campo | Tipo | Observação |
|---|---|---|
| `id` | Long | PK |
| `supplier_id` | Long (FK) | — |
| `organization_code` | String (FK) | Quem solicitou |
| `requested_by_user_id` | Long (FK) | — |
| `summary` | Text | O que a organização escreveu no modal |
| `created_at` | Instant | — |

### Fluxos

**1. Auto-cadastro do fornecedor** (público, sem conta):
`POST /public/suppliers/register` → valida `document` (`@Doc`) → dedup igual já existe hoje (se o
`document` já tem `Supplier`, reaproveita o registro existente em vez de duplicar) → cria/atualiza
`SupplierSubscription` (`status=PAST_DUE` até o primeiro pagamento) → gera cobrança PIX detached via
`AsaasClient` → retorna o link de pagamento. No webhook `PAYMENT_RECEIVED` (handler novo, filtra por
prefixo de `externalReference` distinto do billing de organização, ex. `SUPPLIER-<id>` vs.
`BILLING-<id>` já usado hoje): `SupplierSubscription.status = ACTIVE`,
`Supplier.marketplace_enabled = true`, `activation_source = SELF_REGISTERED`, gera
`SupplierAccessToken` e envia o link por WhatsApp/e-mail.

**2. Cobrança recorrente** (job mensal novo, mesmo padrão do `TrialExpirationService`):
para cada `SupplierSubscription` com `status = ACTIVE` e `current_period_end` vencendo, gera uma
nova cobrança PIX detached, envia lembrete por WhatsApp. Prazo de graça de **3 dias corridos** após
o vencimento antes de suspender — mesmo valor já usado (e validado em produção) pro corte de acesso
de organização em atraso (`billing.blocking.days-after-due`, TASK-236), reaproveitado aqui por
consistência em vez de inventar um número novo. Depois do prazo sem pagar: `status = PAST_DUE`,
`Supplier.marketplace_enabled = false` (some da busca pras outras organizações até pagar de novo —
o registro e a pontuação continuam intactos).

**3. Busca por região** (`GET /suppliers`, endpoint já existente): passa a filtrar
`marketplace_enabled = true` **exceto** para a organização que originalmente cadastrou o fornecedor
(via `SupplierOrganizationLink` já existente) — ela sempre vê o que ela mesma registrou.

**4. Solicitar Orçamento** (autenticado, dentro do grid já existente): botão de ação nova ao lado
dos dados do fornecedor → modal com campo de resumo → `POST /suppliers/{id}/budget-request` grava
`SupplierBudgetRequest` → frontend monta `https://wa.me/<telefone>?text=<mensagem>` com o resumo e
abre em nova aba.

**5. Ativação/cancelamento manual** (admin, `/private`): ação nova em `AdminBillingController` (ou
controller próprio) que define `marketplace_enabled = true`, `activation_source = MANUALLY_ACTIVATED`,
`activated_at = now()` — sem criar `SupplierSubscription`/cobrança (combinado fora da plataforma).
O mesmo painel serve pra desativar (`marketplace_enabled = false`) qualquer fornecedor — inclusive
os que pagaram (`SupplierSubscription.status = CANCELED`) — já que cancelamento self-service está
fora de escopo nesta v1 (decisão de escopo).

**6. Gestão do próprio cadastro** (fornecedor, via link mágico): rota pública
`GET /public/suppliers/manage/{token}` — mostra dado atual (categorias, contato, status da
assinatura), permite editar contato/categorias. Sem exigir token novo a cada acesso.

### Backend — dentro do módulo `supplier` existente + domínio novo `supplier_billing`

- `supplier/domain/Supplier.java` — migration renomeia `cnpj`→`document`, adiciona
  `marketplace_enabled`/`activated_at`/`activation_source`.
- `supplier/domain/SupplierBudgetRequest.java` (novo) + repository.
- `supplier_billing/domain/{SupplierSubscription,SupplierAccessToken}.java` (novo módulo) +
  repositories.
- `supplier_billing/application/service/SupplierRegistrationService.java` — auto-cadastro + dedup.
- `supplier_billing/application/service/SupplierBillingJob.java` (+ `SupplierBillingService`,
  mesmo padrão `Job`/`service` já usado em `jobs/`) — cobrança mensal.
- `supplier_billing/infrastructure/web/` — controller público de auto-cadastro/gestão, controller
  autenticado de "Solicitar Orçamento".
- Webhook: novo handler (ou branch no handler existente) reconhecendo `externalReference` com
  prefixo `SUPPLIER-`.

### Frontend

- Página pública nova (`/fornecedores/cadastro` ou similar) — formulário de auto-cadastro +
  redirecionamento pro checkout Asaas.
- Página pública nova (`/fornecedores/gerenciar/{token}`) — gestão via link mágico.
- Tela `/fornecedores` (já existe) — botão "Solicitar Orçamento" no grid + modal.
- Área admin (`/private`) — ação de ativação manual (dentro de uma tela já existente ou nova, a
  definir na implementação).

---

## Fora de Escopo (v1)

- Cartão como método de pagamento (padrão de assinatura nativa do Asaas já existe pronto, fica pra
  quando/se fizer falta).
- Avaliação explícita (nota/comentário) do fornecedor — pontuação continua só `registration_count`;
  `SupplierBudgetRequest` fica registrado mas não vira métrica de ranking ainda nesta fase (dado
  disponível pra decisão futura).
- Mensageria in-app entre organização e fornecedor — o canal real é WhatsApp, fora da plataforma.
- Dashboard/portal completo do fornecedor (histórico de solicitações recebidas, métricas) — a
  página de gestão via link mágico cobre só edição de cadastro + status da assinatura.
- Pix Automático — cobrança recorrente usa o padrão detached-por-ciclo já existente, não o mandato
  regulamentado (TASK-066, não implementado).
- Cancelamento self-service pelo fornecedor — nesta v1, cancelamento passa por contato (mesmo canal
  que a ativação manual usa).

## Riscos

- **Reconciliação de dado existente**: fornecedores já cadastrados por organizações antes desta fase
  têm `marketplace_enabled = false` por padrão (migration não ativa nada automaticamente) — a busca
  por região vai "esvaziar" pra quem não é o dono do cadastro até a ativação (orgânica ou manual)
  acontecer. Efeito colateral esperado e aceito (é o próprio mecanismo da mudança), mas vale
  comunicar antes de subir pra staging/produção — pode gerar confusão ("cadê os fornecedores que
  apareciam antes?") se não avisado.
- **Job de cobrança mensal novo**: mesma classe de risco que qualquer job financeiro recorrente —
  precisa de idempotência (não gerar 2 cobranças pro mesmo ciclo) desde o desenho, não como correção
  depois (lição direta das TASK-244/245 desta mesma sessão).
- **Webhook único do Asaas precisa distinguir organização de fornecedor** — se o prefixo de
  `externalReference` não for checado com cuidado, um webhook de cobrança de fornecedor pode ser
  processado pelo handler de billing de organização (ou vice-versa). Handler novo precisa de teste
  explícito pra esse cenário de ambiguidade.
- Baixo risco pro billing de organização em si — domínio isolado de propósito (decisão de escopo
  #5), nenhuma tabela/serviço existente de billing é alterado.
