# TASK-192 — Backend: reescreve `FinancialsService` (bruto/líquido, saldo do mês, saldo acumulado) + comissão de afiliado sobre o líquido

## Tipo
BUGFIX / BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🔴 Crítico

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Fase 2

## QA obrigatório
Sim — QA manual: conferir os valores de bruto/líquido/taxa Asaas de um mês real contra o que o
Asaas mostra pro mesmo período; conferir que uma comissão de afiliado nova é calculada sobre o
líquido, não o preço do plano; conferir saldo do mês e saldo acumulado ao longo de vários meses.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-financial-module-design.md`.

Depende da TASK-190 (`expenses`, `manual_commission_rules`). Núcleo de cálculo do módulo — hoje
`FinancialsService.getMonthlyFinancials()` soma `Payment.amountCents` (**bruto**) como receita, não
`Payment.netAmountCents` (líquido), apesar do líquido já vir pronto do Asaas. Isso é uma correção de
cálculo, não só uma feature nova: o "Recebido" que a tela mostra hoje está inflado em relação ao que
efetivamente cai na conta.

**Achado de código, confirmado**: `ReferralCommission` é criada em
`CommissionService.createCommission()` (`affiliates/application/service/`), chamada a partir de
`PaymentReceivedHandler.triggerCommissionIfApplicable()` (`webhooks/asaas/strategy/impl/`, linhas
166-170) — nesse ponto, o `Payment` já está disponível, então trocar a base de cálculo pro líquido é
uma mudança local, sem precisar buscar dado novo.

## Objetivo

`FinancialsService` reescrito com bruto/líquido separados, despesas e comissão manual (regra de %)
entrando no cálculo, saldo do mês e saldo acumulado. Comissão de afiliado passa a ser calculada
sobre o valor líquido do pagamento, preservando `planPrice` como registro do preço cheio do plano
(campo já exibido na tela de afiliados, não pode virar o valor líquido por engano).

## Escopo

### 1. `PaymentRepository` — dois métodos novos

```java
@Query("SELECT COALESCE(SUM(p.netAmountCents), 0) FROM Payment p WHERE p.status = :status AND p.paidAt BETWEEN :start AND :end")
Long sumNetAmountCentsByStatusAndPaidAtBetween(@Param("status") PaymentStatus status, @Param("start") Instant start, @Param("end") Instant end);

@Query("SELECT MIN(p.paidAt) FROM Payment p WHERE p.status = :status")
Instant findMinPaidAtByStatus(@Param("status") PaymentStatus status);
```

### 2. `CommissionService.createCommission()` — ganha um parâmetro novo

```java
@Transactional
public ReferralCommission createCommission(Affiliate affiliate, Long organizationId,
                                           String planName, BigDecimal planPrice, BigDecimal netAmount) {
    if (commissionRepository.existsByOrganizationId(organizationId)) {
        log.info("[Commission] Already exists for orgId={}, skipping (idempotent).", organizationId);
        return null;
    }
    BigDecimal amount = netAmount.multiply(affiliate.getCommissionRate())
            .setScale(2, RoundingMode.HALF_UP);
    ReferralCommission commission = ReferralCommission.builder()
            .affiliateId(affiliate.getId())
            .organizationId(organizationId)
            .planName(planName)
            .planPrice(planPrice)          // preço cheio do plano, só registro/exibição — não muda
            .commissionRate(affiliate.getCommissionRate())
            .commissionAmount(amount)      // agora % sobre o líquido, não sobre planPrice
            .build();
    ReferralCommission saved = commissionRepository.save(commission);
    log.info("[Commission] Created: affiliateId={}, orgId={}, amount={}",
            affiliate.getId(), organizationId, amount);
    return saved;
}
```

`planPrice` continua sendo o preço cheio do plano (usado hoje em `CommissionAdminResponse` pra
exibir "vendeu o plano X por R$Y") — só a BASE do cálculo de `commissionAmount` muda pro líquido.
Não confundir os dois: renomear a variável seria confuso, por isso `netAmount` entra como parâmetro
separado, não substitui `planPrice`.

### 3. `PaymentReceivedHandler.triggerCommissionIfApplicable()` — passa o líquido também

```java
BigDecimal planPrice = payment.getAmountCents() != null
        ? new BigDecimal(payment.getAmountCents()).movePointLeft(2)
        : BigDecimal.ZERO;
