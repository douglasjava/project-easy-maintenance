# TASK-QA-MAN-017 — QA Manual: TRIAL_EXPIRING com vencimento real + grace period

## Tipo
QA Manual

## Categoria
Backend / Billing, Notificações (trial → cobrança), Controle de Acesso

## Prioridade
🔴 Alto

## Tasks cobertas
[TASK-236](../../tasks/TASK-236.md) — E-mail de `TRIAL_EXPIRING` com data errada + acesso sem grace period

---

## Descrição

Valida as duas correções da TASK-236, rodando 100% local (sem depender de nenhum cliente real em trial):

- **Opção B** — `TrialExpirationService`: a cobrança criada no Asaas (PIX e Cartão) e o e-mail de aviso
  passam a usar o vencimento real do trial (`BillingSubscription.currentPeriodEnd`), não mais "hoje"
  (dia em que o job rodou) nem `invoice.getDueDate()` (campo de outro conceito, ~34 dias errado no
  caso real que originou a task).
- **Opção C1** — `SubscriptionAccessService`: o acesso só vira `READ_ONLY` depois de um grace period
  configurável (`billing.trial.grace-days`, default 3 dias) após o vencimento do trial, não mais no
  segundo exato em que `currentPeriodEnd` é ultrapassado.

Toda a implementação está na branch `bugfix/TASK-236-trial-expiring-wrong-due-date`
(`easy-maintenance-api`, commit `333f941`), sem PR aberta ainda.

---

## Pré-condições

- Checkout da branch acima, API rodando local (perfil `local`).
- `ASAAS_API_KEY` sandbox configurada (`asaas.base-url=https://sandbox.asaas.com/api/v3` já é o
  default do perfil local) — necessária pra C3/C4/C5, que criam cobrança real no Asaas sandbox.
- MailHog rodando (padrão do perfil local) — necessário pra C3/C4/C5, que disparam o e-mail
  `TRIAL_EXPIRING` de verdade.
- Acesso ao MySQL local (cliente de sua preferência: `mysql` CLI, DBeaver, Workbench) com as
  migrations do Flyway já aplicadas (`billing_plans` precisa ter a linha `BUSINESS`, já vem seedada
  pela `V21`).
- Para **C6/C7** (grace period): um usuário local que você já consegue logar (e-mail/senha
  conhecidos) com uma `BillingSubscription` própria — pode ser sua conta de teste de sempre. Não é
  necessário criar usuário novo pra esses dois cenários.

⚠️ Todo dado criado por este plano usa `code`/e-mail prefixados `QA-TASK236-*` — sintético,
seguro de rodar local/dev. **Não rodar contra staging/produção.**

---

## Cenários de Teste

### C1 — Suíte automatizada, sem regressão

| Passo | Ação                                                                       | Resultado esperado                                                                                                                               |
|-------|----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| 1     | `mvn clean test` na branch `bugfix/TASK-236-trial-expiring-wrong-due-date` | **918/918 testes passando**, incluindo os novos casos de `TrialExpirationServiceTest`/`SubscriptionAccessServiceTest`/`FeatureAccessServiceTest` |

Já executado e confirmado durante a implementação (ver `TASK-236.md`, seção Implementação) —
incluindo verificação vermelho→verde real via `git stash` do código de produção.

---

### C2 — Setup: criar as 3 subscriptions sintéticas do Opção B

Rodar o script completo abaixo de uma vez (MySQL, sessão única — os `SET @var = LAST_INSERT_ID()`
dependem da ordem de execução dentro da mesma sessão).

