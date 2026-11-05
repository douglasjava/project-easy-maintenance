# TASK-245 — BUGFIX: `POST /me/onboarding/user` duplica item USER da assinatura (cobrança em dobro)

## Tipo
BUGFIX

## Categoria
Backend / Billing / Onboarding

## Prioridade
🔴 Crítico — corrompe `billing_subscriptions.total_cents` (dobra o valor cobrado) e derruba
`POST /organizations` (500) pra qualquer usuário afetado.

## Épico
Sem épico — achado por Douglas durante o QA manual do EPIC-028 (TASK-QA-MAN-020), testando
`/organizations/new`, não relacionado ao módulo de fornecedores.

## QA obrigatório
Sim — confirmar que chamar `POST /me/onboarding/user` duas vezes pro mesmo usuário não duplica o
item USER nem altera `total_cents`, e que `POST /organizations` volta a funcionar pro usuário
afetado (6, `douglasmarquesdias+T2508@gmail.com`).

---

## Contexto

Reportado por Douglas: criar uma organização nova (`/organizations/new`) retornava 500:

```
org.springframework.dao.IncorrectResultSizeDataAccessException: Query did not return a unique result: 2 results were returned
```

### Causa raiz

`OnboardingService.createUser` (chamado por `POST /me/onboarding/user`, sem nenhuma proteção de
idempotência na API — qualquer usuário autenticado pode chamar de novo):

```java
var billingSubscription = billingSubscriptionService.findByUser(user.getId())
        .orElseGet(() -> billingSubscriptionService.createTrial(savedAccount, Duration.ofDays(14)));

var trialPlan = getBillingPlanByCode("BUSINESS");
billingSubscriptionService.addItem(billingSubscription, BillingSubscriptionItemSourceType.USER, ...);
```

Encontra a `BillingSubscription` existente (branch `orElseGet` não roda) mas segue direto pro
`addItem(USER, ...)` **incondicional** — cria um segundo `BillingSubscriptionItem` USER na MESMA
assinatura toda vez que o endpoint é chamado de novo pra um usuário que já tinha completado o
onboarding antes.

Efeito em cascata, confirmado no banco local (usuário 6):
- `billing_subscription_items`: 2 linhas `USER` (ids 16 e 28) na mesma `billing_subscription_id=6`
- `BillingSubscriptionService.addItem` recalcula `total_cents` somando **todos** os itens — resultado
  **59800** (2× o preço do plano BUSINESS, 29900) em vez de 29900
- Qualquer código que assume "no máximo 1 item USER por assinatura" via
  `billingSubscriptionItemRepository.findBySourceTypeAndSourceId(...)` (retorna `Optional`, espera
  0 ou 1 linha) quebra com `NonUniqueResultException`/`IncorrectResultSizeDataAccessException`
  assim que isso acontece — `OrganizationsService.validateOrgLimit` (o que gerou o 500 reportado),
  `OrganizationsService.addOrganizationSubscription`, `UsersService.provisionOrganizationBilling`,
  `SubscriptionAccessService`, `AiCreditService`, `BillingAccountService`, `BillingDashboardService`,
  `PaymentReceivedHandler`.

### Padrão correto (já existente em outro lugar do código)

`OrganizationsService.addOrganizationSubscription` já guarda exatamente esse caso certo: só chama
`addItem(USER, ...)` dentro do `else` (quando `existingSubscription` estava vazio) — nunca no
branch em que a subscription já existia. `OnboardingService.createUser` não seguia o mesmo padrão.

## Escopo

- `OnboardingService.createUser`: só chamar `addItem(USER, ...)` quando `findByUser` não encontrou
  assinatura existente (mesmo padrão do `addOrganizationSubscription`).
- Reparo de dado no ambiente local (fora do código): removida a linha duplicada
  (`billing_subscription_items.id = 28`) e recalculado `billing_subscriptions.total_cents` (6 →
  29900) pro usuário 6. Nenhum outro usuário na base local tinha a mesma duplicidade.

## Critérios de Aceite

- [x] Teste reproduzindo o bug (`createUser` chamado duas vezes pro mesmo usuário) — falhando sem
      o fix, passando depois
- [x] `total_cents` não dobra numa segunda chamada
- [x] `mvn test` sem regressão
- [x] Dado corrompido do usuário 6 reparado no ambiente local (`total_cents` de volta a 29900, item
      duplicado removido)
- [ ] Douglas confirma que `POST /organizations` volta a funcionar pra ele em ambiente real

## Dependências
Nenhuma.

## Riscos
Baixo — fix isolado (1 guarda condicional), mesmo padrão já usado em outro serviço do mesmo módulo.
Risco real já materializado é o motivo da task (cobrança em dobro), não algo introduzido por ela.

## Esforço
Pequeno (~1h: root cause + fix + teste + reparo de dado)

## Implementação

### Arquivos modificados
| Arquivo | Operação |
|---|---|
| `onboarding/application/service/OnboardingService.java` | `createUser`: `addItem(USER, ...)` movido pra dentro de `if (existingSubscription.isEmpty())` — só roda quando a subscription acabou de ser criada nesta chamada |
| `test/.../onboarding/application/service/OnboardingServiceTest.java` | Novo teste `createUser_calledTwiceForSameUser_doesNotDuplicateUserItem` — reproduz o bug real (chamada dupla), falhando antes do fix (2 itens USER, `total_cents=59800`), passando depois (1 item, `total_cents=29900`) |

### Verificação
- `mvn clean test` → **939/939, 0 falhas** (938 já existentes em `staging` + 1 teste novo).
- Reparo manual confirmado no MySQL local: `billing_subscription_items` do usuário 6 voltou a ter
  só 1 linha USER, `billing_subscriptions.total_cents = 29900`.

Branch `bugfix/TASK-245-duplicate-user-billing-item` (a partir de `staging`, independente da branch
do EPIC-028 — bug não relacionado a fornecedores). Sem PR aberta ainda — falta Douglas confirmar
`POST /organizations` funcionando de novo no ambiente dele antes de abrir a PR.

## Status
🟡 Implementado, testado (`mvn test` 939/939) e dado local reparado — aguardando confirmação do
Douglas antes de abrir a PR pra `staging`.

## Atualização 24/09/2026
A correção (commit `1477e13`, 09/09) **nunca tinha sido mergeada** — o bug seguia ativo em PRD
(no onboarding, "← Voltar" no passo 2 + "Próximo" já duplicava o item USER). Redescoberta durante a
TASK-289/291. Branch atualizada com `staging` via merge (sem conflito), teste de regressão conferido
por mutação (falha sem a correção), `mvn test` 1102/1102.
PR: [api#119](https://github.com/douglasjava/easy-maintenance-api/pull/119) (`staging`).

**Status atualizado:** 🟡 Em Validação — PR aberta contra `staging`; pré-requisito da TASK-291.
