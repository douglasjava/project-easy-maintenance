# EPIC-020 — Painel Financeiro Admin (Receita vs. Custo)

## Status
QA manual aprovado por Douglas (11/08/2026) — as 4 tasks (TASK-159 a 162) implementadas e
validadas de ponta a ponta em `staging`, incluindo o ajuste de rótulo pra categoria "Outros"
adicionado após o teste manual. Falta só o merge das PRs para `main`
([easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31),
[easy-maintenance-web#34](https://github.com/douglasjava/easy-maintenance-web/pull/34)).

## Objetivo
Dar visibilidade real de receita recebida vs. custo do negócio (infraestrutura + comissão de
afiliado) e o lucro resultante, numa área administrativa nova — hoje a tela de overview de billing
só mostra uma estimativa de MRR das assinaturas ativas, não receita efetivamente recebida, e não
existe nenhum conceito de custo/despesa do próprio negócio no sistema.

## Descrição

Área nova `/private/admin/billing/financeiro`, só para o admin (acesso único, sem permissão nova
necessária), com três blocos:

1. **Grid de totalizadores do mês atual**: Recebido, Gasto, Total (lucro).
2. **Gráfico dos últimos 12 meses** (Recharts, primeira biblioteca de gráfico do projeto): as
   mesmas três métricas, mês a mês, pra ver tendência.
3. **Cadastro de custo de infraestrutura**: como não existe integração automática com as faturas
   de Railway/OpenAI/S3/Asaas, o custo é lançado manualmente — valor fixo mensal por categoria,
   atualizado quando a fatura real mudar. Atualizar não sobrescreve o valor anterior — cria uma
   nova vigência, preservando a exatidão do histórico no gráfico.

**Definição de receita**: pagamento efetivamente confirmado (Asaas), não MRR de assinaturas
ativas — é o número financeiramente correto pra calcular lucro real, mesmo sendo diferente do que
a tela de overview já mostra hoje.

**Custo de comissão de afiliado** já é dado existente no sistema (`ReferralCommission`) — não
precisa de lançamento manual, só uma consulta agrupada por mês (pela data da venda, não da data em
que o afiliado foi efetivamente pago, pra ficar coerente com a receita do mesmo período).

---

## Contexto Técnico

- `AdminBillingController.getOverview()` hoje soma `totalCents` das assinaturas `ACTIVE` no
  momento (`BillingSubscriptionRepository.sumActiveTotalCents()`) — isso é MRR de compromisso, não
  receita recebida. Esta tela nova não substitui aquela, é um bloco adicional.
- `Payment` (status `RECEIVED`, `amountCents`, `paidAt`) é a fonte real de receita — não existe
  hoje nenhuma consulta agrupada por período, só o que já é usado no dashboard do usuário
  (pagamentos recentes individuais).
- `ReferralCommission` já tem `commissionAmount`, `createdAt`, `status` — totalmente pronto pra
  agregação, sem trabalho de modelagem novo.
- Não existe nenhum conceito de despesa/custo do próprio negócio no sistema hoje — `costCents` em
  `MaintenanceItem` é custo do ativo do *cliente*, sem relação nenhuma com isso.
- Nenhuma biblioteca de gráfico está instalada no frontend — o único "gráfico" hoje
  (`/private/dashboard`) é uma barra CSS artesanal, não uma lib.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-159](../tasks/TASK-159.md) | Backend: modelo de dados + CRUD de custo de infraestrutura (`operating_expense_rates`) | BACKEND | 🟠 Alto |
| [TASK-160](../tasks/TASK-160.md) | Backend: endpoint agregado de financeiro por mês (receita/custo/comissão/lucro) | BACKEND | 🟠 Alto |
| [TASK-161](../tasks/TASK-161.md) | Frontend: página `/financeiro` — grid de totalizadores + gráfico Recharts de 12 meses | FRONTEND | 🟠 Alto |
| [TASK-162](../tasks/TASK-162.md) | Frontend: seção de cadastro/edição de custo de infraestrutura na página `/financeiro` | FRONTEND | 🟠 Alto |

Ordem: TASK-159 primeiro (o endpoint agregado da TASK-160 depende dos dados de custo existirem) →
TASK-160 → TASK-161 (a página precisa do endpoint agregado) → TASK-162 (a seção de cadastro entra
na mesma página já criada na TASK-161).

---

## Critério de Conclusão do Épico

- [x] `/private/admin/billing/financeiro` acessível só pelo admin, mesma autenticação já existente
- [x] Grid mostra Recebido/Gasto/Total do mês atual, calculado a partir de pagamento confirmado
      (não MRR de assinatura ativa)
- [x] Gráfico mostra os últimos 12 meses das mesmas três métricas
- [x] Custo de infraestrutura é lançado manualmente por categoria, com histórico preservado
      (atualizar não apaga o valor anterior)
- [x] Comissão de afiliado entra no cálculo de custo automaticamente, sem lançamento manual
- [x] `npm run build` (frontend) e suíte de testes (backend) sem regressão
- [x] **QA manual com dado real** — aprovado por Douglas em `staging` (11/08/2026)

---

## Fora de Escopo

- Despesas gerais do negócio (ferramentas, contador, etc.) — só infraestrutura + comissão.
- Lançamento avulso de custo por data — só valor fixo mensal por categoria.
- Qualquer nível de permissão além do admin já existente.
- Projeção/forecast de receita ou custo futuro — só histórico real.

## Riscos
Baixo — extensão aditiva da área admin existente, não altera nenhum fluxo de cliente. Único ponto
de atenção técnico: o cálculo de custo por mês é feito em código (não SQL), iterando a janela de
meses e resolvendo a vigência mais recente por categoria — precisa de teste unitário cobrindo
troca de vigência no meio da janela (ex.: Railway custava R$200 até maio, R$250 a partir de junho —
o mês de maio no gráfico precisa continuar mostrando R$200).