```sql
-- ============================================================
-- TASK-236 / TASK-QA-MAN-017 — setup local (sintético, seguro pra local/dev)
-- ============================================================

-- Confirma que o plano usado pelo trial real já existe (seedado pela V21, não deveria falhar)
SELECT code FROM billing_plans WHERE code = 'BUSINESS';

-- CPF de checksum válido, uso genérico em testes (529.982.247-25) — só pra passar a validação do
-- Asaas ao criar o customer sandbox just-in-time (resolveExternalCustomerId).
--
-- IMPORTANTE: o endpoint /checkouts do Asaas (fluxo de Cartão, C4) exige que o customer já tenha
-- endereço completo (address/addressNumber/postalCode/province/city) -- diferente de /payments
-- (PIX, C3/C5), que aceita sem. Por isso os 3 billing_accounts abaixo já vêm com endereço
-- preenchido, mesmo os PIX -- evita 400 "O campo address deve existir para o customer informado."

-- ------------------------------------------------------------
-- C3 — PIX, dentro da janela do job (daysAhead=2): currentPeriodEnd = amanhã
-- Espera-se: dueDate da cobrança Asaas = amanhã; e-mail mostra a MESMA data (não "hoje", não
-- periodEnd+5d da invoice mensal)
-- ------------------------------------------------------------
INSERT INTO organizations (code, name, company_type, require_2fa)
VALUES ('QA-TASK236-C3', 'QA TASK-236 C3 PIX', 'CONDOMINIUM', false);
SET @org_c3 = LAST_INSERT_ID();

INSERT INTO users (email, name, role, status, password_hash)
VALUES ('qa-task236-c3@teste.local', 'QA Trial C3 PIX', 'ADMIN', 'ACTIVE', 'sem-login-necessario');
SET @user_c3 = LAST_INSERT_ID();

INSERT INTO user_organizations (user_id, organization_code) VALUES (@user_c3, 'QA-TASK236-C3');

INSERT INTO billing_accounts
  (user_id, billing_email, name, payment_method, doc, street, number, neighborhood, city, state, zip_code)
VALUES
  (@user_c3, 'qa-task236-c3@teste.local', 'QA TASK-236 C3 PIX', 'PIX', '52998224725',
   'Avenida Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', '01310100');
SET @account_c3 = LAST_INSERT_ID();

INSERT INTO billing_subscriptions
  (billing_account_id, status, cycle, current_period_start, current_period_end, total_cents)
VALUES
  (@account_c3, 'TRIAL', 'MONTHLY', NOW(), NOW() + INTERVAL 1 DAY, 19900);
SET @sub_c3 = LAST_INSERT_ID();

INSERT INTO billing_subscription_items
  (billing_subscription_id, source_type, source_id, plan_code, value_cents)
VALUES (@sub_c3, 'USER', @user_c3, 'BUSINESS', 19900);

SELECT @sub_c3 AS c3_subscription_id, NOW() + INTERVAL 1 DAY AS c3_expected_due_date;

-- ------------------------------------------------------------
-- C4 — Cartão (checkout), dentro da janela do job: currentPeriodEnd = daqui a 2 dias
-- Espera-se: subscription.dueDate/dueDateLimit do checkout Asaas = essa data; mesma data no e-mail
-- ------------------------------------------------------------
INSERT INTO organizations (code, name, company_type, require_2fa)
VALUES ('QA-TASK236-C4', 'QA TASK-236 C4 CARD', 'CONDOMINIUM', false);
SET @org_c4 = LAST_INSERT_ID();

INSERT INTO users (email, name, role, status, password_hash)
VALUES ('qa-task236-c4@teste.local', 'QA Trial C4 CARD', 'ADMIN', 'ACTIVE', 'sem-login-necessario');
SET @user_c4 = LAST_INSERT_ID();

INSERT INTO user_organizations (user_id, organization_code) VALUES (@user_c4, 'QA-TASK236-C4');

INSERT INTO billing_accounts
  (user_id, billing_email, name, payment_method, doc, street, number, neighborhood, city, state, zip_code)
VALUES
  (@user_c4, 'qa-task236-c4@teste.local', 'QA TASK-236 C4 CARD', 'CARD', '52998224725',
   'Avenida Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', '01310100');
SET @account_c4 = LAST_INSERT_ID();

INSERT INTO billing_subscriptions
  (billing_account_id, status, cycle, current_period_start, current_period_end, total_cents)
VALUES
  (@account_c4, 'TRIAL', 'MONTHLY', NOW(), NOW() + INTERVAL 2 DAY, 19900);
SET @sub_c4 = LAST_INSERT_ID();

INSERT INTO billing_subscription_items
  (billing_subscription_id, source_type, source_id, plan_code, value_cents)
VALUES (@sub_c4, 'USER', @user_c4, 'BUSINESS', 19900);

SELECT @sub_c4 AS c4_subscription_id, NOW() + INTERVAL 2 DAY AS c4_expected_due_date;

-- ------------------------------------------------------------
-- C5 — Fallback: job "atrasado", currentPeriodEnd já no passado (simula reprocessamento tardio)
-- Espera-se: dueDate cai pra HOJE (fallback do resolveDueDate), nunca uma data passada
-- ------------------------------------------------------------
INSERT INTO organizations (code, name, company_type, require_2fa)
VALUES ('QA-TASK236-C5', 'QA TASK-236 C5 FALLBACK', 'CONDOMINIUM', false);
SET @org_c5 = LAST_INSERT_ID();

INSERT INTO users (email, name, role, status, password_hash)
VALUES ('qa-task236-c5@teste.local', 'QA Trial C5 Fallback', 'ADMIN', 'ACTIVE', 'sem-login-necessario');
SET @user_c5 = LAST_INSERT_ID();

INSERT INTO user_organizations (user_id, organization_code) VALUES (@user_c5, 'QA-TASK236-C5');

INSERT INTO billing_accounts
  (user_id, billing_email, name, payment_method, doc, street, number, neighborhood, city, state, zip_code)
VALUES
  (@user_c5, 'qa-task236-c5@teste.local', 'QA TASK-236 C5 Fallback', 'PIX', '52998224725',
   'Avenida Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', '01310100');
SET @account_c5 = LAST_INSERT_ID();

INSERT INTO billing_subscriptions
  (billing_account_id, status, cycle, current_period_start, current_period_end, total_cents)
VALUES
  (@account_c5, 'TRIAL', 'MONTHLY', NOW() - INTERVAL 24 DAY, NOW() - INTERVAL 10 DAY, 19900);
SET @sub_c5 = LAST_INSERT_ID();

INSERT INTO billing_subscription_items
  (billing_subscription_id, source_type, source_id, plan_code, value_cents)
VALUES (@sub_c5, 'USER', @user_c5, 'BUSINESS', 19900);

SELECT @sub_c5 AS c5_subscription_id, CURDATE() AS c5_expected_due_date;
```

