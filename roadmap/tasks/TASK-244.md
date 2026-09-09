# TASK-244 — BUGFIX: `TrialExpirationService` gera cobrança/e-mail duplicados a cada execução do job

## Tipo
BUGFIX

## Categoria
Backend / Billing / Jobs (trial → cobrança)

## Prioridade
🔴 Crítico — gera cobranças reais duplicadas no Asaas (link de pagamento novo, e-mail novo) para
qualquer usuário em trial vencido e não pago, todo dia em que o job/endpoint roda, sem limite. Impacto
financeiro e de confiança do cliente (cliente recebe múltiplos e-mails/links cobrando o mesmo trial).

## Épico
Sem épico — achado durante a validação em produção da TASK-236 (fix de data do `TRIAL_EXPIRING`),
mesmo cliente real (Ricardo Cerqueira). Relatado por Douglas em 09/09/2026: após publicar o fix da
TASK-236 em PRD, uma nova cobrança e um novo link de pagamento foram gerados no Asaas para o Ricardo
(e-mail e vencimento desta vez corretos), mesmo já existindo uma cobrança criada horas antes pelo
`DailyTrialJob` das 01:15.

## QA obrigatório
Sim — QA manual: com um trial vencido e não pago (status `TRIAL` no banco, `currentPeriodEnd` no
passado), disparar `processTrialsExpiringWithinDays` (via `DailyTrialJob` ou
`GET /run-jobs/execute-trial-expiration`) duas vezes em dias de calendário diferentes (ou forçando
`LocalDate.now()` diferente) e confirmar que a segunda execução **não** cria uma nova invoice, nova
cobrança Asaas nem novo e-mail — deve reconhecer que aquele ciclo de trial já foi cobrado.

---

## Contexto

Investigação (sessão `claude.ai/code/session_01BxgbppjMN1KnyHgAQFnopf`) partindo do relato de Douglas:
o mesmo cliente (Ricardo, caso já documentado na TASK-236) recebeu uma **segunda** cobrança/link Asaas
no mesmo dia em que o fix da TASK-236 foi publicado em produção, mesmo já existindo uma cobrança para
aquele trial gerada pela execução normal do `DailyTrialJob` (01:15).

### Causa raiz

`TrialExpirationService.processTrialsExpiringWithinDays` (linha 62-71) monta o período da invoice a
partir de `LocalDate.now()`, recalculado a cada execução:

```java
LocalDate periodStart = LocalDate.now();
LocalDate periodEnd = periodStart.plusMonths(1).minusDays(1);
invoiceService.generateInvoices(periodStart, periodEnd, List.of(SubscriptionStatus.TRIAL), threshold);
```

A única proteção contra duplicidade é o dedup de `InvoiceService.processPayerInvoice` (linha 137):
`repository.findByPayerIdAndPeriodStartAndPeriodEnd(payerId, periodStart, periodEnd)`. Como
`periodStart` muda todo dia (é sempre "hoje"), essa chave nunca bate entre duas execuções em dias
diferentes — o dedup não protege nada além de "duas execuções no mesmíssimo dia, sem cruzar meia-noite
do fuso do servidor".

Agravantes:
- `BillingSubscriptionRepository.findEligibleForInvoicing` (linha 34-37) filtra
  `status = TRIAL AND currentPeriodEnd < threshold`, **sem limite superior**. Uma vez que
  `currentPeriodEnd` já passou, a assinatura fica elegível para sempre.
- `status = TRIAL` no banco **nunca muda sozinho** com o tempo. `TRIAL_EXPIRED` só existe como valor
  calculado em tempo real dentro de `SubscriptionAccessService.resolveEffectiveStatus` (usado para
  bloquear acesso), nunca é persistido de volta em `BillingSubscription.status`.
- Resultado prático: **todo usuário em trial vencido e não pago recebe uma cobrança Asaas + link de
  pagamento + e-mail novos a cada execução do job** (cron diário `0 15 1 * * *`, ou disparo manual via
  `GET /run-jobs/execute-trial-expiration`, usado inclusive pelo roteiro de QA da TASK-236), até o
  cliente pagar. Isso não é um efeito colateral pontual de termos mexido na data — é um bug estrutural
  independente do fix da TASK-236, apenas exposto por ele.
