# Módulo Financeiro — página própria, bruto/líquido, despesas e comissões manuais

**Data:** 23/08/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Douglas (dono do produto) controla hoje as finanças da empresa por planilha externa e quer migrar
esse controle pra dentro do sistema — "aqui está a verdade": os dados reais de pagamento (Asaas)
e comissão já vivem no banco, então manter um controle paralelo em planilha é redundante e
propenso a divergência. Pedido explícito de um brainstorm "mais completo" que os recentes desta
sessão, por ser um redesenho maior de uma área existente (não uma feature pontual nova).

## Estado atual (confirmado por leitura de código)

- `/private/admin/billing/financeiro` é hoje uma aba dentro de `BillingAdminLayout`, junto de
  Visão Geral/Assinaturas/Faturas/Planos.
- `FinancialsService.getMonthlyFinancials()` soma `Payment.amountCents` (**bruto**, não o líquido)
  como receita — apesar de `Payment` já ter `netAmountCents`/`gatewayFeeCents` populados a partir
  do retorno do Asaas. É um cálculo incorreto pro que se quer agora, não só uma limitação.
- `ReferralCommission.commissionAmount` (comissão de afiliado) é calculada sobre `planPrice` (preço
  cheio do plano), não sobre o valor líquido recebido.
- `OperatingExpenseRate` modela despesa como uma **taxa mensal recorrente por categoria**
  (`RAILWAY, OPENAI, S3, ASAAS_FEES, OUTROS`, com `amountCents` e `effectiveFrom`) — não um
  lançamento avulso. `FinancialsService` soma a taxa vigente de cada categoria no último dia do mês.
- Não existe conceito de "comissão manual" no sistema hoje.
- A tela atual mostra 3 cards (Recebido/Gasto/Lucro do mês) + gráfico de 12 meses; não existe
  "saldo acumulado" (soma corrida entre meses).

## Decisões de escopo (brainstorm, 23/08/2026)

1. **Página própria de primeiro nível**, removida das abas de Faturamento.
2. **Comissão de afiliado passa a ser calculada sobre o valor líquido** (`Payment.netAmountCents`),
   não mais sobre o preço do plano — mudança de regra de negócio real (afeta o quanto cada afiliado
   recebe da venda), **só válida pra comissões calculadas a partir de agora**; comissões já
   registradas no sistema não são recalculadas.
3. **Despesa vira lançamento avulso** (data + categoria + valor + descrição), substituindo por
   completo o modelo de taxa recorrente — `operating_expense_rates` é **derrubada sem migração de
   dados históricos** (decisão explícita de Douglas: começar do zero na tabela nova; meses passados
   no saldo acumulado/gráfico mostram despesa zerada a partir da mudança, mesmo tendo custo real
   antes).
4. **Despesa comum tem um valor só** (o que foi de fato desembolsado) — não existe "bruto vs.
   líquido" por lançamento de despesa genérico. **Comissão (manual ou de afiliado) é a exceção**:
   usa um percentual calculado sobre a receita líquida, não um valor fixo digitado.
5. **Comissão manual é uma regra recorrente** (nome de quem recebe + percentual + vigência), não um
   lançamento pontual — o sistema calcula o valor devido automaticamente todo mês, igual a como a
   comissão de afiliado agora também funciona (% sobre o líquido do período).
6. **Categorias de despesa definidas**: Fornecedor, Infra, Marketing, Impostos/Taxas,
   Folha/Pró-labore, Jurídico/Contábil, Ferramentas/SaaS, Outros.
7. **Saldo acumulado** conta desde o primeiro mês com dado real no sistema (primeiro `Payment`
   recebido) — sem data de corte configurável.

## Modelo de dados

Migration `V93__replace_operating_expense_rates_with_financials_module.sql` (`easy-maintenance-api`):

