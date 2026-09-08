# TASK-236 — BUGFIX: E-mail de `TRIAL_EXPIRING` mostra data errada e cliente fica sem prazo real de pagamento

## Tipo
BUGFIX

## Categoria
Backend / Billing / Notificações (trial → cobrança)

## Prioridade
🔴 Alto — afeta diretamente conversão de trial pagante: cliente recebe aviso com data de vencimento
falsa e, mesmo se ignorar isso, o acesso é cortado sem nenhuma folga real para pagar.

## Épico
Sem épico — achado investigando um caso real reportado por Douglas (cliente Ricardo Cerqueira,
`actioncond@gmail.com`, 08/09/2026). Tematicamente relacionado ao EPIC-010 (PIX funcional), já
concluído, mas esse bug é específico do fluxo de expiração de TRIAL, não de renovação PIX recorrente
(que já tem grace period — ver Causa raiz).

## QA obrigatório
Sim — QA manual: simular um trial vencendo hoje (via `/dev/simulate` ou ajustando `currentPeriodEnd`
em ambiente de teste), rodar `processTrialsExpiringWithinDays`, e confirmar que (1) a data no e-mail
bate com o `dueDate` real da cobrança criada no Asaas, e (2) o acesso do usuário só vira `READ_ONLY`
depois do grace period configurado, não no segundo exato em que `currentPeriodEnd` é ultrapassado.

---

## Contexto

Douglas recebeu de um cliente em trial (Ricardo Cerqueira, signup 25/08/2026, trial de 14 dias
vencendo hoje 08/09/2026) uma cópia do e-mail `TRIAL_EXPIRING` disparado às 2026-09-08 01:15:01 pelo
`DailyTrialJob`. O e-mail mostrava **"Data de vencimento: 2026-10-12"**, mas o link de pagamento
(`https://www.asaas.com/i/5tdq9sxaxip1cnrj`) apontava para uma cobrança PIX real no Asaas com
**`dueDate: "2026-09-08"` (hoje)** — confirmado no payload do webhook `PAYMENT_CREATED`
(`dateCreated: "2026-09-07 22:15:02"`).

Investigação (sessão `claude.ai/code/session_013ugTaWTu859xeFZsSiMY8u`) encontrou 3 problemas
empilhados, não só o texto errado:

### 1. Data errada no corpo do e-mail

`TrialExpirationService.sendTrialExpirationEmail` (linha 270) usa `invoice.getDueDate()` pra
preencher o e-mail:

```java
String html = emailTemplateHelper.generateSubscriptionExpirationHtml(
    payer.getName(), paymentLink, invoice.getDueDate().toString());
```

Mas a cobrança real no Asaas usa outro valor, `nextDueDate` (linha 81: `LocalDate nextDueDate =
invoice.getPeriodStart();`), passado tanto pro PIX detached (`createPixDetachedCharge`) quanto pro
checkout (`mapToAsaasCheckoutRequest`). `Invoice.dueDate` é calculado em
`InvoiceService.processPayerInvoice` como `periodEnd.plusDays(5)` — um conceito de "vencimento da
próxima fatura mensal + carência", sem relação com a cobrança de trial que acabou de ser criada.
Números do caso real batem exatamente: `periodStart` (= `nextDueDate`, cobrado no Asaas) =
2026-09-08; `periodEnd` = 2026-10-07; `dueDate` da invoice = `periodEnd + 5d` = **2026-10-12**, a
data errada que apareceu no e-mail.

Comparação com um caller correto do mesmo template: `BillingNotificationService.sendPixRenewalEmail`
(fluxo de renovação PIX recorrente) recebe o `dueDate` como parâmetro explícito, vindo de
`PixRenewalService`, sempre o mesmo valor usado na cobrança — só `TrialExpirationService` diverge.

### 2. Cobrança do trial não tem lead time — vencimento é sempre "hoje"

`nextDueDate = invoice.getPeriodStart()` é `LocalDate.now()` no momento em que o `DailyTrialJob`
roda (todo dia, 01:15, `daysAhead=1`) — **não** é o `currentPeriodEnd` real da assinatura. Ou seja, a
cobrança Asaas nasce sempre com vencimento "hoje" (dia do job), nunca amarrada à data real de fim do
trial nem com nenhuma folga.

### 3. Corte de acesso é instantâneo e sem grace — pior que assinatura paga inadimplente

