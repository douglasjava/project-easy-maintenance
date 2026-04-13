# TASK-QA-AUTO-004 — Testes de Integração: Webhook Asaas Idempotência e Validação de Token

## Tipo
QA Automatizada — Integração (API)

## Categoria
Billing / Webhook / Segurança / Backend

## Prioridade
🟠 Alto

## Épico
EPIC-001 / EPIC-010 — Segurança Crítica + PIX

## Flow relacionado
[FLOW-006](../Flow/FLOW-006.md)

## Descrição
Criar testes de integração para o endpoint de webhook do Asaas validando:
1. Rejeição de requisições com token inválido (401)
2. Idempotência — mesmo `providerEventId` processado duas vezes resulta em apenas uma atualização
3. Campos PIX populados corretamente via webhook `PAYMENT_CREATED`

## Justificativa para Automatização
- Duplicação de evento de pagamento é risco financeiro direto (assinatura ativada duas vezes, cobrança processada duplicada)
- A constraint UNIQUE no banco é a linha de defesa final — deve ser testada sob carga e concorrência
- Token de webhook pode ser rotacionado acidentalmente — teste de integração detecta imediatamente

## Tecnologias
- JUnit 5
- MockMvc
- TestContainers (MySQL para verificar constraint UNIQUE)
- `@SpringBootTest(webEnvironment = RANDOM_PORT)`

## Cobertura Esperada

### Validação de token
- [ ] POST /webhooks/asaas com token válido → HTTP 200 imediato
- [ ] POST /webhooks/asaas com token inválido → HTTP 401
- [ ] POST /webhooks/asaas sem token no header → HTTP 401
- [ ] Log de rejeição contém IP de origem (verificar output de log)

### Idempotência de eventos
- [ ] Enviar `PAYMENT_CREATED` com `providerEventId = "evt-001"` → processado (Payment criado/atualizado)
- [ ] Enviar exatamente o mesmo payload com `providerEventId = "evt-001"` novamente → ignorado silenciosamente (sem duplicação no banco)
- [ ] Verificar no banco: apenas 1 registro em `webhook_event_log` para `provider_event_id = "evt-001"`

### Campos PIX via PAYMENT_CREATED
- [ ] PAYMENT_CREATED com `billingType=PIX` e `pixTransaction` preenchido → `pixQrCode`, `pixQrCodeBase64`, `pixExpiresAt` populados em Payment
- [ ] PAYMENT_CREATED com `billingType=CREDIT_CARD` → campos PIX permanecem NULL
- [ ] PAYMENT_CREATED com `pixTransaction=null` → campos PIX NULL sem NPE

### Resposta assíncrona
- [ ] Webhook retorna HTTP 200 imediatamente (antes do processamento assíncrono terminar)
- [ ] Processamento assíncrono ocorre após a resposta (verificar com @Async ou polling)

## Subtasks
- [ ] Criar classe `AsaasWebhookIT`
- [ ] Criar payloads de teste para `PAYMENT_CREATED`, `PAYMENT_OVERDUE` e `PAYMENT_RECEIVED`
- [ ] Criar helper para gerar `providerEventId` único e reutilizável
- [ ] Garantir rollback do banco após cada teste (não contaminar entre testes)
- [ ] Integrar na suite de CI

## Esforço Estimado
Médio (6-10h)

## Status
Pendente — implementar durante SPRINT-03 (alta prioridade para proteção de billing)