- `GET /run-jobs/execute-trial-expiration` (`JobController.java:42-47`) roda
  `processTrialsExpiringWithinDays` sob demanda para **todos** os trials elegíveis (não um usuário
  específico) e, embora exija autenticação (`SecurityConfig`: `/easy-maintenance/**` cai em
  `anyRequest().authenticated()`), qualquer chamada nele reprocessa a base inteira — provavelmente foi
  o gatilho da segunda cobrança do Ricardo, validando o fix da TASK-236 em produção.

### Comparação com o padrão correto (já existente e validado em produção)

`PixRenewalService.renewSubscription` (linha 71-125), fluxo irmão de renovação PIX recorrente, evita
exatamente esse problema com **duas** camadas:
1. Ancora o período no `resolveDueDate(subscription)` (o `currentPeriodEnd` real da assinatura, estável
   entre execuções em dias diferentes) em vez de `LocalDate.now()` — o dedup por período em
   `processPayerInvoice` funciona de verdade.
2. Guarda explícita e independente do período da invoice: `cycleNumber` incremental por assinatura
   (`paymentRepository.findMaxCycleNumberByBillingSubscriptionId` +
   `findByBillingSubscriptionIdAndCycleNumber`) — se já existe um `Payment` para aquele ciclo, pula sem
   criar nada no Asaas nem disparar e-mail.

`TrialExpirationService` não tem nenhuma das duas proteções: usa `InvoiceService.generateInvoices`
(método "em lote", pensado para várias assinaturas compartilhando o mesmo período de calendário — ex.:
faturamento mensal de assinaturas ativas), que não se encaixa no caso de trial, onde cada assinatura
tem sua própria data de fim. `TrialExpirationService` é o único chamador desse método.

## Escopo (proposto, a confirmar no `/execute-task`)

Replicar em `TrialExpirationService` o padrão já validado em produção pelo `PixRenewalService`:

- Trocar a estrutura em lote (`generateInvoices` com período único para todas as assinaturas) por
  iteração por assinatura, usando `InvoiceService.generateInvoiceForPayer(payerId, periodStart,
  periodEnd)` com `periodStart = resolveDueDate(subscription)` (já existe, linha 122-129) em vez de
  `LocalDate.now()` global — resolve a causa raiz do período instável.
- Adicionar guarda explícita de idempotência por assinatura antes de criar a cobrança Asaas — mesmo
  espírito do `cycleNumber` do PIX: já existe um `Payment` de expiração de trial pendente/criado para
  essa `BillingSubscription` e esse `currentPeriodEnd`? Se sim, pular (log + sem nova chamada Asaas,
  sem novo e-mail). Decidir no `/execute-task` a chave exata (reaproveitar algo como `cycleNumber` ou
  usar `billingSubscriptionId` + referência à invoice/período já registrados).
- Avaliar se `findEligibleForInvoicing` precisa de ajuste (hoje sem limite superior) ou se a guarda de
  idempotência acima já é suficiente sozinha — decidir durante o `/execute-task`.

## Critérios de Aceite

- [x] Rodar `processTrialsExpiringWithinDays` duas vezes para o mesmo trial vencido, em dias de
      calendário diferentes, gera cobrança Asaas + e-mail **apenas na primeira vez**
- [x] `GET /run-jobs/execute-trial-expiration` chamado repetidamente não duplica cobrança/e-mail para
      nenhum trial já processado (mesma guarda vale para os dois pontos de entrada, já que ambos caem
      em `processTrialsExpiringWithinDays`)
- [x] Teste reproduzindo o caso real (mesmo trial, duas execuções do job em dias diferentes) —
      falhando sem o fix antes de reaplicar
- [x] `mvn clean test` sem regressão, atenção especial a `TrialExpirationServiceTest` e qualquer teste
      de `PixRenewalService`/`InvoiceService.generateInvoices` que assuma o comportamento atual

## Dependências
TASK-236 (fix de data do e-mail/cobrança de trial) — já mergeada, não bloqueia mas é o contexto direto.

