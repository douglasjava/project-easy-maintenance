# TASK-054 — Enforcement de limites: créditos de IA e cota mensal de upload

## Tipo

FULL_STACK — Backend + Exposição no access-context

## Categoria

Billing / Limites / Produto

## Prioridade

🔴 Crítico — pré-lançamento, protege receita e custos de infraestrutura

## Épico

EPIC-002 — Confiabilidade Operacional / EPIC-006 — Experiência do Usuário

## Depende de

TASK-053 ✅ (nova grade de planos com `aiMonthlyCredits`, `maxFileSizeMb`, `maxMonthlyUploadsMb`)

---

## Problema

Após a reestruturação dos planos (TASK-053), os limites foram definidos no schema de features mas **não estavam sendo enforcement**:
- Qualquer usuário podia chamar IA indefinidamente, sem controle de cota
- O upload de arquivos não tinha limite mensal por org
- O tamanho máximo por arquivo era lido de variável de ambiente (estático), ignorando o plano

## Decisão Técnica

### Créditos de IA (nível usuário)
- Rastrear créditos usados por usuário/mês em tabela dedicada (`ai_usage_monthly`)
- 1 crédito = 1 job de IA completado com sucesso (DONE)
- Validar ANTES de submeter o job; deduzir APÓS conclusão com sucesso
- Limite vem do `aiMonthlyCredits` do plano do item USER na assinatura

### Cota de Upload (nível org)
- Rastrear bytes usados por org no mês corrente via soma em `maintenance_attachments`
- Validar no momento de geração da presigned URL (antes de qualquer upload)
- Tamanho máximo por arquivo também lido do plano (em vez de config estática)
- Limite vem do `maxMonthlyUploadsMb` e `maxFileSizeMb` do plano do item ORGANIZATION

---

## Arquivos Alterados / Criados

### Novos
- `db/migration/V64__add_ai_usage_tracking.sql`
- `ai/domain/AiMonthlyUsage.java`
- `ai/infrastructure/persistence/AiMonthlyUsageRepository.java`
- `ai/application/service/AiCreditService.java`

### Modificados
- `ai/domain/AiJob.java` — campo `userId`
- `ai/application/service/AiJobService.java` — parâmetro `userId`, validação de créditos
- `ai/application/service/AiJobProcessor.java` — dedução de créditos após DONE
- `ai/infrastructure/web/AiController.java` — injeta AuthenticationService, passa userId
- `ai/infrastructure/web/AiBootstrapController.java` — idem
- `assets/infrastructure/persistence/MaintenanceAttachmentRepository.java` — query de soma mensal
- `assets/application/service/MaintenanceAttachmentService.java` — enforcement de cota e tamanho por plano
- `infrastructure/access/application/dto/response/OrganizationUsageResponse.java` — campos de upload
- `infrastructure/access/application/dto/response/AccountAccessResponse.java` — campos de IA
- `infrastructure/access/application/service/FeatureAccessService.java` — preencher novos campos

---

## Critérios de Aceite

- [x] Usuário que atingiu o limite mensal de créditos recebe 422 ao tentar submeter job de IA
- [x] Job de IA bem-sucedido (DONE) deduz 1 crédito em `ai_usage_monthly`
- [x] Job com status FAILED não deduz créditos
- [x] Upload de arquivo acima de `maxFileSizeMb` do plano retorna 422
- [x] Upload que ultrapassa `maxMonthlyUploadsMb` do plano retorna 422
- [x] `/me/access-context` retorna `aiCreditsUsed` e `aiCreditsLimit` no `accountAccess`
- [x] `/me/access-context` retorna `uploadUsedMb` e `uploadLimitMb` no `currentUsage` da org ativa

## Status

✅ Implementado — 10/05/2026