Anote os 3 `subscription_id` retornados (`@sub_c3`, `@sub_c4`, `@sub_c5`) — usados na conferência
pós-job.

> Se mesmo assim a criação do customer/checkout falhar com 400 no seu sandbox (endereço já vem
> preenchido acima, mas o Asaas pode exigir outro campo específico da sua conta sandbox — ex.
> telefone), ajuste o `INSERT INTO billing_accounts` do usuário em questão com o campo pedido pela
> mensagem de erro, ou informe direto um `external_customer_id` de um customer sandbox já existente.

⚠️ **`processTrialsExpiringWithinDays` é `@Transactional` no método inteiro** — se qualquer cenário
do lote falhar (ex.: C4 dando 400 no Asaas), a exceção propaga e desfaz a transação **inteira**,
incluindo os cenários que já tinham dado certo antes dele (C3/C5 nesse exemplo). As linhas de
`organizations`/`users`/`billing_accounts`/`billing_subscriptions`/`billing_subscription_items`
inseridas pelo seu SQL direto continuam no banco (não fazem parte dessa transação), então **não
precisa refazer o INSERT do zero** — só corrija o que causou o erro e rode o job de novo:

```sql
-- Exemplo: corrigir endereço de uma conta já inserida (troque o e-mail pelo que falhou)
UPDATE billing_accounts ba
JOIN users u ON u.id = ba.user_id
SET ba.street = 'Avenida Paulista', ba.number = '1000', ba.neighborhood = 'Bela Vista',
    ba.city = 'São Paulo', ba.state = 'SP', ba.zip_code = '01310100'
WHERE u.email = 'qa-task236-c4@teste.local';
```