```sql
DROP TABLE IF EXISTS operating_expense_rates;

CREATE TABLE expenses (
    id            BIGINT PRIMARY KEY AUTO_INCREMENT,
    category      VARCHAR(30) NOT NULL,
    description   VARCHAR(255) NOT NULL,
    amount_cents  BIGINT NOT NULL,
    expense_date  DATE NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE manual_commission_rules (
    id               BIGINT PRIMARY KEY AUTO_INCREMENT,
    payee_name       VARCHAR(120) NOT NULL,
    percentage       DECIMAL(5,4) NOT NULL,
    effective_from   DATE NOT NULL,
    effective_to     DATE NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

- **`expenses`**: um lançamento por despesa. Novo enum `ExpenseCategory` (substitui o atual, que era
  específico demais pra virar categoria genérica): `FORNECEDOR, INFRA, MARKETING, IMPOSTOS_TAXAS,
  FOLHA_PROLABORE, JURIDICO_CONTABIL, FERRAMENTAS_SAAS, OUTROS`.
- **`manual_commission_rules`**: regra recorrente. `effective_to = NULL` = regra ativa; setar
  `effective_to` "encerra" a regra sem apagar o histórico dela dos meses em que esteve vigente.
  `payee_name` é texto livre (sem FK) porque comissão manual é, por definição, alguém fora do
  sistema de afiliados/usuários cadastrados.
- **`ReferralCommission`** (sem mudança de schema): o ponto no código onde `commissionAmount` é
  calculado (na confirmação de pagamento de assinatura) passa a usar `Payment.netAmountCents` em
  vez do preço do plano — mudança de lógica, não de dado, e só afeta cálculos feitos a partir do
  deploy desta mudança.

## Backend

### `FinancialsService.getMonthlyFinancials()` — reescrito

Por mês, do mais antigo ao mais recente dentro da janela pedida (mesmo padrão de loop já existente):

```java
long revenueGrossCents = sum(Payment.amountCents)    WHERE status=RECEIVED AND paidAt no mês
long revenueNetCents   = sum(Payment.netAmountCents) WHERE status=RECEIVED AND paidAt no mês
long gatewayFeeCents   = revenueGrossCents - revenueNetCents  // informativo

long affiliateCommissionCents = sum(ReferralCommission.commissionAmount) WHERE createdAt no mês
long manualCommissionCents    = soma, para cada manual_commission_rule ATIVA no mês
                                 (effective_from <= fim do mês AND (effective_to IS NULL OR
                                  effective_to >= início do mês)), de (rule.percentage × revenueNetCents)
long expenseCents             = sum(expenses.amount_cents) WHERE expense_date no mês

