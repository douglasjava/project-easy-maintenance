# TASK-025 — Fila/retry para envio de e-mails

## Tipo
Confiabilidade / Produto

## Categoria
Backend / E-mail / Infra

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-002 — Confiabilidade Operacional

## Descrição
O envio de e-mails via MailerSend acontece de forma síncrona (ou assíncrona simples com `@Async`). Se o MailerSend falhar, 
o e-mail é perdido silenciosamente. E-mails críticos como aviso de trial expirando, 
confirmação de pagamento e reset de senha precisam de garantia de entrega.

## Problema
- MailerSend fora do ar por 5 minutos durante o `DailyTrialJob` → todos os e-mails de aviso perdidos
- Falha no envio de reset de senha → usuário não consegue recuperar acesso
- Sem retry, a única solução é reprocessar manualmente

## Impacto
Clientes não recebem comunicações críticas. Suporte aumenta. Conversão de trial cai.

## Dependências
- TASK-012 (profile de e-mail) deve estar concluída
- TASK-008 (circuit breaker) cobre a parte de proteção; esta task cobre o retry

## Critérios de Aceite
- [x] E-mails críticos têm pelo menos 3 tentativas com backoff exponencial
- [x] Falha definitiva (após todas as tentativas) é logada com contexto suficiente para reprocessamento manual
- [x] Tabela `business_email_dispatches` rastreia status de envio com campos de retry
- [ ] Dashboard admin mostra e-mails com falha (fase 3 — opcional)

## Subtasks
- [x] Avaliar estratégia: Spring Retry (`@Retryable`) já existia em `MailerSendServiceImpl`; gap era retry por job para entradas FAILED no banco
- [x] `@Retry` Resilience4j já implementado em `MailerSendServiceImpl` (max=3, backoff 2s×2)
- [x] Verificar `business_email_dispatches` — rastreia status; adicionadas colunas `retry_count` e `last_retry_at` (V59)
- [x] Adicionar log estruturado de falha definitiva com contexto (dispatch ID, recipient, eventType, attempt count)
- [x] `EmailRetryJob` criado com 5 testes unitários — todos passando
- [x] **[AJUSTE]** Identificado gap: e-mails críticos (trial, pagamento, reset) sem cobertura de retry
- [x] **[AJUSTE]** `NotificationEventType` estendido com 6 novos tipos críticos
- [x] **[AJUSTE]** `V60` — colunas `subject`, `html_content`, `retryable` adicionadas; `organization_code`, `reference_type`, `reference_id` tornados nullable
- [x] **[AJUSTE]** `CriticalEmailDispatchService` criado — persiste dispatch + envia e-mail com rastreabilidade
- [x] **[AJUSTE]** `MailerSendServiceImpl.sendEmailFallback()` corrigido — propaga exceção após esgotar retries
- [x] **[AJUSTE]** `EmailRetryJob` atualizado — usa HTML armazenado para retry de e-mails críticos
- [x] **[AJUSTE]** `TrialExpirationService`, `BillingNotificationService`, `PasswordResetService`, `OnboardingService` migrados
- [x] **[AJUSTE]** 3 novos testes unitários — total: 8 testes passando

## Implementação

### Arquivos criados / modificados

| Arquivo                                                                                      | Operação                                                                          |
|----------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `db/migration/V59__add_retry_fields_business_email_dispatches.sql`                           | Criado — colunas `retry_count`, `last_retry_at` + índice                          |
| `db/migration/V60__add_critical_email_support_to_dispatches.sql`                             | Criado — `subject`, `html_content`, `retryable`; nullable em 3 colunas            |
| `infrastructure/notification/enums/NotificationEventType.java`                               | Atualizado — 6 novos tipos críticos adicionados                                   |
| `infrastructure/notification/domain/BusinessEmailDispatch.java`                              | Atualizado — campos `subject`, `htmlContent`, `retryable`; nullable em 3 campos   |
| `infrastructure/notification/repository/BusinessEmailDispatchRepository.java`                | Atualizado — `findEligibleForRetry` filtra `retryable = true`                     |
| `infrastructure/notification/service/CriticalEmailDispatchService.java`                      | **Criado** — wrapper que persiste dispatch + envia e-mail crítico                 |
| `infrastructure/mail/MailerSendServiceImpl.java`                                             | Corrigido — fallback propaga exceção (antes engolia silenciosamente)               |
| `jobs/EmailRetryJob.java`                                                                    | Atualizado — usa HTML armazenado para retry crítico; guards para campos nullable  |
| `infrastructure/notification/service/BusinessEmailNotificationService.java`                  | Atualizado — default case no switch de subject                                    |
| `infrastructure/notification/service/NotificationChannelResolver.java`                       | Atualizado — default case para novos event types                                  |
| `infrastructure/notification/service/BusinessPushNotificationService.java`                   | Atualizado — default case no switch de subject                                    |
| `infrastructure/notification/service/NotificationOrchestratorService.java`                   | Atualizado — default case nos switches de in-app                                  |
| `jobs/service/TrialExpirationService.java`                                                   | Migrado para `CriticalEmailDispatchService` — tipo `TRIAL_EXPIRING`               |
| `billing/application/service/BillingNotificationService.java`                                | Migrado — tipos `SUBSCRIPTION_CANCELLED`, `SUBSCRIPTION_BLOCKED`, `PIX_OVERDUE`  |
| `org_users/application/service/PasswordResetService.java`                                    | Migrado — tipo `PASSWORD_RESET` com `retryable=false`                             |
| `onboarding/application/service/OnboardingService.java`                                      | Migrado — tipo `TRIAL_ACTIVATED`                                                  |
| `test/jobs/EmailRetryJobTest.java`                                                           | Atualizado — 3 novos testes; total 8 testes passando                              |

### Estratégia de retry (atualizada)
- **Camada 1 (imediata):** `@Retry` Resilience4j no `MailerSendServiceImpl` — 3 tentativas em memória com backoff exponencial (2s, 4s) → propaga exceção após esgotar
- **Camada 2 (recuperação):** `EmailRetryJob` — varre `business_email_dispatches` com `status=FAILED AND retryable=true` a cada 30 min
  - E-mails operacionais: reconstrói HTML dinamicamente
  - E-mails críticos: usa `html_content` armazenado no dispatch (sem necessidade de reconstrução)
  - Janela: 24h | Intervalo mínimo: 15 min | MAX_RETRIES: 2
- **`PASSWORD_RESET`**: rastreado no dispatch (`retryable=false`) mas excluído do job — token de 30 min torna retry pelo job inviável; Camada 1 garante 3 tentativas imediatas
- **Total de tentativas possíveis (e-mails retryable):** até 3 imediatas + 2 via job = proteção robusta

## Esforço
Médio (4-8h) + Ajuste (2h)

## Risco de não fazer
E-mails críticos perdidos silenciosamente durante instabilidades do MailerSend.

## Status
Done
