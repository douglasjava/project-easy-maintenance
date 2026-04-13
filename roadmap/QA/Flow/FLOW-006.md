# FLOW-006 — Webhook Asaas e Idempotência

## Criticidade
🟠 HIGH

## Launch Relevance
Duplicação de cobrança ou processamento de evento falso é risco financeiro e legal imediato.

## Tasks Relacionadas
- TASK-007 — Validação robusta de webhook Asaas
- TASK-003 — ShedLock nos jobs agendados

## Descrição do Fluxo

1. Asaas envia evento para `POST /webhooks/asaas` com token no header
2. Controller valida o token contra variável de ambiente `ASAAS_WEBHOOK_TOKEN`
3. Se inválido → 401 + log com IP de origem
4. Se válido → 200 imediato (antes de processar)
5. Processamento assíncrono verifica `providerEventId` na tabela `webhook_event_log`
6. Se já processado (constraint UNIQUE) → ignora silenciosamente
7. Se novo → processa evento (atualiza Payment, Invoice, Subscription conforme tipo)

## Camadas Impactadas
- **Backend:** `AsaasWebhookController`, `WebhookEventLog`, handlers de evento (`PaymentCreatedHandler`, `PaymentOverdueHandler`, etc.)
- **Banco:** Constraint UNIQUE em `provider_event_id` na tabela `webhook_event_log`

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Evento com token válido → 200 + processamento | Happy path | Manual (TASK-007) |
| Evento com token inválido → 401 + log de IP | Segurança | Manual |
| Mesmo `providerEventId` enviado 2x → processado 1x | Idempotência | Manual |
| Race condition: 2 requests simultâneos com mesmo ID | Concorrência | Não coberto |
| Evento `PAYMENT_CREATED` PIX → campos PIX populados | Integração | Unitário (TASK-046) |
| Job executado em 2 instâncias simultâneas → lock adquirido por 1 | ShedLock | Manual |

## Validação Recomendada
- **Manual:** Simular reenvio de evento duplicado via sandbox Asaas
- **Automatizada:** [TASK-QA-AUTO-004](../tasks/TASK-QA-AUTO-004.md)

## Gaps
- Race condition com 2 requests simultâneos do mesmo `providerEventId` — apenas constraint de banco protege
- ShedLock sem teste automatizado de lock distribuído

## Status de Validação
- [ ] Token de webhook em variável de ambiente (não hardcoded) — verificar no Railway
- [ ] Idempotência de eventos duplicados testada manualmente
- [ ] Constraint UNIQUE em `provider_event_id` confirmada no schema
- [ ] TASK-QA-AUTO-004 criada e priorizada
