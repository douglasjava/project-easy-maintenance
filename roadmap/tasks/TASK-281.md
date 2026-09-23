# TASK-281 — `/private/admin/financials` não contabiliza receita de cartão (filtro de status incompleto)

## Tipo
BUGFIX

## Categoria
Backend / Billing (Financials)

## Prioridade
🔴 Alto — dado financeiro exibido ao admin está subestimado; qualquer pagamento originado por
checkout de cartão fica invisível na receita, em qualquer mês, não só setembro.

## Épico
Sem épico — achado por Douglas em 23/09/2026 ao validar o pagamento de cartão do usuário produtivo
(userId=2, ver histórico da conversa/validação do webhook Asaas do mesmo dia).

## QA obrigatório
Sim — dado financeiro exibido ao admin.

---

## Contexto / Causa raiz

`FinancialsService.buildMonth()` (`billing/application/service/FinancialsService.java:72-73`) soma
receita bruta/líquida do mês filtrando **só** `PaymentStatus.RECEIVED`:

```java
long revenueGrossCents = nvl(paymentRepository.sumAmountCentsByStatusAndPaidAtBetween(PaymentStatus.RECEIVED, start, end));
long revenueNetCents = nvl(paymentRepository.sumNetAmountCentsByStatusAndPaidAtBetween(PaymentStatus.RECEIVED, start, end));
```

`PaymentRepository.sumAmountCentsByStatusAndPaidAtBetween`/`sumNetAmountCentsByStatusAndPaidAtBetween`
fazem igualdade exata (`p.status = :status`), sem `OR`/`IN` com outros status.

O problema: **`PaymentStatus.RECEIVED` só é setado pelo `PaymentReceivedHandler`**, reagindo ao
webhook Asaas `PAYMENT_RECEIVED` — que, na prática, só é exercitado pelo fluxo de assinatura
recorrente "PIX manual" (`shouldAdvanceCycle`: `subscription.getExternalSubscriptionId() == null`).

Pagamentos originados por **checkout de cartão** (troca de método PIX→CC, ativação de assinatura via
`PaymentMethodTransitionService.initiateCardUpdate`) nunca recebem `PAYMENT_RECEIVED` — eles fecham
via `PAYMENT_CREATED` (que seta `PaymentStatus.PAID` quando o payload já vem `CONFIRMED`/`RECEIVED`
da Asaas, `PaymentCreatedHandler.java:103-104`) e/ou `CHECKOUT_PAID` (que seta
`PaymentStatus.CHECKOUT_PAID`, `CheckoutPaidHandler.java:66`). Nenhum dos dois nunca vira `RECEIVED`.

Caso real confirmado (userId=2, `pay_ub6qpsk6hmvp2u4n`): `payments.status = PAID`,
`gateway_status = CONFIRMED`, `paid_at = 2026-08-31`. Webhooks confirmados no `webhook_event`:
`PAYMENT_CREATED`, `PAYMENT_CONFIRMED`, `CHECKOUT_PAID` — nunca `PAYMENT_RECEIVED`. Esse valor
(R$ 299,00 bruto / R$ 289,57 líquido) não aparece em nenhum mês da tela `/private/admin/financials`.

Evidência de que `PAID` já é tratado como "assentado" em outro lugar do próprio código —
`PaymentReceivedHandler.java:118`:
```java
if (payment.getStatus() == PaymentStatus.RECEIVED || payment.getStatus() == PaymentStatus.PAID) {
    // idempotente — já settled
}
```
Ou seja, o filtro do financials é o único ponto do sistema que trata `PAID` como "não conta".

Sem risco de dupla contagem: `Payment.status` é um único campo por linha (não um log de eventos) —
somar `WHERE status IN (...)` continua contando cada `Payment` exatamente uma vez, só muda **quais**
status entram no filtro.

Achado à parte, não bloqueia este fix (investigar depois se necessário): `invoices.updated_at` da
fatura desse pagamento (18:07:17) é ~3h depois do último webhook visto (`CHECKOUT_PAID` às
15:13:48 nesse dia, considerando também o `PAYMENT_CHECKOUT_VIEWED` sem handler) — não identificamos
ainda o que tocou a invoice nesse intervalo; a assinatura foi ativada corretamente via
`SUBSCRIPTION_CREATED` (`SubscriptionCreatedHandler`), que não depende do status do `Payment`.

## Escopo da correção

1. **`PaymentRepository`** — trocar os 2 métodos de soma de status único para status múltiplo
   (únicos consumidores confirmados: `FinancialsService`, sem outros callers no código):
   ```java
   @Query("SELECT COALESCE(SUM(p.amountCents), 0) FROM Payment p WHERE p.status IN :statuses AND p.paidAt BETWEEN :start AND :end")
   Long sumAmountCentsByStatusInAndPaidAtBetween(@Param("statuses") Collection<PaymentStatus> statuses, @Param("start") Instant start, @Param("end") Instant end);

   @Query("SELECT COALESCE(SUM(p.netAmountCents), 0) FROM Payment p WHERE p.status IN :statuses AND p.paidAt BETWEEN :start AND :end")
   Long sumNetAmountCentsByStatusInAndPaidAtBetween(@Param("statuses") Collection<PaymentStatus> statuses, @Param("start") Instant start, @Param("end") Instant end);
   ```
