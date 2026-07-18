# Kanban — Easy Maintenance

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
| [TASK-122](tasks/TASK-122.md) | Full-Stack: implementar canal de notificações via WhatsApp (provider existe só como esqueleto, sem integração real) | 🟡 Médio | EPIC-006 | 2 |

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
| [TASK-088](tasks/TASK-088.md) | Compliance e governança do catálogo de normas: curated-first IA, pendingReview + fix V9 period_qty=0 | 🟠 Alto    | EPIC-004 |
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
