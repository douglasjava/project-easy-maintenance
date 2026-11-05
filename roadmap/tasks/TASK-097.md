# TASK-097 — Hardening dos limites de plano: gaps de enforcement e cobertura de testes

## Tipo
BACKEND

## Categoria
Backend / Billing / Plan Enforcement

## Prioridade
🟠 Alto

## Fase
2 — Pós-lançamento

## Épico
EPIC-008 — Qualidade e Cobertura de Testes

---

## Contexto

Auditoria realizada em 27/06/2026 mapeou o estado de enforcement de todos os limites definidos em `BillingPlanFeatures`.
Os limites abaixo já estão implementados e testados — sem ação necessária:

| Limite                | Enforced em                                                 | Teste                                |
|-----------------------|-------------------------------------------------------------|--------------------------------------|
| `maxItems`            | `MaintenanceItemService.validateItemLimit()`                | `MaintenanceItemPlanLimitTest` ✅     |
| `aiMonthlyCredits`    | `AiCreditService.validateHasCredits()`                      | `AiCreditServiceTest` ✅              |
| `maxFileSizeMb`       | `MaintenanceAttachmentService.generatePresignedUploadUrl()` | `MaintenanceAttachmentServiceTest` ✅ |
| `maxMonthlyUploadsMb` | `MaintenanceAttachmentService.generatePresignedUploadUrl()` | `MaintenanceAttachmentServiceTest` ✅ |

Os três itens abaixo têm gaps e precisam de ação.

---

## Subtasks

### TASK-097-A — `maxUsers`: implementar enforcement + testes
**Gap:** `BillingPlanFeatures.maxUsers` existe e é exibido no frontend via `FeatureAccessService.currentUsers`,
mas `UsersService.addOrganization()` nunca valida esse limite. Qualquer usuário pode ser adicionado a uma org
independente do plano contratado.

**O que fazer:**
- Adicionar validação em `UsersService.addOrganization()` no mesmo padrão de `validateItemLimit()`:
  buscar a subscription da organização, parsear as features, checar `countByOrganizationCode >= maxUsers`.
- Lançar `RuleException` com mensagem clara: `"Limite de usuários atingido (X/Y). Faça upgrade do plano."`.
- Criar `UserPlanLimitTest` cobrindo: no limite, excedido, abaixo do limite, sem assinatura, `maxUsers=0` (ilimitado).

**Referência de implementação:** `MaintenanceItemService.validateItemLimit()` (mesma estrutura).

---

### TASK-097-B — `maxOrganizations`: enforcement na criação (não só no downgrade)
**Gap:** `maxOrganizations` é validado em `UserPlanChangeService.validateDowngradeLimits()` — ou seja,
o limite é checado quando o usuário tenta fazer downgrade de plano. Mas `OrganizationsService.create()`
não valida o limite no momento da criação, permitindo que um usuário FREE (limite 1) crie 2 organizações
sem bloqueio.

**O que fazer:**
- Adicionar validação em `OrganizationsService.create()`: buscar a subscription do usuário atual
  (`USER` source type), checar `countByUserId >= maxOrganizations`.
- Lançar `RuleException`: `"Limite de organizações atingido (X/Y). Faça upgrade do plano."`.
- Criar `OrganizationPlanLimitTest` cobrindo: no limite, excedido, abaixo do limite, `maxOrganizations=0` (ilimitado).

**Observação:** O teste de downgrade existente em `UserPlanChangeServiceTest` cobre o caso de
`validateDowngradeLimits` — manter esse comportamento intacto, apenas complementar com a criação.

---

### TASK-097-C — `emailMonthlyLimit`: testes unitários para `BusinessEmailQuotaService`
**Gap:** `BusinessEmailQuotaService.canSend()` e `validateCanSend()` estão implementados e chamados
corretamente em `BusinessEmailNotificationService`, mas não existe nenhum teste unitário para o serviço.

**O que fazer:**
- Criar `BusinessEmailQuotaServiceTest` cobrindo:
  - `canSend_returnsTrue_whenBelowMonthlyLimit()`
  - `canSend_returnsFalse_whenAtMonthlyLimit()`
  - `canSend_returnsFalse_whenNoSubscription()`
  - `canSend_returnsFalse_whenEmailLimitIsZero()`
  - `validateCanSend_throwsRuntimeException_whenLimitReached()`

---

## Critérios de Aceite

- [x] `UsersService.addOrganization()` lança `RuleException` quando `currentUsers >= maxUsers` do plano ✅ TASK-097-A
- [x] `OrganizationsService.validateOrgLimit()` lança `RuleException` quando `currentOrgs >= maxOrganizations` do plano ✅ TASK-097-B
- [x] `maxUsers=0` e `maxOrganizations=0` continuam tratados como "ilimitado" (mesma semântica de `maxItems`) ✅ cobertos em TASK-097-A e TASK-097-B
- [x] `BusinessEmailQuotaServiceTest` com 5 cenários passando ✅ TASK-097-C
- [x] `UserPlanLimitTest` com cenários: no limite, excedido, abaixo, sem assinatura, ilimitado ✅ 6 testes passando
- [x] `OrganizationPlanLimitTest` com cenários equivalentes ✅ 5 testes passando
- [x] Suite completa (447 testes) passando sem falhas ✅

## Esforço Estimado
Médio — 3 subtasks independentes, implementação segue padrão já estabelecido em `validateItemLimit()`.
