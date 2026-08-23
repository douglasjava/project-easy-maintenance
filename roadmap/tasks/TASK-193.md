# TASK-193 — Frontend: página própria `/private/admin/financials` (sai das abas de Faturamento)

## Tipo
FRONTEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo), Fase 2

## QA obrigatório
Sim — QA manual: conferir que "Financeiro" some das abas de Faturamento, aparece no menu lateral
como item próprio, e que os 7 cards + gráfico batem com os valores esperados de um mês real.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-23-financial-module-design.md`.

Depende da TASK-192 (`GET /private/admin/financials` com os campos novos). Primeira parte do pedido
de Douglas: "a página só pra ele, removido das abas atuais". Sem essa task, os dados novos calculados
na TASK-192 não têm onde aparecer.

## Objetivo

Nova página de primeiro nível `/private/admin/financials`, item próprio no menu lateral, removida
das abas de `BillingAdminLayout`. 7 cards de resumo + gráfico de evolução mensal com saldo
acumulado.

## Escopo

### 1. `Sidebar.tsx` — item novo

```typescript
const adminItems: NavItem[] = [
    {href: "/private/users", label: "Usuários", section: "admin"},
    {href: "/private/organizations", label: "Empresas", section: "admin"},
    {href: "/private/admin/billing", label: "Faturamento", section: "admin"},
    {href: "/private/admin/financials", label: "Financeiro", section: "admin"},
    {href: "/private/admin/affiliates", label: "Afiliados", section: "admin"},
    {href: "/private/admin/leads", label: "Leads", section: "admin"},
];
```

### 2. `BillingAdminLayout.tsx` — remove a aba

```typescript
const tabs = [
    { id: "/private/admin/billing", label: "Visão Geral" },
    { id: "/private/admin/billing/subscriptions", label: "Assinaturas" },
    { id: "/private/admin/billing/invoices", label: "Faturas" },
    { id: "/private/admin/billing/plans", label: "Planos" },
];
```

### 3. Diretório `financeiro/` (dentro de `billing/`) é removido por completo — `page.tsx` e
`ExpenseRatesSection.tsx` somem daí.

### 4. Nova página `src/app/private/admin/financials/page.tsx`

Header próprio (`PageHeader`, mesmo componente já usado em `BillingAdminLayout`/outras telas admin),
sem `AdminTabs` (não tem sub-abas).

```typescript
type MonthlyFinancials = {
  month: string;
  revenueGrossCents: number;
  revenueNetCents: number;
  gatewayFeeCents: number;
  affiliateCommissionCents: number;
  manualCommissionCents: number;
  expenseCents: number;
  monthlyBalanceCents: number;
  cumulativeBalanceCents: number;
};
```

Busca `GET /private/admin/financials` (params `{ months: 12 }`) — mesmo padrão de
`fetchFinancials()` já existente, só o path e o shape do dado mudam.

**Cards de resumo (mês mais recente da resposta)**:
```
Recebido (bruto) | Recebido (líquido) | Taxa Asaas
Despesas          | Comissões (afiliado + manual)
Saldo do mês       | Saldo acumulado
```
`Comissões` no card soma `affiliateCommissionCents + manualCommissionCents` (detalhamento
individual fica nas seções da TASK-194, o card é só o totalizador). `Saldo do mês` usa
`monthlyBalanceCents` (verde se ≥ 0, vermelho se negativo — mesma lógica de cor já usada hoje pro
"Total"). `Saldo acumulado` usa `cumulativeBalanceCents`, mesma lógica de cor.

**Gráfico**: trocar `BarChart` por `ComposedChart` (Recharts, já uma dependência do projeto) — barras
de Líquido/Despesas/Comissões (soma das duas) + `Line` de saldo acumulado sobreposta num eixo Y
secundário (`yAxisId`), já que a escala do saldo acumulado (crescente ao longo do tempo) tende a ser
bem maior que a variação mensal das barras.

### 5. Testes / verificação
- `npm run build` limpo.
- QA manual (ver "QA obrigatório").

## Critérios de Aceite

- [ ] `/private/admin/billing` não mostra mais a aba "Financeiro"
- [ ] Menu lateral mostra "Financeiro" como item próprio, entre "Faturamento" e "Afiliados"
- [ ] `/private/admin/financials` carrega os 7 cards corretamente a partir do endpoint novo
- [ ] Gráfico mostra barras (Líquido/Despesas/Comissões) + linha de saldo acumulado
- [ ] `financeiro/page.tsx` e `ExpenseRatesSection.tsx` antigos removidos, nenhum import quebrado
- [ ] `npm run build` limpo

## Dependências
**TASK-192** — precisa do `GET /private/admin/financials` com os campos novos.

## Riscos
Baixo — reorganização de UI + troca de fonte de dado numa tela administrativa já existente, sem
tocar em fluxo de cliente final.

## Esforço
Médio

## Status
🔵 Backlog
