# TASK-157 — Meta Conversions API (CAPI): dedupe de Lead + sinal de qualidade (CONTACTED/CONVERTED)

## Tipo
FULL_STACK (backend: cliente CAPI + 2 pontos de disparo; frontend: `event_id` compartilhado com o
Pixel + captura de `_fbp`/`_fbc`)

## Categoria
Marketing / Tracking

## Prioridade
🟡 Médio

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim — validar (1) que o evento server-side dedupe corretamente com o client-side no Test Events do
Meta (mesmo `event_id`, sem contagem duplicada), (2) que os eventos de qualidade disparam nas
transições certas de status, (3) que falha na chamada à Meta nunca impede salvar o lead/mudar o
status.

---

## Contexto

Escopo original desta task (30/07/2026) era só reenviar o evento `Lead` do backend, deduplicado com
o Pixel client-side, para compensar perda de eventos por ad blocker/ITP — ver `LeadService.createLead`.

Motivação nova (26/08/2026): o Ads Manager oferece a meta de otimização "Maximizar leads
qualificados", que reduz custo por lead de qualidade (~9,5% no teste da conta) — mas ela só funciona
se a Meta receber, além do `Lead` inicial, um sinal de *qualidade* vindo de fora do clique no
anúncio. A tela "Conectar CRM" da Meta oferece dois caminhos: parceiros no-code (Zapier, HubSpot, RD
Station etc. — todos pagos além de um tier gratuito limitado) ou conexão manual via Conversions API.

**Descopo desta rodada:** o Google Enhanced Conversions, que fazia parte do escopo original desta
task, sai daqui — Google Tag nem está instalado ainda (sem ID, ver EPIC-018) e a conversa que gerou
essa atualização foi só sobre a tela de "Conectar CRM" da Meta. Fica registrado como pendência
separada, sem task própria ainda (não inventar número/arquivo sem necessidade real).

Decisão de escopo: **conexão manual**, não parceiro. O motivo é que o "CRM" de leads já existe no
próprio backend — `LandingLead` (`easy-maintenance-api/leads`) já tem o pipeline de qualificação
completo (`LeadStatus`: `NEW → CONTACTED → CONVERTED/LOST`, mudado via `LeadAdminService.updateStatus`
/ `PATCH /admin/leads/{id}/status`). Pagar um parceiro para retransmitir um status que já mora no
banco de dados de vocês seria custo e dependência redundantes.

---

## Objetivo

1. Reenviar o evento `Lead` a partir do backend no momento da criação (`LeadService.createLead`),
   deduplicado via `event_id` compartilhado com o Pixel client-side (escopo original, sem mudança).
2. Enviar um evento de qualidade à Meta quando um lead muda de status via
   `LeadAdminService.updateStatus` — `CONTACTED` e `CONVERTED` — para alimentar a otimização de
   "leads qualificados".

---

## Escopo

### 1. Migração
- `V97__add_meta_capi_fields_to_landing_leads.sql`:
  `ALTER TABLE landing_leads ADD COLUMN event_id VARCHAR(64) NULL, ADD COLUMN fbp VARCHAR(64) NULL,
  ADD COLUMN fbc VARCHAR(64) NULL;`
  (`event_id` é o identificador de dedupe compartilhado com o Pixel; `fbp`/`fbc` são os cookies que a
  Meta seta no navegador e melhoram a taxa de match do CAPI — sem eles o evento ainda funciona, só
  com match rate menor via email/telefone/IP/UA.)

### 2. Frontend (`easy-maintenance-web`)
- `src/lib/tracking.ts`: `trackLead()` passa a aceitar um `eventId` (gerado com
  `crypto.randomUUID()` no submit do formulário) e repassá-lo como terceiro argumento do `fbq`
  (`fbq('track', 'Lead', {}, { eventID })`) — é esse ID que permite ao Meta descartar a cópia
  duplicada quando o mesmo evento chegar também pelo CAPI.
