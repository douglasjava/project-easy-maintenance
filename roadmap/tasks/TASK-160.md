# TASK-160 — Backend: endpoint agregado de financeiro por mês

## Tipo
BACKEND

## Categoria
Admin / Financeiro

## Prioridade
🟠 Alto

## Épico
[EPIC-020](../epics/EPIC-020.md) — Painel Financeiro Admin (Receita vs. Custo)

## QA obrigatório
Sim — validar que a receita reflete pagamento confirmado (não MRR de assinatura ativa) e que o
lucro bate com receita − custo − comissão em cada mês.

---

## Contexto

O painel financeiro precisa de receita/custo/comissão/lucro agrupados por mês, últimos 12 meses.
Receita (`Payment.status = RECEIVED`) e comissão (`ReferralCommission`) já existem como dado, só
falta a consulta agrupada. Custo vem da TASK-159 (`operating_expense_rates`), resolvido por
vigência, não por soma simples — por isso é calculado em código, não numa única query SQL.

---

## Objetivo

Criar `GET /admin/billing/financials?months=12` retornando a série mensal completa.

---

## Escopo

### 1. Consultas novas
- `PaymentRepository`: nova query agrupando `SUM(amountCents)` por ano-mês de `paidAt`, filtrando
  `status = RECEIVED`, dentro da janela de N meses.
- `ReferralCommissionRepository` (ou equivalente): nova query agrupando `SUM(commissionAmount)`
  por ano-mês de `createdAt`, dentro da mesma janela.

### 2. Serviço `FinancialsService` (ou equivalente)
- Para cada mês da janela (do mais antigo ao mais recente):
  - `revenueCents` = resultado da query de pagamentos daquele mês (0 se não houver).
  - `commissionCents` = resultado da query de comissões daquele mês (0 se não houver).
  - `costCents` = soma, por categoria de `ExpenseCategory`, do valor vigente naquele mês (via
    repositório da TASK-159) — 0 pra categoria sem nenhuma vigência cadastrada ainda naquela data.
  - `profitCents = revenueCents - commissionCents - costCents`.

### 3. Controller
- `GET /easy-maintenance/api/v1/admin/billing/financials?months=12` (default 12, máximo
  razoável, ex. 24, pra evitar consulta gigante sem necessidade).
- Resposta: lista ordenada do mês mais antigo ao mais recente,
  `[{ month: "2026-08", revenueCents, costCents, commissionCents, profitCents }, ...]`.
- Mesmo padrão de autenticação do resto de `/admin/*`.

### 4. Testes
- Mês sem nenhum pagamento/comissão/custo retorna todos os valores zerados (não quebra, não pula
  o mês da lista).
- Mês com custo de uma categoria que mudou de vigência no meio da janela reflete o valor correto
  pra cada lado da mudança (o caso de risco citado no épico: Railway R$200 até maio, R$250 a
  partir de junho).
- `profitCents` bate exatamente com `revenueCents - commissionCents - costCents` em cada item.

---

## Critérios de Aceite

- [x] Endpoint retorna 12 meses por padrão, ordenados do mais antigo ao mais recente
- [x] Receita reflete só pagamento confirmado (`status = RECEIVED`), não assinatura ativa
- [x] Custo resolve a vigência correta por mês (via `resolveAmountCents` da TASK-159, já testado lá)
- [x] `profitCents` calculado corretamente em todos os casos de teste
- [x] Suíte de testes backend passa, sem regressão (5 testes novos)

## Dependências
- **TASK-159** — precisa do repositório de custo de infraestrutura já existir.

## Riscos
Médio — é a peça com mais lógica nova (resolução de vigência por mês, não uma soma SQL simples).
Cobrir bem o caso de troca de vigência no meio da janela é o ponto crítico de correção.

## Esforço
Médio

## Status
Concluído — QA manual aprovado por Douglas (11/08/2026). Falta só mergear
[easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31) para `staging`.
