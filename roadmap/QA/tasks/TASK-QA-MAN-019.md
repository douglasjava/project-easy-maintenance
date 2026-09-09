# TASK-QA-MAN-019 — QA Manual: TASK-244 (Trial não duplica cobrança/e-mail Asaas)

## Tipo
QA Manual

## Categoria
Backend / Billing / Jobs — impacto financeiro direto (cobrança real no Asaas)

## Prioridade
🔴 Crítico

## Task coberta
[TASK-244](../../tasks/TASK-244.md) — bug que gerava uma nova cobrança Asaas + link de pagamento +
e-mail a cada execução do job de expiração de trial, para qualquer trial vencido e não pago.

---

## Descrição

Valida que `TrialExpirationService.processTrialsExpiringWithinDays` (disparado pelo cron
`DailyTrialJob` às 01:15 ou sob demanda via `GET /run-jobs/execute-trial-expiration`) **não** cria
uma nova cobrança/e-mail quando rodado mais de uma vez para o mesmo trial vencido.

Implementação na branch `bugfix/TASK-244-trial-duplicate-charge-email` (a partir de `staging`),
commit `98a4716`, `easy-maintenance-api`. Sem PR aberta ainda.

⚠️ Importante sobre este roteiro em relação ao original descrito em TASK-244: o critério de aceite
original pedia rodar o job "em dias de calendário diferentes". A guarda de idempotência escolhida
na implementação (`paymentRepository.existsByBillingSubscriptionId`) **não depende da data** — ela
verifica só se já existe algum `Payment` para aquela `BillingSubscription`. Então rodar o endpoint
duas vezes seguidas, no mesmo dia, já é suficiente para validar o fix — não precisa manipular
`LocalDate.now()` nem esperar virar o dia. Os passos abaixo refletem isso (mais simples que o
roteiro original).

⚠️ **Este cenário chama o Asaas de verdade.** Rode contra o ambiente local com as credenciais
sandbox do Asaas (não staging/produção), do mesmo jeito que o `DailyTrialJob` já rodava antes do
fix — só que agora só deve criar UMA cobrança, não uma por execução.

---

## Pré-condições

- Checkout de `bugfix/TASK-244-trial-duplicate-charge-email` no `easy-maintenance-api`, rodando
  local (perfil `local`, credenciais sandbox do Asaas configuradas — as mesmas já usadas para
  validar TASK-236).
- MailHog rodando (padrão do perfil local) — necessário para conferir o e-mail de expiração de
  trial.
- Precisa de uma organização/usuário com assinatura em trial vencido (`status = TRIAL` no banco,
  `current_period_end` no passado). Se não tiver um à mão, criar um sintético — ver setup abaixo.
- `mvn test` já rodado nesta sessão contra o commit `98a4716`: **938/938, 0 falhas** (inclui os 3
  testes novos de `TrialExpirationServiceTest`: guarda de idempotência isolada, job rodando duas
  vezes pro mesmo trial, isolamento de falha entre assinaturas diferentes).

⚠️ Se criar dado novo, prefixe com `QA-TASK244-*` — sintético, seguro de rodar local/dev. **Não
rodar contra staging/produção** (cobrança real no Asaas sandbox já é suficiente pra validar).

---

## Cenários de Teste

### C1 — Suíte automatizada, sem regressão

| Passo | Ação                                                                     | Resultado esperado |
|-------|---------------------------------------------------------------------------|---------------------|
| 1     | `mvn clean test` na branch `bugfix/TASK-244-trial-duplicate-charge-email` | **938/938**, sem falha em `TrialExpirationServiceTest`, `PixRenewalServiceTest` ou `InvoiceServiceTest` |

Já executado e confirmado nesta sessão.

---

### C2 — Setup: trial vencido e não pago

Se já tiver um usuário/organização em trial vencido de outra rodada de QA (ex.: o caso do Ricardo
citado em TASK-236/TASK-244), pode reaproveitar — pular para C3. Senão, criar um sintético:

```sql
-- localizar (ou criar) um usuário/organização de teste com billing_account já existente
SELECT bs.id AS subscription_id, bs.status, bs.current_period_end, ba.user_id
FROM billing_subscriptions bs
JOIN billing_accounts ba ON ba.id = bs.billing_account_id
WHERE bs.status = 'TRIAL'
ORDER BY bs.id DESC
LIMIT 5;

-- se precisar forçar um trial existente a ficar "vencido":
UPDATE billing_subscriptions
SET current_period_end = NOW() - INTERVAL 3 DAY
WHERE id = <subscription_id>;

-- confirmar que não existe pagamento prévio pra essa assinatura (senão o teste não é válido)
SELECT * FROM payments WHERE billing_subscription_id = <subscription_id>;
```

