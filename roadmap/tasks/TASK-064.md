# TASK-064 — Hardening de webhook Asaas: DLQ + replay manual

## Tipo
BACKEND / INFRA

## Categoria
Backend / Billing / Webhook

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

A validação de webhook do Asaas já está implementada (TASK-007 ✅) e a idempotência tem cobertura E2E (TASK-E2E-003). 
Falta a peça final: o que acontece quando um webhook **falha durante o processamento** (exceção, race condition, bug do handler).

Hoje a falha é registrada em log, mas o evento não é facilmente reprocessável. Sem DLQ explícita:
- Ops não tem visibilidade do que falhou.
- Não há fluxo de replay manual.
- Eventos "perdidos" entram apenas pela reconciliação noturna (TASK-063), que é fallback — não primeira linha.

## Solução

1. Tabela `webhook_dlq`:
   - `id`, `provider_event_id`, `event_type`, `payload (JSON)`, `error_message`, `attempts`, `first_failed_at`, `last_failed_at`, `replayed_at NULL`.
2. Quando o `AsaasWebhookService` falha, mover para DLQ (além de marcar `webhook_event.status=ERROR`).
3. Endpoint administrativo `POST /admin/webhooks/dlq/{id}/replay` + `GET /admin/webhooks/dlq`.
4. Métrica `billing.webhook.dlq.count{event_type=...}` para alerta.

## Escopo

- Migration V67: nova tabela `webhook_dlq`.
- `WebhookDlqEntry` entity, `WebhookDlqRepository`.
- `WebhookDlqService`: enqueue (nova entrada ou incremento de tentativas), replay (desserializa → chama handler), listPending.
- `AsaasWebhookService` modificado: no catch, chama `webhookDlqService.enqueue()`.
- `AdminWebhookController`: endpoints `GET /dlq` e `POST /dlq/{id}/replay`.
- Métricas Prometheus via Micrometer.

## Critérios de Aceite

- [x] Webhooks com falha persistente terminam em DLQ (não desaparecem no log)
- [x] Endpoint de replay funciona e marca `replayed_at`
- [x] Eventos replayados são processados idempotentemente (não duplicam estado)
- [x] Alerta dispara quando DLQ ultrapassa threshold (métrica exposta)
- [x] Testes: falha vai pra DLQ, replay funciona, replay duplo rejeitado, entry inválida rejeitada

## Dependências
- Nenhuma bloqueante.

## Esforço
Médio (1–2 dias)

## Risco de não fazer
Webhook que falha por bug some no log. Incidente de billing fica invisível até alguém reclamar.

## Implementação

### Arquivos criados
- `db/migration/V67__create_webhook_dlq.sql` — tabela `webhook_dlq` com índices em `provider_event_id` e `replayed_at`
- `webhooks/commons/domain/WebhookDlqEntry.java` — entity mapeando a tabela
- `webhooks/commons/repository/WebhookDlqRepository.java` — `findByProviderEventId`, `findByReplayedAtIsNull(Pageable)`
- `webhooks/commons/service/WebhookDlqService.java`:
  - `enqueue()`: cria nova entrada ou incrementa `attempts` se já existe; métrica incrementada apenas na primeira ocorrência
  - `replay()`: deserializa payload → chama `strategy.handle()` → seta `replayed_at`; lança `RuleException` se já replayado ou handler ausente; `NotFoundException` se ID inválido
  - `listPending()`: paginado, apenas entradas com `replayed_at IS NULL`
- `admin/infrastucture/web/AdminWebhookController.java` — `GET /private/admin/webhooks/dlq` e `POST /private/admin/webhooks/dlq/{id}/replay`

### Arquivos modificados
- `webhooks/asaas/service/AsaasWebhookService.java` — adicionado `WebhookDlqService`; no `catch`, chama `webhookDlqService.enqueue(event.id(), event.event(), rawPayload, e.getMessage())`
- `webhooks/asaas/service/AsaasWebhookServiceTest.java` — atualizado constructor call + verificação que `enqueue()` é chamado no cenário de falha do strategy

### Testes criados
- `webhooks/commons/service/WebhookDlqServiceTest.java` — 7 cenários:
  - `enqueue` nova entrada → salva + incrementa métrica
  - `enqueue` entrada existente → incrementa attempts, métrica NÃO duplicada
  - `replay` entry válida → chama handler, seta `replayed_at`, incrementa attempts
  - `replay` já replayado → `RuleException`
  - `replay` entry não encontrada → `NotFoundException`
  - `replay` sem handler registrado → `RuleException`
  - `replay` payload inválido → `RuleException`

### Idempotência no replay
Garantida pelos handlers individuais: verificam `payment.getStatus().isFinal()` antes de qualquer mudança de estado. Replay de evento cujo payment já foi processado é silenciosamente ignorado pelo handler.

### Resultado dos testes
- 355/355 testes green ✅

## Status
Em Validação
