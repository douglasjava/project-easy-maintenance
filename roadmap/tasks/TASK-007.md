# TASK-007 — Validação robusta de webhook Asaas

## Tipo
Segurança / Integração

## Categoria
Backend / Segurança / Billing

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
O `AsaasWebhookController` valida os eventos recebidos apenas comparando um token estático no header da requisição. Embora o Asaas use token de acesso (diferente do Stripe que usa HMAC-SHA256), é necessário garantir que a validação seja robusta e que eventos não possam ser reprocessados (replay attack).

O `WebhookEventLog` com `providerEventId` já existe para deduplicação, mas precisa verificar se a constraint de unicidade está presente no banco e se a verificação acontece de forma atômica antes do processamento.

## Problema
- Sem constraint de unicidade em `providerEventId`, um evento pode ser processado duas vezes em condição de race condition
- Sem registro de IPs permitidos ou validação adicional, qualquer IP que conheça o token pode enviar eventos

## Impacto
- Evento de "pagamento confirmado" enviado duas vezes poderia ativar assinatura duplicadamente
- Evento falso poderia modificar status de assinatura de cliente

## Dependências
- Acesso à documentação do Asaas sobre formato de eventos de webhook

## Critérios de Aceite
- [ ] `providerEventId` tem constraint `UNIQUE` no banco de dados (migration Flyway)
- [ ] Verificação de `providerEventId` usa `INSERT OR IGNORE` ou constraint para garantir idempotência atômica
- [ ] Token de webhook está em variável de ambiente, não hardcoded
- [ ] Log de webhook rejeitado (token inválido) inclui IP de origem
- [ ] Resposta 200 imediata ao Asaas antes de processar (evita timeout e reenvio)
- [ ] Processamento assíncrono após confirmar recebimento

## Subtasks
- [ ] Verificar schema de `webhooks_event_log` — adicionar constraint UNIQUE em `provider_event_id` se ausente
- [ ] Criar migration Flyway para a constraint (se necessário)
- [ ] Verificar que token está em `application.properties` como `${ASAAS_WEBHOOK_TOKEN}` e não hardcoded
- [ ] Implementar resposta 200 imediata + processamento assíncrono (ou confirmar que já está assim)
- [ ] Adicionar log de IP e evento rejeitado por token inválido
- [ ] Testar reenvio do mesmo evento — deve processar apenas uma vez

## Esforço
Pequeno (3-5h)

## Risco de não fazer
Race condition pode processar evento de pagamento duas vezes. Token exposto no código pode permitir eventos falsos.

## Status
Concluído
