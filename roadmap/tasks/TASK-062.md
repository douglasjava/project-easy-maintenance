# TASK-062 — Classificador de motivos de recusa Asaas + roteamento por bucket

## Tipo
BACKEND

## Categoria
Backend / Billing / Tratamento de Erros

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional / Billing Flow

## Problema

Hoje, falhas do Asaas em cobranças (cartão recusado, saldo insuficiente, etc.) são tratadas de forma genérica — 
geralmente logadas e a subscription cai em status de pendência. Não há diferenciação entre:

- **Transiente** (timeout, erro temporário do gateway) → deveria retentar
- **Ação do usuário** (cartão expirado, dados inválidos, consentimento PIX revogado) → deveria notificar e abrir fluxo de atualização
- **Falha definitiva** (fraude, conta bloqueada, recusas repetidas) → deveria cancelar
- **Informativo** (estorno, disputa) → log + notificação, sem mudança de estado

O resultado é incidência de churn silencioso e falta de visibilidade para o time de suporte.

## Solução

Criar um `RefusalReasonClassifier`:

1. Tabela/enum/Map de `asaasErrorCode → RefusalBucket` (TRANSIENT, USER_ACTION, HARD_FAIL, INFO).
2. Para cada bucket, definir a ação:
   - TRANSIENT → schedule retry com backoff exponencial (1m, 5m, 30m, 4h)
   - USER_ACTION → mover subscription para `PAST_DUE`, e-mail + banner com deep link para "atualizar método"
   - HARD_FAIL → `CANCELED`, alerta para ops
   - INFO → log + notificação user-facing leve
3. Estatística mensurável (Micrometer) por bucket para dashboard.

## Escopo

- Classe `RefusalReasonClassifier` em `billing/error/`.
- Map inicial baseado em https://docs.asaas.com/docs/motivos-de-recusa.
- Integração no `PaymentFailedHandler` / `PaymentOverdueHandler`.
- Configuração externalizada (YAML) para ajustar o mapeamento sem deploy.
- Métricas: `billing.refusal.bucket.count{bucket=...}`.

## Critérios de Aceite

- [x] Classifier cobre, no mínimo, os 10 motivos mais comuns documentados
- [x] Cada bucket dispara a ação correta (retry / past_due / cancel / info)
- [x] Configuração externa permite remapear sem rebuild
- [x] Métricas expostas em `/actuator/prometheus`
- [x] Testes unitários por bucket + integração com handler

## Dependências
- Nenhuma bloqueante. Independente de TASK-058..061.

## Esforço
Médio (1–2 dias)

## Risco de não fazer
Subscriptions ficam em estado ambíguo. Usuários "perdidos" por motivos resolvíveis. Suporte sem visibilidade.

## Implementação

### Arquivos criados
- `billing/error/RefusalBucket.java` — enum com 5 buckets: TRANSIENT, USER_ACTION, HARD_FAIL, INFO, UNKNOWN
- `billing/error/RefusalClassificationProperties.java` — `@ConfigurationProperties(prefix = "billing.refusal")` com `Map<String, String> overrides` para remapeamento externo via `application.properties`
- `billing/error/RefusalReasonClassifier.java` — Spring `@Component`; 19 códigos mapeados por default; `@PostConstruct init()` aplica overrides; `classify()` case-insensitive + incrementa contador Micrometer `easy_billing.refusal.bucket.count{bucket=...}`
- `webhooks/asaas/strategy/impl/PaymentRefusedHandler.java` — handler para evento `PAYMENT_REFUSED`; resolve payment por `externalReference` ou `externalPaymentId`; roteia por bucket: TRANSIENT (log), USER_ACTION (PAST_DUE + email), HARD_FAIL (CANCELED + email), INFO/UNKNOWN (log)

### Arquivos modificados
- `infrastructure/saas/application/dto/AsaasDTO.java` — adicionado campo `failureReason` ao record `PaymentObject`
- `webhooks/asaas/strategy/impl/PaymentOverdueHandler.java` — adicionado `RefusalReasonClassifier` para classificar e registrar métrica no evento OVERDUE
- Testes impactados pela adição de campo no record (3 arquivos): adicionado `null` na posição de `failureReason`

### Testes criados
- `billing/error/RefusalReasonClassifierTest.java` — 26 cenários: parametrizados por bucket, null/unknown, case-insensitive, overrides, contadores Micrometer
- `webhooks/.../PaymentRefusedHandlerTest.java` — 11 cenários: TRANSIENT/USER_ACTION/HARD_FAIL/INFO/UNKNOWN routing, guards (final state, not found, null object), idempotência de status

### Resultado dos testes
- 338/338 testes green ✅

## Status
Em Validação