long monthlyBalanceCents = revenueNetCents - affiliateCommissionCents - manualCommissionCents - expenseCents
```

- A comissão manual usa a receita líquida **do próprio mês sendo calculado** — não um valor fixo —
  o que garante que ela reage de verdade à variação de receita mês a mês, coerente com a mesma
  regra aplicada à comissão de afiliado.
- **`cumulativeBalanceCents`**: soma corrida de `monthlyBalanceCents`, começando no primeiro mês em
  que existe qualquer `Payment` recebido — calculado no mesmo loop mensal.

### Endpoints

Todos sob `/easy-maintenance/api/v1/private/admin/financials` — **novo prefixo**, não mais aninhado
sob `/private/admin/billing/...` (o endpoint atual é `/private/admin/billing/financials`; muda de
lugar junto com a página, pra refletir que Financeiro deixou de ser parte de Faturamento).

`GET /private/admin/financials` (substitui o `GET /private/admin/billing/financials` atual, mesmo
formato de resposta mensal, campos expandidos): `revenueGrossCents`, `revenueNetCents`,
`gatewayFeeCents`, `affiliateCommissionCents`, `manualCommissionCents`, `expenseCents`,
`monthlyBalanceCents`, `cumulativeBalanceCents`, por mês.

Despesas:
- `GET /private/admin/financials/expenses` — lista paginada, filtrável por categoria e período.
- `POST /private/admin/financials/expenses` — cria (`category`, `description`, `amountCents`, `expenseDate`).
- `DELETE /private/admin/financials/expenses/{id}` — remove. **Sem edição** — lançamento errado é
  apagado e recriado, não editado (evita rastrear histórico de edição de um valor financeiro;
  consistente com a ideia de que cada linha representa um fato imutável, como numa planilha).

Comissões manuais:
- `GET /private/admin/financials/commission-rules` — lista todas (ativas e encerradas).
- `POST /private/admin/financials/commission-rules` — cria (`payeeName`, `percentage`, `effectiveFrom`).
- `PATCH /private/admin/financials/commission-rules/{id}/close` — seta `effectiveTo = hoje`, preserva
  histórico.
- `DELETE /private/admin/financials/commission-rules/{id}` — só pra regra criada por engano, que nunca
  deveria ter existido (diferente de "encerrar", que preserva o histórico da regra nos meses em que
  esteve ativa).

## Frontend

Nova página `/private/admin/financials/page.tsx`, sem `BillingAdminLayout` (header próprio
"Financeiro"). Item novo no menu lateral (`Sidebar.tsx`, `adminItems`), mesmo nível de
Faturamento/Afiliados/Leads. `/private/admin/billing/financeiro` deixa de existir como aba (removida
de `BillingAdminLayout.tsx`); sem redirect (rota não é referenciada fora do admin).

Cards de resumo (mês atual): Recebido (bruto), Recebido (líquido), Taxa Asaas, Despesas, Comissões
(afiliado + manual), Saldo do mês, Saldo acumulado.

Gráfico de evolução mensal (Recharts `ComposedChart`): barras de Líquido/Despesas/Comissões + linha
de saldo acumulado sobreposta.

Seção "Despesas": tabela com filtro por categoria/período (mesmo padrão de filtro já usado em
Leads/Afiliados), botão "+ Nova despesa" abrindo modal (categoria, descrição, valor, data — mesmo
padrão de modal do `LeadFormModal`), botão remover por linha.

Seção "Comissões manuais": tabela (nome, %, vigência, status ativo/encerrado), botão "+ Nova regra"
(modal: nome, %, data de início), ação "Encerrar" por linha em regra ativa.

`ExpenseRatesSection.tsx` (atual) é removido, substituído pelas duas seções novas.

## Fora de escopo

- Recálculo/correção de comissões de afiliado já registradas no sistema.
- Migração dos dados históricos de `operating_expense_rates` para `expenses` (decisão explícita:
  começar do zero).
- Edição de despesa ou de regra de comissão manual já criada — só criar/remover/encerrar.
- Data de corte configurável para o saldo acumulado.
- Qualquer notificação/alerta automático disparado por saldo negativo ou métrica financeira.
- Exportação (CSV/PDF) dos dados financeiros.

## Testes

- Backend: `FinancialsServiceTest` cobrindo receita bruta vs. líquida, comissão manual calculada
  sobre o líquido do mês (não valor fixo), regra de comissão manual respeitando vigência
  (`effectiveFrom`/`effectiveTo`), saldo mensal e saldo acumulado ao longo de vários meses. CRUD de
  despesas e regras de comissão manual (criar, listar filtrado, remover, encerrar). Teste
  confirmando que `ReferralCommission` criada a partir da mudança usa `netAmountCents`, não
  `planPrice`.
- Sem teste automatizado da migration em si (`DROP`/`CREATE`) — mesmo padrão já registrado em tasks
  anteriores desta sessão: nenhum teste deste projeto roda Flyway de verdade (todo `@DataJpaTest`
  usa `ddl-auto=create-drop`). Validação via QA manual pós-deploy.
- Frontend: `npm run build` limpo + QA manual (cadastrar despesa, cadastrar/encerrar regra de
  comissão manual, conferir os 7 cards, conferir gráfico com a linha de saldo acumulado).

## Riscos

- **Médio** — mudança na base de cálculo da comissão de afiliado é uma mudança de regra de negócio
  real (ainda que só pra frente); vale alinhar com qualquer afiliado ativo antes de ir pra produção,
  já que o valor que ele passa a receber por venda muda.
- **Baixo** — o resto é aditivo/substituição de uma tela administrativa de uso interno, sem tocar em
  nenhum fluxo de cliente final.
- **Aceito explicitamente por Douglas**: histórico de `operating_expense_rates` é descartado, não
  migrado — meses passados no saldo acumulado/gráfico mostram despesa zerada a partir da mudança.
