# Kanban — Easy Maintenance

> Atualizado em: 29/08/2026 — **🔴 TASK-210 criada e implementada (BUGFIX crítico, regressão da
> TASK-209)**: Douglas reportou log de produção do run de hoje (01:30) do `PixRenewalJob` — o fix da
> TASK-209 achou a fatura já existente do payer 2 corretamente, mas quebrou em seguida com
> `LazyInitializationException: no Session` em `CardTransitionService.processTransition`
> (`invoice.getItems()`), então a assinatura de teste (subscriptionId=2) continua travada. Causa raiz:
> a query de fallback da TASK-209 (`findByPayerIdAndPeriodStartAndPeriodEnd`) não carregava `items`
> (`@OneToMany` LAZY) — só não quebrava antes porque o caminho de fatura nova monta `items` em
> memória (lista comum, sem proxy). Fix: `@EntityGraph(attributePaths = {"items"})` na query, mesmo
> padrão já usado em `findFirstByPayerIdAndStatusOrderByCreatedAtDesc`. Teste JPA real novo
> (`InvoiceRepositoryPersistenceTest`, H2) comprova a regressão — falha sem o fix, passa com ele.
> Branch `bugfix/TASK-210-invoice-items-lazy-loading` (a partir de `staging`), commit `d07fc6a`, PR
> contra staging [api#57](https://github.com/douglasjava/easy-maintenance-api/pull/57) aberta.
> 852/852 testes, 0 falhas. Douglas optou por esperar o próximo run automático (01:30) em vez de criar
> um endpoint de trigger manual — QA final (subscription 2 desbloqueada) pendente do merge, deploy e
> desse run.
> Atualizado em: 28/08/2026 — **🔴 TASK-209: mergeada em `staging`, PR `staging → main` aberta**:
> [easy-maintenance-api#56](https://github.com/douglasjava/easy-maintenance-api/pull/56) (PR contra
> staging [#55](https://github.com/douglasjava/easy-maintenance-api/pull/55) já mergeada). Falta
> mergear o #56 e aguardar o deploy — só depois disso o job `PixRenewalJob` (01:30 diário) vai
> reprocessar e desbloquear a assinatura de teste do Douglas automaticamente.
> Atualizado em: 28/08/2026 — **🔴 TASK-209 criada e implementada (BUGFIX crítico)**: Douglas,
> testando com usuário próprio em produção (onboarding PIX → trocou pra Cartão no meio do ciclo),
> achou que a assinatura ficou travada com "Pagamento pendente R$ 299,00" sem link de checkout.
> Causa raiz: `InvoiceService.processPayerInvoice` retorna `Optional.empty()` tanto pra "nada a
> faturar" quanto pra "fatura do período já existe" (idempotência) — `generateInvoiceForPayer`
> repassava esse `Optional.empty()` ambíguo pra 4 fluxos diferentes (`CardTransitionService`,
> `PixRenewalService`, `PaymentMethodTransitionService.initiateCardUpdate`,
> `BillingRecoveryService`), todos os quais desistiam silenciosamente quando a fatura já existia —
> travando a assinatura pra sempre (o job reprocessa todo dia às 01:30 e falha do mesmo jeito).
> **Mais grave que o caso do Douglas**: o mesmo bug atinge `PixRenewalService` — renovação PIX de
> qualquer cliente pagante real pode travar do mesmo jeito, sem cobrança nova e sem alerta visível.
> Fix cirúrgico em `generateInvoiceForPayer` (busca a fatura existente em vez de propagar o
> `Optional.empty()` ambíguo), sem tocar nos 4 pontos de chamada nem no job em lote
> `generateInvoices`. Branch `bugfix/TASK-209-invoice-already-exists-silent-skip`
> (`easy-maintenance-api`, commit `0d3851c`, a partir de `staging`). 844/844 testes, 0 falhas. Sem
> PR aberta ainda. Assinatura travada do Douglas deve se autocorrigir no próximo run do job após o
> deploy (não existe trigger manual pra esse job específico).
> Atualizado em: 27/08/2026 — **TASK-207/208: mergeadas em `staging`, PRs `staging → main`
> abertas**: [easy-maintenance-api#54](https://github.com/douglasjava/easy-maintenance-api/pull/54)
> e [easy-maintenance-web#59](https://github.com/douglasjava/easy-maintenance-web/pull/59). PRs
> anteriores contra `staging` ([api#53](https://github.com/douglasjava/easy-maintenance-api/pull/53),
> [web#58](https://github.com/douglasjava/easy-maintenance-web/pull/58)) já mergeadas.
> Atualizado em: 27/08/2026 — **TASK-207/208: PRs abertas contra `staging`** —
> [easy-maintenance-api#53](https://github.com/douglasjava/easy-maintenance-api/pull/53) e
> [easy-maintenance-web#58](https://github.com/douglasjava/easy-maintenance-web/pull/58). QA manual
> completo por Douglas ([TASK-QA-MAN-016](QA/tasks/TASK-QA-MAN-016.md), cenários C1-C7 confirmados)
> antes da abertura.
> Atualizado em: 27/08/2026 — **TASK-208: achado no QA manual de Douglas** — cenário C6 (sub-linhas
> de beneficiário no financeiro) inicialmente pareceu não funcionar, mas era só a seção
> "Comissões por pessoa" não ter refeito o fetch depois do split ser configurado numa aba já
> aberta (recarregar a página resolveu — sem bug de código). No mesmo QA, Douglas pediu uma coluna
> nova "Usuários" na mesma seção, contando `pendingCount + paidCount` (dado já existente na API,
> sem mudança de backend) — adicionada e commitada (`9c0ad14`, `npm run build` limpo).
> Atualizado em: 27/08/2026 — **Plano de QA manual criado** para o split de comissão (EPIC-020,
> TASK-207/208): [TASK-QA-MAN-016](QA/tasks/TASK-QA-MAN-016.md), 8 cenários (C1 suíte automatizada,
> C2 gerar comissão de teste via `/dev/simulate/affiliate-flow`, C3 regressão em afiliado sem split,
> C4 configurar split 100%, C5 bloqueio de soma errada, C6 valores corretos no financeiro, C7 remover
> divisão, C8 contratos de erro do backend). Aguardando execução por Douglas antes de abrir as PRs.
> Atualizado em: 27/08/2026 — **TASK-208 implementada** (EPIC-020, split de comissão): ação
> "Dividir comissão" na tela de afiliados abre `CommissionSplitModal.tsx` (novo) — lista editável de
> beneficiários (nome + %), validação client-side de soma = 100% antes de habilitar "Salvar", ação
> "Remover divisão" (lista vazia, confirmada via `ConfirmModal` já existente) que volta o afiliado a
> 100% pra ele mesmo. `CommissionsBreakdownSection` (financeiro) ganha sub-linhas indentadas por
> beneficiário quando o afiliado tem split configurado; sem split, comportamento idêntico ao atual.
> Branch `feature/TASK-208-commission-split-ui` (`easy-maintenance-web`, a partir de `staging`),
> commit `1c628e5`. `npm run build` limpo (54 rotas); `npm test`: 105/108 passando, as 3 falhas são
> em `middleware.test.ts`, pré-existentes e sem relação. **Não validada visualmente** — mesma
> limitação já registrada em tasks anteriores (tela exige login, sem credenciais de teste
> disponíveis pra automação). **As 2 tasks da revisão de split (TASK-207/208) estão implementadas**
> — falta QA manual de ponta a ponta por Douglas e abertura das PRs (api + web) contra `staging`.
> Atualizado em: 27/08/2026 — **TASK-207 implementada** (EPIC-020, split de comissão): tabela
> `affiliate_commission_splits` (migration `V98`), endpoints
> `GET`/`PUT /private/admin/affiliates-commissions/{id}/splits` (validação de soma 100% via
> `RuleException`, substituição atômica, lista vazia remove o split) e campo `beneficiaries` novo em
> `GET /private/admin/financials/commissions-breakdown`. Não altera `ReferralCommission`/
> `CommissionService`; afiliado sem split continua 100% pra ele mesmo. Branch
> `feature/TASK-207-commission-split` (`easy-maintenance-api`, a partir de `staging`), commit
> `fcadbbb`. Suíte completa: 843 testes, 0 falhas. Sem PR aberta — aguardando TASK-208 (frontend)
> pra QA de ponta a ponta e PR conjunta. **Achado durante a implementação, registrado na task**: o
> valor de cada beneficiário é truncado (não arredondado) igual ao total do afiliado já era — a soma
> dos beneficiários pode ficar 1 centavo abaixo do total por truncamento; aceito por ora (mesmo
> comportamento já existente no resto do módulo), watch-list se virar problema real no financeiro.
> Atualizado em: 27/08/2026 — **TASK-207/208 criadas** (EPIC-020, split de comissão entre
> beneficiários): caso real levantado por Douglas — "Grupo Silva" precisa dividir a comissão de um
> cliente entre o grupo/afiliado e o vendedor que fechou a venda. Hoje um cliente tem no máximo um
> comissionado ativo (regra confirmada na Revisão da Fase 2, 24/08), com uma única
> `commissionRate` — cadastrar o percentual somado funciona mas perde rastreabilidade de quem
> recebe o quê no relatório "Comissões por pessoa". Decisão: tabela nova
> `affiliate_commission_splits` (afiliado → beneficiário + % do total, somando 100%), consultada só
> na hora de montar o breakdown mensal — não altera `ReferralCommission`/`CommissionService` nem a
> regra de 1 comissionado por cliente; afiliado sem split continua 100% pra ele mesmo, sem
> migração. TASK-207 (backend: schema + endpoints + breakdown) → TASK-208 (frontend: modal de
> divisão + sub-linhas no financeiro). Priorizado por Douglas — precisa implementar agora.
> Atualizado em: 26/08/2026 — **TASK-206 testada localmente, PRs abertas contra `staging`**:
> [api#49](https://github.com/douglasjava/easy-maintenance-api/pull/49),
> [web#54](https://github.com/douglasjava/easy-maintenance-web/pull/54).
> Atualizado em: 26/08/2026 — **TASK-206 implementada**, branch `bugfix/TASK-206-user-subscription-route`
> nos dois repos, aguardando teste local. api `714badf` (rota nova `GET /users/{userId}/subscription`,
> 813/813 testes); web `a25f247` (aponta pra rota nova, corrige abas Assinatura e Pagamento).
> Atualizado em: 26/08/2026 — **TASK-201 a 205 mergeadas em `staging`**:
> [api#48](https://github.com/douglasjava/easy-maintenance-api/pull/48),
> [web#53](https://github.com/douglasjava/easy-maintenance-web/pull/53). PRs `staging → main` ainda
> não abertas.
> Atualizado em: 26/08/2026 — **TASK-201 a 205 testadas localmente pelo Douglas** (`TASK-QA-MAN-014`,
> todos os cenários passaram), **PRs abertas contra `staging`**:
> [api#48](https://github.com/douglasjava/easy-maintenance-api/pull/48),
> [web#53](https://github.com/douglasjava/easy-maintenance-web/pull/53).
> Atualizado em: 26/08/2026 — **TASK-206 criada** (bugfix, sem épico): aba Pagamento do admin
> (`/private/users/[id]`) chama uma rota que não existe mais desde o refactor de billing por
> usuário (`GET /admin/billing/user/{id}/subscription`, removida no commit `815e36e`) — cai num
> `.catch(() => null)` que não quebra a tela, mas faz o campo "Plano" sempre mostrar "STARTER"
> mesmo pra quem está em outro plano. Achado por Douglas ao testar EPIC-002 Fase 3
> (`TASK-QA-MAN-014`), sem relação com ela — registrada separada, foco continua na Fase 3.
> Atualizado em: 25/08/2026 — **TASK-201 a 205 implementadas** (EPIC-002 Fase 3), branch
> `feature/EPIC-002-fase3-asaas-sync` nos dois repos, PR ainda não aberta. api: 809/809 testes
> passando (`2e6e15a`, `738d7a6`, `ff1ef31`); web: `npm run build` limpo (`4b82e2b`, `0620743`).
> Achado no meio do caminho: `@Doc`/CPF-CNPJ (Hibernate Validator) já existia no projeto e já era
> usado em `OrganizationDTO` — só faltava aplicar em `OnboardingDTO`, reduziu o escopo de TASK-203.
> Atualizado em: 25/08/2026 — **TASK-201 a 205 criadas** (EPIC-002 Fase 3): achado real no primeiro
> cliente pagante — CPF com dígito verificador inválido no onboarding foi rejeitado pela Asaas e
> engolido silenciosamente, deixando a conta sem `externalCustomerId`. Escopo: ressincronização
> manual pelo admin (TASK-201), validação de CPF/CNPJ front+back (TASK-202/203), alerta Sentry
> (TASK-204), indicador visual de pendência (TASK-205). Avaliado e descartado por ora: self-service
> do próprio usuário editar CPF/CNPJ depois do onboarding — caso raro (troca CPF→CNPJ pra nota
> fiscal), coberto pelo admin existente; complexidade de cancelar assinatura de cartão ativa na
> Asaas não justifica agora.
> Atualizado em: 25/08/2026 — **TASK-200 concluída** — [api#47](https://github.com/douglasjava/easy-maintenance-api/pull/47)
> e [web#52](https://github.com/douglasjava/easy-maintenance-web/pull/52) mergeadas em `main`.
> Atualizado em: 25/08/2026 — **TASK-200 criada**: campo de descrição livre (opcional, até 1000
> caracteres) no registro de manutenção — hoje não existe em lugar nenhum (nem entidade, nem
> request), e o registro fica só data+tipo+custo, sem dizer o que foi feito de verdade. Motivador:
> Douglas conseguiu um cliente pra validar em trial. Sem épico específico (nenhum candidato
> existente é o lugar certo). Full-stack, esforço baixo — ainda não implementada.
> Atualizado em: 24/08/2026 — **TASK-199 implementada e com PR aberta** — "Receita Total" em
> `/private/admin/billing` somava `plan.priceCents` (preço de tabela) em vez de `item.valueCents`
> (valor real cobrado); item `ORGANIZATION` está zerado desde a EPIC-014, então a receita das
> organizações aparecia inflada. Corrigido em `BillingAccountRepository`
> (`findPayersSummary`/`findTopPayers`), com `@DataJpaTest` novo provando o cenário contra H2 real.
> Commit `edd6d43`, PR [#44](https://github.com/douglasjava/easy-maintenance-api/pull/44) contra
> `staging` (branch `bugfix/TASK-199-receita-total-org-zerada`). Suíte completa: 798 testes, 0
> falhas.
> Atualizado em: 24/08/2026 — **EPIC-020 Fase 2: PRs abertas contra `staging`** —
> [easy-maintenance-api#43](https://github.com/douglasjava/easy-maintenance-api/pull/43) e
> [easy-maintenance-web#49](https://github.com/douglasjava/easy-maintenance-web/pull/49), reunindo
> TASK-190 a 198 mais os bugfixes achados no QA manual de Douglas (migration V95,
> `SimulationController` — PAYMENT_CREATED e `existingUserId`, `ConfirmModal` no lugar do
> `confirm()` nativo). Backend: 796 testes, 0 falhas. Frontend: `npm run build` limpo.
> Achado durante o mesmo QA, fora do escopo da EPIC-020: `/private/admin/billing` (Faturamento)
> mostra "Receita Total" inflada porque a query soma o preço de tabela do plano em vez do valor
> real cobrado no item — o item `ORGANIZATION` está zerado desde a EPIC-014, mas a query nunca
> olhava pro valor real do item. Registrado como **TASK-199** (nova, branch própria a partir de
> `staging` — Douglas vai atualizar `staging` com as PRs acima antes).
> Atualizado em: 24/08/2026 — **Simulador de QA: `existingUserId`** (a pedido de Douglas):
> `SimulationController` sempre criava um usuário sintético novo a cada chamada — sem jeito de
> gerar uma comissão de teste pra um usuário real já criado/atribuído via fluxo normal da
> aplicação. `SimulationRequest` ganhou `existingUserId` opcional: pula a captura de lead e
> reaproveita o usuário/`BillingAccount` existentes, sem sobrescrever o `referralCode` já salvo.
> Commit `582eb1f` (`feature/financial-module-v2`, `easy-maintenance-api`). Suíte completa: 796
> testes, 0 falhas.
> Atualizado em: 24/08/2026 — **Simulador de QA corrigido** (achado no roteiro de QA da revisão do
> EPIC-020): `SimulationController` disparava só `PAYMENT_RECEIVED`, sem passar pelo
> `PAYMENT_CREATED` que grava `netAmountCents`/`gatewayFeeCents` no fluxo real — a comissão
> simulada calculava sobre o bruto (fallback já documentado desde a TASK-192, não bug novo) e a
> tela de financeiro mostrava taxa Asaas zerada. Corrigido disparando os dois webhooks na ordem
> certa, reaproveitando `PaymentCreatedHandler` de verdade. Commit `28416b1`
> (`feature/financial-module-v2`, `easy-maintenance-api`). Suíte completa: 796 testes, 0 falhas.
> Atualizado em: 24/08/2026 — **Bug na migration V95 corrigido** (achado no teste local de
> Douglas): `DROP INDEX uk_referral_commissions_org` explícito falhava sempre — o `ALTER`
> anterior na mesma migration já derruba `organization_id` (única coluna daquela unique key) e o
> MySQL remove o índice sozinho junto. Não era drift de schema, quebrava em qualquer ambiente.
> Corrigido e verificado rodando a migration de ponta a ponta contra o MySQL local dele (commit
> `175906f`, `feature/financial-module-v2`, `easy-maintenance-api`). Suíte completa: 796 testes,
> 0 falhas.
> Atualizado em: 24/08/2026 — **TASK-198 implementada — Revisão da Fase 2 do EPIC-020 completa
> (4/4)**: tela de afiliados ganha seção "Comissionados" (não existia — a página só listava
> transações de comissão), com edição de %/recorrência e atribuição de cliente por busca de
> nome/e-mail; achado e corrigido no processo um contrato quebrado pela TASK-196
> (`c.organizationId` → `c.userId`, coluna "Org ID" ficou silenciosamente errada na branch).
> Tela de financeiro troca "Comissões manuais" pela seção "Comissões por pessoa" (endpoint da
> TASK-197). Commit `4a4ff78` em `feature/financial-module-v2` (`easy-maintenance-web`), `npm run
> build` limpo (52 rotas). **As 4 tasks da revisão (TASK-195 a 198) estão completas** — próximo
> passo é QA manual de ponta a ponta por Douglas (local/staging) e abertura do(s) PR(s) reunindo
> toda a Fase 2 (TASK-190 a 198) de uma vez.
> Atualizado em: 24/08/2026 — **TASK-197 implementada** (EPIC-020, revisão da Fase 2):
> `manualCommissionCents` removido de `MonthlyFinancialsResponse` e do cálculo de
> `monthlyBalanceCents` — `affiliateCommissionCents` (`ReferralCommission`) já cobre afiliado
> público e comissionado interno na mesma fonte desde TASK-195/196. Endpoint novo
> `GET /private/admin/financials/commissions-breakdown?month=YYYY-MM` agrega comissão por
> `affiliateId` dentro do mês (nome, e-mail, % atual, recorrência, valor total, contagem
> pendente/pago) — uma linha por comissionado mesmo quando `RECURRING` gerou várias comissões no
> período. Commit `b38b617` em `feature/financial-module-v2` (`easy-maintenance-api`), 796 testes,
> 0 falhas. Próxima: TASK-198 (frontend — edição de afiliado, atribuição a cliente, breakdown na
> tela de financeiro) — última da revisão da Fase 2.
> Atualizado em: 24/08/2026 — **TASK-196 implementada** (EPIC-020, revisão da Fase 2): rekey de
> `referral_commissions.organization_id` para `user_id` + `cycle_number` (migration `V95`);
> `PaymentReceivedHandler` passa a resolver o comissionado via item `USER` da assinatura +
> `User.referralCode` (não mais `Organization.referralCode`) e dispara em todo pagamento — a decisão
> `ONE_TIME` (único, idempotente por usuário) vs `RECURRING` (uma comissão por ciclo) fica inteira em
> `CommissionService`. Endpoint novo `PATCH /private/admin/users/{userId}/referral-code` pra
> atribuir/reatribuir comissionado a cliente existente. `SimulationController` (dev/QA) ajustado pra
> continuar exercitando o fluxo com o novo modelo. Commit `506e529` em `feature/financial-module-v2`
> (`easy-maintenance-api`), 792 testes, 0 falhas. Próxima: TASK-197 (`FinancialsService` sem comissão
> manual + endpoint de breakdown por comissionado).
> Atualizado em: 24/08/2026 — **TASK-195 implementada** (EPIC-020, revisão da Fase 2): `Affiliate`
> ganha `recurrenceType` (`ONE_TIME`/`RECURRING`) e `PATCH /private/admin/affiliates-commissions/{id}`
> pra editar percentual/recorrência; `manual_commission_rules` removida por completo (entidade,
> repositório, DTO, serviço, endpoints, migration `V94`). Ajuste mínimo em `FinancialsService` pra
> compilar sem a dependência removida (`manualCommissionCents` zerado, remoção definitiva do campo é
> escopo da TASK-196/197). Commit `02417bf` em `feature/financial-module-v2`
> (`easy-maintenance-api`), 786 testes, 0 falhas. Próxima: TASK-196 (rekey `organization_id` →
> `user_id`, comissão recorrente).
> Atualizado em: 24/08/2026 — **EPIC-020 Fase 2: revisão antes do PR** — testando a tela nova,
> Douglas identificou que `manual_commission_rules` (TASK-190/191) modela comissão errada (% da
> receita **total** da empresa, sem vínculo com cliente) quando o caso real é comissão **por cliente
> atribuído** a um comissionado. Análise de código confirmou que `Affiliate`/`ReferralCommission` já
> resolve exatamente isso (pessoa + %, vínculo com pagamento) — só faltava edição de % e um conceito
> de recorrência (`ONE_TIME`/`RECURRING`). Decisão: `manual_commission_rules` é removida, `Affiliate`
> é estendido em vez de manter duas estruturas paralelas. Achado à parte na mesma análise: desde a
> EPIC-014 (13/07/2026, cobrança só por `USER`), a atribuição de comissão em `referral_commissions`
> ficou semanticamente errada — travada em `organization_id`, quando quem paga é o `user_id`; nunca
> documentado até agora. 4 tasks novas: [TASK-195](tasks/TASK-195.md), [TASK-196](tasks/TASK-196.md),
> [TASK-197](tasks/TASK-197.md), [TASK-198](tasks/TASK-198.md). Spec:
> `docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`.
> Atualizado em: 23/08/2026 — **EPIC-020 Fase 2: 5/5 tasks implementadas** (TASK-190 a TASK-194),
> módulo financeiro completo (backend + frontend). Tudo na mesma branch `feature/financial-module-v2`
> (mesmo nome nos repos `easy-maintenance-api` e `easy-maintenance-web`), sem PR por task — Douglas
> testa tudo local e em staging junto, antes de abrir a(s) PR(s). Backend: schema
> (`expenses`/`manual_commission_rules`), CRUD de despesas e regras de comissão manual, e
> `FinancialsService` reescrito (bruto/líquido, saldo do mês/acumulado, comissão de afiliado sobre
> o líquido só pra vendas novas) — suíte completa, 0 falhas. Frontend: página própria
> `/private/admin/financials` (fora das abas de Faturamento, item novo no menu lateral) + seções de
> cadastro de despesa e comissão manual — `npm run build` limpo, mas não validado visualmente (tela
> exige login, sem credenciais de teste disponíveis pra automação).
> Atualizado em: 23/08/2026 — **EPIC-020 Fase 2 criada**: módulo financeiro migra de planilha
> externa pro sistema — página própria (sai das abas de Faturamento), receita bruta/líquida
> (`Payment.netAmountCents`, hoje ignorado no cálculo), despesa vira lançamento avulso (substitui
> `operating_expense_rates`, sem migrar histórico — decisão explícita de Douglas), comissão manual
> (regra recorrente de % sobre o líquido, nova) e comissão de afiliado passam a ser calculadas sobre
> o valor líquido (só daí pra frente, sem recalcular comissões já registradas), saldo do mês e saldo
> acumulado. 5 tasks novas (TASK-190 a TASK-194), reaproveitando o EPIC-020 (mesmo épico da primeira
> versão do painel financeiro). Brainstorm formal ("mais completo", a pedido de Douglas) + spec
> aprovada em `docs/superpowers/specs/2026-08-23-financial-module-design.md`.
> Atualizado em: 23/08/2026 — **EPIC-021 Fase 2: PR aberta para staging** — tudo validado
> localmente por Douglas, PR [#42](https://github.com/douglasjava/easy-maintenance-api/pull/42)
> (`easy-maintenance-api`) e PR [#48](https://github.com/douglasjava/easy-maintenance-web/pull/48)
> (`easy-maintenance-web`) abertas contra `staging`.
> Atualizado em: 23/08/2026 — **EPIC-021 Fase 2: 3/3 tasks implementadas** (TASK-187 a TASK-189),
> registro manual de lead + edição completa (telefone incluso). Tudo na mesma branch
> `feature/leads-manual-registration` (mesmo nome nos repos `easy-maintenance-api` e
> `easy-maintenance-web`), sem PR por task — Douglas testa tudo local e em staging junto, antes de
> abrir a(s) PR(s). Backend: 31 testes no módulo `leads`, 0 falhas (colunas `phone`/`origin_type` +
> backfill, `POST`/`PUT` de lead com validação de contato e normalização de telefone). Frontend:
> modal único de criar/editar, botão "+ Novo lead", colunas Telefone/Canal atualizadas — build
> limpo, mas não validado visualmente (tela exige login, sem credenciais de teste disponíveis pra
> automação).
> Atualizado em: 23/08/2026 — **EPIC-021 Fase 2 criada**: registro manual de lead + edição completa
> (nome/e-mail/telefone/fonte), 3 tasks novas (TASK-187 a TASK-189). Motivação: Douglas recebe leads
> de fontes fora do fluxo de ADS (indicação, evento, boca a boca) e não tinha onde registrá-los; e
> leads de clique de WhatsApp nunca guardaram telefone (a tela nem tinha esse campo), sem forma de
> editar um lead depois de criado — hoje só existe troca de status. Brainstorm formal + spec
> aprovada em `docs/superpowers/specs/2026-08-23-leads-screen-improvements-design.md`. Decisões:
> edição completa (não só telefone); fonte de lead manual por lista fixa (Indicação/Evento/Boca a
> boca/Outro), não texto livre, pra não poluir o relatório de Top Fontes; `origin_type` novo vira
> dado real gravado na criação, substituindo a inferência atual da coluna "Canal" (que só olhava se
> tinha e-mail); UI com modal único reaproveitado pra criar e editar. TASK-187 (schema) →
> TASK-188 (endpoints) → TASK-189 (frontend), nessa sequência.
> Atualizado em: 21/08/2026 — **EPIC-025: PRs de staging para main abertas** — PR
> [#41](https://github.com/douglasjava/easy-maintenance-api/pull/41) (`easy-maintenance-api`) e PR
> [#47](https://github.com/douglasjava/easy-maintenance-web/pull/47) (`easy-maintenance-web`),
> ambas `staging` → `main`, levam Fase 1 (TASK-177 a TASK-180) e Fase 2 (TASK-181 a TASK-186) do
> EPIC-025 pra produção. PRs [#40](https://github.com/douglasjava/easy-maintenance-api/pull/40)/
> [#46](https://github.com/douglasjava/easy-maintenance-web/pull/46) (`feature/...` → `staging`) já
> estavam mergeadas quando Douglas pediu pra abrir estas.
> Atualizado em: 21/08/2026 — **EPIC-025 Fase 2: PRs abertas para staging** — tudo validado
> localmente por Douglas (C1-C10 do plano de QA), PR [#40](https://github.com/douglasjava/easy-maintenance-api/pull/40)
> (`easy-maintenance-api`) e PR [#46](https://github.com/douglasjava/easy-maintenance-web/pull/46)
> (`easy-maintenance-web`) abertas contra staging. Backend: 779 testes, 0 falhas. Frontend: build
> limpo. C11 (tipo de empresa pré-preenchido), C12 (rolagem interna) e C13 (experiência mobile,
> TASK-186) seguem implementados mas ainda não revalidados por Douglas em staging.
> Atualizado em: 21/08/2026 — **EPIC-025 Fase 2: QA de Douglas achou 5 pontos** (edição de período
> travada por engano, `apply()` não idempotente, tipo de empresa não pré-preenchido, rolagem
> empurrando título/botões pra fora da tela, e tabela inviável no mobile) — todos corrigidos na
> mesma branch `feature/ai-onboarding-catalog-filter`. O último virou **TASK-186** (nova): lista de
> cards no lugar da tabela abaixo de 768px, mesmo estado/handlers da tabela. Backend: 779 testes, 0
> falhas. Frontend: build limpo, mas **TASK-186 não pôde ser validada visualmente** — a tela exige
> login e não há credenciais de teste disponíveis pra automação. Plano de QA atualizado com C11
> (tipo de empresa), C12 (rolagem interna) e C13 (mobile) —
> `roadmap/QA/tasks/TASK-QA-MAN-013.md`, aguardando Douglas revalidar.
> Atualizado em: 20/08/2026 — **EPIC-025 Fase 2: 5/5 tasks implementadas** (TASK-181 a TASK-185),
> filtro determinístico de catálogo no onboarding por IA. Tudo na mesma branch
> `feature/ai-onboarding-catalog-filter` (mesmo nome nos repos `easy-maintenance-api` e
> `easy-maintenance-web`), sem PR por task a pedido de Douglas — ele testa tudo local e em staging
> junto, antes de abrir a(s) PR(s). Backend: 775 testes, 0 falhas (norm_segments + filtro por
> segmento, endpoint síncrono `/catalog-preview`, IA como complemento sem duplicar catálogo, fix do
> bug de `nextDueAt` divergente). Frontend: `/ai-onboarding` reescrito em duas camadas — catálogo
> instantâneo sempre, IA só com descrição livre, mesclada progressivamente na tabela.
> Atualizado em: 20/08/2026 — **EPIC-025 Fase 2 criada**: filtro determinístico de catálogo no
> onboarding por IA (`/ai-onboarding`), 5 tasks novas (TASK-181 a TASK-185). Motivação: Douglas
> pediu pra validar se o fluxo de IA que sugere itens no onboarding precisa mesmo de IA pra tudo —
> resposta: não, boa parte já é filtro determinístico pelo catálogo curado por segmento
> (`company_type`), sem custo de IA. Brainstorm formal + spec aprovada em
> `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`. Achados: (1) IA hoje gera
> todo item do zero sem saber o que já existe curado — gasto de token à toa; (2) match de itemType
> por igualdade exata de string em `apply()` perde cobertura regulatória por divergência de nome;
> (3) **bug de dado real**: item REGULATORY nasce com `nextDueAt` calculado pelo período que a IA
> inventou, não pelo período real da norma vinculada — diverge do fluxo manual
> (`ServiceBase.resolvePeriod()`), afeta a primeira experiência de cliente novo. Nova tabela
> `norm_segments` (N-pra-N entre `norms` e `company_type`, reaproveitando os mesmos valores de
> `organizations.company_type`) alimentada pela classificação já feita na Fase 1 do EPIC-025. TASK-183
> (bugfix) é independente e priorizada primeiro; TASK-181→182→184→185 seguem em sequência.
> Atualizado em: 19/08/2026 — **EPIC-025: lista consolidada e quebrada em 4 tasks** prontas para
> implementar (TASK-177 a TASK-180). Antes de escrever as tasks, conferido o estado real das
> migrations do banco contra um select de produção fornecido por Douglas — corrigiu 2 suposições
> erradas do levantamento inicial (`ALARME_DE_INCENDIO` já cita NBR 17240 corretamente desde a V78;
> `AR_CONDICIONADO` nunca citou "NBR 11742", isso era de outro item) **e revelou que `TASK-088`
> (EPIC-004) já estava concluída** (`V71`/`V75` corrigiram `period_qty=0` e removeram norms
> `AI_GENERATED`), só não tinha sido movida de "Em Validação" pra "Concluído" — corrigido. TASK-177
> corrige/completa citações no catálogo (`AR_CONDICIONADO`, `CAIXA_DAGUA` + NR-33, rotas de fuga/
> hidrantes com base ABNT nacional além do IT estadual); TASK-178 cria item novo de catálogo para
> gás combustível (NBR 13103+15923, 12 meses); TASK-179 atualiza a página `/norms` (5 entradas
> novas + nota de revogação parcial da RDC 50); TASK-180 revisa o post do blog da NBR 5674
> (preditiva, Código Civil art. 937/938, reserva orçamentária).
> Atualizado em: 19/08/2026 — **EPIC-025 criado**: conteúdo e governança das normas técnicas
> (ABNT/NR/RDC). Auditoria norma-a-norma concluída (22 normas analisadas) em
> `docs/produto/levantamento-normas-abnt.md` (root repo). Decisões confirmadas com Douglas: produto
> não dá suporte a equipamento clínico/industrial (só predial) nos segmentos hospital e indústria;
> regionalização (Corpo de Bombeiros/vigilância sanitária por estado/município) é viável via
> endereço da organização, fica como direção futura; `TASK-088` permanece no EPIC-004 (é governança
> de schema, não de conteúdo).
> Atualizado em: 19/08/2026 — **EPIC-024 criado (desenhado via brainstorm), 2 tasks prontas para
> implementar**: agendamento de demonstração comercial via Cal.com, inspirado no `/agendar` do
> concorrente Easy Alert. Spec em `docs/superpowers/specs/2026-08-19-agendamento-demo-design.md`.
> Nova página `/agendar` (TASK-175) com o widget do Cal.com embutido (plano gratuito, calendário
> único — só Douglas atende por enquanto), webhook `BOOKING_CREATED` (TASK-176) cria lead
> reaproveitando o `LeadService` já existente (mesma tabela `landing_leads`, UTM/afiliado/
> consentimento LGPD propagados) — sem construir calendário/disponibilidade do zero. **Decisão
> importante confirmada com Douglas**: isso não substitui nem altera o formulário de e-mail e o
> botão "Solicitar Demonstração" já existentes — vira só um botão novo "Agendar demonstração" na
> navbar, opção paralela pra quem já quer marcar horário na hora (em vez de esperar contato
> manual).
> Atualizado em: 18/08/2026 — **EPIC-023 criado (desenhado via brainstorm), 3 tasks prontas para
> implementar**: fornecedores nas notificações de vencimento (e-mail e WhatsApp) — ideia do
> Douglas, fecha o ciclo "avisei que venceu" → "aqui está quem pode resolver" numa etapa só. Spec
> em `docs/superpowers/specs/2026-08-18-supplier-notifications-design.md`. Achado importante da
> pesquisa: a busca de fornecedores existente (`SupplierSearchService`) é 100% interativa, depende
> de geolocalização do navegador — não existe fornecedor salvo em banco nem coordenada de
> organização, então o job de notificação (que roda à noite, sem navegador) precisa de uma peça
> nova (`SupplierLookupService`, TASK-172) que busca por texto (cidade/estado) em vez de
> coordenada. **Decisões de escopo**: cache de 7 dias, só busca nos eventos que já disparam
> WhatsApp/E-mail hoje (não no PUSH in-app), e-mail sem restrição (bloco HTML novo, TASK-173) vs.
> WhatsApp que precisa de um template HSM **novo** (`vencimento_manutencao_v3`, TASK-174) porque o
> `v2` atual já está aprovado pela Meta e não pode ser editado — mesma dependência externa (e
> mesmo risco de demora) que já atrasou o `v2` no EPIC-015; se a busca achar menos de 2
> fornecedores, o envio por WhatsApp desse evento específico é pulado (mesmo fallback já existente
> hoje). Confirmado com Douglas: WhatsApp já está aprovado e funcionando em produção desde o
> EPIC-015 (dúvida que motivou a primeira pergunta do brainstorm).
> Atualizado em: 18/08/2026 — **TASK-171 criada e implementada** (EPIC-022, follow-up da TASK-170):
> resolve os 2 achados do QA manual do Douglas (link do `/blog` ausente na landing, layout "ruim")
> e escreve os posts 2-5 já aprovados na spec (manutenção preventiva x corretiva, checklist de
> manutenção predial, planilha de manutenção falha, CMMS Brasil) — blog fecha com 5 posts. Índice
> redesenhado usando o blog do concorrente [Easy Alert](https://easyalert.com.br/blog/) como
> referência visual (pedido do Douglas): hero no topo, categoria como texto discreto acima do
> título (não mais um bloco gráfico), tempo de leitura calculado automaticamente por contagem de
> palavras (`src/lib/blogReadingTime.ts`), filtro de categoria clicável, capa do card usando print
> real do produto (`dashboard_preview.webp`) em vez do tratamento abstrato de cor da primeira
> versão — sem foto de banco de imagem disponível. **Achado colateral corrigido**: `.claude/worktrees/`
> não estava no `.gitignore`, quase causando commit acidental de um worktree órfão inteiro (com
> `node_modules`) via `git add -A`; adicionado ao `.gitignore` e a pasta órfã removida. TASK-170
> marcada como QA concluído. Branch `feature/blog-content-mdx` ainda não mergeada em `staging`.
> Atualizado em: 17/08/2026 — **EPIC-022 criado, TASK-170 implementada e em validação**: Blog de
> Conteúdo (SEO) — motivado por concorrente direto (Condo Guardian) com blog SEO ativo nas mesmas
> keywords do nosso plano de SEO. Infra via `@next/mdx` (sem CMS, sem rota dinâmica — cada post é
> uma pasta própria), `BlogPostShell` reaproveitando padrão de `/termos`, primeiro post real
> publicado ("NBR 5674 na prática"), `robots.txt`/`sitemap.ts` atualizados. Desenhado via brainstorm
> — spec em `docs/superpowers/specs/2026-08-17-blog-content-design.md`, plano em
> `docs/superpowers/plans/2026-08-17-blog-content.md`, executado via subagent-driven-development (5
> tasks + 1 fix de revisão final). **Achado crítico corrigido na revisão final**: `/blog` não estava
> no allowlist público do `Shell.tsx` — sem o fix, visitante anônimo era redirecionado pro `/login`
> e o conteúdo nunca renderizava, nulificando a feature inteira; nenhuma task do plano tocava esse
> arquivo, só apareceu na revisão de branch inteira. Corrigido (commit `d1d5982`). Branch
> `feature/blog-content-mdx` em `easy-maintenance-web`, com push de segurança em
> `origin/feature/blog-content-mdx`, ainda não mergeada em `staging`. **QA manual de Douglas em
> andamento**: 2 achados abertos, sem bloquear a funcionalidade — link do `/blog` ausente na landing
> page (página só descoberta via sitemap hoje) e layout dos posts precisa de refinamento visual
> (hoje usa só Bootstrap padrão, sem CSS dedicado pro conteúdo longo). Posts 2-5 (temas já aprovados
> na spec) ainda não escritos — só o primeiro post existe até agora.
> Atualizado em: 11/08/2026 — **TASK-169 criada e implementada** (🔴 Crítico, BUGFIX, achado por
> Douglas em uso real): cadastrar um 2º custo "Outros" (GoDaddy) além de um já existente (Vercel)
> quebrava com "vigência deve ser posterior...". Causa raiz mais séria que o erro em si: a
> validação e o cálculo do total financeiro tratavam a categoria OUTROS inteira como 1 linha,
> ignorando o `label` — `resolveAmountCents` só considerava o item mais recente, **o total
> financeiro já estava incorreto antes desta correção** (ignorava silenciosamente os demais
> "Outros" cadastrados). Confirmado com Douglas via pergunta: intenção é multi-item, cada label soma
> no total. Fix: identidade de vigência passa a ser `(category, label)`. 9 testes novos/ajustados,
> suíte sem regressão. Frontend não precisou de mudança (já renderiza lista genérica).
> Atualizado em: 11/08/2026 — **TASK-168 criada e implementada** (BUGFIX, achado por Douglas em
> revisão manual da landing, fora de qualquer épico): botão "Ver todos os recursos" era um
> `<button>` sem `onClick`/`href` — trocado por `<a href="#solucao">`, mesmo padrão de âncora
> interna já usado no resto da página. `npm run build` limpo. Achado colateral fora de escopo: todo
> link de âncora da landing (inclusive o "Solução" do menu, pré-existente) rola a página ~800px
> além do topo da seção alvo — comportamento uniforme da página inteira (CSS `scroll-behavior:
> smooth` global), não introduzido por este fix.
> Atualizado em: 11/08/2026 — **PRs do EPIC-021 abertas pra `staging`**: backend
> [#32](https://github.com/douglasjava/easy-maintenance-api/pull/32), frontend
> [#35](https://github.com/douglasjava/easy-maintenance-web/pull/35). Falta QA manual com dado real
> por Douglas antes do merge.
> Atualizado em: 11/08/2026 — **TASK-167 implementada** (EPIC-021), última task do épico: seção de
> lista de leads (filtros status/fonte/campanha/período + tabela paginada + troca de status inline
> via `PATCH .../status`, otimista com rollback). **EPIC-021 com implementação completa** —
> `npm run build` limpo, falta QA manual com dado real (mesmo bloqueio de secrets locais das
> TASK-161/162/166) e abrir os PRs `feature/EPIC-021-leads-dashboard` → `staging` nos dois repos.
> Achado corrigido durante a implementação: bug de closure obsoleta no botão "Limpar" (buscava com
> filtro antigo por causa do `setState` assíncrono) — resolvido separando rascunho dos inputs do
> filtro de fato aplicado.
> Atualizado em: 11/08/2026 — **TASK-166 implementada** (EPIC-021): rota `/private/admin/leads` —
> gráfico Recharts empilhado (12 meses × 4 status) + tabelas de top fontes/referrers, consumindo o
> endpoint da TASK-164. Item "Leads" adicionado ao menu admin. `npm run build` limpo. QA manual com
> dado real pendente — mesmo bloqueio de secrets locais já registrado nas TASK-161/162 (falta
> `OPENAI_API_KEY`/`DEEPSEEK_API_KEY`/Postgres pra subir o backend local). Próxima: TASK-167
> (lista individual + filtros + troca de status inline), depende desta e da TASK-165.
> Atualizado em: 11/08/2026 — **TASK-165 implementada** (EPIC-021): `GET /admin/leads` (lista
> paginada/filtrável por status, source, campaign exato e período) + `PATCH
> /admin/leads/{id}/status` (troca de status, 404 se id inexistente). `LandingLeadRepository`
> passou a implementar `JpaSpecificationExecutor`, mesmo padrão de `Specification` já usado em
> `PaymentRepository`. 9 testes novos (6 num `@DataJpaTest` isolado provando os filtros contra H2
> real — Mockito só provaria que o método foi chamado, não que o filtro funciona —, 3 Mockito pro
> service), suíte sem regressão. Próxima: TASK-166 (frontend, depende da TASK-164) e depois
> TASK-167 (frontend, depende desta task e da TASK-166).
> Atualizado em: 11/08/2026 — **TASK-164 implementada** (EPIC-021): endpoint
> `GET /admin/leads/summary` — contagem mensal por status + top 10 fontes/referrers. Mesmo
> raciocínio de agregação em Java do EPIC-020. 6 testes novos, suíte sem regressão. TASK-165 pode
> seguir em paralelo (só depende da TASK-163, já pronta).
> Atualizado em: 11/08/2026 — **TASK-163 implementada** (EPIC-021): `LandingLead.status` convertido
> de `String` livre pra enum `LeadStatus` (NEW/CONTACTED/CONVERTED/LOST). Sem migração de schema
> (coluna já `VARCHAR(20)`, cabe todos os valores). Achado: `SimulationController` (dev-only)
> também usava o literal `"NEW"`, corrigido junto. 2 testes novos, suíte sem regressão. Próxima:
> TASK-164 e TASK-165 (endpoints, podem andar em paralelo).
> Atualizado em: 11/08/2026 — **EPIC-021 criado e pronto para implementar**: Painel de Leads —
> visão agregada (gráfico mensal empilhado por status + top fontes/referrers) e mini-CRM básico
> (lista filtrável + troca de status inline). Desenhado via brainstorm — spec em
> `docs/superpowers/specs/2026-08-11-painel-leads-design.md`. 5 tasks criadas (TASK-163 a 167):
> converter `status` pra enum → endpoint agregado + endpoint de lista/troca de status (paralelos)
> → item de menu/visão agregada → lista individual. Item novo "Leads" no menu admin, mesmo nível
> de Faturamento/Afiliados. Fora de escopo: filtro por `medium`, automação por mudança de status,
> exportação CSV.
> Atualizado em: 11/08/2026 — **EPIC-020: PRs mergeadas em `staging`**
> ([easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31),
> [easy-maintenance-web#34](https://github.com/douglasjava/easy-maintenance-web/pull/34)). Diffs
> limpos em ambos, só os commits do épico. Falta abrir a promoção `staging` → `main`.
> Atualizado em: 11/08/2026 — **EPIC-020 concluído — QA manual aprovado por Douglas.**
> Painel financeiro admin (receita recebida vs. custo de infraestrutura + comissão de afiliado,
> grid de totalizadores, gráfico Recharts, cadastro de custo com rótulo pra "Outros") validado de
> ponta a ponta com dado real (fora de `staging` — as PRs abaixo ainda não foram mergeadas lá).
> Falta mergear pra `staging`
> ([easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31),
> [easy-maintenance-web#34](https://github.com/douglasjava/easy-maintenance-web/pull/34)) e depois
> abrir a promoção `staging` → `main`, mesmo fluxo do resto do projeto.
> Atualizado em: 11/08/2026 — **EPIC-020: ajuste pós-teste manual do Douglas** — categoria "Outros"
> do cadastro de custo de infraestrutura ganhou campo de rótulo (obrigatório só nessa categoria),
> pra não virar caixa preta com o tempo. Commits já empurrados pras PRs #31 (api) e #34 (web) que
> já estavam abertas — não precisou de PR nova. Suítes sem regressão. Ainda pendente: QA manual de
> ponta a ponta em `staging`.
> Atualizado em: 11/08/2026 — **EPIC-020: PRs abertas para `staging`**
> ([easy-maintenance-api#31](https://github.com/douglasjava/easy-maintenance-api/pull/31),
> [easy-maintenance-web#34](https://github.com/douglasjava/easy-maintenance-web/pull/34)). O PR do
> frontend depende do backend já estar em `staging` pra funcionar de ponta a ponta — mergear a
> api primeiro. **Falta QA manual do Douglas antes do merge** — não foi validado clicando na tela
> nesta sessão.
> Atualizado em: 11/08/2026 — **EPIC-020 completo (TASK-159 a 162)**: painel financeiro admin —
> receita recebida vs. custo de infraestrutura + comissão de afiliado, grid de totalizadores +
> gráfico Recharts, cadastro de custo por categoria. Ambos os repos, branches
> `feature/EPIC-020-financial-dashboard` a partir de `staging`. Suítes sem regressão em cada
> commit. **Falta QA manual de ponta a ponta** — não foi possível rodar o backend local nesta
> sessão (faltam chaves de IA — DeepSeek/OpenAI — no ambiente); Douglas precisa clicar na tela de
> verdade em `staging` antes de considerar isso pronto. Falta também abrir as PRs (feature→staging)
> em ambos os repos.
> Atualizado em: 10/08/2026 — **TASK-161 implementada** (EPIC-020): página
> `/private/admin/billing/financeiro` com grid de totalizadores + gráfico Recharts (primeira lib
> de gráfico do projeto). `npm run build` limpo. **QA manual de ponta a ponta pendente** — não deu
> pra rodar o backend local nesta sessão (faltam chaves de IA no ambiente). Próxima: TASK-162
> (cadastro de custo de infraestrutura na mesma página).
> Atualizado em: 10/08/2026 — **TASK-160 implementada** (EPIC-020): endpoint
> `GET /admin/billing/financials` — receita/custo/comissão/lucro por mês, últimos 12 (clamp 1-24).
> 5 testes novos, suíte completa sem regressão. Backend do EPIC-020 completo (TASK-159 + 160).
> Próxima: TASK-161 (frontend — página + gráfico Recharts).
> Atualizado em: 10/08/2026 — **TASK-159 implementada** (EPIC-020): tabela
> `operating_expense_rates` + CRUD de custo de infraestrutura, em `feature/EPIC-020-financial-
> dashboard` (branch a partir de `staging`). 7 testes novos, suíte completa sem regressão. Próxima:
> TASK-160 (endpoint agregado de financeiro por mês).
> Atualizado em: 10/08/2026 — **EPIC-020 criado e pronto para implementar**: Painel Financeiro
> Admin (receita recebida vs. custo de infraestrutura + comissão de afiliado, gráfico mensal
> Recharts, grid de totalizadores do mês atual). Desenhado via brainstorm com Douglas — spec em
> `docs/superpowers/specs/2026-08-10-painel-financeiro-admin-design.md`. 4 tasks criadas
> (TASK-159 a 162), ordem: modelo de custo → endpoint agregado → página/gráfico → cadastro de
> custo. Sem permissão nova (admin único). Fora de escopo: despesas gerais do negócio, forecast.
> Atualizado em: 31/07/2026 — **🔴 URGENTE: PR staging → main aberta pro Meta Pixel**
> ([easy-maintenance-web#33](https://github.com/douglasjava/easy-maintenance-web/pull/33)). Falta
> merge final de Douglas em `main` **e** configurar `NEXT_PUBLIC_META_PIXEL_ID` no Railway — sem
> isso o pixel não ativa em produção mesmo com o código mergeado.
> Atualizado em: 31/07/2026 — **🔴 URGENTE: Meta Pixel real instalado (TASK-156)** — Douglas
> iniciou a 1ª campanha do Meta Ads hoje e passou o Pixel ID
> (`2228895387905537`) durante a campanha já no ar (sem o pixel, zero sinal de conversão chegava
> ao Meta — sem otimização de entrega, sem retargeting). Instalado, validado em produção local
> (requisições reais a `www.facebook.com/tr` confirmadas via inspeção de rede).
> [PR #32](https://github.com/douglasjava/easy-maintenance-web/pull/32) aberto para `staging`.
> **Ação pendente de Douglas**: configurar `NEXT_PUBLIC_META_PIXEL_ID` no Railway (produção e
> staging) — sem isso o pixel não funciona fora do ambiente local, mesmo com o PR mergeado.
> Google Tag (Google Ads) continua sem ID fornecido.
> Atualizado em: 31/07/2026 — **EPIC-019 desenhada (Em Análise, não priorizada)**: Product
> Analytics — motor de eventos próprio (event-driven), pra reduzir dependência de GA4/Clarity nos
> casos de uso internos. Stack proposta: MongoDB (novo datastore, poliglota deliberado) +
> ingestão síncrona no MVP (RabbitMQ fica pra fase 2, quando o volume justificar). Reaproveita
> diretamente a infra do EPIC-018 (`utm.ts`, cookie `em_ref`, stubs de `tracking.ts`, checkbox de
> consentimento LGPD). Documento completo (modelo de eventos, payload, desenho de banco, backlog
> de tasks BE/FE/dashboard, roadmap futuro) em `roadmap/epics/EPIC-019.md`. Sem tasks
> individuais criadas ainda — só acontece quando for priorizada/sequenciada com Douglas.
> Atualizado em: 31/07/2026 — **TASK-158 aprovada e mergeada em `staging`** (PR #30). PR de
> promoção `staging` → `main` aberta:
> [easy-maintenance-web#31](https://github.com/douglasjava/easy-maintenance-web/pull/31). Falta
> merge final de Douglas em `main` e a revisão jurídica do conteúdo (ver riscos do TASK-158).
> Atualizado em: 31/07/2026 — **TASK-158 criada e implementada**: página pública `/termos`,
> resolvendo o link "Termos de Uso" quebrado desde antes do TASK-151 (flagado como fora de escopo
> no TASK-151 e no EPIC-018 por falta de conteúdo jurídico). Douglas confirmou os dados: entidade
> legal BRAINBYTE CONSULTORIA TI LTDA (CNPJ 50.047.256/0001-22), sem política de reembolso, trial
> de 14 dias (já confirmado via TASK-087). [PR #30](https://github.com/douglasjava/easy-maintenance-web/pull/30)
> aberto para `staging`. **Rascunho, não substitui revisão jurídica** — recomendado revisão de
> advogado antes do primeiro cliente pagante real.
> Atualizado em: 30/07/2026 — **EPIC-018: PRs para `staging` aprovadas e mergeadas** (api#29,
> web#28) — **PRs de promoção `staging` → `main` abertas**:
> [easy-maintenance-api#30](https://github.com/douglasjava/easy-maintenance-api/pull/30) e
> [easy-maintenance-web#29](https://github.com/douglasjava/easy-maintenance-web/pull/29). Falta
> merge final de Douglas em `main` e os IDs de Meta Pixel/Google Tag para fechar TASK-156 de fato.
> Atualizado em: 30/07/2026 — **EPIC-018: PRs abertos para `staging`.**
> [easy-maintenance-api#29](https://github.com/douglasjava/easy-maintenance-api/pull/29) (TASK-152)
> e [easy-maintenance-web#28](https://github.com/douglasjava/easy-maintenance-web/pull/28)
> (TASK-153 a 156 + melhorias de conversão da landing: badges de segmento no Hero, reordenação da
> seção "Para quem", reescrita de 3 dos 5 cards de Diferenciais, selo LGPD/ABNT, CTA sticky mobile,
> compressão de imagem, correções de acessibilidade Lighthouse 88→100, remoção da alegação "centenas
> de gestores" sem cliente real). Falta revisão/merge de Douglas e os IDs de Meta Pixel/Google Tag
> para fechar TASK-156 de fato.
> Atualizado em: 30/07/2026 — **EPIC-018: TASK-152 a 156 implementadas e movidas para Em
> Validação** (Douglas pediu para retomar o épico; estavam commitadas em
> `feature/EPIC-018-conversion-tracking` em ambos os repos, mas os docs de roadmap ainda diziam
> "Pronto para Implementar" — TASK-154 estava com a mudança só staged, sem commit; foi commitada
> nesta sessão). Validação: suíte backend completa (719+ testes) verde, `npm run build` do
> frontend limpo, e QA manual em browser real (Playwright) do fluxo /landing→/obrigado. **Achado
> de QA corrigido**: o link de WhatsApp em `/obrigado` nunca incluía o contexto de campanha (UTM)
> por um mismatch de hidratação — `buildWhatsAppLink()` lia o cookie durante o render de uma
> página estaticamente pré-renderizada, e o React não corrige esse tipo de mismatch depois da
> hidratação inicial. Corrigido movendo a leitura do cookie para dentro de um `useEffect`
> (commit `f03dfe4`). Falta: QA manual formal, PR para `staging` em ambos os repos, e os IDs de
> Meta Pixel/Google Tag (Douglas) para fechar TASK-156 de fato.
> Atualizado em: 30/07/2026 — **EPIC-018 criado** (Douglas): tracking de conversão para Meta
> Ads/Google Ads — captura/persistência de UTM, checkbox de consentimento LGPD no form de
> demonstração, nova página `/obrigado` (com correção da whitelist `isAuth` do `Shell.tsx`, mesma
> classe de bug do TASK-151) e scaffolding de eventos Lead/Contact. TASK-152 a 156 prontas para
> implementar; TASK-157 (Conversions API/Enhanced Conversions server-side) fica no backlog,
> bloqueada por credenciais que Douglas ainda vai levantar. Nenhum Meta Pixel/Google Tag instalado
> hoje — IDs pendentes de Douglas, não inventados.
> Atualizado em: 28/07/2026 — **EPIC-017 concluído e aprovado no QA manual.** TASK-QA-MAN-012
> (5 cenários) validada por Douglas, incorporando 2 achados no processo: TASK-149 (seletor de
> organização inline na Prestação de Contas, sem sair da tela — exigiu ajustar o interceptor do
> `apiClient` pra respeitar `X-Org-Id` explícito por chamada) e TASK-150 (ocultar o menu
> "Relatórios" por completo quando o plano não inclui a funcionalidade, em vez de só bloquear o
> botão dentro da tela — C3 corrigido pra refletir isso). Suíte backend final: 719/719 verde.
> Todas as 6 tasks técnicas + QA manual commitadas, PR aberto para `staging` em ambos os repos.
> Atualizado em: 28/07/2026 — **TASK-150 criada e implementada** (achado no QA manual, C3 da
> TASK-QA-MAN-012, Douglas): o gate `reportsEnabled` bloqueava só o botão dentro da tela
> `/reports` — decisão mais coerente foi esconder o item "Relatórios" do menu inteiro (Sidebar e
> dropdown do `UserTopBar`) quando o plano da organização ativa não inclui relatórios, mesmo
> padrão já usado ali pra `canManageBilling`. Sem guard de rota (redirecionamento se acessar
> `/reports` direto pela URL) — deliberadamente fora do escopo, já que isso bloquearia também as
> abas Visão Geral/Manutenções, que hoje funcionam pra qualquer plano. `npm run build` limpo,
> 86/89 frontend.
> Atualizado em: 28/07/2026 — **TASK-149 criada e implementada** (achado pós-TASK-146, Douglas):
> seletor de organização na aba "Prestação de Contas" — antes, gerar o relatório de outra empresa
> exigia trocar no seletor global e sair da tela. Só aparece quando o usuário tem acesso a mais de
> uma organização. Achado técnico: o interceptor do `apiClient` sobrescrevia incondicionalmente
> `X-Org-Id` com a organização ativa globalmente; ajustado pra só aplicar esse valor quando a
> chamada não já especifica o header — mudança aditiva, retrocompatível, usada só pelas 3 chamadas
> deste relatório (passam `X-Org-Id` explícito da organização escolhida no seletor local, sem
> tocar no contexto global do resto do app). `npm run build` limpo, 86/89 frontend.
> Atualizado em: 27/07/2026 — **TASK-148 implementada, EPIC-017 com todas as 4 tasks técnicas em
> Em Validação** (falta só a TASK-QA-MAN-012, o QA manual). TASK-148 (frontend): tela do Relatório
> Analítico em `/reports` atualizada pra refletir Excel em vez de CSV (rótulo, `title`, tipo do
> blob e extensão do arquivo baixado) — mudança isolada, ícone `Download` mantido por já ser
> genérico o suficiente. `npm run build` limpo, 86/89 frontend (3 falhas pré-existentes).
> Atualizado em: 27/07/2026 — TASK-147 implementada e movida para Em Validação
> (`feature/EPIC-017-reports-accountability-analytics` em `easy-maintenance-api`): export cross-org
> do Relatório Analítico trocado de CSV puro pra `.xlsx` real (Apache POI `poi-ooxml`), com 2 colunas
> novas ("Status do item" via `StatusCalculator`, "Qtd. de evidências anexadas" via
> `findByMaintenanceIdIn` da TASK-142, sem N+1) e tipos nativos de data/moeda (não texto formatado).
> Métodos renomeados (`exportCsvCrossOrg`→`exportExcelCrossOrg`) — nome antigo seria enganoso pra um
> retorno `.xlsx`. Export single-org (usado por `/maintenances/export` fora do `/me/reports`)
> continua CSV, fora do escopo. Testes existentes reescritos pra ler o workbook via POI em vez de
> comparar string crua. 719/719 backend green.
> Atualizado em: 27/07/2026 — TASK-146 implementada e movida para Em Validação
> (`feature/EPIC-017-reports-accountability-analytics` em `easy-maintenance-web`): nova aba
> "Prestação de Contas" em `/reports`, PDF gerado client-side via `@react-pdf/renderer` (RN-017-05),
> 4 seções (resumo/KPIs, manutenções realizadas, canceladas/auditoria via TASK-145, itens
> pendentes/vencidos). **Achado que mudou o escopo original**: sem seletor de organização nesta
> tela — todo endpoint org-scoped depende do `X-Org-Id` global (seletor de organização já existente
> no app), então um dropdown local criaria duas noções conflitantes de "organização atual"; o
> relatório é sempre da organização ativa, trocar de organização usa o seletor global de sempre.
> KPIs calculados no frontend a partir de 3 chamadas já existentes, sem endpoint agregador novo.
> `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes).
> Atualizado em: 27/07/2026 — TASK-145 implementada e movida para Em Validação
> (`feature/EPIC-017-reports-accountability-analytics` em `easy-maintenance-api`, a partir de
> `staging` já com EPIC-016 mergeado): estendeu `GET /items/maintenances/cancelled` (em vez de criar
> endpoint novo) — `itemId` agora opcional, `performedAtFrom`/`performedAtTo` buscam canceladas de
> toda a organização no período (query nativa com `JOIN maintenance_items`, filtro de organização
> embutido, mesmo cuidado multi-tenant da TASK-137/139). Refatorado `enrichCancelled()` compartilhado
> entre `findCancelledByItem` e o novo `findCancelledByOrganization`, evitando duplicar a resolução
> em lote de nome de quem cancelou + anexos/autores (TASK-141/142). Teste extra com H2 real provando
> isolamento por organização de verdade (join correto), não só que os parâmetros certos foram
> passados. 718/718 backend green.
> Atualizado em: 27/07/2026 — **EPIC-017 desenhado**: Relatórios — Prestação de Contas (PDF) e
> Analítico (Excel). Hoje `/me/reports` só tem um relatório básico (KPIs cross-org + tabela + CSV),
> que não serve pra "mostrar pra alguém de fora o que foi feito". Dois relatórios com propósitos
> diferentes: (1) **Prestação de Contas** — PDF de UMA organização por vez (nunca cross-org), 4
> seções (resumo do período, manutenções realizadas, canceladas/auditoria — usa o histórico do
> EPIC-016 —, itens pendentes/vencidos), gerado **client-side** via `@react-pdf/renderer` (decisão
> consciente pra v1: sem endpoint de PDF no backend; migra pra lá só se precisar de automação
> futura); (2) **Analítico** — evolução do export cross-org existente, de CSV pra `.xlsx` real
> (Apache POI), com 2 colunas novas (status do item, qtd. de evidências), dado cru sem abas de
> totais agregados (decisão deliberada: cálculo é trabalho do usuário no Excel dele). Decisão de
> escopo importante: nada de "níveis de relatório" (auditor/controle interno/etc.) por enquanto — um
> relatório configurável por filtros, não vários templates fixos. Gap real identificado: canceladas
> hoje só são consultáveis por item (TASK-139) — falta uma consulta por organização+período
> (TASK-145), pré-requisito do PDF. 5 tasks técnicas (TASK-145 a 148) + QA manual (TASK-QA-MAN-012)
> criadas em Backlog.
> Atualizado em: 27/07/2026 — **EPIC-016 concluído e aprovado no QA manual.** TASK-QA-MAN-011 (8
> cenários) validada por Douglas, achando e corrigindo 3 bugs reais no processo: (1) `cancel()`
> não persistia `cancelledAt`/`cancelledBy`/`cancelReason` — `save()`+`delete()` na mesma transação
> faz o Hibernate descartar o UPDATE de dirty-checking; corrigido com `saveAndFlush()`; (2)
> constraint UNIQUE `uq_maint_item_date` (V24) não considerava `deleted_at`, bloqueando reaproveitar
> o dia após cancelar; corrigido com migration V85 + coluna `active_dedup_key`; (3) `register()`
> conferia duplicidade contra `LocalDate.now()` em vez de `req.performedAt()` — bug pré-existente,
> só exposto porque C2 foi o primeiro cenário a registrar com data diferente de hoje. Além disso,
> **TASK-144** nova: "Histórico de manutenções" (abas Ativas/Canceladas) movido pra página de
> detalhe do item — o card equivalente da TASK-141 foi removido de `/maintenances` (achado de UX
> do próprio QA). C5 também expôs que o roteiro de QA descrevia um parâmetro `includeCancelled`
> que nunca existiu — a TASK-139 tinha escolhido um endpoint dedicado (`/maintenances/cancelled`);
> roteiro corrigido. Suíte backend final: 713/713 verde. Todas as 9 tasks técnicas + QA manual
> commitadas, PR aberto para `staging` em ambos os repos.
> Atualizado em: 26/07/2026 — **TASK-142 e TASK-143 implementadas, EPIC-016 com todas as 8 tasks
> técnicas em Em Validação** (falta só a TASK-QA-MAN-011, o QA manual). TASK-142 (backend): anexo
> ganha `uploadedByName` resolvido em lote — e, ao estender pra `findCancelledByItem` (que lista N
> manutenções de uma vez), a implementação foi refeita pra buscar os anexos de **todas** as
> manutenções canceladas do item numa única query (`findByMaintenanceIdIn`, novo), não uma por
> manutenção — evitando reintroduzir N+1 nesse fluxo. TASK-143 (frontend): botão "+ Adicionar anexo"
> no detalhe da manutenção, reaproveitando o mesmo fluxo de upload via S3 (presigned URL) já usado
> na tela de criação; permissão usa `canRegisterMaintenance` (não o `userRole` da TASK-140), porque o
> backend não restringe upload de anexo por papel, diferente do cancelamento. Cada anexo agora mostra
> "Anexado por {nome} em {data}". 707/707 backend green; `npm run build` limpo no frontend.
> Atualizado em: 26/07/2026 — TASK-141 implementada e movida para Em Validação (mesma branch,
> `easy-maintenance-web`): toggle "Mostrar canceladas" na tela de manutenções (só com item
> selecionado), card expansível (`CancelledMaintenanceRow`) com badge sempre visível e
> motivo/autor/data ao expandir. **Achado antes de implementar**: o card já assumia "quem cancelou"
> como nome resolvido, mas a TASK-139 só expunha o ID cru — corrigido retroativamente na própria
> TASK-139 (novo `cancelledByName`, resolução em lote via `UserRepository`, mesmo padrão de
> `MaintenanceExportService.resolveUserNames` da TASK-104). **Decisão de design**: não reaproveitou
> o modal de detalhe existente pra canceladas — ele busca por `GET /items/maintenances/{id}`, que
> `@SQLRestriction` sempre esconde (404); o card inline usa os dados já completos do endpoint de
> canceladas da TASK-139, sem chamada extra. `npm run build` limpo, 703/703 backend green.
> Atualizado em: 26/07/2026 — TASK-140 implementada e movida para Em Validação
> (`feature/EPIC-016-cancel-maintenance-reason` em `easy-maintenance-web`): botão "Cancelar
> manutenção" no detalhe da manutenção, visível só pra ADMIN/SYNDIC (checagem de `userRole` salvo no
> login, mesmo padrão de `/users`/`UserTopBar` — deliberadamente não reaproveitou a flag
> `permissions.canRegisterMaintenance` já usada nesta página, porque um TECH pode registrar
> manutenção mas não deveria poder cancelar). Novo `CancelMaintenanceModal` com motivo obrigatório
> (mín. 5 caracteres) e invalidação de queries (`maintenances`/`items`/`item`) pós-cancelamento.
> **Achado**: o 422 real do `@Valid @RequestBody` inválido não bate com o 400 documentado na
> TASK-137 — corrigido no doc. `npm run build` limpo, 86/89 testes (3 falhas pré-existentes,
> `middleware.test.ts`). **Sem clique-a-clique real no navegador** — página protegida por auth e API
> local ainda bloqueada pelo gap de `bootstrap.admin.token`; validação visual completa fica pro
> cenário C7 da TASK-QA-MAN-011.
> Atualizado em: 26/07/2026 — TASK-139 implementada e movida para Em Validação (mesma branch,
> `feature/EPIC-016-cancel-maintenance-reason`): novo endpoint `GET
> /items/maintenances/cancelled?itemId=X` (query nativa, contornando `@SQLRestriction` de propósito)
> pra consultar canceladas separadas das válidas, com motivo/autor/data. **Achado de segurança real
> fora do escopo original**: `findForExport`, `findForExportCrossOrg` (export CSV) e
> `avgDaysToResolveLast90` (KPI do dashboard) são queries nativas que `@SQLRestriction` não filtra —
> nenhuma tinha `deleted_at IS NULL` no WHERE. Antes da TASK-137 isso não importava (nunca existia
> cancelamento); a partir de agora, sem a correção, o export e o KPI de dias-pra-resolver vazariam
> manutenções canceladas de verdade. Corrigido nas três. Sem cobertura automatizada possível (sem
> `@DataJpaTest` no repo) — validação fica pro cenário C5 da TASK-QA-MAN-011. 4 testes novos,
> 702/702 backend green.
> Atualizado em: 26/07/2026 — TASK-138 implementada e movida para Em Validação (mesma branch da
> TASK-137, dependência direta): item recalcula `nextDueAt`/`lastPerformedAt`/`status` a partir da
> manutenção válida mais recente por `performedAt` após um cancelamento — não da "próxima
> cadastrada" (RN-016-03), coberto explicitamente pelo cenário M1/M2/M3 fora de ordem. Sem
> manutenção válida remanescente, reverte pra "sem manutenção registrada". Lógica de cálculo
> extraída de `register()` e compartilhada com o recálculo — achado durante a implementação: o
> "estado original do item antes da primeira manutenção" citado na regra de negócio não é
> literalmente recuperável (register() sobrescreve `lastPerformedAt` a cada chamada), então o reset
> usa a mesma fórmula de `MaintenanceItemService.create()` pra item sem data informada (base = hoje).
> Novo teste de regressão pra `register()` (não existia nenhum antes desta task, já que a extração
> tocou nesse método). 7 testes novos, 698/698 backend green.
> Atualizado em: 25/07/2026 — TASK-137 implementada e movida para Em Validação: endpoint `POST
> /items/maintenances/{id}/cancel` com motivo obrigatório (`@NotBlank`/`@Size`), restrição por papel
> (ADMIN/SYNDIC, mesmo padrão manual de `TeamMemberService.requireAdmin`), soft-delete via
> `@SQLDelete` já existente na entidade. Achado de segurança fora do escopo original: `@SQLRestriction`
> filtra canceladas de `findById`, então idempotência (cancelar 2x) exigiu uma query nativa dedicada
> pra distinguir 404 (nunca existiu) de 409 (já cancelada) — com filtro de organização embutido na
> própria query, pra não vazar cross-tenant se um ID de outra empresa existe/foi cancelado. 7 testes
> novos (`MaintenanceCancelTest`, primeiro teste de `MaintenanceService` no projeto), 691/691 testes
> backend green. Migration V84. Branch `feature/EPIC-016-cancel-maintenance-reason` a partir de
> `staging`, ainda não commitada/pushada.
> Atualizado em: 25/07/2026 — **EPIC-016 ganha TASK-142/143**: durante o desenho do épico, surgiu a
> dúvida se anexar evidência a uma manutenção *depois* de registrada feriria compliance do mesmo
> jeito que editar a manutenção. Decisão com Douglas: **não** — nenhum fato muda, só a documentação
> é completada, desde que fique visível quem e quando anexou (`MaintenanceAttachment.uploadedAt`/
> `uploadedByUserId` já existem no banco, só não expostos ao usuário hoje). TASK-142 (backend:
> resolver nome do autor em lote, padrão já usado na TASK-104) e TASK-143 (frontend: permitir
> anexar em manutenção existente + exibir autor/data) criadas em Backlog; C8 adicionado à
> TASK-QA-MAN-011. Ficou como decisão em aberto, fora do escopo deste épico: se vale travar o quanto
> `performedAt` pode ser retroativo em relação à data real de registro (`createdAt`) — mitigaria o
> cenário de alguém registrar tardiamente alegando ter feito na data de vencimento original, mas
> exige definir com Douglas qual janela seria razoável antes de virar task.
> Atualizado em: 25/07/2026 — **Backfill de TASK-135 e TASK-136**: ambas já implementadas e em
> `staging`/PR #25 desde antes desta entrada, mas nunca tinham ganho arquivo de task nem linha no
> kanban — corrigido agora. TASK-135 (template WhatsApp v2, 5 variáveis + botão de URL dinâmica,
> vinculada ao EPIC-015) e TASK-136 (provedor de e-mail Resend + endpoint de teste manual, sem
> épico — melhoria de infraestrutura/custo) movidas direto para Concluído.
> Atualizado em: 25/07/2026 — **EPIC-016 criado e planejado**: cancelamento de manutenções com
> motivo obrigatório, sem editar/apagar o registro original — corrige um gap real encontrado
> testando em produção (não havia como corrigir uma manutenção cadastrada errada; o mais próximo
> era anexar documentação, que também não estava disponível pra manutenções já existentes).
> Decisão de produto com Douglas: correção é sempre por **cancelamento com motivo** (soft-delete já
> existente na entidade `Maintenance`, só sem endpoint até então), nunca por edição direta dos
> campos — preserva o histórico auditável. Recálculo do item após cancelar usa a manutenção válida
> mais recente por `performedAt` (não a próxima cadastrada), caindo no estado "sem manutenção
> registrada" se não sobrar nenhuma. 5 tasks técnicas (TASK-137 a TASK-141) + QA manual
> (TASK-QA-MAN-011) criadas em Backlog. ⚠️ Nota à parte: os commits `TASK-135` (botão de URL
> dinâmica no template WhatsApp) e `TASK-136` (provedor de e-mail Resend) já foram implementados e
> estão em `staging`, mas nunca ganharam arquivo de task/entrada no kanban — numeração deste épico já
> considera isso (começa em 137); ficou pendente backfillar a documentação retroativa de 135/136.
> Atualizado em: 24/07/2026 — **EPIC-015 fechado.** TASK-QA-MAN-010 (suíte de QA manual, 13
> cenários) executada em staging e aprovada por Douglas — cobre opt-in, janela de urgência de 48h,
> idempotência, quota mensal, rate limit diário, fallback automático para e-mail (C8, validado como
> esperado dado que o template HSM ainda não está aprovado pela Meta), horário comercial e webhook
> de status (handshake, delivered/read, payload de falha 130497, rejeição de assinatura inválida).
> Com isso, as 6 tasks de implementação do épico (122/129/130/131/128/132) e a própria
> TASK-QA-MAN-010 movem de Backlog/Em Validação para Concluído. ⚠️ Pendência que **não** bloqueou o
> fechamento (decisão de produto): envio real com `status=SENT` contra a Meta em produção segue
> dependente da aprovação do template HSM "vencimento_manutencao_v2" pela Meta — o caminho de
> fallback para e-mail cobre esse cenário até lá, e o próprio desenho da suíte de QA (TASK-QA-MAN-010)
> assume isso como esperado, não como bug.
> Atualizado em: 20/07/2026 — TASK-132 implementada e movida para Em Validação: `JobController`
> ganha 2 endpoints `GET /run-jobs/execute-notification-detection` e
> `GET /run-jobs/execute-whatsapp-deferred-send`, mesmo padrão do `execute-trial-expiration` já em
> produção — disparam sob demanda os jobs do EPIC-015 que só rodavam via `@Scheduled`
> (`NotificationEventDetectionJob`/`WhatsAppDeferredSendJob`), sem precisar esperar o cron das 5h
> nem a janela de horário comercial. Criada em conjunto a
> [TASK-QA-MAN-010](QA/tasks/TASK-QA-MAN-010.md), suíte de QA manual com 13 cenários (opt-in,
> janela de urgência de 48h, idempotência, quota, rate limit, fallback e-mail, horário comercial,
> webhook de status) cobrindo o EPIC-015 ponta a ponta, com queries SQL prontas pra montar cada
> cenário direto no banco. Decisão de design: **sem** endpoint de simulação para o webhook — os
> cenários usam o endpoint real (`POST /public/webhooks/whatsapp`) com assinatura HMAC calculada
> de verdade, porque simular um bypass de assinatura testaria menos do que a TASK-128 promete
> garantir. Sem testes novos (wrappers finos, mesmo padrão do endpoint já existente sem teste
> dedicado), 672/672 testes backend green (suíte inalterada).
> Atualizado em: 20/07/2026 — TASK-128 implementada e movida para Em Validação: novo pacote
> `webhooks/whatsapp/` (`WhatsAppWebhookController` GET handshake + POST eventos,
> `WhatsAppSignatureValidator` HMAC-SHA256 real sobre `X-Hub-Signature-256` — ao contrário do
> `AsaasWebhookController`, que nunca valida assinatura). `business_whatsapp_dispatches` estendida
> (migration V83) com `delivery_status`/`delivered_at`/`read_at`/`failed_error_code`/
> `failed_error_message`, atualizados via lookup por `wamid` (já existia da TASK-130, com índice).
> Idempotência por ranking monotônico de status (SENT/FAILED < DELIVERED < READ) — evento atrasado
> não regride status já mais avançado. 31 testes novos (assinatura válida/forjada, handshake
> token/mode, parsing delivered/read/failed com fixture do erro 130497, não-regressão), 672/672
> testes backend green. Com isso, fecha o EPIC-015 (todas as tasks — 122/129/130/131/128 — em
> Em Validação). ⚠️ Não testado contra a Meta real (endpoint precisa estar publicamente acessível
> via HTTPS para o handshake — pendente configurar `WHATSAPP_WEBHOOK_VERIFY_TOKEN`/
> `WHATSAPP_APP_SECRET` em produção e registrar a URL no App do Meta) — só testes unitários.
> Atualizado em: 19/07/2026 — TASK-131 implementada e movida para Em Validação: `BusinessWhatsAppQuotaService`
> novo (quota mensal, `whatsappMonthlyLimit` em `BillingPlanFeatures`), rate limit diário por telefone
> (cap simples — decisão confirmada com Douglas: agregação real em "resumo do dia" ficaria pra depois,
> exige template HSM novo na Meta) e janela de horário comercial (8h-20h Brasília) com fila de verdade
> (`PENDING_HOURS_WINDOW` + `WhatsAppDeferredSendJob`, mesmo padrão do `EmailRetryJob`) — maior que o
> esforço estimado no card original, necessário porque a detecção roda às 5h, fora da janela. Com isso,
> só falta a TASK-128 (webhook) pra fechar o EPIC-015. 25 testes novos, 653/653 testes backend green.
> Atualizado em: 19/07/2026 — TASK-130 implementada e movida para Em Validação: regra de urgência de
> 48h no `NotificationChannelResolver` (arredondada para dias inteiros — só `daysOffset==1` é alcançado
> hoje, dado que `NotificationEvent` não carrega granularidade de hora); `BusinessWhatsAppNotificationService`
> novo com idempotência real (`business_whatsapp_dispatches`, migration V81) e fallback pra e-mail em
> falha final do WhatsApp. **Achado durante a implementação**: a chave de dedup do card
> (organização/tipo/referência/vencimento) tratava múltiplos checkpoints de atraso (0/7/15/30 dias
> vencido, mesmo due_date) como duplicata um do outro — corrigido adicionando `days_offset` à
> constraint única. 22 testes novos, 638/638 testes backend green.
> Atualizado em: 19/07/2026 — TASK-129 implementada e movida para Em Validação: `WhatsAppClient` novo
> (mesmo estilo do `AsaasClient`) envia templates HSM via Graph API e retorna `wamid`; classificação de
> falha transitória (5xx/timeout/429) vs. permanente (demais 4xx, erro 130497, erro 190/401 — loga
> `WHATSAPP_TOKEN_EXPIRED`) via 2 exceções novas; retry seletivo via Resilience4j (só a transitória é
> retentada, diferente do `mailersend` que retenta em qualquer exceção). 15 testes novos (via
> `com.sun.net.httpserver.HttpServer` local + teste isolado do mecanismo de retry, sem dependência
> nova), 616/616 testes backend green. ⚠️ Não verificado contra a Meta real (template HSM ainda não
> aprovado) — só contra mock local. Ainda não wireado no orchestrator (escopo da TASK-130).
> Atualizado em: 19/07/2026 — TASK-122 validada por Douglas em teste manual real e ajustada
> visualmente (bloco de opt-in do WhatsApp em `/profile`: divisor, ícone de marca, hierarquia
> tipográfica, LGPD como linha separada — só layout, sem tocar em API/estado). PRs abertos para
> `staging`: [easy-maintenance-api#19](https://github.com/douglasjava/easy-maintenance-api/pull/19)
> e [easy-maintenance-web#22](https://github.com/douglasjava/easy-maintenance-web/pull/22).
> Atualizado em: 19/07/2026 — TASK-122 implementada e movida para Em Validação: `phone_number`/
> `whatsapp_opt_in` em `users` (migration V80), `PhoneNumberNormalizer` novo (trata 9º dígito/DDI/máscara
> BR), regra "opt-in exige telefone" via `RuleException`, reaproveitando `PATCH /user/{id}` existente
> (campos aditivos). Frontend: `/profile` ganhou campo de telefone com máscara + toggle de opt-in
> (LGPD), opt-in autodesativa se o telefone for limpo. 601/601 testes backend green, 86/89 frontend
> (3 falhas pré-existentes de `middleware.test.ts`, não relacionadas). `tsc`/`next build` limpos.
> ⚠️ Não verificado visualmente no browser — recomendado teste manual do fluxo antes de aceitar.
> Atualizado em: 18/07/2026 — TASK-122 quebrada em [EPIC-015](epics/EPIC-015.md) (Notificações via
> WhatsApp): card único tinha crescido demais (provedor + dado do usuário + integração + orquestração +
> quota + webhook). TASK-122 ficou só com telefone/opt-in do usuário; TASK-129 criada para a integração
> real com a Meta Cloud API (envio de template, classificação de falha transitória/permanente); TASK-130
> criada para a orquestração (regra de urgência de 48h no resolver, `BusinessWhatsAppNotificationService`
> com idempotência real via constraint única e fallback pra e-mail em falha permanente — especificação
> técnica detalhada trazida por Douglas); TASK-131 criada para quota mensal/rate limiting. TASK-128
> (webhook, já existente) recategorizada sob o mesmo épico, com dependências ajustadas para TASK-129/130
> em vez de TASK-122.
> Atualizado em: 18/07/2026 — TASK-128 criada: card de backlog vinculado à TASK-122 para implementar o
> webhook de status de entrega/leitura da WhatsApp Cloud API (Meta), levantado a partir de um prompt de
> especificação técnica de Douglas. Investigação prévia do padrão de webhook existente (Asaas) encontrou
> uma lacuna de segurança real que não deve ser copiada — `AsaasWebhookController` nunca valida
> assinatura/token do request recebido. TASK-128 exige handshake `GET` de verificação e validação real de
> `X-Hub-Signature-256` (HMAC-SHA256). Decisão de design: estender `business_whatsapp_dispatches` (tabela
> já prevista na TASK-122) com colunas de status de entrega, em vez de criar uma tabela paralela de log.
> Atualizado em: 15/07/2026 — TASK-126 implementada e movida para Em Validação: bloco "O risco real"
> (RiskBlock, copy aprovada) inserido logo após o Hero, absorvendo e removendo o card duplicado "Medo de
> multa e processo"; carrossel mobile reutilizável (CardCarousel, CSS scroll-snap) aplicado nos 4 grids da
> landing + no bloco novo; padding mobile das seções reduzido de 110px para 64px. `eslint`/`next build`
> limpos. ⚠️ Desktop verificado visualmente no browser; mobile NÃO verificado (ferramenta de automação de
> browser ficou instável nesta sessão) — padrão de responsividade é o mesmo já validado na TASK-124,
> recomendado Douglas conferir no celular/DevTools antes de aceitar.
> Atualizado em: 15/07/2026 — TASK-126 ampliada para virar um único card de reformulação da landing:
> bloco "O risco real" (processo, multa/interdição, acidente — copy aprovada por Douglas após pesquisa de
> fontes: IBAPE Nacional, Seciesp, Código Civil Art. 1.348, Corpo de Bombeiros) **+** redução de scroll
> mobile via componente reutilizável de carrossel/accordion (em vez de página mobile separada, decisão
> tomada pra não duplicar manutenção nem arriscar cloaking no Google). Absorve e remove o card "Medo de
> multa e processo" hoje diluído na seção `#problema`.
> Atualizado em: 15/07/2026 — TASK-125 implementada e movida para Em Validação: botão de WhatsApp
> flutuante ativado na landing (reaproveitando `.whatsapp-float`, que já existia no CSS mas nunca foi
> usado) + número de contato atualizado para (31) 9 9982-6634 nos 3 pontos onde aparecia (CTA "Falar com
> Consultor", texto do rodapé — que virou link clicável — e botão flutuante), todos com a mesma mensagem
> pré-preenchida definida com Douglas. Verificado no browser via dev server local. `eslint`/`next build`
> limpos.
> Atualizado em: 15/07/2026 — TASK-125 criada: card de backlog para adicionar botão de WhatsApp na landing
> (reaproveitando a classe CSS `.whatsapp-float` já existente mas não usada) e trocar o número de contato
> para 55 31 9982-6634. Levantamento prévio mostrou que o número antigo (5531995639390 / (31) 99563-9390)
> só existe em `landing/page.tsx` (CTA + rodapé), sem duplicação em outros arquivos. Pendente: confirmar
> 9º dígito do número novo e definir a mensagem pré-preenchida do link com Douglas antes de implementar.
> Atualizado em: 15/07/2026 — TASK-124 validada por Douglas em teste manual real (toggle Lista/Calendário, navegação entre meses, painel do dia, item sem `nextDueAt` ausente do grid). PRs abertos para `staging`: [easy-maintenance-api#15](https://github.com/douglasjava/easy-maintenance-api/pull/15) e [easy-maintenance-web#13](https://github.com/douglasjava/easy-maintenance-web/pull/13).
> Atualizado em: 15/07/2026 — TASK-124 implementada e movida para Em Validação: `GET /easy-maintenance/api/v1/items/calendar` (novo `MaintenanceItemSpecs.dueDateBetween` + `MaintenanceItemService.findAllForCalendar`, 6 testes novos, 571/571 backend green) + toggle "Lista | Calendário" em `/items` com a visão isolada em componentes próprios (`ItemsCalendarView`, `ItemsCalendarDayPanel`, `calendarUtils`, `shared`), a pedido de Douglas para não poluir `page.tsx`. tsc/eslint limpos, `next build` sem erros. ⚠️ Não verificado visualmente (mesma limitação de segredos locais ausentes da TASK-115/116) — recomendado teste manual antes de mover para Done.
> Atualizado em: 14/07/2026 — TASK-123 concluída: validado por Douglas em teste real — `.ics` importou corretamente nos calendários. Ajuste de UX após feedback: botão saiu do cabeçalho apertado do detalhe do item e virou link contextual "+ calendário" junto ao "Próximo vencimento"; listagem `/items` ganhou o mesmo botão em cada linha (tabela e card mobile, sem competir por espaço com Editar/Remover).
> Atualizado em: 14/07/2026 — TASK-123 implementada e movida para Em Validação: `GET /easy-maintenance/api/v1/items/{id}/calendar.ics` (novo `ItemCalendarExportService`, reaproveita `MaintenanceItemService.findEntityForOrg` para escopo de organização) + botão "Adicionar ao calendário" em `/items/[id]`. 565/565 testes backend green (4 novos: VEVENT válido, 2 VALARM, RuleException quando sem `nextDueAt`, TenantException propaga em org errada). tsc/eslint limpos no frontend. ⚠️ Não verificado visualmente (sem ambiente local rodando) — recomendado importar o `.ics` de verdade no Google Calendar antes de aceitar.
> Atualizado em: 14/07/2026 — TASK-124 criada: card de backlog para visão em calendário dos itens — desenhado via brainstorming com Douglas antes da criação. Decisão v1: toggle "Lista | Calendário" dentro de `/items` (reaproveitando filtros existentes), célula do dia com bolinhas por status + contador, clique abre painel com lista do dia; caso de uso validado é planejamento (enxergar picos de vencimento no mês). Backend precisa de query por range de datas, diferente da paginação cursor atual.
> Atualizado em: 14/07/2026 — TASK-123 criada: card de backlog para exportação de lembrete de item em `.ics` (calendário) — desenhado via brainstorming com Douglas antes da criação. Decisão v1: sem OAuth (não existe integração OAuth com Google hoje, só API key do Google Places), botão só no detalhe do item, `.ics` com 2 VALARM (7d/1d antes), sem resync automático (limitação aceita conscientemente).
> Atualizado em: 14/07/2026 — TASK-122 criada: card de backlog para implementar o canal de notificações via WhatsApp — hoje só existe o esqueleto (`NotificationType.WHATSAPP`, `WhatsAppNotificationProvider` com TODO, `NotificationChannelResolver` nunca resolve WHATSAPP), sem integração real, sem campo de telefone no `User`, sem opt-in/quota. Descrição completa com regras de disparo, limites e tabela comparativa de provedores (Meta direto, Twilio, 360dialog, Zenvia, Take Blip, Gupshup, Infobip).
> Atualizado em: 13/07/2026 — TASK-121 criada e concluída: achado durante validação manual da TASK-117 — botão "+ Novo Item" continuava habilitado com pool de itens esgotado (20/20), porque `FeatureAccessService.canCreateItem` ainda comparava uso por organização isolada, não o pool da conta. Corrigido com o mesmo padrão da TASK-120 (`TenantContext.runCrossOrg`); frontend `/items` agora mostra UsageMeter + botão desabilitado com mensagem clara. 561/561 testes backend green.
> Atualizado em: 13/07/2026 — TASK-120 criada e concluída: bug crítico achado por Douglas em `/billing` (contagem de itens zerada para orgs não-ativas). Causa raiz: `TenantFilterAspect` escopa TODA query de `MaintenanceItemRepository` ao X-Org-Id ativo, mesmo com orgCode explícito no parâmetro — afetava não só exibição mas o enforcement real do pool de itens (TASK-111) e a validação de downgrade (TASK-112). Corrigido em 6 pontos com novo helper `TenantContext.runCrossOrg()` (mesmo padrão da TASK-QA-BUG-012). 558/558 testes backend green. Bug irmão não corrigido (fora do escopo): `ReportsService.getOverview` tem o mesmo problema, pré-existente à EPIC-014.
> Atualizado em: 13/07/2026 — TASK-119 criada e concluída: `/organizations/[code]` ainda exibia card "Assinatura e Plano" (outro resquício do modelo antigo, achado por Douglas em teste manual). Removido; card de dados da empresa passou a ocupar largura total; adicionado botão "Editar" (só para a organização ativa da sessão, por limitação do X-Org-Id — confirmado com Douglas). tsc/eslint limpos.
> Atualizado em: 13/07/2026 — TASK-118 revisada (2ª rodada): Douglas notou que o frontend ainda chamava PUT .../subscription mesmo sem seletor de plano — correto, não deveria. Movido o provisionamento do item ORGANIZATION para dentro de `UsersService.addOrganization()` (acontece automaticamente ao vincular a org à conta), idempotente. Frontend não faz mais nenhuma chamada de "subscription". 554/554 testes backend green.
> Atualizado em: 13/07/2026 — TASK-118 criada e concluída: bug encontrado por Douglas em teste manual local — `/organizations/new` ainda tinha Step 2 "Configuração de Assinatura" com seletor de plano para a organização (resquício do modelo antigo). Corrigido: `OrganizationsService.addOrganizationSubscription()` agora ignora o planCode do request e sempre herda o plano do item USER da conta quando ela já existe; frontend virou fluxo de passo único, sem seletor de plano. 552/552 testes backend green.
> Atualizado em: 13/07/2026 — TASK-116 em validação: painel admin `subscriptions/` remove Upgrade/Downgrade/Cancelar de linhas ORGANIZATION ("Incluída na conta"), mostra sourceId + uso do pool por org/conta. Backend (`BillingAdminDTO`/`listSubscriptions`) estendido no mesmo padrão da TASK-115. Agrupamento visual conta→orgs NÃO implementado (paginação continua por item — gap documentado). 550/550 testes backend green. ⚠️ Mesma limitação de verificação visual da TASK-115.
> Atualizado em: 13/07/2026 — TASK-115 em validação: `/billing` consolidado num card único de conta + lista read-only de organizações (uso do pool). Escopo expandiu para FULL_STACK — `BillingSummaryResponse`/`BillingDashboardService` ganharam campos de uso (organizações/usuários/itens). 548/548 testes backend green, tsc/eslint limpos no frontend. ⚠️ UI NÃO verificada visualmente — boot completo do backend local bloqueado por múltiplos segredos ausentes (Asaas/Google Places/OpenAI/DeepSeek/tokens) e navegação no browser falhou repetidamente; recomendado rodar `npm run dev` localmente antes de aceitar.
> Atualizado em: 12/07/2026 — TASK-114 em validação: migration V79 aplicada e validada de verdade contra o MySQL local de desenvolvimento — 17 itens ORGANIZATION zerados, total_cents recalculado (ex.: STARTER R$198→R$99), 33/33 linhas preservadas (desenho original previa DELETE; ajustado para zerar valueCents pois TASK-111/113 dependem das linhas existirem). Boot completo da app (onboarding/PIX/CC) não testado por falta de segredos locais.
> Atualizado em: 12/07/2026 — TASK-113 em validação: `GET/PUT /organizations/{code}/subscription` retornam novo `OrganizationSubscriptionResponse` — plano/preço vêm do item USER (conta), com itemsUsedByOrg/itemsUsedTotalAccount/maxItemsAccount para o pool compartilhado (TASK-111). Mudança aditiva no JSON (sem remoção de campo), mas não validada contra o frontend real — pendente TASK-115/116. 546/546 testes backend green.
> Atualizado em: 12/07/2026 — TASK-112 em validação: downgrade de plano agora valida o pool de itens (TASK-111) além de organizationCount; `SubscriptionItemChangePlanAdapter` bloqueia troca de plano por item ORGANIZATION (404); `OrganizationPlanChangeService` removida (órfã). 544/544 testes backend green.
> Atualizado em: 12/07/2026 — TASK-111 em validação: `MaintenanceItemService.validateItemLimit()` reescrito — maxItems vira pool compartilhado entre todas as organizações da mesma BillingSubscription (via `MaintenanceItemRepository.countByOrganizationCodeIn`), não mais teto isolado por org. 539/539 testes backend green (MaintenanceItemPlanLimitTest reescrito com 9 cenários).
> Atualizado em: 12/07/2026 — TASK-110 em validação: `BillingSubscriptionService.addItem()` — item ORGANIZATION passa a ter valueCents=0 (não-cobrável), apenas o item USER soma ao totalCents. 8 testes novos (BillingSubscriptionServiceTest, OnboardingServiceTest, OrganizationsServiceTest), 539/539 testes backend green. Branch feature/EPIC-014 criada a partir de staging (API + Web).
> Atualizado em: 12/07/2026 — EPIC-014 criada: consolidação de billing para plano único por conta — remove cobrança duplicada USER+ORGANIZATION (hoje gera ~R$598/mês num cadastro novo BUSINESS). TASK-110 a TASK-117 no backlog, sem clientes pagantes reais afetados.
> Atualizado em: 06/07/2026 — TASK-109 concluída: 3 endpoints (POST /transition/pix, /update-card, /transition/card) + CardTransitionService + SubscriptionCreatedHandler CC→CC card update — 527 testes, 0 falhas
> Atualizado em: 06/07/2026 — TASK-108 concluída: BillingRecoveryService + 2 endpoints (POST /recover/pix e /recover/checkout) + fix updatePaymentMethod — 499 testes, 0 falhas
> Atualizado em: 06/07/2026 — TASK-108 e TASK-109 criadas: especificação completa de troca de método de pagamento em PAST_DUE e ACTIVE — Backlog EPIC-010
> Atualizado em: 01/07/2026 — TASK-107 concluída: BUGFIX advanceCycle() preenche nextDueDate para assinaturas PIX — 475 testes, 0 falhas
> Atualizado em: 30/06/2026 — TASK-105 concluída: botão "Limpar" sempre visível em /items — estilo dinâmico cinza/vermelho igual ao /maintenances
> Atualizado em: 30/06/2026 — TASK-104 criada: Frontend — exibir criador/modificador nos detalhes do item (depende de TASK-103)
> Atualizado em: 01/07/2026 — TASK-104 concluída: "Registrado por" nos CSVs de manutenções (org + cross-org) — resolução batch, 471 testes, 0 falhas
> Atualizado em: 01/07/2026 — TASK-106 concluída: BUGFIX notificações escopadas por org (TenantContext) — 468 testes, 0 falhas
> Atualizado em: 01/07/2026 — TASK-103 concluída: migration V76 + entidades + DTOs + services + 4 testes — 464 testes, 0 falhas
> Atualizado em: 30/06/2026 — fix/member-access em validação: MEMBER status implementado — membros de equipe recebem FULL_ACCESS via assinatura da org; Faturamento ocultado no menu (PR #6 backend, PR #5 frontend)
> Atualizado em: 29/06/2026 — TASK-102 em validação: `/users/[id]/edit` — edição com multi-org diff via PATCH, self-edit guard, pré-populate
> Atualizado em: 29/06/2026 — TASK-101 em validação: `/users/new` reescrito — convite via POST /me/team/users, multi-org checkboxes, roles, guard ADMIN
> Atualizado em: 29/06/2026 — TASK-100 em validação: `/users` page — listagem de equipe com UsageMeter, badges, delete local, guard ADMIN
> Atualizado em: 29/06/2026 — TASK-099 em validação: "Usuários" no UserTopBar (ADMIN only) via `userRole` salvo no login
> Atualizado em: 28/06/2026 — EPIC-013 revisado: modelo corrigido para Gestão de Equipe por Conta — dono ADMIN gerencia membros com multi-org assignment via `/me/team/users`
> Atualizado em: 27/06/2026 — TASK-097 concluída: todas subtasks (A, B, C) entregues — 447 testes, 0 falhas
> Atualizado em: 27/06/2026 — TASK-097-C concluída: `BusinessEmailQuotaServiceTest` (5 testes, 447 passando)
> Atualizado em: 27/06/2026 — TASK-097-B concluída: `maxOrganizations` enforcement em `OrganizationsService.validateOrgLimit()` + `OrganizationPlanLimitTest` (5 testes, 442 passando)
> Atualizado em: 27/06/2026 — TASK-097-A concluída: `maxUsers` enforcement em `UsersService` + `UserPlanLimitTest` (6 testes, 437 passando)
> Atualizado em: 27/06/2026 — TASK-097 criada: hardening limites de plano (maxUsers, maxOrganizations na criação, teste emailMonthlyLimit)
> Atualizado em: 21/06/2026 — issue #56 em validação: IA Onboarding adicionado ao menu lateral (Ações); emojis removidos de Relatórios e Ajuda
> Atualizado em: 21/06/2026 — EPIC-012 (Affiliate Referral) registrado no backlog com TASK-089 a TASK-096
> Atualizado em: 30/05/2026 — SPRINT-01, SPRINT-02 e SPRINT-06 concluídas; SPRINT-03 concluída (6/6); SPRINT-04 concluída (5/5); SPRINT-05 não iniciada
> Sprints concluídas: 1, 2, 3, 4, 6 | EPIC-009 completo | TASK-025, TASK-026, TASK-027, TASK-028 concluídas
> **Bugs registrados (02/05/2026):** TASK-QA-BUG-001 🔄 Corrigido v2 (JWT stale pós-onboarding — aguarda validação) | ~~TASK-QA-BUG-002~~ ✅ Concluído
> **Bug ativo (25/05/2026):** TASK-QA-BUG-003 🔴 Criação de organização admin — 422 companyType nulo
> **Bug ativo (25/05/2026):** TASK-QA-BUG-004 🟠 Step 2 de cadastro de org — PUT .../organizations/{code}/subscription retorna 500 (rota inexistente no backend)
> **Bug ativo (14/05/2026):** Trial → PIX recorrente quebrado no Asaas (`/subscriptions` só aceita CREDIT_CARD) — tratamento em TASK-058 a TASK-066
> **Bug em validação (30/05/2026):** TASK-QA-BUG-005 🟠 Erro ao cadastrar dados de faturamento — fix aplicado: campos name/paymentMethod/planCode adicionados ao formulário frontend
> **Bug concluído (30/05/2026):** TASK-QA-BUG-006 ✅ Erro ao cadastrar nova empresa — fix completo: `orElseGet` + `paymentMethod` obrigatório no Step 2 + pre-populate `name`/`billingEmail` do User
> **Em validação (30/05/2026):** TASK-069 🟡 Filtros nome/e-mail adicionados à tela /private/users — frontend + service atualizados

---

## Legenda de Prioridade
🔴 Crítico | 🟠 Alto | 🟡 Médio | 🔵 Baixo

---


## 🐛 Bugs — Em Execução

_Vazio_

## 🐛 Bugs — Em Validação

| ID                                             | Título                                                                                                                           | Prioridade | Épico    | Severidade |
|------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|------------|----------|------------|
| [TASK-151](tasks/TASK-151.md)                  | Política de Privacidade inacessível para visitantes não logados (Shell.tsx isAuth)                                              | 🔴 Crítico | EPIC-003 | ALTA       |
| [TASK-QA-BUG-017](QA/tasks/TASK-QA-BUG-017.md) | IA Onboarding e dica do SAMU exibidos mesmo com `aiEnabled: false` — Sidebar + QuickActions corrigidos | 🟠 Alto    | EPIC-006 | MÉDIA      |
| TASK-QA-BUG-016                                | E-mail de alerta exibe ID do item em vez do nome — referenceId usado em vez de referenceLabel                                   | 🟠 Alto    | EPIC-006 | MÉDIA      |
| TASK-QA-BUG-015                                | /reports: data exibida com -1 dia (timezone) e CSV com coluna monetária quebrada (issue #55)                                    | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-014                                | Dashboard: overdueCount=0, daysLate=0, breakdowns sem OVERDUE — status stale em KPIs/attention/breakdowns (issue #54)            | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-013                                | Status dos itens desatualizado — NEAR_DUE exibido para itens vencidos, filtro ?status=OVERDUE quebrado (issue #53)               | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-012                                | items 21/24 sem orgCode em /me/reports/maintenances — TenantFilterAspect filtrava findAllById cross-org                          | 🔴 Crítico | EPIC-011 | ALTA       |
| TASK-079                                       | Exibir periodicidade da norma nos detalhes do item Regulatório (issue #50)                                                        | 🔵 Baixo   | EPIC-006 | —          |
| TASK-QA-BUG-011                                | Filtro "Realizados este mês" retorna manutenções fora do mês — backend só tinha data exata (issue #49)                            | 🟡 Médio   | EPIC-006 | BAIXA      |
| TASK-QA-BUG-010                                | Campo norma não pré-preenchido ao editar item Regulatório — useEffect acessava `item.norm?.id` em vez de `item.normId` (issue #52) | 🟡 Médio   | EPIC-006 | BAIXA      |
| TASK-078                                       | Ao remover org do usuário via admin, agendar cancelamento do billing_subscription_items + warning no frontend                    | 🟠 Alto    | EPIC-007 | ALTA       |
| TASK-QA-BUG-009                                | Crash TypeError na aba Empresas de /private/users/[id] — subscription nula não tratada (issue #46)                               | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-008                                | Paginação some na página 2+ em /items e /maintenances — totalElements=-1 no cursor mode (issue #45)                              | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-007                                | Mensagem "Invalid period in norm" ao cadastrar item regulatório com periodicidade zerada (issue #37)                             | 🟠 Alto    | EPIC-006 | ALTA       |
| TASK-QA-BUG-005                                | Erro ao cadastrar dados de faturamento — PUT .../billing/users/22/account retorna 422 (planCode/paymentMethod/name não enviados) | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-055](tasks/TASK-055.md)                  | Sessão do usuário sem organização é apagada após login                                                                           | 🔴 Crítico | EPIC-006 | GRAVE      |
| [TASK-QA-BUG-001](QA/tasks/TASK-QA-BUG-001.md) | Onboarding sem redirect e sem dados da organização após conclusão                                                                | 🟠 Alto    | EPIC-006 | GRAVE      |

## 🐛 Bugs — Concluídos

| ID                                             | Título                                                                                                          | Prioridade | Épico    | Severidade |
|------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|------------|----------|------------|
| TASK-QA-BUG-006                                | Erro ao cadastrar nova empresa — paymentMethod obrigatório + orElseGet + pre-populate name/billingEmail do User | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-QA-BUG-004](QA/tasks/TASK-QA-BUG-004.md) | Step 2 cadastro org — PUT organizations/{code}/subscription retorna 500 (rota backend inexistente)              | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-QA-BUG-003](QA/tasks/TASK-QA-BUG-003.md) | Criação de organização via admin falha com 422 — campo companyType nulo                                         | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-056](tasks/TASK-056.md)                  | Recriar rota GET /organizations/{code}/subscription                                                             | 🔴 Crítico | EPIC-006 | ALTA       |
| [TASK-052](tasks/TASK-052.md)                  | E-mail de convite de admin não entra na fila de retry                                                           | 🟠 Alto    | EPIC-002 | ALTA       |

## 🐛 Bugs — Backlog

_Vazio_

---

---

## Backlog

| ID                            | Título                                                                  | Prioridade | Épico    | Fase |
|-------------------------------|-------------------------------------------------------------------------|------------|----------|------|
| ~~TASK-001~~                  | ~~Persistir chaves RSA JWT~~                                            | 🔴 Crítico | EPIC-001 | 1    |
| ~~TASK-002~~         | ~~Migrar JWT de localStorage para cookie HttpOnly~~                     | 🔴 Crítico | EPIC-001 | 1    |
| ~~TASK-003~~         | ~~Implementar ShedLock nos jobs agendados~~                             | 🔴 Crítico | EPIC-002 | 1    |
| ~~TASK-004~~         | ~~Testes mínimos para billing e tenant isolation~~                      | 🔴 Crítico | EPIC-008 | 1    |
| ~~TASK-005~~         | ~~Desabilitar Swagger/OpenAPI em produção~~                             | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-006~~         | ~~Rate limiting em auth, reset e IA~~                                   | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-007~~         | ~~Validação robusta de webhook Asaas~~                                  | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-008~~         | ~~Circuit breaker para serviços externos~~                              | 🟠 Alto    | EPIC-002 | 1    |
| ~~TASK-009~~         | ~~Validar X-Org-Id contra claims do JWT~~                               | 🟠 Alto    | EPIC-003 | 1    |
| ~~TASK-010~~         | ~~Auditar e rotacionar secrets no repositório~~                         | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-011~~         | ~~Restringir endpoints do Actuator em produção~~                        | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-012~~         | ~~Verificar e corrigir profile de e-mail em produção~~                  | 🟠 Alto    | EPIC-002 | 1    |
| ~~TASK-013~~         | ~~Adicionar security headers HTTP~~                                     | 🟠 Alto    | EPIC-001 | 1    |
| ~~TASK-014~~         | ~~Restrição CORS para domínio de produção~~                             | 🟠 Alto    | EPIC-003 | 1    |
| ~~TASK-015~~         | ~~Banner de trial expirando no dashboard~~                              | 🟠 Alto    | EPIC-006 | 1    |
| ~~TASK-016~~         | ~~Tratamento de erro claro no onboarding~~                              | 🟠 Alto    | EPIC-006 | 1    |
| ~~TASK-017~~         | ~~Enforcement automático de tenant no repository~~                      | 🟡 Médio   | EPIC-003 | 1    |
| ~~TASK-018~~         | ~~Soft delete nas entidades críticas~~                                  | 🟡 Médio   | EPIC-004 | 2    |
| ~~TASK-019~~         | ~~Índices ausentes no banco de dados~~                                  | 🟡 Médio   | EPIC-004 | 2    |
| ~~TASK-020~~         | ~~Schema formal para features JSON em billing_plans~~                   | 🟡 Médio   | EPIC-004 | 2    |
| TASK-021             | Alertas no Prometheus/Grafana                                           | 🟡 Médio   | EPIC-005 | 2    |
| ~~TASK-022~~         | ~~Sentry em backend e frontend~~                                        | 🟡 Médio   | EPIC-005 | 2    |
| ~~TASK-023~~         | ~~Indicador de uso vs limite de plano no frontend~~                     | 🟡 Médio   | EPIC-006 | 2    |
| ~~TASK-024~~         | ~~Exportação de relatórios PDF/Excel~~                                  | 🟡 Médio   | EPIC-006 | 2    |
| ~~TASK-025~~         | ~~Fila/retry para envio de e-mails~~                                    | 🟡 Médio   | EPIC-002 | 2    |
| TASK-026             | Testes de integração — billing e auth completos                         | 🟡 Médio   | EPIC-008 | 2    |
| ~~TASK-027~~         | ~~Pre-signed URLs S3 para uploads diretos~~                             | 🟡 Médio   | EPIC-007 | 2    |
| ~~TASK-028~~         | ~~Processamento assíncrono de chamadas IA~~                             | 🟡 Médio   | EPIC-007 | 2    |
| ~~TASK-029~~         | ~~Runbook de incidentes e operação~~                                    | 🟡 Médio   | EPIC-005 | 2    |
| ~~TASK-030~~         | ~~Tela de comparação de planos (upgrade page)~~                         | 🟡 Médio   | EPIC-006 | 2    |
| ~~TASK-031~~         | ~~Notificações in-app (lista no header)~~                               | 🔵 Baixo   | EPIC-006 | 2    |
| ~~TASK-032~~         | ~~Tour guiado pós-onboarding~~                                          | 🔵 Baixo   | EPIC-006 | 2    |
| TASK-033             | Status page básica                                                      | 🔵 Baixo   | EPIC-005 | 2    |
| ~~TASK-034~~         | ~~Central de ajuda / FAQ in-app~~                                       | 🔵 Baixo   | EPIC-006 | 2    |
| TASK-035             | Política de retenção para audit_logs                                    | 🔵 Baixo   | EPIC-004 | 2    |
| ~~TASK-036~~         | ~~Paginação cursor-based em listagens grandes~~                         | 🔵 Baixo   | EPIC-007 | 3    |
| TASK-037             | Jobs de billing assíncronos com fila                                    | 🔵 Baixo   | EPIC-007 | 3    |
| ~~TASK-038~~         | ~~LGPD: exportação e exclusão de dados pessoais~~                       | 🔵 Baixo   | EPIC-003 | 3    |
| ~~TASK-039~~         | ~~Autenticação 2FA~~                                                    | 🔵 Baixo   | EPIC-001 | 3    |
| TASK-040             | Acessibilidade básica (WCAG AA)                                         | 🔵 Baixo   | EPIC-006 | 3    |
| ~~TASK-041~~         | ~~Configurar defaults globais do React Query~~                          | 🟠 Alto    | EPIC-009 | 2    |
| ~~TASK-042~~         | ~~Adicionar loading.tsx nas rotas principais~~                          | 🟠 Alto    | EPIC-009 | 2    |
| ~~TASK-043~~         | ~~Migrar useDashboardData para useQuery~~                               | 🟡 Médio   | EPIC-009 | 2    |
| ~~TASK-044~~         | ~~Eliminar N+1 de permissões na página de itens~~                       | 🟡 Médio   | EPIC-009 | 2    |
| ~~TASK-045~~         | ~~Criar middleware.ts para guards de autenticação~~                     | 🟡 Médio   | EPIC-009 | 2    |
| ~~TASK-046~~         | ~~PIX: popular QR Code e expiração nas cobranças recorrentes~~          | 🔴 Crítico | EPIC-010 | 2    |
| ~~TASK-047~~         | ~~PIX: e-mail de lembrete no PAYMENT_OVERDUE~~                          | 🟠 Alto    | EPIC-010 | 2    |
| ~~TASK-048~~         | ~~PIX: exibir QR Code pendente na página de billing~~                   | 🔴 Crítico | EPIC-010 | 2    |
| ~~TASK-049~~         | ~~Centralizar validação de expiração de TRIAL no /me/access-context~~   | 🔴 Crítico | EPIC-003 | 1    |
| ~~TASK-050~~         | ~~Criar páginas públicas de retorno do checkout~~                       | 🟠 Alto    | EPIC-010 | 2    |
| ~~TASK-QA-AUTO-001~~ | ~~Testes IT: isolamento multi-tenant~~ *(substituída por TASK-E2E-002)* | 🔴 Crítico | EPIC-003 | —    |
| ~~TASK-QA-AUTO-004~~ | ~~Testes IT: webhook idempotência~~ *(substituída por TASK-E2E-003)*    | 🟠 Alto    | EPIC-001 | —    |
| ~~TASK-QA-AUTO-005~~ | ~~Testes IT: soft delete~~ *(substituída por TASK-E2E-004)*             | 🟡 Médio   | EPIC-004 | —    |
| ~~TASK-QA-AUTO-006~~ | ~~Testes E2E: React Query cache~~ *(migrada para TASK-E2E-005)*         | 🟡 Médio   | EPIC-009 | —    |
| ~~TASK-069~~         | ~~Criar busca para usuários~~                                           | 🟡 Médio   | EPIC-006 | 3    |
| ~~TASK-070~~         | ~~Padronizar a cor da seção de usuários~~                               | 🔵 Baixo   | EPIC-006 | 3    |
| ~~TASK-071~~         | ~~Padronizar as nomenclaturas de empresas (Organizações → Empresas)~~   | 🔵 Baixo   | EPIC-006 | 3    |
| TASK-081             | Backend: GET /me/reports/overview — KPIs consolidados + por org        | 🟠 Alto    | EPIC-011 | 3    |
| TASK-082             | Backend: GET /me/reports/maintenances — listagem paginada cross-org    | 🟠 Alto    | EPIC-011 | 3    |
| [TASK-098](tasks/TASK-098.md) | Backend: guard ADMIN + invitation email + DELETE em UsersOrganizationsController | 🔴 Crítico | EPIC-013 | 3 |
| ~~[TASK-099](tasks/TASK-099.md)~~ | ~~Frontend: "Usuários" no UserTopBar dropdown (ADMIN only)~~       | 🟠 Alto    | EPIC-013 | 3    |
| ~~[TASK-100](tasks/TASK-100.md)~~ | ~~Frontend: `/users` — listagem de usuários da org com CRUD actions~~ | 🟠 Alto    | EPIC-013 | 3    |
| ~~[TASK-101](tasks/TASK-101.md)~~ | ~~Frontend: reescrever `/users/new` — convite por e-mail + org select~~ | 🔴 Crítico | EPIC-013 | 3    |
| ~~[TASK-102](tasks/TASK-102.md)~~ | ~~Frontend: `/users/[id]/edit` — edição + desativação de usuário~~ | 🟠 Alto    | EPIC-013 | 3    |
| [TASK-QA-MAN-009](QA/tasks/TASK-QA-MAN-009.md) | QA Manual: E2E fluxo completo de convite e gestão de usuários | 🟠 Alto | EPIC-013 | 3 |
| [TASK-104](tasks/TASK-104.md) | Full-Stack: "Registrado por" nos CSVs de manutenções — resolução batch via UserRepository, 3 testes novos | 🟡 Médio | EPIC-013 |
| ~~[TASK-103](tasks/TASK-103.md)~~ | ~~Backend: auditoria de criação/modificação em maintenance_items e maintenances (createdBy/updatedBy como Long)~~ | 🟠 Alto | EPIC-013 | 3 |
| ~~[TASK-104](tasks/TASK-104.md)~~ | ~~Full-Stack: createdBy/updatedBy nos relatórios de exportação (colunas "Criado por" / "Registrado por" com nome resolvido em batch)~~ | 🟡 Médio | EPIC-013 | 3 |
| ~~[TASK-105](tasks/TASK-105.md)~~ | ~~Frontend: botão "Limpar" sempre visível em /items — paridade com /maintenances (estilo dinâmico cinza/vermelho)~~ | 🔵 Baixo | EPIC-006 | 3 |
| ~~[TASK-106](tasks/TASK-106.md)~~ | ~~BUGFIX Full-Stack: notificações escopadas por org — bell exibia todas as orgs causando "Item não pertence a essa organização"~~ | 🟠 Alto | EPIC-013 | 3 |
| ~~[TASK-QA-MAN-011](QA/tasks/TASK-QA-MAN-011.md)~~ | ~~QA Manual: E2E cancelamento de manutenção + recálculo de compliance (8 cenários)~~ | 🟠 Alto | EPIC-016 | 3 |

---

## ~~Sprint 1 — Concluída~~ (ver [SPRINT-01.md](sprints/SPRINT-01.md))

## ~~Sprint 2 — Concluída~~ (ver [SPRINT-02.md](sprints/SPRINT-02.md))

---

## ~~Sprint 6 — Concluída~~ (ver [SPRINT-06.md](sprints/SPRINT-06.md))

---

## Situação das Sprints

| Sprint                                | Foco                                    | Status           | Concluídas                        | Pendentes                              |
|---------------------------------------|-----------------------------------------|------------------|-----------------------------------|----------------------------------------|
| ~~[SPRINT-03](sprints/SPRINT-03.md)~~ | Integridade de Dados + Estabilidade     | Concluída 6/6    | TASK-017, 018, 019, 020, 025, 026 | —                                      |
| [SPRINT-04](sprints/SPRINT-04.md)     | Observabilidade + Performance           | Parcial 3/5      | TASK-022, TASK-027, TASK-029      | TASK-021, TASK-028                     |
| [SPRINT-05](sprints/SPRINT-05.md)     | Escalabilidade + Compliance + Polimento | Não iniciada 0/7 | —                                 | TASK-033, 035, 036, 037, 038, 039, 040 |

---

## Pronto para Implementar

**EPIC-020 — split de comissão entre beneficiários (caso Grupo Silva) — *(27/08/2026)***:
*(estende `Affiliate` sem alterar `ReferralCommission`/`CommissionService` nem a regra de 1
comissionado por cliente)*
- ~~**[TASK-207](tasks/TASK-207.md)**~~ — ~~Backend: `affiliate_commission_splits` + endpoints de leitura/edição + beneficiários no breakdown mensal~~ *(mergeada em staging, PR staging→main [api#54](https://github.com/douglasjava/easy-maintenance-api/pull/54) aberta)*
- ~~**[TASK-208](tasks/TASK-208.md)**~~ — ~~Frontend: ação "Dividir comissão" na tela de afiliados + sub-linhas de beneficiário no financeiro~~ *(mergeada em staging, PR staging→main [web#59](https://github.com/douglasjava/easy-maintenance-web/pull/59) aberta)*

*(2/2 tasks mergeadas em staging — PRs staging→main abertas, aguardando merge final em produção)*

**Sem épico — bugfix pontual, achado no QA da EPIC-002 Fase 3 mas independente dela — *(26/08/2026)***:
- **[TASK-206](tasks/TASK-206.md)** — BUGFIX Full-stack: rota morta de assinatura por usuário no admin (mostra plano errado) — testado local, PR api#49/web#54

**EPIC-020 Fase 2 — Revisão: comissionado atribuído substitui comissão manual — 4/4 tasks
implementadas, PRs abertas contra `staging` — *(24/08/2026)***:
*(estende `Affiliate`/`ReferralCommission` em vez de manter `manual_commission_rules` — ver
`docs/superpowers/specs/2026-08-24-affiliate-commission-rework.md`;
[easy-maintenance-api#43](https://github.com/douglasjava/easy-maintenance-api/pull/43),
[easy-maintenance-web#49](https://github.com/douglasjava/easy-maintenance-web/pull/49))*
- ~~**[TASK-195](tasks/TASK-195.md)**~~ — ~~Backend: `Affiliate` ganha `recurrenceType`; CRUD admin de edição; remove `ManualCommissionRule`~~ *(implementada — commit `02417bf`, 786 testes, 0 falhas)*
- ~~**[TASK-196](tasks/TASK-196.md)**~~ — ~~Backend: rekey `referral_commissions.organization_id` → `user_id`; corrige atribuição; suporta comissão recorrente~~ *(implementada — commit `506e529`, 792 testes, 0 falhas)*
- ~~**[TASK-197](tasks/TASK-197.md)**~~ — ~~Backend: `FinancialsService` sem comissão manual; endpoint de breakdown por comissionado~~ *(implementada — commit `b38b617`, 796 testes, 0 falhas)*
- ~~**[TASK-198](tasks/TASK-198.md)**~~ — ~~Frontend: edição de afiliado (%/recorrência), atribuição a cliente, breakdown na tela de financeiro~~ *(implementada — commit `4a4ff78`, `npm run build` limpo, não validada visualmente por mim)*

**EPIC-014 — bugfix achado no QA da EPIC-020, sem relação direta — *(24/08/2026)***:
*(branch própria a partir de `staging` — aguardando Douglas atualizar `staging` com as PRs #43/#49
acima antes de puxar a branch nova)*
- ~~**[TASK-199](tasks/TASK-199.md)**~~ — ~~Backend: "Receita Total" no Faturamento soma preço de tabela do item ORGANIZATION, que está zerado desde a EPIC-014~~ *(implementada — commit `edd6d43`, PR [#44](https://github.com/douglasjava/easy-maintenance-api/pull/44), 798 testes, 0 falhas)*

**EPIC-020 Fase 2 — módulo financeiro (página própria, bruto/líquido, despesas, comissão manual) — 5/5 tasks implementadas, aguardando teste local de Douglas — *(23/08/2026)***:
*(na branch `feature/financial-module-v2`, `easy-maintenance-api` + `easy-maintenance-web`, sem PR
por task — mesma convenção das leves anteriores)*
- ~~**[TASK-190](tasks/TASK-190.md)**~~ — ~~Backend: substitui `operating_expense_rates` por `expenses` + `manual_commission_rules`~~ *(implementada — a parte de `manual_commission_rules` é revertida pela TASK-195)*
- ~~**[TASK-191](tasks/TASK-191.md)**~~ — ~~Backend: CRUD de despesas e regras de comissão manual~~ *(implementada — 787 testes, 0 falhas; a parte de regras de comissão manual é revertida pela TASK-195)*
- ~~**[TASK-192](tasks/TASK-192.md)**~~ — ~~Backend: reescreve `FinancialsService` (bruto/líquido, saldo do mês/acumulado) + comissão de afiliado sobre o líquido~~ *(implementada — suíte completa, 0 falhas)*
- ~~**[TASK-193](tasks/TASK-193.md)**~~ — ~~Frontend: página própria `/private/admin/financials`~~ *(implementada — `npm run build` limpo, não validada visualmente por mim)*
- ~~**[TASK-194](tasks/TASK-194.md)**~~ — ~~Frontend: seções de cadastro de despesas e regras de comissão manual~~ *(implementada — `npm run build` limpo, não validada visualmente por mim; seção de comissão manual é removida pela TASK-198)*

**EPIC-021 Fase 2 — registro manual de lead + edição completa (telefone) — 3/3 tasks implementadas, PR aberta para staging — *(23/08/2026)***:
*(todas as tasks desta leva na mesma branch `feature/leads-manual-registration` —
`easy-maintenance-api`/`easy-maintenance-web` — testadas localmente por Douglas antes da abertura
das PRs: [#42](https://github.com/douglasjava/easy-maintenance-api/pull/42) (api) e
[#48](https://github.com/douglasjava/easy-maintenance-web/pull/48) (web))*
- ~~**[TASK-187](tasks/TASK-187.md)**~~ — ~~Backend: `phone` + `origin_type` em `landing_leads`~~ *(implementada, PR #42)*
- ~~**[TASK-188](tasks/TASK-188.md)**~~ — ~~Backend: criação manual + edição completa de lead~~ *(implementada, PR #42 — 11 testes em `LeadAdminServiceTest`, 0 falhas)*
- ~~**[TASK-189](tasks/TASK-189.md)**~~ — ~~Frontend: modal de criar/editar + colunas Telefone/Canal~~ *(implementada, PR #48 — `npm run build` limpo, validada localmente por Douglas)*

**EPIC-025 Fase 2 — filtro determinístico de catálogo no onboarding por IA — 6/6 tasks implementadas, PRs abertas para staging — *(21/08/2026)***:
*(todas as tasks desta leva na mesma branch `feature/ai-onboarding-catalog-filter` —
`easy-maintenance-api`/`easy-maintenance-web` — testadas localmente por Douglas antes da abertura
das PRs: [#40](https://github.com/douglasjava/easy-maintenance-api/pull/40) (api) e
[#46](https://github.com/douglasjava/easy-maintenance-web/pull/46) (web))*
- ~~**[TASK-186](tasks/TASK-186.md)**~~ — ~~Frontend: experiência mobile — cards no lugar da tabela~~ *(implementada, PR #46 — não validada visualmente por mim, tela exige login)*
- ~~**[TASK-183](tasks/TASK-183.md)**~~ — ~~Backend: corrige `nextDueAt`/`customPeriod*` divergente em itens REGULATORY~~ *(implementada, PR #40 — QA de Douglas ok)*
- ~~**[TASK-181](tasks/TASK-181.md)**~~ — ~~Backend: tabela `norm_segments` + filtro por segmento no `NormRepository`~~ *(implementada, PR #40)*
- ~~**[TASK-182](tasks/TASK-182.md)**~~ — ~~Backend: endpoint síncrono `POST /ai/bootstrap/catalog-preview`~~ *(implementada, PR #40)*
- ~~**[TASK-184](tasks/TASK-184.md)**~~ — ~~Backend: IA como complemento — evita duplicata, aceita `normId` explícito~~ *(implementada, PR #40 — backend 100% pronto, 779 testes, 0 falhas)*
- ~~**[TASK-185](tasks/TASK-185.md)**~~ — ~~Frontend: `/ai-onboarding` — filtro instantâneo + IA progressiva~~ *(implementada, PR #46 — `npm run build` limpo)*

**EPIC-025 Fase 1 — conteúdo e governança das normas técnicas — ✅ concluída (19/08/2026)**:
- ~~**[TASK-177](tasks/TASK-177.md)**~~ — ~~Backend: corrigir/completar citações de normas no catálogo `norms`~~ *(concluída — PR #38 mergeada em staging)*
- ~~**[TASK-179](tasks/TASK-179.md)**~~ — ~~Frontend: atualizar página `/norms` com os achados do levantamento~~ *(concluída — PR #44 mergeada em staging)*
- ~~**[TASK-178](tasks/TASK-178.md)**~~ — ~~Backend: novo item de catálogo para instalação de gás combustível~~ *(concluída — PR #39 mergeada em staging)*
- ~~**[TASK-180](tasks/TASK-180.md)**~~ — ~~Conteúdo: revisar post do blog sobre NBR 5674~~ *(concluída — PR #45 mergeada em staging)*

**🟠 Alto (EPIC-024 — agendamento de demonstração via Cal.com) — *(backlog, não priorizado agora, 19/08/2026)***:
- **[TASK-175](tasks/TASK-175.md)** — Frontend: página `/agendar` (embed Cal.com) + botão na navbar da landing (🟠 Alto | EPIC-024)
- **[TASK-176](tasks/TASK-176.md)** — Backend: webhook do Cal.com cria lead via `LeadService` (🟠 Alto | EPIC-024)

**🟠 Alto (EPIC-023 — fornecedores nas notificações de vencimento) — *(backlog, não priorizado agora, 18/08/2026)***:
- **[TASK-172](tasks/TASK-172.md)** — Backend: `SupplierLookupService` — busca textual + cache 7 dias (🟠 Alto | EPIC-023)
- **[TASK-173](tasks/TASK-173.md)** — Backend: fornecedores no e-mail de notificação (🟠 Alto | EPIC-023)
- **[TASK-174](tasks/TASK-174.md)** — Backend: fornecedores no WhatsApp — template v3, depende de aprovação Meta (🟡 Médio | EPIC-023)

**🟠 Alto (EPIC-021 — painel de leads, visão agregada + mini-CRM de status)**:
- ~~**[TASK-163](tasks/TASK-163.md)**~~ — ~~Backend: `status` de `String` livre pra enum `LeadStatus`~~ *(em validação)*
- ~~**[TASK-164](tasks/TASK-164.md)**~~ — ~~Backend: endpoint agregado `GET /admin/leads/summary`~~ *(em validação)*
- ~~**[TASK-165](tasks/TASK-165.md)**~~ — ~~Backend: lista paginada/filtrável + troca de status~~ *(em validação)*
- ~~**[TASK-166](tasks/TASK-166.md)**~~ — ~~Frontend: item "Leads" no menu + visão agregada~~ *(em validação, QA manual pendente)*
- ~~**[TASK-167](tasks/TASK-167.md)**~~ — ~~Frontend: lista individual — filtros + troca de status inline~~ *(em validação, QA manual pendente)*

**🟠 Alto (EPIC-018 — tracking de conversão, tráfego pago inicia esta semana)**:
- ~~**[TASK-152](tasks/TASK-152.md)**~~ — ~~Backend: `consent_accepted_at` + validação de consentimento obrigatório~~ *(em validação)*
- ~~**[TASK-153](tasks/TASK-153.md)**~~ — ~~Frontend: captura e persistência de UTM (cookie 30 dias)~~ *(em validação)*
- ~~**[TASK-154](tasks/TASK-154.md)**~~ — ~~Frontend: checkbox de consentimento LGPD + envio de UTM no form de demonstração~~ *(em validação)*
- ~~**[TASK-155](tasks/TASK-155.md)**~~ — ~~Frontend: página `/obrigado` + correção da whitelist `isAuth`~~ *(em validação)*
- ~~**[TASK-156](tasks/TASK-156.md)**~~ — ~~Frontend: scaffolding de eventos Lead/Contact — pendente de IDs de pixel~~ *(em validação)*
- **[TASK-157](tasks/TASK-157.md)** — *(QA aprovado 26/08/2026, mergeada em `staging`, PRs `staging → main` abertas)* Meta Conversions API — dedupe de Lead + sinal de qualidade (CONTACTED/CONVERTED), credenciais reais configuradas e validadas no Test Events da Meta (🟡 Médio | EPIC-018). Mergeados: [api#51](https://github.com/douglasjava/easy-maintenance-api/pull/51), [web#56](https://github.com/douglasjava/easy-maintenance-web/pull/56). Promoção pra main: [api#52](https://github.com/douglasjava/easy-maintenance-api/pull/52), [web#57](https://github.com/douglasjava/easy-maintenance-web/pull/57). QA: [TASK-QA-MAN-015](QA/tasks/TASK-QA-MAN-015.md)

**🔴 Crítico (bug ativo de receita) — sequência sugerida**:
- ~~**TASK-058**~~ — Refatorar job de expiração de TRIAL: PIX via DETACHED *(em validação)*
- ~~**TASK-059**~~ — Subscription PIX recorrente manual *(em validação)*
- ~~**TASK-060**~~ — Webhook PAYMENT_RECEIVED avança ciclo PIX manual *(em validação)*
- ~~**TASK-061**~~ — UX: seleção de método antes da expiração do TRIAL *(em validação)*

**🟠 Alto (robustez pós-MVP de PIX manual)**:
- ~~**TASK-062**~~ — Classificador de motivos de recusa Asaas *(em validação)*
- ~~**TASK-063**~~ — Job de reconciliação noturna Asaas *(em validação)*
- ~~**TASK-064**~~ — Hardening de webhook: DLQ + replay *(em validação)*
- ~~**TASK-065**~~ — Tela "Atualizar método de pagamento" *(em validação)*

**🟡 Médio (próxima fase)**:
- **TASK-066** — Pix Automático (mandato regulamentado) (🟡 Médio | EPIC-010)
- **[TASK-109](tasks/TASK-109.md)** — Troca de método em ACTIVE: CC→PIX, CC→CC, PIX→CC (🟡 Médio | EPIC-010)
- ~~**TASK-068**~~ — Enriquecer response de notificações com nome do item referenciado (🟡 Médio | EPIC-006)

**Pendentes de SPRINT-04**:
- ~~**TASK-021**~~ — ~~Alertas no Prometheus/Grafana~~ *(em validação)*

**Projeto E2E — Playwright** (`easy-maintenance-e2e`):
- **TASK-E2E-004** — Soft delete via API (🟡 Médio | EPIC-004) — substitui TASK-QA-AUTO-005
- **TASK-E2E-005** — React Query cache performance (🟡 Médio | EPIC-009) — migração de TASK-QA-AUTO-006

---

## Em Execução

_Vazio_

---

## Em Validação

| ID                            | Título                                                                          | Prioridade | Épico    |
|-------------------------------|---------------------------------------------------------------------------------|------------|----------|
| [TASK-209](tasks/TASK-209.md) | 🔴 BUGFIX Backend: `generateInvoiceForPayer` desistia quando a fatura já existia — travava renovação PIX/troca de cartão em produção — mergeada em staging, PR staging→main [api#56](https://github.com/douglasjava/easy-maintenance-api/pull/56) aberta | 🔴 Crítico | — |
| [TASK-210](tasks/TASK-210.md) | 🔴 BUGFIX Backend: `LazyInitializationException` em `invoice.getItems()` (regressão da TASK-209) — PR contra staging [api#57](https://github.com/douglasjava/easy-maintenance-api/pull/57) aberta | 🔴 Crítico | — |
| [TASK-207](tasks/TASK-207.md) | Backend: split de comissão entre beneficiários (`affiliate_commission_splits`) — mergeada em staging, PR staging→main [api#54](https://github.com/douglasjava/easy-maintenance-api/pull/54) aberta | 🟠 Alto | EPIC-020 |
| [TASK-208](tasks/TASK-208.md) | Frontend: ação "Dividir comissão" + sub-linhas de beneficiário no financeiro — mergeada em staging, PR staging→main [web#59](https://github.com/douglasjava/easy-maintenance-web/pull/59) aberta | 🟠 Alto | EPIC-020 |
| [TASK-201](tasks/TASK-201.md) | Full-stack: ressincronização manual de cliente Asaas por usuário — testado local, PR api#48/web#53 | 🟠 Alto | EPIC-002 |
| [TASK-202](tasks/TASK-202.md) | Frontend: validação de dígito verificador de CPF/CNPJ no onboarding — testado local, PR web#53 | 🟠 Alto | EPIC-002 |
| [TASK-203](tasks/TASK-203.md) | Backend: validação de dígito verificador de CPF/CNPJ (defesa em profundidade) — testado local, PR api#48 | 🟡 Médio | EPIC-002 |
| [TASK-204](tasks/TASK-204.md) | Backend: alerta (Sentry) quando falha a criação do cliente Asaas — testado local, PR api#48 | 🟠 Alto | EPIC-002 |
| [TASK-205](tasks/TASK-205.md) | Frontend: indicador visual de sincronização pendente com Asaas — testado local, PR web#53 | 🟡 Médio | EPIC-002 |
| [TASK-171](tasks/TASK-171.md) | Frontend: Blog — link na landing + redesenho do índice + posts 2-5             | 🟠 Alto    | EPIC-022 |
| [TASK-170](tasks/TASK-170.md) | Frontend: Blog — infraestrutura MDX + primeiro post real (NBR 5674)            | 🟠 Alto    | EPIC-022 |
| [TASK-169](tasks/TASK-169.md) | BUGFIX Backend: custos "Outros" com labels diferentes conflitavam (total financeiro incorreto) | 🔴 Crítico | —        |
| [TASK-168](tasks/TASK-168.md) | BUGFIX Frontend: botão "Ver todos os recursos" da landing sem destino          | 🟡 Médio   | —        |
| [TASK-158](tasks/TASK-158.md) | Frontend: página pública de Termos de Uso — corrige link quebrado do rodapé     | 🟠 Alto    | —        |
| [TASK-152](tasks/TASK-152.md) | Backend: `consent_accepted_at` em `landing_leads` + validação de consentimento obrigatório | 🟠 Alto | EPIC-018 |
| [TASK-153](tasks/TASK-153.md) | Frontend: captura e persistência de UTM (cookie 30 dias)                        | 🟠 Alto    | EPIC-018 |
| [TASK-154](tasks/TASK-154.md) | Frontend: checkbox de consentimento LGPD + envio de UTM no form de demonstração | 🟠 Alto    | EPIC-018 |
| [TASK-155](tasks/TASK-155.md) | Frontend: página `/obrigado` + correção da whitelist `isAuth` no `Shell.tsx`    | 🟠 Alto    | EPIC-018 |
| [TASK-156](tasks/TASK-156.md) | Frontend: scaffolding de eventos de conversão (Lead/Contact) — pendente de IDs de pixel | 🟡 Médio | EPIC-018 |
| [TASK-118](tasks/TASK-118.md) | BUGFIX Full-Stack: /organizations/new não pede mais plano próprio (herda plano da conta) | 🔴 Crítico | EPIC-014 |
| [TASK-116](tasks/TASK-116.md) | Frontend+Backend: painel admin subscriptions — remove ações por org, mostra pool (não verificado visualmente) | 🟡 Médio | EPIC-014 |
| [TASK-115](tasks/TASK-115.md) | Frontend+Backend: /billing consolidado — card único de conta + pool de orgs/itens (não verificado visualmente) | 🟠 Alto | EPIC-014 |
| [TASK-114](tasks/TASK-114.md) | Migration V79 — zera value_cents dos itens ORGANIZATION legados + recalcula total_cents | 🟠 Alto | EPIC-014 |
| [TASK-113](tasks/TASK-113.md) | Backend: GET/PUT organizations/{code}/subscription — plano da conta + uso do pool | 🟠 Alto  | EPIC-014 |
| [TASK-112](tasks/TASK-112.md) | Backend: downgrade valida pool de itens + remove OrganizationPlanChangeService  | 🟠 Alto    | EPIC-014 |
| [TASK-111](tasks/TASK-111.md) | Backend: pool compartilhado de maxItems entre organizações do owner            | 🔴 Crítico | EPIC-014 |
| [TASK-110](tasks/TASK-110.md) | Backend: parar de criar item ORGANIZATION cobrável (addItem valueCents=0)       | 🔴 Crítico | EPIC-014 |
| [TASK-058](tasks/TASK-058.md) | Refatorar job de expiração de TRIAL: PIX via cobrança avulsa (DETACHED)         | 🔴 Crítico | EPIC-010 |
| [TASK-059](tasks/TASK-059.md) | Subscription PIX recorrente "manual": ciclo gerenciado internamente             | 🔴 Crítico | EPIC-010 |
| [TASK-060](tasks/TASK-060.md) | Webhook PAYMENT_RECEIVED avança ciclo PIX manual                                | 🔴 Crítico | EPIC-010 |
| [TASK-061](tasks/TASK-061.md) | UX: seleção de método de pagamento antes do fim do TRIAL                        | 🟠 Alto    | EPIC-010 |
| [TASK-062](tasks/TASK-062.md) | Classificador de motivos de recusa Asaas + roteamento por bucket                | 🟠 Alto    | EPIC-010 |
| [TASK-063](tasks/TASK-063.md) | Job de reconciliação noturna: Asaas vs estado local                             | 🟠 Alto    | EPIC-010 |
| [TASK-064](tasks/TASK-064.md) | Hardening de webhook Asaas: DLQ + replay manual                                 | 🟠 Alto    | EPIC-010 |
| [TASK-065](tasks/TASK-065.md) | Frontend: tela "Atualizar método de pagamento" para subscriptions PAST_DUE      | 🟠 Alto    | EPIC-010 |
| [TASK-108](tasks/TASK-108.md) | Full-Stack: Troca de método de pagamento em PAST_DUE (PIX avulso + checkout CC) | 🟠 Alto    | EPIC-010 |
| [TASK-109](tasks/TASK-109.md) | Full-Stack: Troca de método de pagamento em ACTIVE (CC→PIX, CC→CC, PIX→CC)      | 🟡 Médio   | EPIC-010 |
| TASK-QA-AUTO-002              | Testes unitários: handler PIX e PAYMENT_OVERDUE (casos de borda)                | 🟠 Alto    | EPIC-010 |
| TASK-QA-AUTO-003              | Testes de integração: rate limiting nos endpoints de autenticação (@WebMvcTest) | 🟠 Alto    | EPIC-001 |
| TASK-E2E-001                  | Setup do projeto Playwright E2E (`easy-maintenance-e2e`)                        | 🟠 Alto    | EPIC-008 |
| TASK-E2E-003                  | Testes E2E: Webhook Asaas — token e idempotência                                | 🟠 Alto    | EPIC-001 |
| TASK-082                      | Backend: GET /me/reports/maintenances — listagem paginada cross-org com filtros | 🟠 Alto    | EPIC-011 |
| TASK-081                      | Backend: GET /me/reports/overview — KPIs consolidados + breakdown por org       | 🟠 Alto    | EPIC-011 |
| TASK-086                      | Frontend: Seção de Relatórios — filtros, tabela paginada e export CSV (GET /me/reports/maintenances)    | 🟡 Médio   | EPIC-011 |
| TASK-085                      | Frontend: Dashboard Unificado — KPIs globais + grid de cards por empresa (GET /me/reports/overview)     | 🟠 Alto    | EPIC-011 |
| TASK-084                      | Frontend: estrutura da página /reports + entrada no sidenav e menu do usuário                           | 🟠 Alto    | EPIC-011 |
| TASK-083                      | Backend: GET /me/reports/maintenances/export — CSV consolidado cross-org (4 testes, 374 passando)       | 🟡 Médio   | EPIC-011 |
| TASK-080                      | Visibilidade de cancelamento agendado na tela /billing — banner âmbar + campo scheduledCancellationDate | 🟠 Alto    | EPIC-007 |
| TASK-072                      | Exibir link de comprovante nas faturas pagas da tela /billing                    | 🟡 Médio   | EPIC-006 |
| TASK-069                      | Criar busca para usuários — filtros nome/e-mail na tela /private/users           | 🟡 Médio   | EPIC-006 |
| [TASK-099](tasks/TASK-099.md) | Frontend: "Usuários" no UserTopBar dropdown (ADMIN only) — `userRole` salvo no login, lido no TopBar | 🟠 Alto    | EPIC-013 |
| [TASK-100](tasks/TASK-100.md) | Frontend: `/users` — listagem com UsageMeter, badges role/status, org badges, delete local, guard ADMIN | 🟠 Alto    | EPIC-013 |
| [TASK-101](tasks/TASK-101.md) | Frontend: `/users/new` reescrito — POST /me/team/users, multi-org checkboxes, roles select, guard ADMIN | 🔴 Crítico | EPIC-013 |
| [TASK-102](tasks/TASK-102.md) | Frontend: `/users/[id]/edit` — PATCH com diff de orgs, pré-populate, guard ADMIN, self-edit protection | 🟠 Alto    | EPIC-013 |
| [TASK-087](tasks/TASK-087.md) | Trial 7→14 dias + planos anuais com 17% desconto (2 meses grátis)               | 🟠 Alto    | EPIC-010 |
| [TASK-021](tasks/TASK-021.md) | Alertas no Prometheus/Grafana — rules, AlertManager, Grafana dashboard           | 🟡 Médio   | EPIC-005 |
| TASK-038                      | LGPD: exportação e exclusão de dados pessoais (endpoints + frontend + privacidade) | 🔵 Baixo   | EPIC-003 |
| issue #56                     | IA Onboarding adicionado ao menu lateral (Ações) + emojis removidos de Relatórios e Ajuda            | 🔵 Baixo   | EPIC-006 |
| TASK-089                      | Backend: migrations V72/V73 + entidades Affiliate/ReferralCommission + repositórios (EPIC-012)        | 🔴 Crítico | EPIC-012 |
| TASK-090                      | Backend: DTOs + AffiliateService (createAffiliate, suggestForEmail, getDashboard) + CommissionService  | 🔴 Crítico | EPIC-012 |
| TASK-091                      | Backend: AffiliateController, CommissionAdminController, lead/org integration, auto-match referralCode  | 🔴 Crítico | EPIC-012 |
| TASK-092                      | Backend: trigger comissão no PaymentReceivedHandler (cycleNumber==1 → CommissionService)               | 🔴 Cr��tico | EPIC-012 |
| TASK-093                      | Frontend: cookie em_ref na landing page (?ref=CODE) + affiliateCode no submit do lead                  | 🟠 Alto    | EPIC-012 |
| TASK-094                      | Frontend: /indicador/novo — formulário de cadastro de afiliado + estado de sucesso com link copiável   | 🟠 Alto    | EPIC-012 |
| TASK-095                      | Frontend: /indicador/[code] — painel do afiliado com KPIs, tabela de leads mascarados e badge de status | 🟠 Alto    | EPIC-012 |
| TASK-096                      | Frontend: /private/admin/affiliates — painel admin comissões com filtro, "Marcar pago" e total a pagar  | 🟠 Alto    | EPIC-012 |
| [TASK-124](tasks/TASK-124.md) | Full-Stack: visão em calendário dos itens — toggle Lista/Calendário dentro de /items, componentes isolados (não verificado visualmente) | 🟡 Médio | EPIC-006 |
| [TASK-125](tasks/TASK-125.md) | Frontend: botão de WhatsApp na landing + número de contato atualizado para (31) 9 9982-6634 | 🟠 Alto | EPIC-006 |
| [TASK-126](tasks/TASK-126.md) | Frontend: reformulação da landing — bloco "O risco real" + carrossel mobile (não verificado visualmente em mobile) | 🟠 Alto | EPIC-006 |
---

## Concluído

| ID                            | Título                                                                          | Prioridade | Épico        |
|-------------------------------|---------------------------------------------------------------------------------|------------|--------------|
| [TASK-200](tasks/TASK-200.md) | Full-stack: descrição livre no registro de manutenção — api#47 e web#52 mergeadas em main | 🟠 Alto | — |
| [TASK-180](tasks/TASK-180.md) | Conteúdo: revisar post do blog sobre NBR 5674 — PR #45 mergeada em staging | 🔵 Baixo | EPIC-025 |
| [TASK-178](tasks/TASK-178.md) | Backend: novo item de catálogo para instalação de gás combustível — PR #39 mergeada em staging (V90) | 🟡 Médio | EPIC-025 |
| [TASK-179](tasks/TASK-179.md) | Frontend: atualizar página `/norms` com os achados do levantamento — PR #44 mergeada em staging | 🟠 Alto | EPIC-025 |
| [TASK-177](tasks/TASK-177.md) | Backend: corrigir/completar citações de normas no catálogo `norms` — PR #38 mergeada em staging (V89) | 🟠 Alto | EPIC-025 |
| [TASK-088](tasks/TASK-088.md) | Compliance e governança do catálogo de normas: curated-first IA + fix V9 period_qty=0 — confirmado concluído (V71/V75) ao conferir o banco durante o levantamento de normas (EPIC-025), estava parado em "Em Validação" | 🟠 Alto | EPIC-004 |
| [TASK-162](tasks/TASK-162.md) | Frontend: cadastro/edição de custo de infraestrutura + rótulo pra "Outros" (achado de QA) — aprovado por Douglas | 🟠 Alto | EPIC-020 |
| [TASK-161](tasks/TASK-161.md) | Frontend: página `/financeiro` — grid de totalizadores + gráfico Recharts — aprovado por Douglas | 🟠 Alto | EPIC-020 |
| [TASK-160](tasks/TASK-160.md) | Backend: endpoint agregado de financeiro por mês (receita/custo/comissão/lucro) | 🟠 Alto | EPIC-020 |
| [TASK-159](tasks/TASK-159.md) | Backend: modelo de dados + CRUD de custo de infraestrutura (`operating_expense_rates`) | 🟠 Alto | EPIC-020 |
| [TASK-QA-MAN-012](QA/tasks/TASK-QA-MAN-012.md) | QA Manual: E2E dos dois relatórios (PDF de prestação de contas + Excel analítico) — 5 cenários aprovados por Douglas | 🟠 Alto | EPIC-017 |
| [TASK-150](tasks/TASK-150.md) | Frontend: ocultar menu "Relatórios" quando o plano não inclui relatórios (achado no QA manual, C3) | 🟡 Médio | EPIC-017 |
| [TASK-149](tasks/TASK-149.md) | Frontend: seletor de organização na aba Prestação de Contas (achado pós-TASK-146) | 🟡 Médio | EPIC-017 |
| [TASK-148](tasks/TASK-148.md) | Frontend: ajustar tela de Relatório Analítico para refletir export em Excel | 🔵 Baixo | EPIC-017 |
| [TASK-147](tasks/TASK-147.md) | Backend: evoluir export cross-org de CSV para Excel (.xlsx) real, com novas colunas, 6 testes novos | 🟡 Médio | EPIC-017 |
| [TASK-146](tasks/TASK-146.md) | Frontend: Relatório de Prestação de Contas — PDF de uma organização, 4 seções | 🟠 Alto | EPIC-017 |
| [TASK-145](tasks/TASK-145.md) | Backend: listar manutenções canceladas de uma organização num período (auditoria), 5 testes novos | 🟠 Alto | EPIC-017 |
| [TASK-136](tasks/TASK-136.md) | Infra: provedor de e-mail Resend (grátis) + endpoint de teste manual de envio, MailerSend mantido religável via config | 🟡 Médio | — |
| [TASK-135](tasks/TASK-135.md) | Backend: template WhatsApp v2 — 5 variáveis de corpo + botão de URL dinâmica pro item | 🟡 Médio | EPIC-015 |
| [TASK-QA-MAN-010](QA/tasks/TASK-QA-MAN-010.md) | QA Manual: E2E fluxo completo de notificações WhatsApp — 13 cenários executados em staging e aprovados por Douglas | 🟠 Alto | EPIC-015 |
| [TASK-122](tasks/TASK-122.md) | Full-Stack: dado do usuário — telefone + opt-in para notificações WhatsApp — validado visualmente por Douglas + QA manual | 🟡 Médio | EPIC-015 |
| [TASK-129](tasks/TASK-129.md) | Backend: integração com WhatsApp Cloud API (Meta) — envio de template, classificação transitória/permanente confirmada contra a Meta real via QA manual | 🟡 Médio | EPIC-015 |
| [TASK-130](tasks/TASK-130.md) | Backend: orquestração de urgência (48h) + idempotência + fallback para e-mail — validado via QA manual | 🟡 Médio | EPIC-015 |
| [TASK-131](tasks/TASK-131.md) | Backend: quota mensal + rate limiting do canal WhatsApp — validado via QA manual | 🟡 Médio | EPIC-015 |
| [TASK-128](tasks/TASK-128.md) | Backend: webhook de status de entrega/leitura do WhatsApp Cloud API (Meta) — handshake + validação real de X-Hub-Signature-256, 31 testes novos, 672/672 backend green, validado via QA manual | 🟡 Médio | EPIC-015 |
| [TASK-QA-MAN-011](QA/tasks/TASK-QA-MAN-011.md) | QA Manual: E2E cancelamento de manutenção + recálculo de compliance — 8 cenários aprovados por Douglas; achou e corrigiu 3 bugs reais (ver TASK-137) | 🟠 Alto | EPIC-016 |
| [TASK-144](tasks/TASK-144.md) | Frontend: histórico de manutenções (ativas e canceladas) na página de detalhe do item — achado de UX durante o QA manual | 🟡 Médio | EPIC-016 |
| [TASK-142](tasks/TASK-142.md) | Backend: resolver autor de cada anexo de manutenção — sem N+1 mesmo com múltiplas manutenções (query em lote), 4 testes novos, 707/707 backend green | 🟡 Médio | EPIC-016 |
| [TASK-143](tasks/TASK-143.md) | Frontend: permitir anexar evidência a manutenções existentes, exibindo autor e data — build/lint limpos | 🟡 Médio | EPIC-016 |
| [TASK-141](tasks/TASK-141.md) | Frontend: exibir manutenções canceladas na tela do item — card expansível com motivo/autor/data, build/lint limpos | 🟡 Médio | EPIC-016 |
| [TASK-140](tasks/TASK-140.md) | Frontend: ação "Cancelar manutenção" com modal de motivo obrigatório — build/lint limpos, sem clique-a-clique real (ver TASK-QA-MAN-011 C7) | 🟠 Alto | EPIC-016 |
| [TASK-139](tasks/TASK-139.md) | Backend: expor manutenções canceladas na consulta/detalhe do item — 4 testes novos, 702/702 backend green | 🟡 Médio | EPIC-016 |
| [TASK-138](tasks/TASK-138.md) | Backend: recálculo de nextDueAt/lastPerformedAt/status do item após cancelamento — 7 testes novos, 698/698 backend green | 🟠 Alto | EPIC-016 |
| [TASK-137](tasks/TASK-137.md) | Backend: endpoint de cancelamento de manutenção com motivo obrigatório — 7 testes novos, 691/691 backend green | 🟠 Alto | EPIC-016 |
| [TASK-132](tasks/TASK-132.md) | Backend: endpoints de disparo manual dos jobs de notificação/WhatsApp — apoio para TASK-QA-MAN-010 | 🟡 Médio | EPIC-015 |
| [TASK-123](tasks/TASK-123.md) | Full-Stack: exportar lembrete de item em .ics (2 VALARM) — botão no detalhe + na listagem, validado por Douglas | 🟡 Médio | EPIC-006 |
| [TASK-106](tasks/TASK-106.md) | BUGFIX Full-Stack: notificações escopadas por org via TenantContext — 4 testes novos, 468 passando | 🟠 Alto | EPIC-013 |
| [TASK-103](tasks/TASK-103.md) | Backend: auditoria createdBy/updatedBy em maintenance_items e maintenances — Long sem @ManyToOne, migration V76, 4 testes | 🟠 Alto | EPIC-013 |
| [TASK-105](tasks/TASK-105.md) | Frontend: botão "Limpar" sempre visível em /items — estilo dinâmico cinza/vermelho (paridade com /maintenances) | 🔵 Baixo | EPIC-006 |
| [TASK-097](tasks/TASK-097.md) | Hardening dos limites de plano: `maxUsers` + `maxOrganizations` na criação + testes `emailMonthlyLimit`  | 🟠 Alto    | EPIC-008 |
| TASK-077                      | Cards KPI do dashboard clicáveis com navegação filtrada (issue #43)                          | 🟡 Médio   | EPIC-006     |
| TASK-076                      | Botão de voltar ao dashboard na tela de IA Onboarding (issue #44)                            | 🔵 Baixo   | EPIC-006     |
| TASK-075                      | Exibir mais itens em 'Atenção Agora' — limitAttention 5→10 no dashboard (issue #40)          | 🔵 Baixo   | EPIC-006     |
| TASK-074                      | Coluna Item na tela /maintenances — itemType no response + coluna desktop/mobile (issue #41) | 🟡 Médio   | EPIC-006     |
| TASK-073                      | Botão limpar filtros na página /items (issue #42)                                         | 🔵 Baixo   | EPIC-006     |
| TASK-070                      | Padronizar cor da seção de usuários — cyan #0891b2 em users/page.tsx e users/new/page.tsx | 🔵 Baixo   | EPIC-006     |
| TASK-071                      | Padronizar nomenclaturas: Organizações → Empresas (labels frontend)             | 🔵 Baixo   | EPIC-006     |
| [TASK-068](tasks/TASK-068.md) | Enriquecer response de notificações com nome do item referenciado               | 🟡 Médio   | EPIC-006     |
| [TASK-057](tasks/TASK-057.md) | Adicionar activated_at em billing_subscription_items                            | 🟠 Alto    | EPIC-010     |
| TASK-028                      | Processamento assíncrono de chamadas IA                                         | 🟡 Médio   | EPIC-007     |
| TASK-027                      | Pre-signed URLs S3 para uploads diretos                                         | 🟡 Médio   | EPIC-007     |
| TASK-025                      | Fila/retry para envio de e-mails (críticos incluídos)                           | 🟡 Médio   | EPIC-002     |
| TASK-050                      | Criar páginas públicas de retorno do checkout (sucesso, cancelado, expirado)    | 🟠 Alto    | EPIC-010     |
| TASK-001                      | Persistir chaves RSA JWT                                                        | 🔴 Crítico | EPIC-001     |
| TASK-003                      | Implementar ShedLock nos jobs agendados                                         | 🔴 Crítico | EPIC-002     |
| TASK-005                      | Desabilitar Swagger/OpenAPI em produção                                         | 🟠 Alto    | EPIC-001     |
| TASK-009                      | Validar X-Org-Id contra claims do JWT                                           | 🟠 Alto    | EPIC-003     |
| TASK-011                      | Restringir endpoints do Actuator em produção                                    | 🟠 Alto    | EPIC-001     |
| TASK-013                      | Adicionar security headers HTTP                                                 | 🟠 Alto    | EPIC-001     |
| TASK-010                      | Auditar e rotacionar secrets no repositório                                     | 🟠 Alto    | EPIC-001     |
| TASK-012                      | Verificar e corrigir profile de e-mail em produção                              | 🟠 Alto    | EPIC-002     |
| TASK-006                      | Rate limiting em auth, reset e IA                                               | 🟠 Alto    | EPIC-001     |
| TASK-014                      | Restrição CORS para domínio de produção                                         | 🟠 Alto    | EPIC-003     |
| TASK-007                      | Validação robusta de webhook Asaas                                              | 🟠 Alto    | EPIC-001     |
| TASK-002                      | Migrar JWT de localStorage para cookie HttpOnly                                 | 🔴 Crítico | EPIC-001     |
| TASK-004                      | Testes mínimos para billing e tenant isolation                                  | 🔴 Crítico | EPIC-008     |
| TASK-008                      | Circuit breaker para serviços externos                                          | 🟠 Alto    | EPIC-002     |
| TASK-015                      | Banner de trial expirando no dashboard                                          | 🟠 Alto    | EPIC-006     |
| TASK-016                      | Tratamento de erro claro no onboarding                                          | 🟠 Alto    | EPIC-006     |
| TASK-017                      | Enforcement automático de tenant no repository                                  | 🟡 Médio   | EPIC-003     |
| TASK-023                      | Indicador de uso vs limite de plano no frontend                                 | 🟡 Médio   | EPIC-006     |
| TASK-024                      | Exportação de relatórios PDF/Excel                                              | 🟡 Médio   | EPIC-006     |
| TASK-030                      | Tela de comparação de planos (upgrade page)                                     | 🟡 Médio   | EPIC-006     |
| TASK-031                      | Notificações in-app (lista no header)                                           | 🔵 Baixo   | EPIC-006     |
| TASK-032                      | Tour guiado pós-onboarding                                                      | 🔵 Baixo   | EPIC-006     |
| TASK-034                      | Central de ajuda / FAQ in-app                                                   | 🔵 Baixo   | EPIC-006     |
| TASK-019                      | Índices ausentes no banco de dados                                              | 🟡 Médio   | EPIC-004     |
| TASK-041                      | Configurar defaults globais do React Query                                      | 🟠 Alto    | EPIC-009     |
| TASK-042                      | Adicionar loading.tsx nas rotas principais                                      | 🟠 Alto    | EPIC-009     |
| TASK-043                      | Migrar useDashboardData para useQuery                                           | 🟡 Médio   | EPIC-009     |
| TASK-044                      | Eliminar N+1 de permissões na página de itens                                   | 🟡 Médio   | EPIC-009     |
| TASK-045                      | Criar middleware.ts para guards de autenticação                                 | 🟡 Médio   | EPIC-009     |
| TASK-022                      | Sentry em backend e frontend                                                    | 🟡 Médio   | EPIC-005     |
| TASK-018                      | Soft delete nas entidades críticas                                              | 🟡 Médio   | EPIC-004     |
| TASK-020                      | Schema formal para features JSON em billing_plans                               | 🟡 Médio   | EPIC-004     |
| TASK-029                      | Runbook de incidentes e operação                                                | 🟡 Médio   | EPIC-005     |
| TASK-046                      | PIX: popular QR Code e expiração nas cobranças recorrentes                      | 🔴 Crítico | EPIC-010     |
| TASK-047                      | PIX: e-mail de lembrete no PAYMENT_OVERDUE                                      | 🟠 Alto    | EPIC-010     |
| TASK-048                      | PIX: exibir QR Code pendente na página de billing                               | 🔴 Crítico | EPIC-010     |
| TASK-049                      | Centralizar validação de expiração de TRIAL no /me/access-context               | 🔴 Crítico | EPIC-003     |
| TASK-QA-MAN-006 (BUG C8)      | Bloqueio de criação de item ao atingir limite do plano                          | 🔴 Crítico | EPIC-006     |
| TASK-E2E-002                  | Testes E2E: isolamento multi-tenant                                             | 🔴 Crítico | EPIC-003     |
| TASK-026                      | Testes de integração — billing e auth completos                                 | 🟡 Médio   | EPIC-008     |
| TASK-036                      | Paginação cursor-based em listagens grandes                                     | 🔵 Baixo   | EPIC-007     |
| TASK-039                      | Autenticação 2FA (TOTP + backup codes + recovery)                               | 🔵 Baixo   | EPIC-001     |
| TASK-QA-BUG-002               | Bug: Loop infinito no primeiro login — troca de senha com 403 (corrigido)       | 🔴 Crítico | EPIC-001/003 |
| TASK-053                      | Reestruturação de planos: remover FREE, trial BUSINESS, nova grade de features  | 🔴 Crítico | EPIC-006     |
| TASK-054                      | Enforcement de limites: créditos de IA por usuário/mês + cota de upload por org | 🔴 Crítico | EPIC-002     |
| TASK-051                      | Padronizar logos no frontend — SVGs + BrandLogo server component                | 🟡 Médio   | EPIC-009     |

---

## 💸 EPIC-010 — Redesenho do fluxo PIX recorrente + Pix Automático

> Adicionado em 14/05/2026 — destrava conversão de TRIAL para PIX (bug ativo) e prepara terreno para Pix Automático.

| ID                            | Título                                                                     | Prioridade | Fase | Tipo       |
|-------------------------------|----------------------------------------------------------------------------|------------|------|------------|
| [TASK-058](tasks/TASK-058.md) | Refatorar job de expiração de TRIAL: PIX via cobrança avulsa (DETACHED)    | 🔴 Crítico | 2    | BACKEND    |
| [TASK-059](tasks/TASK-059.md) | Subscription PIX recorrente "manual": ciclo gerenciado internamente        | 🔴 Crítico | 2    | BACKEND    |
| [TASK-060](tasks/TASK-060.md) | Webhook PAYMENT_RECEIVED do PIX detached avança o ciclo da subscription    | 🔴 Crítico | 2    | BACKEND    |
| [TASK-061](tasks/TASK-061.md) | UX: seleção de método de pagamento antes da expiração do TRIAL             | 🟠 Alto    | 2    | FRONTEND   |
| [TASK-062](tasks/TASK-062.md) | Classificador de motivos de recusa Asaas + roteamento por bucket           | 🟠 Alto    | 2    | BACKEND    |
| [TASK-063](tasks/TASK-063.md) | Job de reconciliação noturna: Asaas vs estado local                        | 🟠 Alto    | 2    | BACKEND    |
| [TASK-064](tasks/TASK-064.md) | Hardening de webhook Asaas: DLQ + replay manual                            | 🟠 Alto    | 2    | BACKEND    |
| [TASK-065](tasks/TASK-065.md) | Frontend: tela "Atualizar método de pagamento" para subscriptions PAST_DUE | 🟠 Alto    | 2    | FRONTEND   |
| [TASK-066](tasks/TASK-066.md) | Implementar Pix Automático (mandato no banco do payer)                     | 🟡 Médio   | 3    | FULL_STACK |
| [TASK-109](tasks/TASK-109.md) | Full-Stack: Troca de método de pagamento em ACTIVE (CC→PIX, CC→CC, PIX→CC) | 🟡 Médio   | 3    | FULL_STACK |

---

## 📊 EPIC-011 — Dashboard Unificado e Relatórios Cross-Org (`/me/reports`)

> Adicionado em 12/06/2026 — nova área no sidenav (/me) que consolida dados de todas as empresas do usuário autenticado sem quebrar contratos existentes. Inclui dashboard de KPIs unificado por org e gerador de relatórios com exportação CSV. Backend usa `user_organizations` para determinar orgs autorizadas — sem X-Org-Id.

| ID       | Título                                                                          | Prioridade | Fase | Tipo       |
|----------|---------------------------------------------------------------------------------|------------|------|------------|
| TASK-081 | Backend: GET /me/reports/overview — KPIs consolidados + breakdown por org       | 🟠 Alto    | 3    | BACKEND    |
| TASK-082 | Backend: GET /me/reports/maintenances — listagem paginada cross-org com filtros | 🟠 Alto    | 3    | BACKEND    |
| TASK-083 | Backend: GET /me/reports/maintenances/export — CSV consolidado cross-org        | 🟡 Médio   | 3    | BACKEND    |
| TASK-084 | Frontend: estrutura da página /me/reports + entrada no sidenav                  | 🟠 Alto    | 3    | FRONTEND   |
| TASK-085 | Frontend: Dashboard Unificado — KPIs globais + grid de cards por empresa        | 🟠 Alto    | 3    | FRONTEND   |
| TASK-086 | Frontend: Seção de Relatórios — filtros, tabela paginada e exportação CSV       | 🟡 Médio   | 3    | FRONTEND   |

---

## 👥 EPIC-013 — Gestão de Usuários por Organização

> Adicionado em 28/06/2026 — dono ADMIN gerencia uma equipe de membros (READER/VIEWER) que ajudam a operar suas organizações. Multi-org assignment no convite. `maxUsers` do plano do dono. Novos endpoints: `GET/POST/PATCH/DELETE /me/team/users`. Frontend: "Usuários" no UserTopBar, listagem `/users` com orgs por membro, `/users/new` com multi-select de orgs, `/users/[id]/edit` com gestão de orgs.

| ID                                            | Título                                                              | Prioridade | Fase | Tipo        |
|-----------------------------------------------|---------------------------------------------------------------------|------------|------|-------------|
| [TASK-098](tasks/TASK-098.md)                 | Backend: guard ADMIN + invitation email + DELETE endpoint           | 🔴 Crítico | 3    | BACKEND     |
| ~~[TASK-099](tasks/TASK-099.md)~~             | ~~Frontend: "Usuários" no UserTopBar dropdown (ADMIN only)~~        | 🟠 Alto    | 3    | FRONTEND    |
| ~~[TASK-100](tasks/TASK-100.md)~~             | ~~Frontend: `/users` — listagem de usuários da org com CRUD actions~~ | 🟠 Alto    | 3    | FRONTEND    |
| ~~[TASK-101](tasks/TASK-101.md)~~             | ~~Frontend: reescrever `/users/new` — convite por e-mail + org select~~ | 🔴 Crítico | 3    | FRONTEND    |
| ~~[TASK-102](tasks/TASK-102.md)~~             | ~~Frontend: `/users/[id]/edit` — edição + desativação de usuário~~  | 🟠 Alto    | 3    | FRONTEND    |
| [TASK-QA-MAN-009](QA/tasks/TASK-QA-MAN-009.md) | QA Manual: E2E fluxo completo de convite e gestão de usuários     | 🟠 Alto    | 3    | QA          |

---

## 💳 EPIC-014 — Consolidação de Billing: Plano Único por Conta

> Adicionado em 12/07/2026 — hoje o sistema cobra um item de assinatura por USER + um item por cada
> ORGANIZATION, ambos somados na mesma fatura (ex.: onboarding cria USER BUSINESS R$299 + ORGANIZATION
> BUSINESS R$299 = R$598/mês num cadastro novo). Isso contraria o desenho original da grade de planos
> (TASK-053), onde "Organizações" e "Itens/Org" já são limites embutidos no mesmo tier, não produtos
> separados. Decisão validada com Douglas (12/07/2026): consolidar para 1 plano por conta, organizações
> incluídas até o limite do plano, `maxItems` vira pool compartilhado entre todas as organizações do
> usuário (não mais por organização isolada). Sem clientes pagantes reais hoje — migração limpa, sem
> grandfathering.

| ID                             | Título                                                                          | Prioridade | Fase | Tipo       |
|---------------------------------|----------------------------------------------------------------------------------|------------|------|------------|
| [TASK-110](tasks/TASK-110.md)  | Backend: parar de criar item ORGANIZATION cobrável (Onboarding + addOrganizationSubscription) | 🔴 Crítico | 1    | BACKEND    |
| [TASK-111](tasks/TASK-111.md)  | Backend: pool compartilhado de maxItems entre organizações do owner              | 🔴 Crítico | 1    | BACKEND    |
| [TASK-112](tasks/TASK-112.md)  | Backend: downgrade valida pool de itens + depreciar OrganizationPlanChangeService | 🟠 Alto    | 1    | BACKEND    |
| [TASK-113](tasks/TASK-113.md)  | Backend: compat GET /organizations/{code}/subscription (plano da conta + uso do pool) | 🟠 Alto    | 1    | BACKEND    |
| [TASK-114](tasks/TASK-114.md)  | Backend/Infra: migration Flyway — limpar billing_subscription_items ORGANIZATION legados | 🟠 Alto    | 1    | INFRA      |
| [TASK-115](tasks/TASK-115.md)  | Frontend: /billing — card único de conta + lista informativa de organizações     | 🟠 Alto    | 1    | FRONTEND   |
| [TASK-116](tasks/TASK-116.md)  | Frontend: painel admin billing/subscriptions — mesma consolidação                | 🟡 Médio   | 1    | FRONTEND   |
| [TASK-117](tasks/TASK-117.md)  | QA: E2E fluxo completo billing consolidado                                       | 🔴 Crítico | 1    | QA         |
| [TASK-118](tasks/TASK-118.md)  | BUGFIX: /organizations/new ainda pedia plano próprio para a organização          | 🔴 Crítico | 1    | FULL_STACK |
| [TASK-119](tasks/TASK-119.md)  | BUGFIX: /organizations/[code] ainda exibia card de Assinatura e Plano + edição inline | 🟠 Alto | 1  | FRONTEND   |
| [TASK-120](tasks/TASK-120.md)  | BUGFIX: TenantFilterAspect zerava contagem cross-org (afetava pool real da TASK-111) | 🔴 Crítico | 1 | BACKEND |
| [TASK-121](tasks/TASK-121.md)  | BUGFIX: botão "+ Novo Item" não bloqueava proativamente com pool esgotado | 🔴 Crítico | 1 | FULL_STACK |
