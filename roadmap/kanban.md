# Kanban — Easy Maintenance

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

| ID                                              | Título                                                                                                                           | Prioridade | Épico    | Severidade |
|-------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|------------|----------|------------|
| TASK-QA-BUG-005                                 | Erro ao cadastrar dados de faturamento — PUT .../billing/users/22/account retorna 422 (planCode/paymentMethod/name não enviados) | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-055](tasks/TASK-055.md)                   | Sessão do usuário sem organização é apagada após login                                                                           | 🔴 Crítico | EPIC-006 | GRAVE      |
| [TASK-QA-BUG-001](QA/tasks/TASK-QA-BUG-001.md) | Onboarding sem redirect e sem dados da organização após conclusão                                                                | 🟠 Alto    | EPIC-006 | GRAVE      |

## 🐛 Bugs — Concluídos

| ID                                             | Título                                                                                             | Prioridade | Épico    | Severidade |
|------------------------------------------------|----------------------------------------------------------------------------------------------------|------------|----------|------------|
| TASK-QA-BUG-006                                  | Erro ao cadastrar nova empresa — paymentMethod obrigatório + orElseGet + pre-populate name/billingEmail do User | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-QA-BUG-004](QA/tasks/TASK-QA-BUG-004.md) | Step 2 cadastro org — PUT organizations/{code}/subscription retorna 500 (rota backend inexistente) | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-QA-BUG-003](QA/tasks/TASK-QA-BUG-003.md) | Criação de organização via admin falha com 422 — campo companyType nulo                            | 🟠 Alto    | EPIC-006 | ALTA       |
| [TASK-056](tasks/TASK-056.md)                  | Recriar rota GET /organizations/{code}/subscription                                                | 🔴 Crítico | EPIC-006 | ALTA       |
| [TASK-052](tasks/TASK-052.md)                  | E-mail de convite de admin não entra na fila de retry                                              | 🟠 Alto    | EPIC-002 | ALTA       |

## 🐛 Bugs — Backlog

_Vazio_

---

---

## Backlog

| ID                   | Título                                                                  | Prioridade | Épico    | Fase |
|----------------------|-------------------------------------------------------------------------|------------|----------|------|
| ~~TASK-001~~         | ~~Persistir chaves RSA JWT~~                                            | 🔴 Crítico | EPIC-001 | 1    |
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
| TASK-038             | LGPD: exportação e exclusão de dados pessoais                           | 🔵 Baixo   | EPIC-003 | 3    |
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
- ~~**TASK-068**~~ — Enriquecer response de notificações com nome do item referenciado (🟡 Médio | EPIC-006)

**Pendentes de SPRINT-04**:
- **TASK-021** — Alertas no Prometheus/Grafana (🟡 Médio | EPIC-005)

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
| [TASK-058](tasks/TASK-058.md) | Refatorar job de expiração de TRIAL: PIX via cobrança avulsa (DETACHED)         | 🔴 Crítico | EPIC-010 |
| [TASK-059](tasks/TASK-059.md) | Subscription PIX recorrente "manual": ciclo gerenciado internamente             | 🔴 Crítico | EPIC-010 |
| [TASK-060](tasks/TASK-060.md) | Webhook PAYMENT_RECEIVED avança ciclo PIX manual                                | 🔴 Crítico | EPIC-010 |
| [TASK-061](tasks/TASK-061.md) | UX: seleção de método de pagamento antes do fim do TRIAL                        | 🟠 Alto    | EPIC-010 |
| [TASK-062](tasks/TASK-062.md) | Classificador de motivos de recusa Asaas + roteamento por bucket                | 🟠 Alto    | EPIC-010 |
| [TASK-063](tasks/TASK-063.md) | Job de reconciliação noturna: Asaas vs estado local                             | 🟠 Alto    | EPIC-010 |
| [TASK-064](tasks/TASK-064.md) | Hardening de webhook Asaas: DLQ + replay manual                                 | 🟠 Alto    | EPIC-010 |
| [TASK-065](tasks/TASK-065.md) | Frontend: tela "Atualizar método de pagamento" para subscriptions PAST_DUE      | 🟠 Alto    | EPIC-010 |
| TASK-QA-AUTO-002              | Testes unitários: handler PIX e PAYMENT_OVERDUE (casos de borda)                | 🟠 Alto    | EPIC-010 |
| TASK-QA-AUTO-003              | Testes de integração: rate limiting nos endpoints de autenticação (@WebMvcTest) | 🟠 Alto    | EPIC-001 |
| TASK-E2E-001                  | Setup do projeto Playwright E2E (`easy-maintenance-e2e`)                        | 🟠 Alto    | EPIC-008 |
| TASK-E2E-003                  | Testes E2E: Webhook Asaas — token e idempotência                                | 🟠 Alto    | EPIC-001 |
| TASK-072                      | Exibir link de comprovante nas faturas pagas da tela /billing                    | 🟡 Médio   | EPIC-006 |
| TASK-069                      | Criar busca para usuários — filtros nome/e-mail na tela /private/users           | 🟡 Médio   | EPIC-006 |

---

## Concluído

| ID                            | Título                                                                          | Prioridade | Épico        |
|-------------------------------|---------------------------------------------------------------------------------|------------|--------------|
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