2. **`FinancialsService`** — definir o conjunto de status "receita assentada" uma vez
   (`private static final Set<PaymentStatus> SETTLED_STATUSES = Set.of(PaymentStatus.RECEIVED, PaymentStatus.PAID, PaymentStatus.CHECKOUT_PAID);`)
   e usar nos dois `paymentRepository.sum...` de `buildMonth()`.
3. **Testes** (`FinancialsServiceTest`):
   - atualizar os mocks existentes (`eq(PaymentStatus.RECEIVED)` → `eq(SETTLED_STATUSES)` ou
     `any()`, conforme o mock já usa `any()` na maioria dos testes — checar caso a caso).
   - novo teste cobrindo o caso real: pagamento `PAID` (cartão/checkout) contado junto com um
     `RECEIVED` (PIX) no mesmo mês, somando ambos.
   - teste negativo: `PENDING`/`FAILED`/`CANCELED`/`REFUNDED`/`OVERDUE`/`EXPIRED` continuam fora da
     soma (guarda de regressão).
4. **Frontend**: nenhuma mudança necessária — `FinancialsDTO.MonthlyFinancialsResponse` não muda de
   formato, só os valores agregados passam a refletir a receita real.
5. **Validação em produção (read-only)**: antes de considerar concluído, rodar de novo a query
   ```sql
   SELECT p.id, p.status, p.method_type, p.amount_cents, p.paid_at
   FROM payments p
   WHERE p.status IN ('PAID','CHECKOUT_PAID') AND p.paid_at IS NOT NULL
   ORDER BY p.paid_at;
   ```
   para dimensionar quantos meses passados vão mudar de valor quando o fix for pro ar — avisar
   Douglas que números de meses já "fechados" vão subir (correção, não regressão nova).

## Critérios de Aceite
- [x] `/private/admin/financials` (via `GET /admin/financials`) passa a contar pagamentos com
      status `PAID` e `CHECKOUT_PAID`, além de `RECEIVED`, na receita bruta/líquida do mês —
      implementado (`FinancialsService.SETTLED_PAYMENT_STATUSES`)
- [~] Pagamento real do userId=2 (`pay_ub6qpsk6hmvp2u4n`, R$ 299,00, `paid_at` 2026-08-31) aparece
      no mês de agosto/2026 ao consultar o endpoint — reproduzido de forma equivalente em teste
      sintético (`PaymentRepositoryPersistenceTest`, RECEIVED+PAID+CHECKOUT_PAID somados contra H2
      real); **não confirmado contra o banco de produção** — pendente Douglas conferir
      `/private/admin/financials` ou a query SQL após o deploy
- [x] Teste de regressão cobrindo: soma de múltiplos status settled no mesmo mês + status não-settled
      continuam excluídos — `PaymentRepositoryPersistenceTest` (2 testes, H2 real via `@DataJpaTest`)
- [x] `mvn clean test` sem regressão — **1060/1060**, 0 falhas, 0 erros
- [x] Nenhum outro caller dos métodos alterados de `PaymentRepository` quebrado — confirmado via grep
      antes do rename (único consumidor era `FinancialsService`/seu teste)

## Dependências
Nenhuma.

## Riscos
- Baixo tecnicamente (mudança aditiva em filtro de leitura, sem migration, sem mudança de contrato
  de API).
- Risco de percepção: valores de meses já fechados vão mudar (subir) — comunicar antes de publicar,
  não é uma regressão nova, é a correção do subcontado.

## Esforço
Pequeno (~1-2h): 1 query de repositório + 1 ajuste de service + testes.

## Implementação

- Branch: `bugfix/TASK-281-financials-missing-card-revenue` (a partir de `staging`, commit base
  `670ef33`)
- `PaymentRepository`: `sumAmountCentsByStatusAndPaidAtBetween`/`sumNetAmountCentsByStatusAndPaidAtBetween`
  renomeados para `...StatusInAndPaidAtBetween`, assinatura trocada de `PaymentStatus status` pra
  `Collection<PaymentStatus> statuses`, JPQL `p.status = :status` → `p.status IN :statuses`
- `FinancialsService`: nova constante `SETTLED_PAYMENT_STATUSES = {RECEIVED, PAID, CHECKOUT_PAID}`,
  usada nos dois `paymentRepository.sum...` de `buildMonth()`
- `FinancialsServiceTest`: mocks atualizados pro novo nome/assinatura; teste
  `getMonthlyFinancials_computesGrossNetFeeAndBalance` agora verifica explicitamente que o conjunto
  de 3 status é passado ao repositório (`eq(SETTLED_STATUSES)`)
- Novo `PaymentRepositoryPersistenceTest` (`@DataJpaTest` + H2 real, mesmo padrão de
  `InvoiceRepositoryPersistenceTest`): 2 testes — soma `RECEIVED`+`PAID`+`CHECKOUT_PAID` no mesmo mês
  ignorando `PENDING`/`OVERDUE`; e caso sem nenhum pagamento settled retorna zero
- Frontend: nenhuma mudança (DTO `MonthlyFinancialsResponse` não muda de forma)
- `mvn clean test`: **1060/1060**, 0 falhas, 0 erros

## Status
🟡 Em Validação — implementado, testado (`mvn clean test` 1060/1060), PR aberta contra `staging`:
[api#110](https://github.com/douglasjava/easy-maintenance-api/pull/110).
Falta: Douglas revisar/mergear a PR e confirmar o pagamento real (userId=2) aparecendo em
`/private/admin/financials` após o deploy (critério de aceite parcial acima) antes de mover pra
`Done`.