`SubscriptionAccessService.resolveEffectiveStatus` (linha 65-70) roda em tempo real a cada
request e derruba `TRIAL → TRIAL_EXPIRED → READ_ONLY` no exato segundo em que
`Instant.now() > currentPeriodEnd`, sem nenhuma tolerância e independente de cobrança criada/e-mail
enviado. Comparando com o que já existe pra assinatura **paga**: `SubscriptionBlockingService` dá 3
dias de graça (`billing.blocking.days-after-due:3`) entre `PAST_DUE` e `BLOCKED` antes de cortar
acesso. **Cliente em trial hoje tem menos tolerância que cliente pagante inadimplente.**

Runway real observado no caso do Ricardo: como `currentPeriodEnd = signup + 14 dias` (mesmo horário
do dia do signup, `BillingSubscriptionService.createTrial`, linha 357/363) e o job roda sempre às
01:15, a janela entre "e-mail recebido" e "acesso cortado" varia de poucas horas a quase 24h
dependendo do horário do signup original — nunca é um prazo previsível ou comunicado corretamente ao
cliente.

### Fator adicional mapeado (não incluído no escopo desta task)

PIX detached (`createPixDetachedCharge`) não passa nenhum parâmetro de expiração explícito pro Asaas
— a validade do QR fica a critério do comportamento padrão do Asaas em cima do `dueDate` (hoje sem
folga). Resolvendo o problema 2 (dueDate real), esse ponto tende a melhorar como efeito colateral,
mas vale confirmar em sandbox depois — registrado aqui só como observação, não como critério de
aceite.

## Causa raiz

Resumo: `TrialExpirationService` usa duas fontes de data diferentes e desalinhadas (`invoice.dueDate`
pro e-mail vs. `invoice.periodStart` pra cobrança real), e o cálculo de `nextDueDate` nunca olha o
`currentPeriodEnd` real da assinatura — sempre usa "hoje". Separadamente, `SubscriptionAccessService`
não tem noção de grace period pra TRIAL, diferente do padrão já usado (e validado em produção) pra
assinatura paga via `SubscriptionBlockingService`.

## Escopo (proposto, a confirmar no `/execute-task`)

Decisão com Douglas: implementar as opções **B** (cobrança com vencimento real) + **C1** (grace
period cirúrgico reaproveitando o padrão já existente de `days-after-due`).

### Opção B — cobrança e e-mail com vencimento real
- `TrialExpirationService`: trocar `nextDueDate = invoice.getPeriodStart()` para usar o
  `currentPeriodEnd` real da `BillingSubscription` (convertido pra `LocalDate`) como vencimento da
  cobrança — tanto no PIX detached quanto no checkout.
- `sendTrialExpirationEmail`: passar esse mesmo `nextDueDate` real pro e-mail em vez de
  `invoice.getDueDate()`.
- Avaliar se `InvoiceService.processPayerInvoice` precisa de um `dueDate` diferenciado pro fluxo de
  trial, já que hoje hardcoda `periodEnd.plusDays(5)` pra todo invoice — decidir durante o
  `/execute-task` se o campo `Invoice.dueDate` deve refletir o valor real de trial ou se continua
  representando "vencimento da fatura mensal" (conceito diferente) sem impacto na cobrança/e-mail.

### Opção C1 — grace period antes do corte de acesso
- `SubscriptionAccessService.resolveEffectiveStatus`: comparar `Instant.now()` contra
  `currentPeriodEnd.plus(graceDays)` em vez de `currentPeriodEnd` puro, com `graceDays` configurável
  (reaproveitar `billing.blocking.days-after-due` ou criar propriedade própria pro trial — decidir no
  `/execute-task` se faz sentido usar o mesmo valor de 3 dias ou um número diferente).
- Rodar toda a suíte de testes de `SubscriptionAccessService`/`FeatureAccessService` — método é
  chamado em toda checagem de acesso do sistema, superfície de teste ampla.

## Critérios de Aceite

- [x] E-mail de `TRIAL_EXPIRING` mostra a mesma data usada como `dueDate` na cobrança Asaas real
      (PIX e checkout)
- [x] `dueDate` da cobrança de trial deixa de ser sempre "hoje" (dia do job) e passa a refletir o
      `currentPeriodEnd` real da assinatura
- [x] Acesso do trial só vira `TRIAL_EXPIRED`/`READ_ONLY` depois do grace period configurado, não no
      segundo exato em que `currentPeriodEnd` é ultrapassado