- Form de demonstração (`landing/page.tsx`): gera o `eventId`, lê os cookies `_fbp`/`_fbc` (já
  setados pelo Pixel; não recalcular `_fbc` manualmente a partir do `fbclid` — usar o cookie que a
  própria Meta já gerencia), e envia os três campos (`eventId`, `fbp`, `fbc`) no `CreateLeadRequest`.
- Sem esses três valores o backend não quebra — todos opcionais, evento sai só com os dados de
  contato hasheados.

### 3. Domínio / DTO
- `LandingLead`: novos campos `eventId`, `fbp`, `fbc`.
- `CreateLeadRequest`: novos campos opcionais `eventId`, `fbp`, `fbc`.

### 4. Cliente Meta CAPI (backend)
- Novo `MetaCapiClient` (`infrastructure/meta` ou junto de `infrastructure/notification`), no mesmo
  estilo do `WhatsAppClient` já existente: `WebClient` próprio, timeout por chamada, classificação de
  erro (permanente vs. transitório), sem retry agressivo (falha aqui nunca deve travar o fluxo
  principal).
- `MetaCapiProperties` (`@ConfigurationProperties(prefix = "meta-capi")`):
  `meta-capi.access-token=${META_CAPI_ACCESS_TOKEN:}`,
  `meta-capi.dataset-id=${META_CAPI_DATASET_ID:}`,
  `meta-capi.base-url=https://graph.facebook.com/v21.0` (mesma versão de Graph API já usada pelo
  `WhatsAppClient`).
- Payload: `email`/`phone` com hash SHA-256 (lowercase + trim, conforme spec da Meta), mais
  `client_ip_address`, `client_user_agent`, `fbp`, `fbc`, `event_id`, `event_source_url`,
  `action_source: "website"`. **Nunca logar o hash nem o valor original de email/telefone** — só
  contadores/IDs de lead nos logs.
- Chamada síncrona com timeout (10s, mesmo padrão do `WhatsAppClient`) — quem garante que a falha
  não bloqueia o fluxo principal é o chamador (`LeadService`/`LeadAdminService`), com `try/catch`
  ao redor da chamada, exatamente como o `BusinessWhatsAppNotificationService` já faz ao redor do
  `WhatsAppClient`. Sem `@Async`/reativo fire-and-forget — não havia precedente disso no código e
  acrescentaria complexidade sem necessidade real.

### 5. Ponto de disparo 1 — `LeadService.createLead`
- Após salvar o lead, dispara evento padrão `Lead`. O `event_id` vem do frontend (gerado no submit
  do formulário); se ausente, o evento sai sem `event_id` (sem dedupe com o Pixel, mas ainda válido
  — não há fallback de geração no backend, não implementado por não ser necessário hoje).

### 6. Ponto de disparo 2 — `LeadAdminService.updateStatus`
- Transição para `CONTACTED` → evento customizado `LeadQualified`.
- Transição para `CONVERTED` → evento customizado `LeadConverted`.
- **Decisão pendente com Douglas:** hoje `CONVERTED` é uma marcação manual do time comercial, sem
  vínculo automático com o lead virar de fato uma organização paga (não existe FK entre
  `LandingLead` e `BillingAccount`/`User`). Por isso o evento sai **sem** `value`/`currency` — não
  usar o evento padrão `Purchase` até existir esse vínculo real. Se Douglas quiser valor monetário
  real no evento, é uma task separada (linkar lead → billing account no onboarding).
- Sem disparo para `NEW` (estado inicial, já coberto pelo `Lead` da criação) nem para `LOST`
  (sinal negativo não pedido pela Meta nesse fluxo; reavaliar se quiserem sinalizar leads ruins
  explicitamente).

### 7. Testes
- `Sha256HasherTest`: normalização (trim/lowercase), determinismo, formato hex de 64 chars.
- `MetaCapiPayloadBuilderTest`: payload puro — hash de email/telefone, omissão de chaves quando o
  campo está ausente, `event_source_url`/`event_id` corretos.
- `LeadServiceTest`: `createLead` aciona o client com o `event_id`/`fbp`/`fbc` recebidos; falha do
  client não impede o lead de ser salvo.
