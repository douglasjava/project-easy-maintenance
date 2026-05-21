# TASK-053 — Reestruturação dos planos: remover FREE, nova grade de features, trial automático BUSINESS

## Tipo

FULL_STACK — Backend + Frontend + Infra/Config

## Categoria

Billing / Onboarding / Produto

## Prioridade

🔴 Crítico — decisão de produto pré-lançamento

## Épico

EPIC-006 — Experiência do Usuário / EPIC-002 — Confiabilidade Operacional

---

## Problema

O produto estava com:
- Plano FREE ativo concorrendo com o trial, gerando ambiguidade de monetização
- Seleção de plano no onboarding expondo complexidade desnecessária ao novo usuário
- Grade de features desatualizada (IA no STARTER com créditos elevados, sem limites de upload)
- Campos `maxFileSizeMb` e `maxMonthlyUploadsMb` ausentes do schema de features

## Decisão de Produto

- Remover plano FREE (desativar, preservar integridade referencial)
- Todo novo usuário entra direto no trial de 7 dias com features do plano BUSINESS
- Grade revisada com controle de IA por créditos e limites de upload por plano
- Onboarding simplificado: sem seleção de plano, com banner informativo do trial

---

## Nova Grade de Planos

| Feature                      | STARTER              | BUSINESS                 | ENTERPRISE             |
|------------------------------|----------------------|--------------------------|------------------------|
| Preço                        | R$ 99/mês            | R$ 199/mês               | R$ 499/mês             |
| Organizações                 | 1                    | 3                        | 10                     |
| Usuários/Org                 | 3                    | 10                       | 100                    |
| Itens/Org                    | 100                  | 500                      | 5.000                  |
| IA                           | ✅ 5.000 créditos/mês | ✅ 40.000 créditos/mês    | ✅ 200.000 créditos/mês |
| Upload — tamanho máx/arquivo | 5 MB                 | 20 MB                    | 50 MB                  |
| Upload — cota mensal/org     | 500 MB               | 2 GB                     | 10 GB                  |
| Relatórios                   | ✅                    | ✅                        | ✅                      |
| E-mails/mês                  | 500                  | 3.000                    | 10.000                 |
| Suporte                      | Comunidade           | E-mail prioritário       | Dedicado               |
| **Trial**                    | —                    | **7 dias (entry point)** | —                      |

---

## Arquivos Alterados

### Backend
- `billing/domain/BillingPlanFeatures.java` — campos `maxFileSizeMb` e `maxMonthlyUploadsMb` adicionados
- `onboarding/application/dto/OnboardingDTO.java` — `planCode` removido de `AccountUserRequest` e `AccountOrganizationRequest`
- `onboarding/application/service/OnboardingService.java` — plano BUSINESS fixado para USER e ORG no trial
- `db/migration/V63__restructure_billing_plans.sql` — FREE desativado, STARTER/BUSINESS/ENTERPRISE atualizados

### Frontend
- `app/onboarding/page.tsx` — seleção de plano removida de Step 1 e Step 2; banner de trial BUSINESS adicionado; `planCode` removido do estado e payloads

---

## Critérios de Aceite

- [x] Plano FREE está com `status = 'INACTIVE'` no banco
- [x] STARTER, BUSINESS e ENTERPRISE têm os novos valores de features (incluindo `maxFileSizeMb` e `maxMonthlyUploadsMb`)
- [x] Novo usuário que completa o onboarding recebe trial de 7 dias com features do BUSINESS
- [x] Onboarding não exibe seleção de plano em nenhum step
- [x] Banner informativo aparece em Step 1 e Step 2 do onboarding
- [x] API `/me/onboarding/user` e `/me/onboarding/organization` não aceitam mais `planCode` no body
- [x] `BillingPlanFeatures` deserializa corretamente os novos campos com fallback para defaults

## Status

✅ Implementado — 09/05/2026
