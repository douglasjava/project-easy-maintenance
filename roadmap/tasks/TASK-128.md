# TASK-128 — Backend: Webhook de status de entrega/leitura do WhatsApp Cloud API (Meta)

## Tipo
BACKEND

## Categoria
Notificações / Integração Externa / Segurança

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — endpoint público exposto à internet, validação de assinatura é a única barreira contra forjar
eventos, e o resultado alimenta rastreamento de custo/compliance com a Meta.

---

## Contexto

Parte do [EPIC-015](../epics/EPIC-015.md) (Notificações via WhatsApp), que já decidiu usar a **Meta
Cloud API direta** (sem BSP), com número remetente `+55 31 97213-9145`. A tabela
`business_whatsapp_dispatches` (entidade `BusinessWhatsAppDispatch`) é criada pela **TASK-130**
(orquestração/idempotência) — esta task estende essa mesma tabela com colunas de status de entrega.

Ir direto com a Meta (sem BSP) significa que **não existe um painel de terceiro cuidando de status de
entrega/leitura** — o Easy Maintenance precisa do próprio webhook para receber esses callbacks da Graph
API (`entry[].changes[].value.statuses[]`) e, se o cliente responder, mensagens inbound
(`entry[].changes[].value.messages[]`). Sem isso, não há como saber se uma notificação de vencimento
enviada por WhatsApp foi de fato entregue, lida, ou falhou (ex.: erro 130497, já visto em teste — limite
de mensagens business-initiated por número).

### Levantamento do padrão existente (Asaas)

O sistema já tem um webhook em produção — `webhooks/asaas/` — que deve servir de referência de
**estrutura**, mas com uma lacuna de segurança real que **não deve ser copiada**:

- `AsaasWebhookController` (`webhooks/asaas/controller/AsaasWebhookController.java`) só verifica se o
  secret configurado no próprio servidor não está vazio — **nunca compara nenhum header/token do request
  recebido**. Não há validação de assinatura HMAC em nenhum lugar do código hoje (confirmado por busca no
  repositório). A Meta exige dois mecanismos que o Asaas não tem: handshake `GET` de verificação
  (`hub.mode`/`hub.verify_token`/`hub.challenge`) e assinatura `X-Hub-Signature-256` (HMAC-SHA256 com o
  App Secret) em todo `POST`. **Esta task deve implementar essa validação de verdade**, não repetir o
  padrão frouxo do Asaas.
- As tabelas genéricas `webhook_event`/`webhook_dlq` (Flyway `V37`/`V67`) não têm coluna de provider e
  `WebhookDlqService.replay()` está hardcoded para o tipo Asaas (`AsaasDTO.WebhookCheckoutEvent`) — **não
  são reaproveitáveis como estão** para o WhatsApp sem generalizar essas classes (fora do escopo desta
  task; ver "Riscos").
- Em vez de criar uma tabela paralela de log ("WhatsappNotificationLog"), a recomendação é **estender a
  tabela `business_whatsapp_dispatches`** (criada pela TASK-130) com colunas de status de entrega —
  ligando o evento do webhook de volta ao registro do envio outbound pelo `wamid` (message id retornado
  pela Meta no momento do envio). Evita duas tabelas rastreando a mesma mensagem.
- `WhatsAppNotificationProvider` (`infrastructure/notification/provider/`) já existe como stub (só loga,
  `// TODO`) — é o componente que a **TASK-129** vai implementar para o envio; esta task cuida só do
  caminho inverso (callback da Meta → nosso backend).

---

## Objetivo

Implementar o endpoint de webhook que recebe callbacks de status de entrega/leitura/falha (e mensagens
inbound) da WhatsApp Cloud API para as notificações de vencimento enviadas via templates (TASK-129/
TASK-130), com verificação de assinatura real e persistência ligada ao envio original via `wamid`.

---

## Escopo

### 1. Estrutura de pacotes (proposta — validar antes de implementar por completo)

Novo pacote `webhooks/whatsapp/`, mirrorando a organização de `webhooks/asaas/` (controller/service/dto),
mas **sem reaproveitar** `webhook_event`/`webhook_dlq` nem a validação fraca do `AsaasWebhookController`:

