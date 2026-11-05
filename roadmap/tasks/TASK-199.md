# TASK-199 — Backend: "Receita Total" no Faturamento soma preço de tabela do item ORGANIZATION, que está zerado desde a EPIC-014

## Tipo
BUGFIX

## Categoria
Admin / Faturamento

## Prioridade
🟠 Alto

## Épico
EPIC-014 — consolidação de billing para plano único por conta (sem arquivo de epic dedicado,
rastreada só em `roadmap/kanban.md`)

## QA obrigatório
Sim — QA manual: abrir `/private/admin/billing`, conferir que "Receita Total" de um pagador com
organizações vinculadas passa a mostrar só o valor do item `USER`, sem somar nada do lado das
organizações.

---

## Contexto

Achado por Douglas (24/08/2026) testando `/private/admin/billing` (aba Visão Geral) durante o QA da
revisão do EPIC-020: a coluna "Receita Total" do grid de pagadores/assinaturas ainda mostra valor
como se a organização também fosse cobrada, quando desde a EPIC-014 (13/07/2026, commit `48cc214`)
só o item `USER` é cobrado — o item `ORGANIZATION` sempre tem `valueCents = 0`.

**Causa raiz confirmada**: `BillingAccountRepository.findPayersSummary()` (e `findTopPayers()`,
que hoje não tem nenhum consumidor) somam `plan.priceCents` (preço de tabela do plano vinculado ao
item) em vez de `item.valueCents` (valor realmente cobrado naquele item). Como todo item
`ORGANIZATION` referencia o mesmo plano do item `USER` da conta, `plan.priceCents` é sempre
não-zero pros dois tipos de item — mesmo o `ORGANIZATION` estando com `valueCents = 0` na prática.
Resultado: `organizationSubscriptionPriceCents` (e por consequência `RevenueDetail.orgsCents` /
`totalCents`) fica inflado, mostrando um valor que a organização nunca cobrou de verdade.

Não é um bug introduzido pela revisão do EPIC-020 (TASK-195 a 198) — é órfão da própria EPIC-014,
só não tinha sido notado até agora.

## Objetivo

`findPayersSummary()` (e `findTopPayers()`, por consistência) somam `item.valueCents` em vez de
`plan.priceCents` — "Receita Total" passa a refletir só o que é de fato cobrado (hoje, só o item
`USER`).

## Escopo

### 1. `BillingAccountRepository.java` — troca a base do SUM/ORDER BY

Em `findPayersSummary()`:
```java
CAST(SUM(COALESCE(CASE WHEN i.sourceType = 'ORGANIZATION' THEN i.valueCents END, 0)) AS long),
CAST(COALESCE(SUM(CASE WHEN i.sourceType = 'USER' THEN i.valueCents END), 0) AS long)
```
(troca `p.priceCents` por `i.valueCents` nas duas expressões — `p`/`i.plan` deixa de ser necessário
pro cálculo, mas o `JOIN i.plan p` continua no `FROM` porque outros campos do DTO/uso futuro podem
depender dele; não remover o join nesta task, fora de escopo.)

Em `findTopPayers()`: mesma troca nas duas expressões `SUM` e no `ORDER BY`.

### 2. Nenhuma mudança em `BillingAccountService`/`BillingAdminDTO`

`BillingAccountService.getOverview()` já calcula `totalCents = orgsCents + userCents` a partir do
que a query devolve — corrigindo a fonte (a query), o resultado já sai certo sem tocar no service.

### 3. Teste

`@DataJpaTest` novo (mesmo padrão de `LandingLeadFilterPersistenceTest`/`ExpenseFilterPersistenceTest`,
já usado no projeto pra testar JPQL/`Specification` direto contra o banco de teste) cobrindo:
`findPayersSummary()` retorna `organizationSubscriptionPriceCents = 0` pra uma conta com item
`ORGANIZATION` de `valueCents = 0` e plano de preço não-zero; `userSubscriptionPriceCents` reflete
o `valueCents` real do item `USER`.

## Critérios de Aceite

- [x] `findPayersSummary()` soma `item.valueCents`, não `plan.priceCents`
- [x] `findTopPayers()` idem (mesmo sem consumidor hoje — evita deixar a mesma armadilha pra quem
      for usar depois)
- [x] Teste `@DataJpaTest` cobrindo o cenário (organização zerada, usuário com valor real) passa
- [ ] `GET /private/admin/billing` (overview) mostra "Receita Total" = só o valor do item `USER`
      pra contas com organizações vinculadas — QA manual pendente
- [x] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Independente da revisão do EPIC-020 (TASK-195 a 198) — achado durante o QA dela,
mas vive em área de código diferente (Faturamento, não Financeiro/Afiliados).

## Riscos
Baixo — troca de coluna-fonte numa agregação JPQL existente, sem mudança de contrato de API
(`PayerSummaryResponse`/`RevenueDetail` mantêm os mesmos campos, só o valor calculado muda pra
refletir a realidade).

## Esforço
Baixo

## Status
✅ Implementada e commitada (24/08/2026) na branch `bugfix/TASK-199-receita-total-org-zerada`
(`easy-maintenance-api`, commit `edd6d43`) — PR aberta contra `staging`:
[#44](https://github.com/douglasjava/easy-maintenance-api/pull/44). Suíte completa: 798 testes,
0 falhas (796 + 2 novos). Aguardando QA manual de Douglas em `/private/admin/billing`.
