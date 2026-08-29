# TASK-210 — BUGFIX Backend: `LazyInitializationException` em `invoice.getItems()` após o fix da TASK-209 (regressão)

## Tipo
BUGFIX

## Categoria
Backend / Billing (job `PixRenewalJob` → `CardTransitionService`)

## Prioridade
🔴 Crítico

## Épico
Sem épico — regressão encontrada ao investigar por que a assinatura travada de Douglas
(subscriptionId=2, TASK-209) não se autocorrigiu no primeiro run do job após o deploy, 29/08/2026.

## QA obrigatório
Sim — QA manual: confirmar no próximo run do `PixRenewalJob` (01:30) que a assinatura de Douglas
(subscriptionId=2) finalmente gera o checkout/link de pagamento, sem o erro
`LazyInitializationException` no log.

---

## Contexto

Douglas reportou log de produção do run de hoje (29/08, 01:30) do `PixRenewalJob`. O fix da TASK-209
funcionou até certo ponto — `generateInvoiceForPayer` encontrou a fatura já existente do payer 2 (em
vez de devolver `Optional.empty()` como antes) — mas a subscription 2 continua travada, agora com um
erro novo:

```
Generating invoice for payer 2 and period 2026-08-31 to 2026-09-29
Invoice already exists for payer 2 and period 2026-08-31 to 2026-09-29. Skipping.
[CardTransition] Failed to process CC transition for subscription 2:
failed to lazily initialize a collection of role: ...Invoice.items: could not initialize proxy - no Session
org.hibernate.LazyInitializationException: failed to lazily initialize a collection of role:
com.brainbyte.easy_maintenance.billing.domain.Invoice.items: could not initialize proxy - no Session
	at ...CardTransitionService.processTransition(CardTransitionService.java:76)
	at ...CardTransitionService.processCardTransitions(CardTransitionService.java:52)
	at ...PixRenewalJob.run(PixRenewalJob.java:30)
```

## Causa raiz

O fallback adicionado na TASK-209 (`InvoiceService.generateInvoiceForPayer`, linha 127) busca a
fatura já existente via `InvoiceRepository.findByPayerIdAndPeriodStartAndPeriodEnd(...)` — método sem
`@EntityGraph`, então `items` (`@OneToMany` padrão `LAZY`) volta como proxy Hibernate não
inicializado.

Isso nunca tinha quebrado antes porque, no caminho de fatura **nova** (`processPayerInvoice`,
linha 144-152), `items` é montado em memória com `new ArrayList<>()` + `.add(...)` — uma lista comum,
sem proxy, então `.getItems()` sempre funcionou independente de sessão aberta. O caminho de fatura
**já existente** é o único que devolve uma entidade recém-buscada do banco, e é exatamente esse
caminho que a TASK-209 passou a expor pros 4 chamadores.

Em `CardTransitionService`, o problema fica visível porque `processCardTransitions` chama
`processTransition(sub)` como *self-invocation* (`this.processTransition(sub)`, mesma classe) — isso
contorna o proxy do Spring e o `@Transactional` de `processTransition` nunca é ativado. Sem uma
transação própria envolvendo a chamada, `generateInvoiceForPayer` (que tem seu próprio
`@Transactional`) abre e fecha sua própria sessão Hibernate antes de devolver o `Invoice` — daí
`invoice.getItems().isEmpty()`, já fora de qualquer sessão, quebra.

(`PixRenewalService.renewSubscription` não sofre do mesmo self-invocation — já usa o padrão correto,
injetando `@Lazy PixRenewalService self` e chamando `self.renewSubscription(...)`, o que preserva o
`@Transactional`. Ainda assim, sem o fetch eager, ficaria dependente desse detalhe de implementação
para não quebrar — mesmo risco, só não observado no log de hoje porque não havia assinatura PIX
elegível nesse run.)

## Objetivo

`InvoiceRepository.findByPayerIdAndPeriodStartAndPeriodEnd` passa a carregar `items` via
`@EntityGraph`, igual ao padrão já usado em `findFirstByPayerIdAndStatusOrderByCreatedAtDesc` — a
fatura devolvida por `generateInvoiceForPayer` fica utilizável pelos 4 chamadores independente de
haver ou não uma transação/sessão Hibernate aberta no momento em que acessam `.getItems()`.

## Escopo

### `InvoiceRepository.findByPayerIdAndPeriodStartAndPeriodEnd` — fetch eager de `items`

```java
@EntityGraph(attributePaths = {"items"})
Optional<Invoice> findByPayerIdAndPeriodStartAndPeriodEnd(Long payerUserId, LocalDate periodStart, LocalDate periodEnd);
```

Nenhuma mudança em `InvoiceService`, `CardTransitionService`, `PixRenewalService`,
`PaymentMethodTransitionService` ou `BillingRecoveryService` — o fix é só no fetch da query.

**Fora de escopo (registrado, não corrigido agora):** o self-invocation em
`CardTransitionService.processCardTransitions → processTransition` que contorna o `@Transactional`.
O fetch eager já resolve o crash reportado por conta própria (não depende de sessão aberta), então
misturar as duas correções violaria "um fix por vez". Vale abrir um follow-up se quiser blindar
`CardTransitionService` do mesmo jeito que `PixRenewalService` já está (injeção `@Lazy self`).

## Critérios de Aceite

- [x] `findByPayerIdAndPeriodStartAndPeriodEnd` devolve a fatura com `items` já inicializado
      (`Hibernate.isInitialized(...) == true`), comprovado por teste JPA real (H2) — reproduz o
      `LazyInitializationException` sem o fix e passa com ele
- [x] `mvn test` sem regressão
- [ ] QA manual: assinatura travada de Douglas (subscriptionId=2) gera checkout/link de pagamento no
      próximo run do `PixRenewalJob` (01:30), sem `LazyInitializationException` no log — pendente de
      deploy em produção

## Dependências
TASK-209 (regressão do fix daquela task).

## Riscos
Baixo — `@EntityGraph` adicional numa query já existente, sem mudança de contrato ou de comportamento
fora do fetch. Mesmo padrão já usado em `findFirstByPayerIdAndStatusOrderByCreatedAtDesc` na mesma
interface.

## Esforço
Baixo

## Status
✅ Implementado e PR aberta contra `staging`: [api#57](https://github.com/douglasjava/easy-maintenance-api/pull/57).
Branch `bugfix/TASK-210-invoice-items-lazy-loading`, commit `d07fc6a`. Suíte completa: 852/852
testes, 0 falhas. Teste JPA novo (`InvoiceRepositoryPersistenceTest`) comprovadamente pega a
regressão (falha sem o fix, passa com ele). Douglas optou por esperar o próximo run automático do
`PixRenewalJob` (01:30) em vez de criar um endpoint de trigger manual agora. QA final (assinatura de
Douglas, subscriptionId=2, desbloqueada) pendente do merge, deploy em produção e do próximo run do
job.