```
webhooks/whatsapp/
├── controller/WhatsAppWebhookController.java   — GET (handshake) + POST (eventos), mesmo path
├── service/WhatsAppWebhookService.java         — parsing, persistência, @Async no processamento pesado
├── security/WhatsAppSignatureValidator.java    — HMAC-SHA256 sobre o corpo bruto da requisição
└── dto/WhatsAppWebhookDTO.java                 — records aninhados (mirror do padrão AsaasDTO),
                                                   @JsonIgnoreProperties(ignoreUnknown = true)
```

### 2. Handshake de verificação (GET)

- Endpoint `GET /easy-maintenance/api/v1/public/webhooks/whatsapp` (mesmo prefixo `public/webhooks/`
  usado pelo Asaas, por consistência de `SecurityConfig`/`TenantFilter`).
- Lê os query params `hub.mode`, `hub.verify_token`, `hub.challenge`.
- Compara `hub.verify_token` com a env var `WHATSAPP_WEBHOOK_VERIFY_TOKEN` (comparação constant-time,
  não `String.equals` simples, para evitar timing attack).
- Se bater **e** `hub.mode == "subscribe"`: responde `200` com `hub.challenge` como texto puro
  (`Content-Type: text/plain`, sem envelope JSON — a Meta exige o valor cru).
- Caso contrário: `403`.

### 3. Recebimento de eventos (POST)

- Mesmo path do handshake, método `POST`.
- Parseia o payload em DTOs dedicados: `entry[].changes[].value.statuses[]` (status de
  sent/delivered/read/failed) e `entry[].changes[].value.messages[]` (mensagens inbound, se o cliente
  responder — v1 só precisa logar/persistir, sem lógica de resposta automática).
- Para cada status recebido, persistir (ver item 5): `wamid`, telefone do destinatário, status, timestamp
  da Meta, e — se `failed` — código e mensagem de erro (ex.: `130497`, já visto em teste real).
- Responde `200` imediatamente após validar a assinatura (a Meta espera ack rápido e reenvia se não
  receber 200 a tempo); qualquer processamento mais pesado (ex.: disparar evento de domínio, notificar
  admin em caso de falha recorrente) deve ser assíncrono, seguindo o mesmo padrão `@Async` já usado em
  `AsaasWebhookService`.

### 4. Segurança (obrigatório, não opcional)

- Validar o header `X-Hub-Signature-256` em todo `POST` recebido: HMAC-SHA256 do corpo bruto da
  requisição usando o Meta App Secret (`WHATSAPP_APP_SECRET`), comparado em constant-time com a
  assinatura recebida (prefixo `sha256=`).
- Requisição com assinatura ausente ou inválida → `403`, sem processar o payload.
- **Nunca logar** o access token (`WHATSAPP_API_TOKEN`) nem o App Secret em nenhum nível de log —
  inclusive em mensagens de erro/stacktrace (cuidado com `toString()` de configs/exceptions que
  encapsulem essas variáveis).

### 5. Persistência — estender `business_whatsapp_dispatches` (não criar tabela paralela)

- Assumindo que a TASK-130 já criou `BusinessWhatsAppDispatch`/`business_whatsapp_dispatches`: nova
  migration Flyway adicionando colunas de status de entrega a essa tabela (não uma tabela nova de
  "log"): `wamid` (indexado, para lookup rápido no callback), `delivery_status`
  (`SENT`/`DELIVERED`/`READ`/`FAILED`), `delivered_at`, `read_at`, `failed_error_code`,
  `failed_error_message`.
- Se a TASK-130 ainda não tiver sido implementada quando esta task começar: propor a migration junto
  (coordenar para não gerar duas migrations conflitantes na mesma tabela).
- Idempotência: a Meta pode reenviar o mesmo evento de status mais de uma vez — o update por `wamid`
  deve ser idempotente (ex.: não regredir `READ` de volta para `DELIVERED` se um evento atrasado chegar
  fora de ordem).

### 6. Config

Novas variáveis de ambiente (nunca hardcoded, nunca commitadas — mesmo padrão de segredos já usado para
MailerSend/Asaas, ver TASK-010):
- `WHATSAPP_API_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_WABA_ID`
- `WHATSAPP_WEBHOOK_VERIFY_TOKEN`
- `WHATSAPP_APP_SECRET`

### 7. Testes

- Unitário: validação de assinatura (`WhatsAppSignatureValidator`) — caso válido e caso inválido
  (assinatura forjada/corpo alterado).
