# TASK-E2E-003 — Testes E2E: Webhook Asaas — Token e Idempotência

## Tipo
QA Automatizada — E2E (End-to-End)

## Categoria
Billing / Webhook / Segurança

## Prioridade
🟠 Alto

## Épico
EPIC-001 / EPIC-010 — Segurança Crítica + PIX

## Flow relacionado
[FLOW-006](../Flow/FLOW-006.md)

## Migração
Substitui **TASK-QA-AUTO-004** (IT com TestContainers/Spring — pendente, não iniciada).

## Descrição
Criar testes E2E para o endpoint `POST /webhooks/asaas` validando:
1. Rejeição de requisições com token inválido ou ausente (401)
2. Idempotência — mesmo `providerEventId` processado duas vezes gera apenas um registro no banco
3. Campos PIX populados corretamente via evento `PAYMENT_CREATED`

A idempotência DEVE ser verificada contra o banco real — é uma constraint UNIQUE no `webhook_event_log`. E2E com DB real é a única forma de garantir isso de forma confiável.

## Justificativa
- Duplicação de evento de pagamento é risco financeiro direto (assinatura ativada duas vezes)
- Token do webhook pode ser rotacionado acidentalmente — teste detecta imediatamente
- E2E com DB real verifica a constraint UNIQUE que é a defesa final contra duplicação

## Tecnologias
- Playwright (TypeScript) — `request` fixture (API testing sem browser)
- Docker Compose E2E com MySQL real
- Payloads JSON simulando eventos Asaas

## Cobertura Esperada

### Validação de token
- [x] `POST /webhooks/asaas` com token válido no header → HTTP 200 imediato
- [x] `POST /webhooks/asaas` com token inválido → HTTP 401
- [x] `POST /webhooks/asaas` sem token no header → HTTP 401
- [x] `POST /webhooks/asaas` com token em branco → HTTP 401

### Idempotência de eventos
- [x] `PAYMENT_CREATED` com `providerEventId = "evt-idem-xxx"` → HTTP 200
- [x] Mesmo payload reenviado → HTTP 200 (ignorado sem duplicação)
- [x] Verificar via query direta ao `webhook_event`: apenas 1 linha para aquele `provider_event_id`

### Campos PIX via PAYMENT_CREATED
- [x] `PAYMENT_CREATED` com `billingType=PIX` e `pixTransaction` preenchido → `pixQrCode` e `pixExpiresAt` populados no banco
- [x] `PAYMENT_CREATED` com `billingType=CREDIT_CARD` → handler não lança exceção; evento armazenado corretamente
- [x] `PAYMENT_CREATED` com `pixTransaction=null` → HTTP 200, sem erro 500

### Resposta assíncrona
- [x] Webhook retorna HTTP 200 imediatamente (< 500ms)
- [x] Dados aparecem disponíveis após polling curto via helpers/db.ts

## Subtasks
- [x] Criar payloads JSON de teste para `PAYMENT_CREATED` (PIX e CREDIT_CARD)
- [x] Criar helper `helpers/db.ts` com `countWebhookEvents`, `getPaymentPix`, `pollUntil`
- [x] Implementar `tests/billing/webhook-token.spec.ts` — 5 testes de validação de token
- [x] Implementar `tests/billing/webhook-idempotency.spec.ts` — 4 testes de idempotência e campos PIX
- [x] Adicionar `ASAAS_WEBHOOK_TOKEN` ao `.env.e2e.example`
- [x] Adicionar seed (seção 8-9 no `e2e-seed.sql`): Invoice + Payment para o teste de campos PIX
- [ ] Integrar na suite CI (job obrigatório em PRs que tocam segurança/billing/webhook)

## Arquivos Criados / Modificados

| Arquivo | Operação |
|---------|----------|
| `easy-maintenance-e2e/tests/billing/webhook-token.spec.ts` | Criado — 5 testes de token (válido/inválido/ausente/branco/timing) |
| `easy-maintenance-e2e/tests/billing/webhook-idempotency.spec.ts` | Criado — 4 testes (idempotência DB + PIX fields + CREDIT_CARD + null pixTransaction) |
| `easy-maintenance-e2e/helpers/db.ts` | Criado — `countWebhookEvents`, `getPaymentPix`, `pollUntil` |
| `easy-maintenance-e2e/seed/e2e-seed.sql` | Atualizado — seções 8-9 adicionadas (invoice + payment para PIX test) |
| `easy-maintenance-e2e/.env.e2e.example` | Atualizado — `ASAAS_WEBHOOK_TOKEN` adicionado |

## Esforço Estimado
Médio (6-9h)

## Dependências
- TASK-E2E-001 (setup Playwright + Docker Compose) concluída
- Variável `ASAAS_WEBHOOK_TOKEN` configurada no ambiente da API (deve coincidir com `asaas.webhook-token`)

## Status
Concluído — TypeScript compila; 9 testes detectados pelo Playwright; aguarda execução contra API + DB reais