BigDecimal netAmount = payment.getNetAmountCents() != null
        ? new BigDecimal(payment.getNetAmountCents()).movePointLeft(2)
        : planPrice; // fallback defensivo: se por algum motivo o líquido não veio do Asaas, usa o bruto em vez de gerar comissão zerada

commissionService.createCommission(affiliate, org.getId(), planName, planPrice, netAmount);
```

### 4. `FinancialsDTO.MonthlyFinancialsResponse` — campos novos

```java
public record MonthlyFinancialsResponse(
        String month,
        long revenueGrossCents,
        long revenueNetCents,
        long gatewayFeeCents,
        long affiliateCommissionCents,
        long manualCommissionCents,
        long expenseCents,
        long monthlyBalanceCents,
        long cumulativeBalanceCents
) {}
```

Remove os campos antigos (`revenueCents`, `costCents`, `commissionCents`, `profitCents`) — nenhum
outro consumidor além do frontend desta tela (TASK-193 atualiza o consumo junto).

### 5. `FinancialsService` — reescrito

```java
public List<FinancialsDTO.MonthlyFinancialsResponse> getMonthlyFinancials(Integer months) {
    int windowSize = clamp(months);
    YearMonth currentMonth = YearMonth.now(ZoneOffset.UTC);

    List<FinancialsDTO.MonthlyFinancialsResponse> result = new ArrayList<>();
    long cumulativeBalanceCents = 0L;
    for (int i = windowSize - 1; i >= 0; i--) {
        YearMonth ym = currentMonth.minusMonths(i);
        FinancialsDTO.MonthlyFinancialsResponse month = buildMonth(ym);
        cumulativeBalanceCents += month.monthlyBalanceCents();
        result.add(new FinancialsDTO.MonthlyFinancialsResponse(
                month.month(), month.revenueGrossCents(), month.revenueNetCents(), month.gatewayFeeCents(),
                month.affiliateCommissionCents(), month.manualCommissionCents(), month.expenseCents(),
                month.monthlyBalanceCents(), cumulativeBalanceCents));
    }
    return result;
}

private FinancialsDTO.MonthlyFinancialsResponse buildMonth(YearMonth ym) {
    Instant start = ym.atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();
    Instant end = ym.atEndOfMonth().atTime(23, 59, 59).atZone(ZoneOffset.UTC).toInstant();

    long revenueGrossCents = nvl(paymentRepository.sumAmountCentsByStatusAndPaidAtBetween(PaymentStatus.RECEIVED, start, end));
    long revenueNetCents = nvl(paymentRepository.sumNetAmountCentsByStatusAndPaidAtBetween(PaymentStatus.RECEIVED, start, end));
    long gatewayFeeCents = revenueGrossCents - revenueNetCents;

    BigDecimal commission = referralCommissionRepository.sumCommissionAmountByCreatedAtBetween(start, end);
    long affiliateCommissionCents = commission != null ? commission.movePointRight(2).longValue() : 0L;

    long manualCommissionCents = manualCommissionRuleRepository.findAll().stream()
            .filter(rule -> isActiveInMonth(rule, ym))
            .mapToLong(rule -> rule.getPercentage()
                    .multiply(BigDecimal.valueOf(revenueNetCents))
                    .setScale(0, RoundingMode.HALF_UP).longValue())
            .sum();

    long expenseCents = expenseRepository.sumAmountCentsByExpenseDateBetween(ym.atDay(1), ym.atEndOfMonth());

    long monthlyBalanceCents = revenueNetCents - affiliateCommissionCents - manualCommissionCents - expenseCents;

    return new FinancialsDTO.MonthlyFinancialsResponse(
            ym.toString(), revenueGrossCents, revenueNetCents, gatewayFeeCents,
            affiliateCommissionCents, manualCommissionCents, expenseCents, monthlyBalanceCents, 0L);
    // cumulativeBalanceCents é preenchido em getMonthlyFinancials(), não aqui
}