- [x] Teste reproduzindo o caso real (trial vencendo, e-mail e cobrança gerados) confirmando data
      consistente entre e-mail e Asaas — falhando sem o fix antes de reaplicar
- [x] Testes de `SubscriptionAccessService` cobrindo: dentro do grace (ainda `FULL_ACCESS`), fora do
      grace (`READ_ONLY`) — falhando sem o fix antes de reaplicar
- [x] `mvn clean test` sem regressão (atenção especial a qualquer teste existente de
      `SubscriptionAccessService`/`FeatureAccessService` que assuma corte instantâneo)

## Dependências
Nenhuma.

## Riscos
Médio — a mudança em `SubscriptionAccessService.resolveEffectiveStatus` (Opção C1) toca um método
usado em toda checagem de acesso do sistema (usuário e organização), não só no fluxo de trial;
qualquer teste existente que assuma corte instantâneo no `currentPeriodEnd` pode quebrar e precisa
ser revisado, não só re-executado. A Opção B é mais isolada (só `TrialExpirationService`), risco
baixo.

## Esforço
Médio (B: ~4-6h, C1: ~4-6h — total próximo de 1 dia)

## Implementação

### Arquivos criados / modificados

| Arquivo | Operação |
|---|---|
| `jobs/service/TrialExpirationService.java` | `resolveDueDate(BillingSubscription)` novo (mesmo padrão de `CardTransitionService`/`PixRenewalService`); cobrança (PIX e checkout) e e-mail passam a usar o mesmo `currentPeriodEnd` real em vez de `invoice.getPeriodStart()`/`invoice.getDueDate()` |
| `infrastructure/access/application/service/SubscriptionAccessService.java` | `resolveEffectiveStatus`: `static` → instância, com grace period configurável (`billing.trial.grace-days`, novo `@Value`) |
| `infrastructure/access/application/service/FeatureAccessService.java` | 3 chamadas estáticas migradas para o bean injetado (`subscriptionAccessService.resolveEffectiveStatus`) |
| `application.properties` | `billing.trial.grace-days=3` (novo, independente de `billing.blocking.days-after-due`) |
| `test/.../TrialExpirationServiceTest.java` | 2 testes novos (vencimento real usado na cobrança/e-mail; fallback pra hoje quando `currentPeriodEnd` já passou) |
| `test/.../SubscriptionAccessServiceTest.java` | bloco `resolveEffectiveStatus` convertido de chamada estática pra instância; 4 testes novos de grace period (`resolveEffectiveStatus` e `resolveUserAccessMode`, dentro/fora do grace) |
| `test/.../FeatureAccessServiceTest.java` | 2 testes existentes ajustados — precisam stubar `resolveEffectiveStatus` no mock agora que deixou de ser estático |

### Decisões tomadas durante a implementação
- `InvoiceService.processPayerInvoice`/`Invoice.dueDate` (`periodEnd.plusDays(5)`) **não foi alterado** — decidido manter como conceito à parte (vencimento da fatura mensal), já que também é usado fora do fluxo de trial (histórico/admin de invoices); `TrialExpirationService` simplesmente parou de ler esse campo.
- `billing.trial.grace-days` ganhou propriedade própria (não reaproveitou `billing.blocking.days-after-due`) — mesmo default (3 dias) mas configurável de forma independente, já que são conceitos distintos (trial vs. assinatura paga inadimplente).

### Verificação
`git stash` do código de produção (mantendo os testes novos) confirmou vermelho: `FeatureAccessServiceTest` (2 erros), `SubscriptionAccessServiceTest` (4 erros), `TrialExpirationServiceTest` (1 falha + 1 erro). Após restaurar o fix: `mvn clean test` → **918/918, 0 falhas**.

Branch `bugfix/TASK-236-trial-expiring-wrong-due-date` (a partir de `staging`), commit `333f941`. Sem PR aberta ainda.

## QA Manual
[TASK-QA-MAN-017](../QA/tasks/TASK-QA-MAN-017.md) — plano local (setup via SQL sintético + Asaas
sandbox/MailHog para Opção B, `UPDATE` em usuário de teste existente para Opção C1/grace period).
Ainda não executado.

## Status
🟡 Implementada, aguardando QA manual (TASK-QA-MAN-017) e decisão de abrir PR