Depois, chame `GET /run-jobs/execute-trial-expiration` de novo — a geração de invoice é idempotente
por período/payer, então C3/C5 (que não tinham invoice ainda, por causa do rollback) são reprocessados
normalmente junto com o C4 corrigido.

(Nota lateral, sem impacto no teste: o customer criado no Asaas sandbox na tentativa que falhou
— `cus_000009038174` no log do exemplo — fica órfão lá, já que o `externalCustomerId` não foi
persistido por causa do rollback; no rerun, `resolveExternalCustomerId` cria um customer novo pro
mesmo `billing_account`. Sem problema pro teste, só um registro a mais no sandbox.)

---

### C3 — PIX dentro da janela: cobrança e e-mail com o vencimento real

| Passo | Ação                                                                                                                                                                | Resultado esperado                                                                       |
|-------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| 1     | Rodar o setup de C3 (bloco acima)                                                                                                                                   | `@sub_c3` anotado                                                                        |
| 2     | `GET /easy-maintenance/api/v1/run-jobs/execute-trial-expiration` (job usa `daysAhead=2`)                                                                            | 200, sem erro                                                                            |
| 3     | Abrir MailHog (`http://localhost:8025` por padrão) e localizar o e-mail enviado pra `qa-task236-c3@teste.local`, assunto "Renove sua assinatura - Easy Maintenance" | E-mail chegou                                                                            |
| 4     | Conferir o campo **"Data de vencimento"** no corpo do e-mail                                                                                                        | Bate com `NOW() + 1 dia` anotado no setup (não pode ser ~34 dias no futuro — bug antigo) |
| 5     | `SELECT payment_link FROM payments WHERE billing_subscription_id = <@sub_c3>;` e abrir o link retornado                                                             | Abre a página de cobrança PIX no Asaas sandbox                                           |
| 6     | Conferir "Data de vencimento" na página do Asaas                                                                                                                    | **Idêntica** à do e-mail (passo 4) — é o cerne do bug original                           |

---

### C4 — Cartão (checkout) dentro da janela: mesma validação, outro método

| Passo | Ação                                                                                                      | Resultado esperado                                     |
|-------|-----------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| 1     | Setup de C4 já rodado junto do bloco C2                                                                   | `@sub_c4` anotado                                      |
| 2     | Já disparado no mesmo `GET /run-jobs/execute-trial-expiration` do C3 (roda todos os elegíveis de uma vez) | —                                                      |
| 3     | Localizar no MailHog o e-mail pra `qa-task236-c4@teste.local`                                             | Data de vencimento = `NOW() + 2 dias` anotado no setup |
| 4     | `SELECT payment_link FROM payments WHERE billing_subscription_id = <@sub_c4>;` e abrir o checkout Asaas   | Vencimento do checkout bate com a mesma data do e-mail |

---

### C5 — Fallback: `currentPeriodEnd` já no passado não gera cobrança retroativa

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Setup de C5 já rodado junto do bloco C2 | `@sub_c5` anotado |
| 2 | Já disparado no mesmo `GET /run-jobs/execute-trial-expiration` | — |
| 3 | Localizar no MailHog o e-mail pra `qa-task236-c5@teste.local` | Data de vencimento = **hoje** (`CURDATE()`), nunca uma data no passado |
| 4 | `SELECT payment_link FROM payments WHERE billing_subscription_id = <@sub_c5>;` e abrir no Asaas sandbox | Vencimento = hoje, cobrança válida (Asaas rejeitaria `dueDate` no passado se o fallback não existisse) |

---

### ✅ Resultado real da execução (08/09/2026, após correção do endereço)

| Cenário | `current_period_end` | Data no e-mail (MailHog) | `dueDate` enviado ao Asaas (log) | Link Asaas |
|---|---|---|---|---|
| C3 (PIX) | 2026-09-09 13:32:39 | **2026-09-09** | `"2026-09-09"` | `sandbox.asaas.com/i/y0rskn8866hvim0i` |
| C4 (Cartão) | 2026-09-10 13:33:21 | **2026-09-10** | (checkout, mesma data no `subscription.nextDueDate`) | `sandbox.asaas.com/checkoutSession/show/cb7779ca-...` |
| C5 (fallback) | 2026-08-29 13:33:51 (já passado) | **2026-09-08 (hoje)** | `"2026-09-08"` | `sandbox.asaas.com/i/3r2obc5avavc20x8` |