private boolean isActiveInMonth(ManualCommissionRule rule, YearMonth ym) {
    boolean startedBefore = !rule.getEffectiveFrom().isAfter(ym.atEndOfMonth());
    boolean notEndedYet = rule.getEffectiveTo() == null || !rule.getEffectiveTo().isBefore(ym.atDay(1));
    return startedBefore && notEndedYet;
}

private long nvl(Long value) {
    return value != null ? value : 0L;
}
```

`ExpenseRepository` precisa do método `sumAmountCentsByExpenseDateBetween(LocalDate from, LocalDate to)`
(`@Query` análoga às somas já existentes) — adicionar nesta task (não foi coberto pela TASK-190, que
só criou o repositório básico).

**Sobre o saldo acumulado começar no primeiro mês com dado real**: como o `getMonthlyFinancials()`
já limita a janela pelo parâmetro `months` (12 por padrão), a soma corrida começa do primeiro mês
*dentro da janela pedida*, não necessariamente do primeiro pagamento da história da empresa — isso
é aceitável porque a tela sempre pede pelo menos 12 meses (suficiente pra cobrir a operação toda,
dado que o produto tem poucos meses de vida); documentar essa limitação no Javadoc do método pra não
virar suposição errada no futuro se a janela pedida for pequena.

## Critérios de Aceite

- [x] `revenueGrossCents` reflete `Payment.amountCents`, `revenueNetCents` reflete
      `Payment.netAmountCents`, ambos só de pagamentos `RECEIVED` no mês
- [x] `gatewayFeeCents` = bruto - líquido
- [x] Comissão de afiliado criada a partir desta mudança usa `netAmount` (não `planPrice`) como base
      de `commissionAmount`; `planPrice` no registro continua sendo o preço cheio do plano
- [x] `manualCommissionCents` soma corretamente as regras ativas no mês, calculadas sobre o líquido
      do próprio mês, respeitando `effectiveFrom`/`effectiveTo`
- [x] `expenseCents` soma despesas pela `expenseDate` dentro do mês
- [x] `monthlyBalanceCents` = líquido - comissão de afiliado - comissão manual - despesas
- [x] `cumulativeBalanceCents` é a soma corrida de `monthlyBalanceCents` desde o mês mais antigo da
      janela pedida
- [x] `mvn test` sem regressão

**Notas de implementação**:
- `PaymentRepository.findMinPaidAtByStatus` (item 1 do escopo original) não foi adicionado — ficaria
  sem nenhum chamador, já que a decisão final foi aceitar a limitação do saldo acumulado começar no
  início da janela pedida, não no primeiro pagamento histórico. Método morto não entrou no código.
- `GET /private/admin/financials` foi migrado de `AdminBillingController` (`/private/admin/billing/financials`)
  para o `AdminFinancialsController` criado na TASK-191 — consolida o módulo sob um prefixo só,
  conforme a spec ("Financeiro deixou de ser parte de Faturamento").

## Dependências
**TASK-190** — precisa de `Expense`, `ManualCommissionRule` e seus repositórios.

## Riscos
Médio — muda o valor de "Recebido" que a tela mostra (de bruto pra líquido, correção de cálculo) e a
base de cálculo de comissão de afiliado pra vendas novas (mudança de regra de negócio real,
combinada com Douglas no brainstorm). Mitigado por não recalcular nada retroativo — só afeta dado
gerado a partir do deploy.

## Esforço
Alto

## Status
✅ Implementada e commitada (23/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-api`, commit `fda0e3a`) — mesma branch reúne toda a Fase 2. Suíte completa: 106
classes de teste, 0 falhas. Ainda sem PR — mesma branch reúne toda a Fase 2.
