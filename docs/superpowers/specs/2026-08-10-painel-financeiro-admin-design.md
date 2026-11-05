# Painel Financeiro Admin — Design

**Data**: 2026-08-10
**Status**: Aprovado por Douglas (via diálogo de brainstorm)

## Contexto

Hoje a área `/private/admin/billing` mostra uma "Receita Mensal Est." que é, na prática, a soma
das assinaturas ativas no momento (`sumActiveTotalCents()`), não receita recebida de fato. Não
existe nenhuma consulta agrupada por período (mês a mês), nenhum conceito de custo/despesa do
próprio negócio (só existe `costCents` em itens de manutenção, que é custo do ativo do *cliente*,
sem relação nenhuma com isso), e nenhuma biblioteca de gráfico instalada no frontend.

Douglas quer uma visão administrativa pra acompanhar receita recebida vs. custo (infraestrutura +
comissão de afiliado) e o lucro resultante, com gráfico de evolução mensal e um resumo rápido do
mês atual.

## Decisões de escopo (confirmadas com Douglas)

1. **O que conta como custo**: comissão de afiliado (já modelada no sistema, tabela
   `ReferralCommission`) + custo de infraestrutura (Railway, OpenAI, S3, taxas Asaas — não existe
   no sistema hoje, lançado manualmente). Despesas gerais do negócio (ferramentas, contador etc.)
   ficam fora de escopo.
2. **Modelo de lançamento de custo de infraestrutura**: valor fixo mensal por categoria, atualizado
   quando a fatura real mudar — não lançamento avulso por data.
3. **Definição de receita**: pagamento efetivamente confirmado (Asaas), não MRR das assinaturas
   ativas — é o número financeiramente correto pra calcular lucro real.
4. **Visão temporal**: evolução mensal (últimos 12 meses), não só o retrato do mês atual.
5. **Localização**: página nova dedicada (`/private/admin/billing/financeiro`), não expande a
   página de overview existente.
6. **Grid de totalizadores**: 3 cartões — Recebido, Gasto (custo de infra + comissão somados),
   Total (lucro) — refletindo o **mês atual** (não o acumulado dos 12 meses do gráfico).
7. **Permissão**: nenhuma nova — só Douglas acessa `/private/admin/*` hoje, o token/guard
   existente já é suficiente.
8. **Biblioteca de gráfico**: nenhuma está instalada no projeto. Escolha: **Recharts** (padrão de
   mercado pra React, leve, API declarativa).

## Modelo de dados

### Nova tabela: `operating_expense_rates`

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | bigint PK | |
| `category` | enum (`RAILWAY`, `OPENAI`, `S3`, `ASAAS_FEES`, `OUTROS`) | |
| `amount_cents` | int | Valor mensal da categoria |
| `effective_from` | date | A partir de quando esse valor vale |
| `created_at` | timestamp | |

**Append-only por categoria**: atualizar um custo cria uma nova linha, nunca sobrescreve a
anterior — isso preserva a exatidão do gráfico de meses passados mesmo depois que uma fatura mudar
de valor. O custo de uma categoria em um mês M é o valor da linha mais recente daquela categoria
com `effective_from <= último dia de M`.

### Tabelas reutilizadas (sem alteração de schema)

- `payments` (`status = 'RECEIVED'`, `amount_cents`, `paid_at`) — fonte da receita.
- `referral_commissions` (`commission_amount`, `created_at`) — fonte do custo de comissão,
  agrupado pela data de criação da comissão (data da venda), não pela data de pagamento ao
  afiliado — assim o custo de comissão fica no mesmo mês da receita que o gerou, coerente pra
  cálculo de lucro do período.

## Backend

### Novo endpoint

`GET /easy-maintenance/api/v1/admin/billing/financials?months=12`

Resposta: lista de `{ month: "2026-08", revenueCents, costCents, commissionCents, profitCents }`
para os últimos N meses (default 12), mais antigo primeiro. O item mais recente da lista alimenta
o grid de totalizadores do mês atual no frontend (não precisa de endpoint separado).

- `revenueCents` — `SUM(amount_cents)` de `payments` com `status = RECEIVED`, agrupado por
  ano-mês de `paid_at`.
- `commissionCents` — `SUM(commission_amount)` de `referral_commissions`, agrupado por ano-mês de
  `created_at`.
- `costCents` — calculado em código (não SQL): para cada mês da janela, para cada categoria de
  `operating_expense_rates`, pega o valor vigente naquele mês e soma.
- `profitCents = revenueCents - commissionCents - costCents`.

### Novo endpoint (CRUD de custo)

- `GET /admin/billing/expense-rates` — lista os valores vigentes atuais por categoria.
- `POST /admin/billing/expense-rates` — cria uma nova vigência para uma categoria
  (`category`, `amountCents`, `effectiveFrom`).

Mesmo padrão de autenticação/autorização já usado no resto de `/admin/*`.

## Frontend

Nova página `src/app/private/admin/billing/financeiro/page.tsx`:

1. **Grid de 3 cartões** (mês atual, do item mais recente de `/admin/billing/financials`):
   Recebido, Gasto, Total (lucro) — cores neutras exceto o Total, que muda de cor se negativo.
2. **Gráfico Recharts** (barra agrupada ou linha, a definir no plano): Receita, Gasto, Lucro por
   mês, últimos 12 meses.
3. **Seção de custo de infraestrutura**: tabela com os valores vigentes atuais por categoria +
   formulário simples pra lançar um novo valor (categoria, valor, data de vigência).

## Fora de escopo (não construir agora)

- Despesas gerais do negócio (ferramentas, contador, etc.).
- Lançamento avulso de custo por data — só valor fixo mensal por categoria.
- Qualquer nível de permissão além do admin já existente.
- Projeção/forecast de receita ou custo futuro — só histórico real.
