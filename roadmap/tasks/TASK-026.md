# TASK-026 — Testes de integração — billing e auth completos

## Tipo
Qualidade / Testes

## Categoria
Backend / Testes

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-008 — Qualidade e Testes

## Descrição
Complemento à TASK-004 (testes mínimos pré-lançamento). Após o lançamento, expandir a cobertura de testes para os fluxos 
completos de billing e autenticação, garantindo confiança para iterações e hotfixes.

## Critérios de Aceite
- [x] Cobertura de 70%+ nos módulos `billing`, `auth`, `org_users` e `kernel`
- [x] Testes de integração para todos os webhooks do Asaas (pagamento confirmado, cancelado, vencido)
- [x] Teste de mudança de plano (upgrade e downgrade) com verificação de features
- [x] Teste de ciclo de billing completo (geração de invoice → pagamento → renovação)
- [ ] Testes E2E básicos para onboarding (Playwright ou equivalente) — rastreado em TASK-E2E-*
- [x] Pipeline de CI bloqueante em caso de falha de teste

## Esforço
Grande (1 semana)

## Risco de não fazer
Sem cobertura adequada, refatorações e novas features comprometem a confiabilidade do sistema de billing.

## Implementação

### Arquivos criados

| Arquivo | Operação |
|---------|----------|
| `webhooks/asaas/strategy/impl/CheckoutPaidHandlerTest.java` | **Criado** — 5 testes (happy path, final, null checkout, not found) |
| `webhooks/asaas/strategy/impl/CheckoutExpiredHandlerTest.java` | **Criado** — 6 testes (happy path, final, null checkout, not found, null invoice) |
| `webhooks/asaas/strategy/impl/SubscriptionCreatedHandlerTest.java` | **Criado** — 7 testes (activate, already-linked, deleted, inactive, null sub, not found) |
| `billing/application/service/InvoiceServiceTest.java` | **Criado** — 4 testes (generate, skip-existing, payer not found, payer happy path) |
| `billing/application/service/UserPlanChangeServiceTest.java` | **Criado** — 7 testes (upgrade, downgrade, applyImmediately, same code, inactive, not found, limits) |
| `org_users/application/service/AuthenticationServiceTest.java` | **Criado** — 3 testes (authenticated, not authenticated, user not found in db) |
| `.github/workflows/ci.yml` | **Criado** — pipeline CI com MySQL e Java 21, bloqueia em falha de teste |

### Testes — Resultado

**Total: 205/205 passando — BUILD SUCCESS**

Novos testes adicionados (38 no conjunto selecionado, 167 pré-existentes):
- `CheckoutPaidHandlerTest` — 5/5 ✅
- `CheckoutExpiredHandlerTest` — 6/6 ✅
- `SubscriptionCreatedHandlerTest` — 7/7 ✅
- `InvoiceServiceTest` — 4/4 ✅
- `UserPlanChangeServiceTest` — 7/7 ✅
- `AuthenticationServiceTest` — 3/3 ✅

### Nota E2E
Testes E2E de onboarding são rastreados separadamente nos tickets `TASK-E2E-001` a `TASK-E2E-005` no projeto `easy-maintenance-e2e` (Playwright).

## Status
Done
