# TASK-028 — Processamento assíncrono de chamadas IA

## Tipo
Performance / UX / Arquitetura

## Categoria
Backend / Frontend / IA / Performance

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-007 — Performance e Escalabilidade

## Descrição
Chamadas para OpenAI e DeepSeek aconteciam de forma síncrona dentro de endpoints HTTP. O modelo GPT-4o-mini 
pode demorar 5-30 segundos dependendo do tamanho do prompt e carga do serviço. 
Isso bloqueava threads do servidor e podia causar timeout no browser.

Solução implementada: os endpoints de IA retornam 202 Accepted com um `jobId` imediatamente. 
O processamento ocorre em thread pool dedicado (`@Async`). O frontend faz polling em `GET /ai/jobs/{jobId}` para obter o resultado.

## Critérios de Aceite
- [x] Endpoints de IA retornam 202 Accepted com `jobId` imediatamente
- [x] Job é processado em thread pool separado (`@Async` — bean `aiJobExecutor`, 2 core / 5 max)
- [x] Frontend faz polling em `GET /ai/jobs/{jobId}` para verificar status (PENDING, PROCESSING, DONE, FAILED)
- [x] Resultado disponível por 24h após conclusão (`cleanupExpiredJobs` — job horário via ShedLock)
- [x] Timeout de processamento configurável (padrão: 60s via `ai.job.timeout-seconds`)

## Esforço
Grande (2-3 dias)

## Implementação

### Arquitetura — Fluxo Async

```
Browser → POST /ai/assistant        → 202 { jobId }
Browser → GET  /ai/jobs/{jobId}     ← PENDING / PROCESSING
          (polling cada 2s, max 30x)
Browser → GET  /ai/jobs/{jobId}     ← DONE { result: { answer: "..." } }
```

### Decisões de Design
- `AiJobProcessor` é um bean **separado** de `AiJobService` — necessário para que `@Async` funcione através do proxy Spring
- `TenantContext.set(orgCode)` é chamado no início do método assíncrono e `TenantContext.clear()` no `finally` — garante isolamento multi-tenant no thread do pool
- `GET /ai/summary` mantido síncrono: quando `pretty=false` é apenas query de banco (instantâneo); quando `pretty=true` o overhead de IA é secundário
- `POST /ai/bootstrap/apply` mantido síncrono: não chama IA, apenas persiste no banco
- Limpeza de jobs expirados: job agendado hourly com ShedLock (`cleanupExpiredAiJobs`)

### Tenant Isolation — Segurança
`GET /ai/jobs/{jobId}` valida que `job.organizationCode == TenantContext.get()`. Acesso a job de outra org → `NotAuthorizedException`.

### Arquivos criados / modificados

| Arquivo                                               | Operação                                                             |
|-------------------------------------------------------|----------------------------------------------------------------------|
| `db/migration/V61__create_ai_jobs.sql`                | **Criado** — tabela `ai_jobs` com índices                            |
| `ai/domain/enums/AiJobStatus.java`                    | **Criado** — PENDING, PROCESSING, DONE, FAILED                       |
| `ai/domain/enums/AiJobType.java`                      | **Criado** — ASSISTANT, SUGGEST_ITEM, BOOTSTRAP_PREVIEW              |
| `ai/domain/AiJob.java`                                | **Criado** — entidade JPA                                            |
| `ai/infrastructure/persistence/AiJobRepository.java`  | **Criado** — `deleteCompletedBefore()`                               |
| `ai/application/dto/AiJobAcceptedResponse.java`       | **Criado** — `{ jobId }`                                             |
| `ai/application/dto/AiJobStatusResponse.java`         | **Criado** — `{ jobId, status, result, error, ... }`                 |
| `ai/application/service/AiJobProcessor.java`          | **Criado** — bean com `@Async("aiJobExecutor")`                      |
| `ai/application/service/AiJobService.java`            | **Criado** — `submitJob()`, `getJobStatus()`, `cleanupExpiredJobs()` |
| `configuration/SchedulerConfig.java`                  | Adicionado bean `aiJobExecutor` (thread pool)                        |
| `ai/infrastructure/web/AiController.java`             | Reescrito — assistant/suggest-item → 202; + `GET /ai/jobs/{jobId}`   |
| `ai/infrastructure/web/AiBootstrapController.java`    | preview → 202; removido mock()                                       |
| `application.properties`                              | Adicionado `ai.job.timeout-seconds=60`                               |
| `easy-maintenance-web/src/lib/aiPolling.ts`           | **Criado** — `pollAiJob<T>()` utility                                |
| `easy-maintenance-web/src/ia/ChatWidget.tsx`          | Migrado para polling (2s × 30 tentativas)                            |
| `easy-maintenance-web/src/app/ai-onboarding/page.tsx` | Migrado para polling (2s × 45 tentativas)                            |
| `test/.../AiJobServiceTest.java`                      | **Criado** — 6 testes unitários, todos passando                      |

### Testes
- `shouldSubmitJob_saveRecord_andTriggerAsyncProcessing` ✅
- `shouldReturnJobStatus_withResult_whenDone` ✅
- `shouldReturnPendingStatus_withoutResult` ✅
- `shouldThrowNotFoundException_whenJobDoesNotExist` ✅
- `shouldThrowNotAuthorizedException_whenJobBelongsToDifferentOrg` ✅
- `shouldReturnFailedStatus_withErrorMessage` ✅

**Resultado: 6/6 passando — BUILD SUCCESS**

## Risco de não fazer
Timeout em chamadas de IA com prompts grandes. Threads do servidor bloqueadas durante pico de uso simultâneo.

## Status
Done