## Riscos
Baixo-médio — mudança isolada em `TrialExpirationService` (não toca `SubscriptionAccessService` nem
fluxo de assinatura paga). Atenção a não quebrar o caso legítimo de "trial venceu, cliente não pagou,
prazo de graça também passou, precisa continuar aparecendo em relatórios/QA" — a guarda deve impedir
nova cobrança/e-mail, não esconder o usuário de outras rotinas.

## Esforço
Pequeno-médio (~3-5h: fix + guarda de idempotência + testes de regressão).

## Implementação

### Arquivos modificados

| Arquivo                                                     | Operação                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `jobs/service/TrialExpirationService.java`                  | `processTrialsExpiringWithinDays` reescrito: itera direto sobre `BillingSubscriptionRepository.findEligibleForInvoicing` (removida a dependência de `InvoiceService.generateInvoices`/`BillingSubscriptionService.findByUser`), com isolamento de falha por assinatura (try/catch no loop, mesmo espírito de `PixRenewalService.processPixRenewals`); nova guarda `paymentRepository.existsByBillingSubscriptionId(subscriptionId)` antes de gerar qualquer cobrança; período da invoice (`generateInvoiceForPayer`) ancorado em `resolveDueDate(subscription)` em vez de `LocalDate.now()` |
| `payment/infrastructure/persistence/PaymentRepository.java` | novo método `existsByBillingSubscriptionId(Long)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `test/.../TrialExpirationServiceTest.java`                  | testes existentes adaptados ao novo fluxo (mock de `BillingSubscriptionRepository` em vez de `BillingSubscriptionService`); 3 testes novos: guarda de idempotência isolada, job rodando duas vezes pro mesmo trial (só a 1ª cria cobrança/e-mail), isolamento de falha entre assinaturas diferentes; teste de vencimento real (TASK-236) estendido pra também capturar o período passado a `generateInvoiceForPayer`                                                                                                                                                                        |

### Decisões tomadas durante a implementação
- `InvoiceService.generateInvoices` (o método em lote usado antes por `TrialExpirationService`) **não foi
  removido** — é testado de forma independente em `InvoiceServiceTest` como capacidade genérica de
  `InvoiceService`, não exclusiva do fluxo de trial; `TrialExpirationService` simplesmente parou de
  chamá-lo, mesma decisão já tomada na TASK-236 para `Invoice.dueDate`.
- Guarda de idempotência escolhida: "já existe algum `Payment` para essa `BillingSubscription`" —
  mais simples que o `cycleNumber` do `PixRenewalService`, mas equivalente em efeito, já que um trial
  só é processado por este fluxo uma única vez na vida da assinatura (diferente de PIX, que tem ciclos
  recorrentes).
- Isolamento de falha por assinatura adicionado ao restructurar o loop (antes, uma exceção em qualquer
  assinatura fazia rollback de toda a transação do lote, inclusive invoices/pagamentos já criados para
  outras assinaturas na mesma execução) — mesmo padrão defensivo já usado por `PixRenewalService`.

### Verificação
`mvn clean test` → **938/938, 0 falhas** (contra as 918 da TASK-236 — 20 testes novos/ajustados nesta
task, sem regressão em `PixRenewalServiceTest`, `InvoiceServiceTest`, `SubscriptionAccessServiceTest`
nem `FeatureAccessServiceTest`). Reconfirmado em sessão de finalização (09/09/2026), mesmo resultado
938/938 antes do commit.

Branch `bugfix/TASK-244-trial-duplicate-charge-email` (a partir de `staging`), commit `98a4716`.
QA manual aprovada por Douglas em [TASK-QA-MAN-019](../QA/tasks/TASK-QA-MAN-019.md) (09/09/2026) —
dois trials sintéticos vencidos e sem `Payment` prévio, cada um gerou exatamente 1 cobrança/e-mail
Asaas, sem duplicidade em reexecuções nem vazamento entre assinaturas.

## Status
🟢 Implementado, testado (`mvn test` 938/938), commitado (`98a4716`) e validado manualmente contra
Asaas sandbox ([TASK-QA-MAN-019](../QA/tasks/TASK-QA-MAN-019.md), aprovado por Douglas 09/09/2026) —
PR aberta para `staging`.