E-mail e cobrança Asaas batem exatamente em todos os 3 — bug original (data do e-mail divergente do
vencimento real) confirmado corrigido. C5 confirma o fallback: `currentPeriodEnd` no passado não gera
cobrança retroativa, cai pra hoje.

**Nota à parte (não é regressão da TASK-236):** o checkout do Asaas sandbox (C4) mostrou expiração de
link de ~1h na tela, mesmo `asaas.checkout-minutes-to-expire=120` (2h) sendo o que a API manda no
request. Campo não tocado por esta task — comportamento aparenta ser do sandbox Asaas (possível teto
próprio pra conta de teste), não do nosso código. Sem impacto nos critérios de aceite da TASK-236.

---

### C6 — Dentro do grace period: acesso permanece liberado

Troque `SEU-USUARIO-DE-TESTE@...` pelo e-mail de um usuário local que você já loga (a
`BillingSubscription` dele será temporariamente alterada — restaure ao final, passo 5).

```sql
-- Localizar a subscription do usuário de teste
SELECT bs.id AS subscription_id, bs.status, bs.current_period_end
FROM billing_subscriptions bs
JOIN billing_accounts ba ON ba.id = bs.billing_account_id
JOIN users u ON u.id = ba.user_id
WHERE u.email = 'SEU-USUARIO-DE-TESTE@...';

-- Trial "venceu" há 1 dia; grace default = 3 dias => ainda dentro da tolerância
UPDATE billing_subscriptions
SET status = 'TRIAL', current_period_end = NOW() - INTERVAL 1 DAY
WHERE id = <subscription_id anotado acima>;
```

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Rodar o UPDATE acima | 1 linha afetada |
| 2 | Logado como esse usuário, chamar `GET /easy-maintenance/api/v1/me/access-context` (ou abrir o dashboard no frontend) | `accountAccess.subscriptionStatus = "TRIAL"`, `accountAccess.accessMode = "FULL_ACCESS"` — sistema **não** bloqueia, mesmo com o trial já formalmente vencido há 1 dia |
| 3 | No frontend, navegar por uma tela que exige `FULL_ACCESS` (ex.: cadastrar item) | Funciona normalmente, sem bloqueio |

---

### C7 — Fora do grace period: acesso vira somente leitura

```sql
-- Trial "venceu" há 4 dias; grace default = 3 dias => grace já esgotado
UPDATE billing_subscriptions
SET status = 'TRIAL', current_period_end = NOW() - INTERVAL 4 DAY
WHERE id = <mesmo subscription_id de C6>;
```

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Rodar o UPDATE acima | 1 linha afetada |
| 2 | Chamar `GET /me/access-context` (mesmo usuário) | `accountAccess.subscriptionStatus = "TRIAL_EXPIRED"`, `accountAccess.accessMode = "READ_ONLY"` |
| 3 | No frontend, tentar uma ação que exige `FULL_ACCESS` | Bloqueada / somente leitura |
| 4 | **Regressão**: rodar o mesmo teste com `current_period_end = NOW() + INTERVAL 7 DAY` (trial ainda válido) | Continua `FULL_ACCESS` — grace period não interferiu no caso normal |
| 5 | **Restaurar o usuário ao final**: `UPDATE billing_subscriptions SET current_period_end = NOW() + INTERVAL 14 DAY WHERE id = <subscription_id>;` | Usuário de teste volta ao estado normal |

---

### ✅ Resultado real da execução (08/09/2026)

Conta usada: `douglasmarquesdias+T2508@gmail.com` (`subscription_id = 6`, valor original
`current_period_end = 2026-09-08 22:01:11`, restaurado ao final).