Anote `<subscription_id>` — vai usar para conferir o resultado nos próximos passos.

---

### C3 — Primeira execução: cria cobrança + e-mail

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | `GET http://localhost:8080/easy-maintenance/api/v1/run-jobs/execute-trial-expiration` (autenticado) | 200, sem erro |
| 2 | `SELECT * FROM payments WHERE billing_subscription_id = <subscription_id>` | Exatamente **1** linha nova, com `paymentLink`/`externalPaymentId` preenchidos |
| 3 | Conferir no painel do Asaas sandbox (ou `GET` na API do Asaas pelo `externalPaymentId`) | Cobrança existe, valor/vencimento batem com o plano da assinatura |
| 4 | Abrir MailHog (`http://localhost:8025`) | E-mail de expiração de trial chegou pro e-mail do payer, com o link de pagamento |
| 5 | Log da aplicação | Linha `Create Subscription And Payment for Provider ...` — **não** deve aparecer `Trial expiration payment already exists ... Skipping` nesta primeira execução |

---

### C4 — Segunda execução: **não** duplica (o cenário que este QA existe pra provar)

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Repetir exatamente o mesmo `GET .../run-jobs/execute-trial-expiration` de novo (mesmo dia, sem esperar nada) | 200, sem erro |
| 2 | `SELECT * FROM payments WHERE billing_subscription_id = <subscription_id>` | Ainda **exatamente 1** linha — a mesma do C3, nenhuma nova |
| 3 | Painel do Asaas sandbox | Nenhuma cobrança nova criada para esse cliente |
| 4 | MailHog | Nenhum e-mail novo de expiração de trial pra esse payer |
| 5 | Log da aplicação | Linha `Trial expiration payment already exists for subscription <subscription_id>. Skipping.` |
| 6 | (Opcional, reforça a robustez) Repetir mais 1-2 vezes | Mesmo resultado — sempre skip, nunca duplica |

---

### C5 — Isolamento: outro trial vencido, sem `Payment` ainda, continua sendo processado

Garante que a guarda de idempotência não "trava" o job inteiro nem esconde outros trials legítimos.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Ter (ou criar) um **segundo** trial vencido, diferente do C2, sem `Payment` prévio | — |
| 2 | Rodar `GET .../run-jobs/execute-trial-expiration` de novo | Esse segundo trial recebe sua cobrança/e-mail normalmente (mesmo comportamento do C3), **e** o trial do C2 continua não gerando nada novo (mesmo comportamento do C4) — confirma que o loop isola por assinatura e não há vazamento entre elas |

---

### C6 — `DailyTrialJob` (cron) usa o mesmo caminho

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Conferir `DailyTrialJob.java` | Chama `trialExpirationService.processTrialsExpiringWithinDays(...)` — mesmo método validado em C3/C4, não precisa de teste manual separado pro cron em si |

---

## Limpeza (dados sintéticos do C2/C5, se criados)

```sql
DELETE FROM payments WHERE billing_subscription_id IN (<subscription_id>, <subscription_id_2>);
-- reverter current_period_end se foi alterado num trial real (não sintético)
```

---

## Critérios de Aceite da Suíte

- [ ] C1: `mvn clean test` 938/938 sem regressão
- [ ] C2: trial vencido de teste disponível, sem `Payment` prévio
- [ ] C3: primeira execução cria 1 cobrança Asaas + 1 e-mail
- [ ] C4: segunda execução (mesmo dia) **não** cria cobrança nem e-mail novos — log mostra skip
- [ ] C5: um segundo trial vencido continua sendo processado normalmente (sem vazamento entre assinaturas)
- [ ] C6: `DailyTrialJob` confirmado como o mesmo caminho de código (não precisa rodar via cron de verdade)

## Status
🟡 Aguardando execução por Douglas — implementação e testes automatizados prontos (commit `98a4716`
na branch `bugfix/TASK-244-trial-duplicate-charge-email`), falta validar C2-C5 contra Asaas sandbox
real antes de abrir a PR para `staging`.
