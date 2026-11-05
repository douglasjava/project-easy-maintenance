# TASK-QA-MAN-010 — QA Manual: E2E fluxo completo de notificações WhatsApp (EPIC-015)

## Tipo
QA Manual

## Categoria
Backend / Notificações / Integração Externa (WhatsApp Cloud API)

## Prioridade
🟠 Alto

## Épico
[EPIC-015](../../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Tasks cobertas
. [TASK-122](../../tasks/TASK-122.md) (telefone/opt-in) 
· [TASK-129](../../tasks/TASK-129.md) (envio via Meta)
· [TASK-130](../../tasks/TASK-130.md) (urgência/idempotência/fallback) 
· [TASK-131](../../tasks/TASK-131.md) (quota/rate-limit/horário) 
· [TASK-128](../../tasks/TASK-128.md) (webhook de status)
· [TASK-132](../../tasks/TASK-132.md) (endpoints de disparo manual usados nesta suíte)

---

## Descrição

Validação end-to-end de todo o EPIC-015, do opt-in do usuário até o retorno de status de
entrega/leitura via webhook — cobrindo os cenários que o teste automatizado não cobre sozinho
porque dependem de **tempo real** (checkpoints de vencimento, janela de horário comercial) e da
**Meta real** (assinatura de webhook, resposta de envio). Como não existe endpoint de simulação
para os jobs de detecção/envio (só rodam via cron), esta suíte usa duas rotas novas de disparo
manual (TASK-132) + queries SQL diretas para montar cada cenário sem precisar esperar o
relógio/cron.

---

## Pré-condições

- Ambiente: staging (`{BASE_URL}` = URL base da API, ex.: `https://api-staging.easymaintenance.com.br`)
- Acesso ao banco de staging (mysql client, DBeaver, TablePlus etc.)
- Token JWT válido de um usuário staging (`Authorization: Bearer {JWT}`) — os endpoints
  `/run-jobs/*` exigem autenticação e (por comportamento pré-existente, não específico desta
  task) um header `X-Org-Id` válido, mesmo o job sendo cross-tenant por dentro; qualquer
  `X-Org-Id` de uma organização à qual o usuário pertença serve.
- Valores configurados em staging: `WHATSAPP_WEBHOOK_VERIFY_TOKEN` e `WHATSAPP_APP_SECRET`
  (necessários para os cenários C9-C12, que chamam o webhook real) — pedir para quem administra
  as variáveis de ambiente se você não tiver acesso.
- Uma organização de teste (`{ORG_CODE}`) com um usuário (`{USER_ID}`) que tenha um telefone
  válido em E.164 (`{PHONE}`, ex.: `5531999999999` — número próprio para receber o WhatsApp de
  teste) e pelo menos um item de manutenção ativo (`{ITEM_ID}`). Idealmente essa organização deve
  ter **um único usuário vinculado** — `BusinessWhatsAppNotificationService.resolveRecipient()`
  pega o primeiro usuário retornado por `user_organizations` para a org, sem critério de "quem é o
  responsável"; com múltiplos usuários o destinatário pode não ser o `{USER_ID}` esperado.
- ⚠️ **Nota importante**: o template HSM da Meta ainda não foi aprovado em produção (ver nota da
  TASK-129 no kanban — "não verificado contra a Meta real"). Isso significa que, em staging hoje,
  uma tentativa de envio real deve **falhar com erro permanente da Meta** (ex.: "template does not
  exist" / código `132001`). Isso é **esperado**, não é bug — e é justamente o que torna o cenário
  C8 (fallback para e-mail) testável sem depender da aprovação do template.

---

## Rotas de apoio usadas nesta suíte

| Rota                                                                             | Uso                                                                                                                                                                                                                                                                                                  |
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GET {BASE_URL}/easy-maintenance/api/v1/run-jobs/execute-notification-detection` | Dispara agora a detecção de eventos (equivalente ao cron das 5h) — evita esperar o dia seguinte depois de ajustar `next_due_at` via SQL. Retorna `{"eventsDetected": N}`.                                                                                                                            |
| `GET {BASE_URL}/easy-maintenance/api/v1/run-jobs/execute-whatsapp-deferred-send` | Reprocessa agora os dispatches represados em `PENDING_HOURS_WINDOW` — evita esperar até 15min + a virada do horário comercial. Retorna `{"candidatesProcessed": N}`.                                                                                                                                 |
| `POST {BASE_URL}/easy-maintenance/api/v1/public/webhooks/whatsapp`               | O endpoint **real** do webhook (TASK-128) — sem bypass, usado nos cenários C9-C12 com assinatura HMAC calculada de verdade (ver snippet no C9). Não criamos endpoint de simulação para o webhook porque testar a validação de assinatura *de verdade* é justamente o ponto mais crítico da TASK-128. |

---

## Cenários de Teste

### C1 — Sem opt-in: nenhum WhatsApp é enviado

Setup:
```sql
UPDATE users SET whatsapp_opt_in = FALSE WHERE id = {USER_ID};
UPDATE maintenance_items SET next_due_at = CURRENT_DATE + INTERVAL 1 DAY
WHERE id = {ITEM_ID};
```

| Passo | Ação                                                    | Resultado esperado                                           | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------|--------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` | `eventsDetected >= 1`                                        | OK                             |
| 2     | Consultar `business_whatsapp_dispatches` (query abaixo) | 1 registro com `status = 'SKIPPED_OPT_OUT'`, `wamid IS NULL` | OK                             |

```sql
SELECT id, organization_code, event_type, days_offset, status, wamid, recipient_phone
FROM business_whatsapp_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID}
ORDER BY created_at DESC LIMIT 5;
```

---

### C2 — Opt-in ativo, fora da janela de 48h (offset=7): sem WhatsApp, só PUSH

Setup:
```sql
UPDATE users SET whatsapp_opt_in = TRUE, phone_number = '{PHONE}' WHERE id = {USER_ID};
UPDATE maintenance_items SET next_due_at = CURRENT_DATE + INTERVAL 7 DAY
WHERE id = {ITEM_ID};
```

| Passo | Ação                                                    | Resultado esperado                                                                                                                                                                                                                              | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` | `eventsDetected >= 1`                                                                                                                                                                                                                           | OK                             |
| 2     | Consultar `business_whatsapp_dispatches`                | **Nenhum** registro novo para este item — `NotificationChannelResolver` não inclui WHATSAPP quando `daysOffset > 2` (regra de 48h ⇒ `ceil(48/24)=2`, só `daysOffset<=2` qualifica; checkpoints existentes são `{30,15,7,1}`, então só `1` bate) | OK                             |
| 3     | Consultar notificações in-app/push do item              | Notificação PUSH criada normalmente (canal não afetado pela regra de 48h)                                                                                                                                                                       | OK                             |

---

### C3 — Opt-in ativo, dentro da janela de 48h (offset=1): caminho feliz de envio

Setup:
```sql
UPDATE maintenance_items SET next_due_at = CURRENT_DATE + INTERVAL 1 DAY
WHERE id = {ITEM_ID};
```

| Passo | Ação                                                    | Resultado esperado                                                                                                                | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` | `eventsDetected >= 1`                                                                                                             | OK                             |
| 2     | Consultar `business_whatsapp_dispatches`                | 1 registro novo, `status` = `SENT` (template aprovado) **ou** `FAILED` (template ainda não aprovado — ver nota nas Pré-condições) | OK                             |
| 3a    | Se `status = SENT`                                      | `wamid` preenchido, `sent_at` preenchido                                                                                          | OK                             |
| 3b    | Se `status = FAILED` (esperado hoje)                    | `error_message` preenchido com erro da Meta; ver C8 para confirmar o fallback de e-mail                                           | -                              |

```sql
SELECT id, status, wamid, error_message, sent_at, recipient_phone, days_offset
FROM business_whatsapp_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID}
ORDER BY created_at DESC LIMIT 1;
```

---

### C4 — Item vencido (OVERDUE): WhatsApp sempre incluído, independente do threshold

Setup:
```sql
UPDATE maintenance_items SET next_due_at = CURRENT_DATE - INTERVAL 7 DAY
WHERE id = {ITEM_ID};
DELETE FROM business_whatsapp_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID} AND days_offset = -7;
```

| Passo | Ação                                                    | Resultado esperado                                                                                                                                         | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` | `eventsDetected >= 1`, `event_type = ITEM_OVERDUE`                                                                                                         | ok                             |
| 2     | Consultar `business_whatsapp_dispatches`                | 1 registro com `days_offset = -7` (checkpoint de 7 dias vencido) — incluído mesmo sendo "distante" no tempo, porque OVERDUE ignora o threshold de urgência | ok                             |

---

### C5 — Idempotência: rodar a detecção duas vezes não duplica nem regride

| Passo | Ação                                                                                                                 | Resultado esperado                                                                              | Resultado esperado (detalhado) |
|-------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` novamente (mesmo dia, mesmo item do C3/C4)                   | 200 OK                                                                                          | ok                             |
| 2     | Consultar contagem de dispatches para o mesmo `(organization_code, event_type, reference_id, due_date, days_offset)` | **Ainda 1 registro** — `uk_business_whatsapp_dispatches_dedup` (migration V81) impede duplicata | ok                             |

```sql
SELECT organization_code, event_type, reference_id, due_date, days_offset, COUNT(*) AS qtd
FROM business_whatsapp_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID}
GROUP BY organization_code, event_type, reference_id, due_date, days_offset
HAVING COUNT(*) > 1;
```
Esperado: **0 linhas** (nenhum grupo com mais de 1).

---

### C6 — Quota mensal atingida: `SKIPPED_QUOTA`

Setup — reduzir a cota do plano da organização de teste para 0 (descobrir o plano primeiro):
```sql
SELECT bp.code, bp.features_json
FROM billing_plans bp
JOIN billing_subscription_items bsi ON bsi.plan_code = bp.code
WHERE bsi.source_type = 'ORGANIZATION' AND bsi.source_id = '{ORG_CODE}';
```
```sql
UPDATE billing_plans
SET features_json = JSON_SET(features_json, '$.whatsappMonthlyLimit', 0)
WHERE code = '{PLAN_CODE}';
```

| Passo | Ação                                                                                                                                                                       | Resultado esperado                        | Resultado esperado (detalhado) |
|-------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|--------------------------------|
| 1     | Forçar novo checkpoint: `UPDATE maintenance_items SET next_due_at = CURRENT_DATE + INTERVAL 1 DAY WHERE id = {ITEM_ID}` + `DELETE` o dispatch anterior desse `days_offset` | —                                         | ok                             |
| 2     | Disparar `GET /run-jobs/execute-notification-detection`                                                                                                                    | 200 OK                                    | ok                             |
| 3     | Consultar `business_whatsapp_dispatches`                                                                                                                                   | 1 registro com `status = 'SKIPPED_QUOTA'` | ok                             |
| 4     | **Restaurar a cota** (`whatsappMonthlyLimit` de volta ao valor original, ex. 30) antes de seguir para os próximos cenários                                                 | —                                         | ok                             |

---

### C7 — Rate limit diário por telefone: `SKIPPED_RATE_LIMIT`

Setup — inserir 3 dispatches "SENT hoje" para o mesmo telefone (limite padrão
`notification.whatsapp.daily-limit-per-recipient=3`):
```sql
INSERT INTO business_whatsapp_dispatches
(organization_code, event_type, reference_type, reference_id, due_date, days_offset,
 recipient_phone, status, wamid, sent_at, created_at)
VALUES
('{ORG_CODE}', 'ITEM_NEAR_DUE', 'ITEM', 999901, CURRENT_DATE, 1, '{PHONE}', 'SENT', 'sim-wamid-1', NOW(), NOW()),
('{ORG_CODE}', 'ITEM_NEAR_DUE', 'ITEM', 999902, CURRENT_DATE, 1, '{PHONE}', 'SENT', 'sim-wamid-2', NOW(), NOW()),
('{ORG_CODE}', 'ITEM_NEAR_DUE', 'ITEM', 999903, CURRENT_DATE, 1, '{PHONE}', 'SENT', 'sim-wamid-3', NOW(), NOW());
```

| Passo | Ação                                                                                              | Resultado esperado                                                                     | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|--------------------------------|
| 1     | Forçar novo checkpoint (offset=1) em `{ITEM_ID}`, apagar dispatch anterior desse offset           | —                                                                                      | ok                             |
| 2     | Disparar `GET /run-jobs/execute-notification-detection`                                           | 200 OK                                                                                 | ok                             |
| 3     | Consultar `business_whatsapp_dispatches`                                                          | 1 registro com `status = 'SKIPPED_RATE_LIMIT'` (4ª mensagem pro mesmo telefone no dia) | ok                             |
| 4     | Limpar as 3 linhas inseridas no setup (`DELETE ... WHERE reference_id IN (999901,999902,999903)`) | —                                                                                      | ok                             |

---

### C8 — Falha permanente de envio → fallback automático para e-mail

Pré-requisito: um dispatch `FAILED` recente (naturalmente obtido no C3, já que o template HSM
ainda não está aprovado — ver Pré-condições) e cujo evento **não** tinha EMAIL já no conjunto de
canais resolvido (`email_already_covered = FALSE`).

| Passo | Ação                                                                                                                                               | Resultado esperado                                                                                                             | Resultado esperado (detalhado) |
|-------|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Confirmar no dispatch do C3: `status = 'FAILED'` e `email_already_covered = FALSE`                                                                 | —                                                                                                                              | ok                             |
| 2     | Consultar `business_email_dispatches` (ou tabela de notificação por e-mail equivalente) para o mesmo `(organization_code, reference_id, due_date)` | 1 registro de e-mail correspondente, criado **automaticamente** pelo fallback (`notification.whatsapp.fallback-to-email=true`) | ok                             |
| 3     | Verificar a caixa de e-mail do destinatário de teste                                                                                               | E-mail de vencimento recebido                                                                                                  | ok                             |

```sql
SELECT id, organization_code, reference_id, due_date, days_offset, created_at
FROM business_email_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID}
ORDER BY created_at DESC LIMIT 3;
```

---

### C9 — Webhook: handshake de verificação (GET)

```bash
curl -i "{BASE_URL}/easy-maintenance/api/v1/public/webhooks/whatsapp?hub.mode=subscribe&hub.verify_token={WHATSAPP_WEBHOOK_VERIFY_TOKEN}&hub.challenge=teste123"
```

| Passo | Ação                                                | Resultado esperado                                         | Resultado esperado (detalhado) |
|-------|-----------------------------------------------------|------------------------------------------------------------|--------------------------------|
| 1     | Rodar o curl acima com o `hub.verify_token` correto | `200 OK`, corpo `teste123` (texto puro, sem envelope JSON) | ok                             |
| 2     | Repetir com `hub.verify_token=errado`               | `403 Forbidden`                                            | ok                             |
| 3     | Repetir com `hub.mode=unsubscribe` (token certo)    | `403 Forbidden`                                            | ok                             |

---

### C10 — Webhook: status `delivered`/`read` atualiza o dispatch existente

Pré-requisito: um `wamid` real (de um envio `SENT` — se não houver nenhum em staging por causa do
template não aprovado, usar o `INSERT` abaixo para criar um dispatch `SENT` sintético só para
este teste de webhook):
```sql
INSERT INTO business_whatsapp_dispatches
(organization_code, event_type, reference_type, reference_id, due_date, days_offset,
 recipient_phone, status, wamid, sent_at, created_at)
VALUES ('{ORG_CODE}', 'ITEM_NEAR_DUE', 'ITEM', 999999, CURRENT_DATE, 1,
        '{PHONE}', 'SENT', 'qa-wamid-c10', NOW(), NOW());
```

Script para calcular a assinatura e chamar o webhook real (substituir `{WHATSAPP_APP_SECRET}`):
```bash
BODY='{"object":"whatsapp_business_account","entry":[{"id":"WABA_ID","changes":[{"field":"messages","value":{"messaging_product":"whatsapp","statuses":[{"id":"qa-wamid-c10","status":"delivered","timestamp":"'$(date +%s)'","recipient_id":"{PHONE}"}]}}]}]}'
SIG=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "{WHATSAPP_APP_SECRET}" | sed 's/^.* //')
curl -i -X POST "{BASE_URL}/easy-maintenance/api/v1/public/webhooks/whatsapp" \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIG" \
  -d "$BODY"
```

| Passo | Ação                                                                   | Resultado esperado                                                                   | Resultado esperado (detalhado) |
|-------|------------------------------------------------------------------------|--------------------------------------------------------------------------------------|--------------------------------|
| 1     | Rodar o script acima com `status: "delivered"`                         | `200 OK` imediato (processamento é assíncrono)                                       |                                |
| 2     | Aguardar ~1s e consultar o dispatch                                    | `delivery_status = 'DELIVERED'`, `delivered_at` preenchido                           |                                |
| 3     | Repetir o script trocando `"status":"delivered"` por `"status":"read"` | `delivery_status = 'READ'`, `read_at` preenchido                                     |                                |
| 4     | Repetir o passo 1 (`delivered` de novo, evento atrasado/duplicado)     | `delivery_status` **continua `READ`** — não regride (ranking monotônico da TASK-128) |                                |

```sql
SELECT wamid, delivery_status, delivered_at, read_at, failed_error_code, failed_error_message
FROM business_whatsapp_dispatches WHERE wamid = 'qa-wamid-c10';
```

---

### C11 — Webhook: payload de falha (erro 130497) persiste código e mensagem

```bash
BODY='{"object":"whatsapp_business_account","entry":[{"id":"WABA_ID","changes":[{"field":"messages","value":{"messaging_product":"whatsapp","statuses":[{"id":"qa-wamid-c10","status":"failed","timestamp":"'$(date +%s)'","recipient_id":"{PHONE}","errors":[{"code":130497,"title":"Limite de mensagens business-initiated excedido.","message":"Message failed to send because there were more than 24 hours since the recipient last replied."}]}]}}]}]}'
SIG=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "{WHATSAPP_APP_SECRET}" | sed 's/^.* //')
curl -i -X POST "{BASE_URL}/easy-maintenance/api/v1/public/webhooks/whatsapp" \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIG" \
  -d "$BODY"
```

| Passo | Ação                                                                               | Resultado esperado                                                                                                                                                                    | Resultado esperado (detalhado) |
|-------|------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Rodar o script acima (mesmo `wamid` do C10, agora já em `READ`)                    | `200 OK`                                                                                                                                                                              | ok                             |
| 2     | Consultar o dispatch                                                               | `delivery_status` **continua `READ`** (FAILED não regride um status já mais avançado) — usar um `wamid` novo (`SENT`, sem histórico) para validar a persistência do erro isoladamente | ok                             |
| 3     | Repetir com um `wamid` novo, dispatch recém-criado em `SENT` sem `delivery_status` | `delivery_status = 'FAILED'`, `failed_error_code = '130497'`, `failed_error_message` preenchido com o texto do `message`                                                              | ok                             |

---

### C12 — Webhook: assinatura ausente/inválida é rejeitada

| Passo | Ação                                                                                                                            | Resultado esperado                                                                         | Resultado esperado (detalhado) |
|-------|---------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|--------------------------------|
| 1     | Repetir o curl do C10 **sem** o header `X-Hub-Signature-256`                                                                    | `403 Forbidden`, payload não processado (dispatch não muda)                                | ok                             |
| 2     | Repetir com `X-Hub-Signature-256: sha256=0000000000000000000000000000000000000000000000000000000000000000` (assinatura forjada) | `403 Forbidden`                                                                            | ok                             |
| 3     | Conferir logs da aplicação (staging)                                                                                            | Nenhuma menção ao valor de `WHATSAPP_APP_SECRET`/`WHATSAPP_API_TOKEN` nos logs de rejeição | ok                             |

---

### C13 — Janela de horário comercial: envio represado e reenviado pelo job

Setup (rodar fora do horário 8h-20h Brasília, ou simular temporariamente ajustando
`notification.whatsapp.business-hours-start`/`-end` em `application-{profile}.properties` para uma
janela que exclua o horário atual, se o teste precisar rodar durante o dia):
```sql
UPDATE maintenance_items SET next_due_at = CURRENT_DATE + INTERVAL 1 DAY WHERE id = {ITEM_ID};
DELETE FROM business_whatsapp_dispatches
WHERE organization_code = '{ORG_CODE}' AND reference_id = {ITEM_ID} AND days_offset = 1;
```

| Passo | Ação                                                                                                   | Resultado esperado                                                         | Resultado esperado (detalhado) |
|-------|--------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------|--------------------------------|
| 1     | Disparar `GET /run-jobs/execute-notification-detection` fora do horário comercial                      | `eventsDetected >= 1`                                                      | ok                             |
| 2     | Consultar `business_whatsapp_dispatches`                                                               | 1 registro com `status = 'PENDING_HOURS_WINDOW'`                           | ok                             |
| 3     | Dentro do horário comercial (8h-20h Brasília), disparar `GET /run-jobs/execute-whatsapp-deferred-send` | `candidatesProcessed >= 1`                                                 | ok                             |
| 4     | Consultar novamente o dispatch                                                                         | `status` mudou para `SENT` ou `FAILED` (nunca mais `PENDING_HOURS_WINDOW`) | ok                             |

---

## Critérios de Aceite da Suite

- [x] C1: sem opt-in, nenhuma mensagem tentada (`SKIPPED_OPT_OUT`)
- [x] C2: fora da janela de 48h, WhatsApp não é incluído (só PUSH)
- [x] C3: dentro da janela de 48h, WhatsApp é tentado (`SENT` ou `FAILED`, conforme status do template)
- [x] C4: item vencido sempre inclui WhatsApp, independente do threshold
- [x] C5: detecção rodada 2x não duplica dispatch (constraint única)
- [x] C6: quota mensal esgotada bloqueia envio (`SKIPPED_QUOTA`)
- [x] C7: rate limit diário por telefone bloqueia a 4ª mensagem (`SKIPPED_RATE_LIMIT`)
- [x] C8: falha permanente aciona fallback automático para e-mail
- [x] C9: handshake do webhook responde challenge/403 corretamente
- [x] C10: webhook atualiza delivery_status (`DELIVERED`/`READ`) sem regressão em evento duplicado
- [x] C11: webhook persiste código/mensagem de erro do payload `failed` (130497)
- [x] C12: webhook rejeita assinatura ausente/forjada sem vazar segredo em log
- [x] C13: dispatch represado por horário comercial é reenviado pelo job de deferred-send

---

## Status
Concluído — todos os 13 cenários executados em staging e aprovados por Douglas em 24/07/2026.
Fecha o EPIC-015 (junto com TASK-122/129/130/131/128/132). C3/C8 confirmaram o comportamento
esperado com o template HSM ainda não aprovado pela Meta (falha permanente → fallback e-mail).