- `LeadAdminServiceTest`: `updateStatus` para `CONTACTED`/`CONVERTED` aciona o evento certo; para
  `NEW`/`LOST` não aciona nada; falha do client não impede a atualização de status.
- `MetaCapiClientImpl` (a implementação real que fala com a Graph API) **não tem teste dedicado** —
  mesmo padrão já aplicado a `WhatsAppClient`/`AsaasClient` neste repo (sem WireMock/MockWebServer
  como dependência de teste); a lógica determinística (hash, payload) está coberta acima.
- Frontend: `metaCapi.test.ts` (novo) e `tracking.test.ts` (estendido) cobrem os helpers de
  cookie/eventID. `landing/page.tsx`/`ObrigadoContent.tsx` não têm teste de componente — mesma
  limitação já registrada no design original do EPIC-018.

---

## Como obter as credenciais (`META_CAPI_ACCESS_TOKEN` / `META_CAPI_DATASET_ID`)

1. Acessar o [Events Manager](https://business.facebook.com/events_manager2) da conta de anúncios
   já usada pela campanha em produção (`act=1601481751594170`, mesma conta da tela de "Conectar
   CRM" já discutida).
2. Selecionar o dataset **`Dados_EasyMaintenance_Web`** — é o mesmo conjunto de dados que o Pixel
   client-side já usa (não é preciso criar um novo).
3. **Dataset ID**: é o mesmo número já configurado como `NEXT_PUBLIC_META_PIXEL_ID` no frontend
   (visível no topo da página do Events Manager, "ID do Pixel"/"ID do conjunto de dados" — Meta
   unificou os dois conceitos, um pixel e seu dataset de CAPI compartilham o mesmo ID).
4. **Access Token**: na mesma página, aba **Configurações** → seção **Conversions API** → botão
   "Gerar token de acesso" (às vezes rotulado "Generate access token"). Copiar o valor mostrado —
   ele só aparece uma vez.
5. Configurar as duas variáveis no ambiente do **Railway** (serviço `easy-maintenance-api`), mesmo
   lugar onde `WHATSAPP_API_TOKEN` já está configurado hoje — ver `docs/INFRAESTRUTURA-TECNICA.md`:
   - `META_CAPI_ACCESS_TOKEN` = o token gerado no passo 4
   - `META_CAPI_DATASET_ID` = o ID do passo 3
6. Não é preciso redeploy de código — só reiniciar o serviço depois de adicionar as variáveis (o
   Railway costuma reiniciar sozinho ao salvar novas env vars).

**Tratar o access token como segredo** (mesmo nível de cuidado que `WHATSAPP_API_TOKEN`/`ASAAS_API_KEY`)
— nunca colar em chat, PR, ou commit.

---

## Bloqueado por (credenciais que Douglas precisa levantar para ativar em produção)

- Meta: access token do Conversions API + Dataset ID (Events Manager → Configurações → Conversions
  API → "Gerar token de acesso") — **código já implementado e no-op sem essas credenciais** (mesma
  diretriz do TASK-156 para o Pixel: infraestrutura pronta, nada hardcoded, ativa assim que
  `META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` forem configurados no ambiente).
- Confirmar que `/privacidade` cobre o envio de email/telefone (mesmo hasheado) para a Meta via CAPI
  — ver ressalva de LGPD já registrada em `docs/produto/contexto-trafego-pago.md`. Sem isso
  confirmado, não ativar em produção mesmo com as credenciais em mãos.

---

## Critérios de Aceite

- [x] Evento `Lead` enviado ao Meta CAPI a partir do backend, com `event_id` igual ao usado no pixel
      client-side (dedupe real no Ads Manager/Test Events só é verificável com credenciais reais —
      código e testes cobrem a lógica; validação end-to-end fica para QA após TASK-157 ser ativada)
- [x] Evento `LeadQualified` enviado quando um lead muda para `CONTACTED`
- [x] Evento `LeadConverted` enviado quando um lead muda para `CONVERTED` (sem `value`/`currency`,
      ver decisão pendente acima)
- [x] Nenhum disparo para transição para `NEW` ou `LOST`
- [x] Falha no envio a qualquer momento é best-effort — não bloqueia criação de lead nem mudança de
      status, e fica logada (sem PII em texto plano)
- [x] Nenhuma credencial hardcoded — via variável de ambiente/secret (`META_CAPI_ACCESS_TOKEN`,
      `META_CAPI_DATASET_ID`)
- [x] `fbp`/`fbc`/`eventId` são opcionais em `CreateLeadRequest` — lead sem eles continua sendo
      criado e o evento sai só com email/telefone hasheados + IP/UA

## Dependências
- **TASK-156** — pixel client-side básico instalado e validado primeiro.
- Credenciais e decisão de nomenclatura de evento (`LeadQualified`/`LeadConverted`) confirmadas com
  Douglas antes de escopar sprint.

## Riscos
- Enviar dado pessoal (mesmo hasheado) à Meta é compartilhamento com terceiro — exige checar a
  Política de Privacidade antes de ligar em produção (ver bloqueio acima).
- `CONVERTED` sem vínculo com billing real pode gerar sinal de qualidade impreciso para a Meta se o
  time comercial marcar leads como convertidos de forma inconsistente — vale alinhar critério de
  quando marcar `CONTACTED`/`CONVERTED` com quem usa o admin de leads no dia a dia.
- Sem `fbp`/`fbc` (lead que nunca carregou o Pixel antes, ex. cadastro manual/WhatsApp) o match rate
  cai — aceitável, é o mesmo trade-off documentado para qualquer implantação de CAPI.

## Esforço
Médio — migration + client novo (reaproveitando o padrão já validado do `WhatsAppClient`) + 2 pontos
de disparo + mudança pequena no frontend (event_id + leitura de cookies). Menor incerteza que a
estimativa original porque o pipeline de status (`LeadStatus`) e o padrão de cliente HTTP best-effort
já existem no código.

## Status
Implementada em `feature/TASK-157-meta-capi` (ambos os repos, 26/08/2026) — TDD: `Sha256HasherTest`,
`MetaCapiPayloadBuilderTest`, `LeadServiceTest`/`LeadAdminServiceTest` estendidos (backend), `tracking.test.ts`
estendido + `metaCapi.test.ts` novo (frontend). Suíte completa do backend (`mvn test`) e do frontend
(`npx jest`) passando sem regressão; `npm run build` (Next.js) verde.

**QA manual aprovado por Douglas em 26/08/2026** — os 7 cenários do
[TASK-QA-MAN-015](../QA/tasks/TASK-QA-MAN-015.md) validados, incluindo Parte B com credenciais reais
(`META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` configuradas, eventos `Lead`/`LeadQualified`/
`LeadConverted` confirmados no Test Events da Meta, dedupe com o Pixel funcionando). Mergeado em
`staging`: [api#51](https://github.com/douglasjava/easy-maintenance-api/pull/51),
[web#56](https://github.com/douglasjava/easy-maintenance-web/pull/56). Promovido pra `main`:
[api#52](https://github.com/douglasjava/easy-maintenance-api/pull/52),
[web#57](https://github.com/douglasjava/easy-maintenance-web/pull/57).

**Confirmado em produção (Railway) em 26/08/2026, 21:47-21:50** — Douglas configurou
`META_CAPI_ACCESS_TOKEN`/`META_CAPI_DATASET_ID` reais no serviço `easy-maintenance-api` e gerou um
lead de teste real (`samueloliveira@gmail.com`, lead id 22) passando pelas três transições. Log de
produção confirma os três envios com sucesso, sem nenhum `WARN`/falha:
`Lead` (21:47:21) → `LeadQualified` (21:49:10) → `LeadConverted` (21:50:19). TASK-157 está
**ativa e funcionando de ponta a ponta em produção** — não é mais só código, os eventos chegam de
verdade na Meta. Próximo passo não é mais técnico: manter o hábito de atualizar o status dos leads
em `/private/admin/leads` é o que faz a Meta acumular sinal de qualidade suficiente para liberar a
otimização "Maximizar leads qualificados".