| Cenário | `current_period_end` aplicado | `subscriptionStatus` | `accessMode` | `canCreateItem` (org) |
|---|---|---|---|---|
| C6 (dentro do grace, -1 dia) | 2026-09-07 13:56:22 | `TRIAL` | **`FULL_ACCESS`** | `true` |
| C7 (fora do grace, -4 dias) | 2026-09-04 14:15:50 | `TRIAL_EXPIRED` | **`READ_ONLY`** | `false` |

Confirmado via `GET /me/access-context` real (payload completo anexado na execução), nos dois
níveis (`accountAccess` e `organizationsAccess`). Grace period de 3 dias funcionando exatamente
como projetado nos dois limites — dentro ainda libera acesso total, fora derruba pra somente
leitura com a mensagem correta ("Seu período de trial encerrou..."/"Trial expirado..."). Conta
restaurada ao valor original ao final.

---

### C8 (opcional) — Confirmação direta via curl, sem depender do frontend

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | `curl http://localhost:8080/easy-maintenance/api/v1/run-jobs/execute-trial-expiration` | 200 |
| 2 | `curl -H "Cookie: <cookie da sessão logada>" http://localhost:8080/easy-maintenance/api/v1/me/access-context \| jq .accountAccess` | Confere `subscriptionStatus`/`accessMode` igual às tabelas de C6/C7 |

---

## Limpeza (rodar ao final, C3/C4/C5)

```sql
DELETE bsi FROM billing_subscription_items bsi
  JOIN billing_subscriptions bs ON bs.id = bsi.billing_subscription_id
  JOIN billing_accounts ba ON ba.id = bs.billing_account_id
  JOIN users u ON u.id = ba.user_id
  WHERE u.email IN ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE p FROM payments p
  JOIN billing_subscriptions bs ON bs.id = p.billing_subscription_id
  JOIN billing_accounts ba ON ba.id = bs.billing_account_id
  JOIN users u ON u.id = ba.user_id
  WHERE u.email IN ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE bs FROM billing_subscriptions bs
  JOIN billing_accounts ba ON ba.id = bs.billing_account_id
  JOIN users u ON u.id = ba.user_id
  WHERE u.email IN ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE ba FROM billing_accounts ba
  JOIN users u ON u.id = ba.user_id
  WHERE u.email IN ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE uo FROM user_organizations uo
  JOIN users u ON u.id = uo.user_id
  WHERE u.email IN ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE FROM users WHERE email IN
  ('qa-task236-c3@teste.local','qa-task236-c4@teste.local','qa-task236-c5@teste.local');

DELETE FROM organizations WHERE code IN
  ('QA-TASK236-C3','QA-TASK236-C4','QA-TASK236-C5');
```

(C6/C7 não criam dado novo — só a `UPDATE` de restauração no passo final de C7 já limpa.)

---

## Critérios de Aceite da Suíte

- [X] C1: suíte automatizada sem regressão (918/918)
- [X] C2: setup roda sem erro, 3 subscriptions sintéticas criadas (após correção do endereço em `billing_accounts`)
- [X] C3: e-mail e cobrança PIX mostram a mesma data real (`currentPeriodEnd`), não mais a data errada do bug original
- [X] C4: mesmo resultado pro fluxo de Cartão/checkout
- [X] C5: `currentPeriodEnd` no passado cai pra hoje, nunca gera cobrança com vencimento retroativo
- [X] C6: trial vencido há 1 dia (dentro do grace de 3) continua `FULL_ACCESS`
- [X] C7: trial vencido há 4 dias (fora do grace) vira `READ_ONLY`/`TRIAL_EXPIRED`
- [ ] C8 (opcional): contratos via curl — não executado (coberto pelo C6/C7 via `/me/access-context` real)

## Status
✅ Executada e aprovada (08/09/2026) — todos os cenários C1-C7 confirmados contra ambiente real
(Asaas sandbox, MailHog, `/me/access-context` autenticado). C8 opcional não executado, redundante
com C6/C7. Dado sintético de C3/C4/C5 ainda no banco — rodar a seção "Limpeza" antes de reusar os
e-mails `qa-task236-*@teste.local` em outro teste.
