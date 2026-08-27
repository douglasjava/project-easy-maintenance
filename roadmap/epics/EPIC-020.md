# EPIC-020 — Painel Financeiro Admin (Receita vs. Custo)

## Status
🟢 **PRs abertas contra `staging`** (24/08/2026) —
[easy-maintenance-api#43](https://github.com/douglasjava/easy-maintenance-api/pull/43) e
[easy-maintenance-web#49](https://github.com/douglasjava/easy-maintenance-web/pull/49), reunindo
toda a Fase 2 (TASK-190 a 198) mais os bugfixes achados no QA manual (migration V95,
`SimulationController`). Backend: suíte completa, 796 testes, 0 falhas. Frontend: `npm run build`
limpo (99/102 testes — 3 falhas pré-existentes em `middleware.test.ts`, sem relação). QA manual de
Douglas em andamento durante o desenvolvimento (vários achados já corrigidos na própria branch, ver
"Revisão da Fase 2" abaixo); QA final acontece em cima da PR.
Fase 1
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

### Revisão da Fase 2 — comissão manual substituída por comissionado atribuído (24/08/2026)

Durante o teste local de Douglas na tela nova, dois problemas de modelagem foram identificados por
análise de código (não em produção — 0 clientes pagantes, branch sem PR aberta):

**1. `manual_commission_rules` modela a coisa errada.** A regra calcula % sobre a receita líquida
**total** da empresa (`FinancialsService`, `rule.percentage × revenueNetCents` do mês inteiro), sem
nenhum vínculo com cliente. Confirmado com Douglas: o caso real de negócio é **comissão por cliente
atribuído** ("vendedor fecha o cliente X, ganha % da receita desse cliente especificamente"), não
rateio do total — o modelo commitado em TASK-190/191 não serve pro requisito real.

**2. `affiliates`/`referral_commissions` já resolve exatamente esse problema — e não deve ser
duplicado.** `Affiliate.commissionRate` + `ReferralCommission` (evento por cliente, vínculo com
pagamento via `Organization.referralCode`, status PENDENTE/PAGO) é estruturalmente o mesmo conceito
que "comissão manual" tentou reconstruir do zero, só que sem os dois recursos que faltavam:
percentual individual editável (já existe o campo, só falta endpoint de edição) e tipo de recorrência
(`ONE_TIME` vs `RECURRING`, que não existe hoje — toda comissão de afiliado é sempre única, travada
em 3 camadas: `PaymentReceivedHandler` só dispara no `cycleNumber == 1`, `CommissionService` tem
idempotência por `organizationId`, e o banco tem `UNIQUE KEY uk_referral_commissions_org
(organization_id)`). Decisão de Douglas: **estender `Affiliate`/`ReferralCommission` em vez de manter
duas estruturas paralelas fazendo a mesma coisa com nomes diferentes** — `manual_commission_rules` é
removida por completo.

**3. Achado à parte, descoberto na mesma análise — bug de atribuição pré-existente.** Desde a
EPIC-014 (13/07/2026, commit `48cc214`), a cobrança é só por `USER` — itens `BillingSubscriptionItem`
do tipo `ORGANIZATION` valem `0` (`BillingSubscriptionService.java:378-380`, migration `V79`), viram
só registro de vínculo pra limite de pool. **O valor da comissão não é afetado** (`PaymentReceivedHandler`
usa `Payment.amountCents`/`netAmountCents`, o valor real cobrado do gateway, não `item.getValueCents()`).
Mas a **atribuição** continua inteiramente organizada por organização (`Organization.referralCode` →
`Affiliate`, `ReferralCommission.organizationId` com `UNIQUE`), enquanto quem paga de fato — e quem
carrega o `referralCode` de origem — é o `User` (`User.referralCode` já existe, mas só é copiado pra
`Organization.referralCode` uma vez, na criação da org; se aplicado depois, nunca propaga). Numa conta
com múltiplas organizações, a comissão hoje prende na organização escolhida arbitrariamente pela
ordem de iteração dos itens da assinatura — não documentado em nenhuma epic até agora (EPIC-012,
21/06/2026, nunca foi revisitada quando a EPIC-014 mudou o modelo de cobrança, 13/07/2026). Corrigido
junto, pois RECURRING sem isso herdaria a mesma ambiguidade a cada ciclo.

**Novo modelo** (spec completa: `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`):

- `Affiliate` ganha `recurrenceType` (`ONE_TIME` | `RECURRING`) e endpoint de edição admin
  (`commissionRate`, `recurrenceType`) — hoje só existe criação, nunca update.
- `referral_commissions.organization_id` → `user_id` (rekey de schema + `PaymentReceivedHandler`
  passa a resolver o afiliado via item `USER` da assinatura + `User.referralCode`, não mais via item
  `ORGANIZATION` + `Organization.referralCode`).
- `PaymentReceivedHandler`/`CommissionService`: `ONE_TIME` mantém a trava atual (só no primeiro
  ciclo); `RECURRING` passa a gerar uma comissão por ciclo de pagamento, enquanto o afiliado estiver
  `ACTIVE`.
- Endpoint novo pra atribuir/reatribuir um afiliado a um usuário já existente (hoje só é setado na
  criação do usuário via admin, sem rota pra alterar depois).
- `manual_commission_rules`/`ManualCommissionRule` removidos por completo (entidade, service,
  controller, migration de drop, seção de frontend).
- Tela `/private/admin/financials` ganha detalhamento por comissionado (nome, %, recorrência, valor
  do período) — fonte única (`ReferralCommission`), cobrindo afiliado público e comissionado interno
  juntos.

**Tasks da revisão:**

| ID                               | Título                                                                                                          | Tipo    | Prioridade |
|-----------------------------------|-------------------------------------------------------------------------------------------------------------------|---------|------------|
| ~~[TASK-195](../tasks/TASK-195.md)~~ | ~~Backend: `Affiliate` ganha `recurrenceType`; CRUD admin de edição; remove `ManualCommissionRule`~~ | BACKEND | 🔴 Crítico *(implementada)* |
| ~~[TASK-196](../tasks/TASK-196.md)~~ | ~~Backend: rekey `referral_commissions.organization_id` → `user_id`; corrige atribuição; suporta comissão recorrente~~ | BUGFIX/BACKEND | 🔴 Crítico *(implementada)* |
| ~~[TASK-197](../tasks/TASK-197.md)~~ | ~~Backend: `FinancialsService` sem comissão manual; endpoint de breakdown por comissionado~~ | BACKEND | 🟠 Alto *(implementada)* |
| ~~[TASK-198](../tasks/TASK-198.md)~~ | ~~Frontend: edição de afiliado (%/recorrência), atribuição a cliente, breakdown na tela de financeiro~~ | FRONTEND | 🟠 Alto *(implementada)* |

Ordem: TASK-195 primeiro (schema/entidade base, `recurrenceType`) → TASK-196 (depende do
`recurrenceType` da TASK-195 pra decidir o comportamento de geração) → TASK-197 (depende da TASK-196
pra agregar comissão corretamente) → TASK-198 (depende dos endpoints da TASK-195/197).

### Revisão da Fase 2 — split de comissão entre beneficiários (27/08/2026)

Caso real levantado por Douglas: "Grupo Silva" precisa repassar comissão pra duas pessoas — o
grupo/afiliado e o vendedor que fechou a venda — sobre o mesmo cliente. A regra "1 comissionado
ativo por cliente" (confirmada na revisão anterior, ver acima) não muda — o que faltava era o
`Affiliate` poder declarar como o valor da comissão que ele gera é dividido entre N beneficiários,
sem duplicar atribuição de cliente nem mexer no schema de `ReferralCommission`/`CommissionService`.

**Decisão**: tabela nova `affiliate_commission_splits` (afiliado → beneficiário + percentual do
total, somando 100%), consultada só na hora de montar o breakdown mensal
(`FinancialsService.getCommissionsBreakdown`) — a comissão continua sendo criada e persistida como
hoje, um único evento por ciclo no valor total do `commissionRate` do afiliado. Afiliado sem split
configurado continua se comportando exatamente como antes (100% pro próprio afiliado) — feature
aditiva, sem migração de dado.

**Tasks:**

| ID                               | Título                                                                                   | Tipo     | Prioridade |
|-----------------------------------|-------------------------------------------------------------------------------------------|----------|------------|
| ~~[TASK-207](../tasks/TASK-207.md)~~ | ~~Backend: `affiliate_commission_splits` + endpoints de leitura/edição + beneficiários no breakdown mensal~~ | BACKEND  | 🟠 Alto *(implementada — commit `fcadbbb`, 843 testes, 0 falhas)* |
| [TASK-208](../tasks/TASK-208.md) | Frontend: ação "Dividir comissão" na tela de afiliados + sub-linhas de beneficiário no financeiro | FRONTEND | 🟠 Alto    |

Ordem: TASK-207 primeiro (schema/endpoints) → TASK-208 (depende dos endpoints da TASK-207).

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
- [x] `expenses` substitui `operating_expense_rates` sem resíduo órfão (TASK-190)
- [x] CRUD de despesas funcionando (TASK-191)
- [x] `FinancialsService` calcula bruto/líquido, saldo do mês e saldo acumulado corretamente;
      comissão de afiliado nova usa o líquido como base (TASK-192)
- [x] `/private/admin/financials` é página própria, fora das abas de Faturamento (TASK-193)
- [x] Cadastro de despesa funcionando na tela (TASK-194, parte de despesas)
- [ ] ~~Regra de comissão manual (% do faturamento total)~~ — **substituída**, ver "Revisão da Fase 2"
- [x] `Affiliate` suporta percentual editável e recorrência (`ONE_TIME`/`RECURRING`) (TASK-195)
- [x] Atribuição de comissão é por `user_id`, não `organization_id`; comissão recorrente gera uma
      linha por ciclo pra afiliados `RECURRING` (TASK-196)
- [x] Financeiro mostra breakdown por comissionado sem depender de `manual_commission_rules`
      (TASK-197)
- [x] Edição de afiliado (%/recorrência) e atribuição a cliente funcionando em admin (TASK-198)
- [x] Afiliado suporta divisão de comissão entre beneficiários, sem alterar a regra de 1
      comissionado por cliente (TASK-207)
- [ ] Divisão configurável e visível no financeiro em admin (TASK-208)

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
- Edição de despesa já criada — só criar/remover.
- Data de corte configurável para o saldo acumulado.
- Notificação/alerta automático disparado por saldo negativo ou métrica financeira.
- Exportação (CSV/PDF) dos dados financeiros.

**Revisão da Fase 2 (24/08/2026):**
- Recálculo retroativo de comissões `referral_commissions` já geradas antes desta mudança — só
  comissões novas (a partir do deploy) usam `user_id`/recorrência.
- Um cliente com mais de um comissionado atribuído ao mesmo tempo — confirmado com Douglas: sempre
  um comissionado ativo por cliente, por vez (histórico preservado se reatribuído).
- Correção do fluxo de autocadastro público (cookie `em_ref` → onboarding) não propagar
  `referralCode` pro usuário automaticamente — bug pré-existente, encontrado na mesma análise, sem
  relação com esta revisão; não bloqueia porque atribuição de comissionado interno é sempre manual
  via admin. Vale abrir bug à parte depois.

**Split de comissão (27/08/2026):**
- Beneficiário do split ter sua própria recorrência/vínculo de cliente independente (ex.: vendedor
  virar afiliado próprio pra outros clientes) — se isso for necessário, é hierarquia de afiliados
  (`parentAffiliateId`), caso mais invasivo, avaliado e não escolhido para este pedido.
- Pagamento automático/split direto na gateway (Asaas) — a divisão é só de visão/relatório dentro do
  sistema; o repasse de fato pro beneficiário continua manual, como já é hoje pro afiliado.

## Riscos
Baixo — extensão aditiva da área admin existente, não altera nenhum fluxo de cliente. Único ponto
de atenção técnico: o cálculo de custo por mês é feito em código (não SQL), iterando a janela de
meses e resolvendo a vigência mais recente por categoria — precisa de teste unitário cobrindo
troca de vigência no meio da janela (ex.: Railway custava R$200 até maio, R$250 a partir de junho —
o mês de maio no gráfico precisa continuar mostrando R$200).