- Unitário: handshake de verificação — token batendo (retorna challenge) e não batendo (403).
- Unitário: parsing de um payload de exemplo de status update (`delivered`/`read`) e de um payload de
  falha real usando o formato do erro `130497` como fixture.
- Unitário: idempotência do update por `wamid` (evento duplicado não duplica registro nem regride
  status).

---

## Arquivos impactados (estimativa)

### Backend
- `webhooks/whatsapp/controller/WhatsAppWebhookController.java` — **novo**
- `webhooks/whatsapp/service/WhatsAppWebhookService.java` — **novo**
- `webhooks/whatsapp/security/WhatsAppSignatureValidator.java` — **novo**
- `webhooks/whatsapp/dto/WhatsAppWebhookDTO.java` — **novo**
- `infrastructure/notification/domain/BusinessWhatsAppDispatch.java` — alterar (colunas de status, da
  TASK-130)
- `infrastructure/notification/repository/BusinessWhatsAppDispatchRepository.java` — alterar (lookup por
  `wamid`)
- `db/migration/V9x__add_delivery_status_to_business_whatsapp_dispatches.sql` — **novo**
- `SecurityConfig.java` — liberar `public/webhooks/whatsapp` (mesmo padrão do Asaas)
- `TenantFilter.java` — bypass de tenant filtering para o novo path (mesmo padrão do Asaas)
- `application.yml` / variáveis de ambiente — 5 novas env vars (item 6 do Escopo)

---

## Critérios de Aceite

- [x] `GET` no endpoint responde `hub.challenge` com `200` quando `hub.verify_token` bate e
      `hub.mode == "subscribe"`; responde `403` em qualquer outro caso
- [x] `POST` sem `X-Hub-Signature-256` válido é rejeitado com `403` e não processa o payload
- [x] `POST` com assinatura válida persiste `wamid`, telefone, status e timestamp corretamente
- [x] Payload de falha (ex.: erro `130497`) persiste código e mensagem de erro
- [x] Endpoint responde `200` rapidamente (sem aguardar processamento pesado, que roda assíncrono)
- [x] Evento de status duplicado (mesmo `wamid` reenviado pela Meta) não duplica registro nem regride
      status já mais avançado
- [x] Nenhum segredo (`WHATSAPP_API_TOKEN`/`WHATSAPP_APP_SECRET`) aparece em log, stacktrace ou resposta
      de erro
- [x] Nenhum segredo do provedor commitado no repositório
- [x] Testes unitários cobrindo assinatura, handshake, parsing (sucesso + falha) e idempotência

## Dependências
- **TASK-130** — precisa da tabela `business_whatsapp_dispatches` existir (ou ser criada em conjunto)
  para o `wamid` fazer sentido; a implementação do endpoint em si (handshake, validação de assinatura,
  parsing) pode começar em paralelo, mas o vínculo com o envio real só fecha depois da TASK-130.
- **TASK-129** — provider WhatsApp configurado (o `wamid` só existe depois de um envio real acontecer)
- TASK-010 (auditoria/rotação de segredos) — padrão a seguir para as 5 novas env vars

## Riscos
- Reaproveitar `webhook_event`/`webhook_dlq` (tabelas do Asaas) sem generalizar `WebhookDlqService`
  causaria colisão de `provider_event_id` e comportamento incorreto no replay — por isso esta task usa
  uma tabela dedicada, e não essas tabelas genéricas.
- Verify token ou assinatura mal configurados impedem a Meta de validar o webhook — sem isso, **nenhum**
  callback de status chega, mesmo com o resto do endpoint correto (falha silenciosa do ponto de vista do
  usuário: notificações continuam sendo enviadas, mas o sistema nunca sabe se chegaram).
- Endpoint público mal protegido (sem validação de assinatura) permite forjar eventos de entrega/leitura
  — mitigado pelo item 4 do Escopo, que é obrigatório e não pode ser adiado para "fase 2".

## Esforço
Médio (endpoint + segurança + migration + testes — menor que a TASK-130, mas depende dela para fazer
sentido em produção)

## Status
Em Validação — implementado em `feature/TASK-128-whatsapp-webhook-status`, 31 testes novos,
672/672 testes backend green. Não testado contra a Meta real (pendente HTTPS público +
configuração das env vars em produção + registro da URL no App do Meta).
