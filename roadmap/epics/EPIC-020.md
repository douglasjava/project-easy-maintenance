# EPIC-020 — Painel Financeiro Admin (Receita vs. Custo)

## Status
🟡 **Fase 2 em andamento** (23/08/2026) — TASK-190 e TASK-191 implementadas (schema + CRUD de
despesas/comissão manual), na branch `feature/financial-module-v2` (`easy-maintenance-api`).
Próxima: TASK-192 (recálculo de `FinancialsService` — bruto/líquido, saldo do mês/acumulado,
comissão de afiliado sobre o líquido). Spec aprovada em
`docs/superpowers/specs/2026-08-23-financial-module-design.md`. Fase 1
(grid + gráfico + custo de infra por taxa recorrente) segue como abaixo — **QA manual aprovado por
Douglas (11/08/2026)** — as 4 tasks (TASK-159 a 162) implementadas e validadas de ponta a ponta,
incluindo o ajuste de rótulo pra categoria "Outros" adicionado após o teste manual. **As PRs para
`staging` ainda estão abertas, não mergeadas**
([easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31),
[easy-maintenance-web#34](https://github.com/douglasjava/easy-maintenance-web/pull/34)) — o teste
foi feito fora de `staging` (branch local/preview, não confirmado exatamente onde).

### Fase 2 — Página própria, bruto/líquido, despesas avulsas, comissão manual (criada 23/08/2026)

Douglas quer migrar o controle financeiro da empresa de uma planilha externa pra dentro do sistema
— "aqui está a verdade": os dados reais de pagamento (Asaas) e comissão já vivem no banco. Pedido
explícito de brainstorm "mais completo" por ser um redesenho maior da Fase 1. Spec aprovada:
`docs/superpowers/specs/2026-08-23-financial-module-design.md`.

**Achados que motivaram esta fase:**
1. A tela hoje é uma aba dentro de Faturamento — devia ser página própria de primeiro nível.
2. `FinancialsService` soma `Payment.amountCents` (**bruto**) como receita — mas `Payment` já tem
   `netAmountCents` pronto do Asaas. É uma correção de cálculo, não só uma feature nova.
3. `ReferralCommission` (comissão de afiliado) é calculada sobre o preço do plano, não sobre o
   líquido recebido — decisão de Douglas: passa a ser sobre o líquido, só pra comissões novas.
4. `OperatingExpenseRate` modela despesa como taxa mensal recorrente por categoria — Douglas quer
   lançamento avulso (um registro por despesa), como numa planilha. Tabela antiga é **derrubada sem
   migrar histórico** (decisão explícita).
5. Não existe "comissão manual" — vira uma regra recorrente (nome + % + vigência), calculada
   automaticamente sobre o líquido do período, igual à comissão de afiliado.
6. Não existe "saldo acumulado" (soma corrida entre meses) — só valores isolados por mês.

**Tasks da Fase 2:**

| ID                               | Título                                                                                                                | Tipo           | Prioridade |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------|----------------|------------|
| [TASK-190](../tasks/TASK-190.md) | Backend: substitui `operating_expense_rates` por `expenses` + `manual_commission_rules`                               | BACKEND        | 🟠 Alto    |
| [TASK-191](../tasks/TASK-191.md) | Backend: CRUD de despesas e regras de comissão manual                                                                 | BACKEND        | 🟠 Alto    |
| [TASK-192](../tasks/TASK-192.md) | Backend: reescreve `FinancialsService` (bruto/líquido, saldo do mês/acumulado) + comissão de afiliado sobre o líquido | BUGFIX/BACKEND | 🔴 Crítico |
| [TASK-193](../tasks/TASK-193.md) | Frontend: página própria `/private/admin/financials`                                                                  | FRONTEND       | 🟠 Alto    |
| [TASK-194](../tasks/TASK-194.md) | Frontend: seções de cadastro de despesas e regras de comissão manual                                                  | FRONTEND       | 🟠 Alto    |

Ordem: TASK-190 primeiro (schema, sem dependência) → TASK-191 e TASK-192 podem andar em paralelo
(ambas só dependem da TASK-190) → TASK-193 (depende do endpoint agregado da TASK-192) → TASK-194
(depende dos endpoints de CRUD da TASK-191 e da página já existir, TASK-193).

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

## Tasks — Fase 1

| ID                               | Título                                                                                 | Tipo     | Prioridade |
|----------------------------------|----------------------------------------------------------------------------------------|----------|------------|
| [TASK-159](../tasks/TASK-159.md) | Backend: modelo de dados + CRUD de custo de infraestrutura (`operating_expense_rates`) | BACKEND  | 🟠 Alto    |
| [TASK-160](../tasks/TASK-160.md) | Backend: endpoint agregado de financeiro por mês (receita/custo/comissão/lucro)        | BACKEND  | 🟠 Alto    |
| [TASK-161](../tasks/TASK-161.md) | Frontend: página `/financeiro` — grid de totalizadores + gráfico Recharts de 12 meses  | FRONTEND | 🟠 Alto    |
| [TASK-162](../tasks/TASK-162.md) | Frontend: seção de cadastro/edição de custo de infraestrutura na página `/financeiro`  | FRONTEND | 🟠 Alto    |

Ordem: TASK-159 primeiro (o endpoint agregado da TASK-160 depende dos dados de custo existirem) →
TASK-160 → TASK-161 (a página precisa do endpoint agregado) → TASK-162 (a seção de cadastro entra
na mesma página já criada na TASK-161).

---

## Critério de Conclusão do Épico

**Fase 1:**
- [x] `/private/admin/billing/financeiro` acessível só pelo admin, mesma autenticação já existente
- [x] Grid mostra Recebido/Gasto/Total do mês atual, calculado a partir de pagamento confirmado
      (não MRR de assinatura ativa)
- [x] Gráfico mostra os últimos 12 meses das mesmas três métricas
- [x] Custo de infraestrutura é lançado manualmente por categoria, com histórico preservado
      (atualizar não apaga o valor anterior)
- [x] Comissão de afiliado entra no cálculo de custo automaticamente, sem lançamento manual
- [x] `npm run build` (frontend) e suíte de testes (backend) sem regressão
- [x] **QA manual com dado real** — aprovado por Douglas (11/08/2026)

**Fase 2:**
- [ ] `expenses` e `manual_commission_rules` substituem `operating_expense_rates` sem resíduo
      órfão (TASK-190)
- [ ] CRUD de despesas e regras de comissão manual funcionando (TASK-191)
- [ ] `FinancialsService` calcula bruto/líquido, saldo do mês e saldo acumulado corretamente;
      comissão de afiliado nova usa o líquido como base (TASK-192)
- [ ] `/private/admin/financials` é página própria, fora das abas de Faturamento (TASK-193)
- [ ] Cadastro de despesa e de regra de comissão manual funcionando na tela (TASK-194)

---

## Fora de Escopo

**Fase 1:**
- Despesas gerais do negócio (ferramentas, contador, etc.) — só infraestrutura + comissão.
- ~~Lançamento avulso de custo por data~~ — passa a ser escopo da **Fase 2** (TASK-190/191).
- Qualquer nível de permissão além do admin já existente.
- Projeção/forecast de receita ou custo futuro — só histórico real.

**Fase 2:**
- Recálculo/correção de comissões de afiliado já registradas no sistema.
- Migração dos dados históricos de `operating_expense_rates` para `expenses` (decisão explícita de
  Douglas: começar do zero).
- Edição de despesa ou de regra de comissão manual já criada — só criar/remover/encerrar.
- Data de corte configurável para o saldo acumulado.
- Notificação/alerta automático disparado por saldo negativo ou métrica financeira.
- Exportação (CSV/PDF) dos dados financeiros.

## Riscos
Baixo — extensão aditiva da área admin existente, não altera nenhum fluxo de cliente. Único ponto
de atenção técnico: o cálculo de custo por mês é feito em código (não SQL), iterando a janela de
meses e resolvendo a vigência mais recente por categoria — precisa de teste unitário cobrindo
troca de vigência no meio da janela (ex.: Railway custava R$200 até maio, R$250 a partir de junho —
o mês de maio no gráfico precisa continuar mostrando R$200).
