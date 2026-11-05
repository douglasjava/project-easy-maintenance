# TASK-197 — Backend: `FinancialsService` sem comissão manual; endpoint de breakdown por comissionado

## Tipo
BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Revisão da Fase 2

## QA obrigatório
Sim — QA manual: conferir que o card "Comissões" da tela de financeiro continua batendo com a soma
de `referral_commissions` do mês (sem mais somar `manual_commission_rules`, que não existe mais);
conferir que o breakdown por comissionado lista nome, %, recorrência e valor corretos pra um mês com
dado real.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`.

Depende da TASK-196 (`referral_commissions.user_id`, comissão recorrente). Com
`manual_commission_rules` removida (TASK-195), `FinancialsService` precisa parar de somar
`manualCommissionCents` — a comissão de afiliado (`ReferralCommission`) já cobre indicador público e
comissionado interno na mesma fonte, então não há "buraco" no cálculo, só simplificação. Falta um
endpoint que Douglas pediu desde o início desta análise: ver quanto cada comissionado ganha
individualmente, não só o total agregado.

## Objetivo

`FinancialsService` sem o termo de comissão manual; endpoint novo de breakdown por comissionado
(nome, %, recorrência, valor do período).

## Escopo

### 1. `FinancialsDTO.MonthlyFinancialsResponse` — remove campo

```java
public record MonthlyFinancialsResponse(
        String month,
        long revenueGrossCents,
        long revenueNetCents,
        long gatewayFeeCents,
        long affiliateCommissionCents,
        long expenseCents,
        long monthlyBalanceCents,
        long cumulativeBalanceCents
) {}
```
(`manualCommissionCents` removido.)

### 2. `FinancialsService.buildMonth()` — remove cálculo de comissão manual

```java
long monthlyBalanceCents = revenueNetCents - affiliateCommissionCents - expenseCents;
```
Remove `manualCommissionRuleRepository`, o filtro `isActiveInMonth`, e todo o bloco de cálculo de
`manualCommissionCents`.

### 3. DTO de breakdown

```java
public record CommissionBreakdownResponse(
        Long affiliateId,
        String name,
        String email,
        BigDecimal commissionRate,
        String recurrenceType, // "ONE_TIME" | "RECURRING"
        long totalAmountCents,
        long pendingCount,
        long paidCount
) {}
```

### 4. `FinancialsService.getCommissionsBreakdown(YearMonth month)`

Agrupa `ReferralCommission` por `affiliateId` dentro do mês pedido (`createdAt` no intervalo, mesmo
padrão já usado pra `affiliateCommissionCents`), soma `commissionAmount`, conta por `status`, junta
com `Affiliate` (nome, e-mail, `commissionRate` atual, `recurrenceType`).

### 5. Endpoint

```java
@GetMapping("/private/admin/financials/commissions-breakdown")
public List<CommissionBreakdownResponse> getCommissionsBreakdown(@RequestParam String month); // "2026-08"
```
No `AdminFinancialsController` já existente (mesmo prefixo `/private/admin/financials`).

### 6. Testes

- `FinancialsServiceTest`: `monthlyBalanceCents` correto sem o termo de comissão manual; breakdown
  agrega corretamente por afiliado, inclui `RECURRING` com múltiplas comissões no mesmo mês somadas
  numa linha só.

## Critérios de Aceite

- [x] `manualCommissionCents` removido de `MonthlyFinancialsResponse` e do cálculo de
      `monthlyBalanceCents`
- [x] `GET /private/admin/financials/commissions-breakdown?month=YYYY-MM` retorna nome, e-mail, %,
      recorrência e valor total por comissionado no mês
- [x] Afiliado `RECURRING` com múltiplas comissões no mês aparece como uma linha só, valor somado
- [x] `mvn test` sem regressão

## Dependências
**TASK-196** — precisa de `referral_commissions.user_id`/`cycle_number` e da lógica de geração
recorrente já funcionando pra o breakdown fazer sentido.

## Riscos
Baixo — remoção de campo não usado por mais ninguém (TASK-198 atualiza o único consumidor, o
frontend) + endpoint aditivo novo.

## Esforço
Médio

## Status
✅ Implementada e commitada (24/08/2026) na branch `feature/financial-module-v2`
(`easy-maintenance-api`, commit `b38b617`) — mesma branch das TASK-190 a 196, sem PR ainda. Suíte
completa: 796 testes, 0 falhas.

**Notas de implementação**:
- `ReferralCommissionRepository` ganhou `findAllByCreatedAtBetween` — não existia nenhum método pra
  buscar as comissões em si dentro de um período (só o agregado via `sumCommissionAmountByCreatedAtBetween`),
  necessário pro agrupamento por `affiliateId` do breakdown.
- `FinancialsService` passou a depender de `AffiliateRepository` (nova injeção) pra resolver
  nome/e-mail/%/recorrência de cada comissionado no breakdown.
- Resultado ordenado por nome do comissionado (`Comparator.comparing(name)`) — não estava no escopo
  original da task, mas necessário pra saída ser determinística/previsível na tela.
- Afiliado removido/inexistente no meio do caminho (edge case) cai no mesmo fallback `"—"` já usado
  em `CommissionAdminResponse`/`CommissionService.listAll()`, mantendo consistência com o padrão
  existente.
