# Kanban — Easy Maintenance

> Atualizado em: 12/04/2026 — SPRINT-01, SPRINT-02 e SPRINT-06 concluídas; SPRINT-03 parcial (4/6); SPRINT-04 parcial (2/5); SPRINT-05 não iniciada
> Sprints concluídas: 1, 2 e 6 | EPIC-009 e EPIC-010 completos | 12 tasks pendentes

---

## Legenda de Prioridade
🔴 Crítico | 🟠 Alto | 🟡 Médio | 🔵 Baixo

---

## Backlog

| ID | Título | Prioridade | Épico | Fase |
|----|--------|-----------|-------|------|
| ~~TASK-001~~ | ~~Persistir chaves RSA JWT~~ | 🔴 Crítico | EPIC-001 | 1 |
| ~~TASK-002~~ | ~~Migrar JWT de localStorage para cookie HttpOnly~~ | 🔴 Crítico | EPIC-001 | 1 |
| ~~TASK-003~~ | ~~Implementar ShedLock nos jobs agendados~~ | 🔴 Crítico | EPIC-002 | 1 |
| ~~TASK-004~~ | ~~Testes mínimos para billing e tenant isolation~~ | 🔴 Crítico | EPIC-008 | 1 |
| ~~TASK-005~~ | ~~Desabilitar Swagger/OpenAPI em produção~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-006~~ | ~~Rate limiting em auth, reset e IA~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-007~~ | ~~Validação robusta de webhook Asaas~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-008~~ | ~~Circuit breaker para serviços externos~~ | 🟠 Alto | EPIC-002 | 1 |
| ~~TASK-009~~ | ~~Validar X-Org-Id contra claims do JWT~~ | 🟠 Alto | EPIC-003 | 1 |
| ~~TASK-010~~ | ~~Auditar e rotacionar secrets no repositório~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-011~~ | ~~Restringir endpoints do Actuator em produção~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-012~~ | ~~Verificar e corrigir profile de e-mail em produção~~ | 🟠 Alto | EPIC-002 | 1 |
| ~~TASK-013~~ | ~~Adicionar security headers HTTP~~ | 🟠 Alto | EPIC-001 | 1 |
| ~~TASK-014~~ | ~~Restrição CORS para domínio de produção~~ | 🟠 Alto | EPIC-003 | 1 |
| ~~TASK-015~~ | ~~Banner de trial expirando no dashboard~~ | 🟠 Alto | EPIC-006 | 1 |
| ~~TASK-016~~ | ~~Tratamento de erro claro no onboarding~~ | 🟠 Alto | EPIC-006 | 1 |
| ~~TASK-017~~ | ~~Enforcement automático de tenant no repository~~ | 🟡 Médio | EPIC-003 | 1 |
| ~~TASK-018~~ | ~~Soft delete nas entidades críticas~~ | 🟡 Médio | EPIC-004 | 2 |
| ~~TASK-019~~ | ~~Índices ausentes no banco de dados~~ | 🟡 Médio | EPIC-004 | 2 |
| ~~TASK-020~~ | ~~Schema formal para features JSON em billing_plans~~ | 🟡 Médio | EPIC-004 | 2 |
| TASK-021 | Alertas no Prometheus/Grafana | 🟡 Médio | EPIC-005 | 2 |
| ~~TASK-022~~ | ~~Sentry em backend e frontend~~ | 🟡 Médio | EPIC-005 | 2 |
| ~~TASK-023~~ | ~~Indicador de uso vs limite de plano no frontend~~ | 🟡 Médio | EPIC-006 | 2 |
| ~~TASK-024~~ | ~~Exportação de relatórios PDF/Excel~~ | 🟡 Médio | EPIC-006 | 2 |
| TASK-025 | Fila/retry para envio de e-mails | 🟡 Médio | EPIC-002 | 2 |
| TASK-026 | Testes de integração — billing e auth completos | 🟡 Médio | EPIC-008 | 2 |
| TASK-027 | Pre-signed URLs S3 para uploads diretos | 🟡 Médio | EPIC-007 | 2 |
| TASK-028 | Processamento assíncrono de chamadas IA | 🟡 Médio | EPIC-007 | 2 |
| ~~TASK-029~~ | ~~Runbook de incidentes e operação~~ | 🟡 Médio | EPIC-005 | 2 |
| ~~TASK-030~~ | ~~Tela de comparação de planos (upgrade page)~~ | 🟡 Médio | EPIC-006 | 2 |
| ~~TASK-031~~ | ~~Notificações in-app (lista no header)~~ | 🔵 Baixo | EPIC-006 | 2 |
| ~~TASK-032~~ | ~~Tour guiado pós-onboarding~~ | 🔵 Baixo | EPIC-006 | 2 |
| TASK-033 | Status page básica | 🔵 Baixo | EPIC-005 | 2 |
| ~~TASK-034~~ | ~~Central de ajuda / FAQ in-app~~ | 🔵 Baixo | EPIC-006 | 2 |
| TASK-035 | Política de retenção para audit_logs | 🔵 Baixo | EPIC-004 | 2 |
| TASK-036 | Paginação cursor-based em listagens grandes | 🔵 Baixo | EPIC-007 | 3 |
| TASK-037 | Jobs de billing assíncronos com fila | 🔵 Baixo | EPIC-007 | 3 |
| TASK-038 | LGPD: exportação e exclusão de dados pessoais | 🔵 Baixo | EPIC-003 | 3 |
| TASK-039 | Autenticação 2FA | 🔵 Baixo | EPIC-001 | 3 |
| TASK-040 | Acessibilidade básica (WCAG AA) | 🔵 Baixo | EPIC-006 | 3 |
| ~~TASK-041~~ | ~~Configurar defaults globais do React Query~~ | 🟠 Alto | EPIC-009 | 2 |
| ~~TASK-042~~ | ~~Adicionar loading.tsx nas rotas principais~~ | 🟠 Alto | EPIC-009 | 2 |
| ~~TASK-043~~ | ~~Migrar useDashboardData para useQuery~~ | 🟡 Médio | EPIC-009 | 2 |
| ~~TASK-044~~ | ~~Eliminar N+1 de permissões na página de itens~~ | 🟡 Médio | EPIC-009 | 2 |
| ~~TASK-045~~ | ~~Criar middleware.ts para guards de autenticação~~ | 🟡 Médio | EPIC-009 | 2 |
| ~~TASK-046~~ | ~~PIX: popular QR Code e expiração nas cobranças recorrentes~~ | 🔴 Crítico | EPIC-010 | 2 |
| ~~TASK-047~~ | ~~PIX: e-mail de lembrete no PAYMENT_OVERDUE~~ | 🟠 Alto | EPIC-010 | 2 |
| ~~TASK-048~~ | ~~PIX: exibir QR Code pendente na página de billing~~ | 🔴 Crítico | EPIC-010 | 2 |

---

## ~~Sprint 1 — Concluída~~ (ver [SPRINT-01.md](sprints/SPRINT-01.md))

## ~~Sprint 2 — Concluída~~ (ver [SPRINT-02.md](sprints/SPRINT-02.md))

---

## ~~Sprint 6 — Concluída~~ (ver [SPRINT-06.md](sprints/SPRINT-06.md))

---

## Situação das Sprints

| Sprint | Foco | Status | Concluídas | Pendentes |
|--------|------|--------|-----------|-----------|
| ~~[SPRINT-03](sprints/SPRINT-03.md)~~ | Integridade de Dados + Estabilidade | Parcial 4/6 | TASK-017, 018, 019, 020 | TASK-025, TASK-026 |
| [SPRINT-04](sprints/SPRINT-04.md) | Observabilidade + Performance | Parcial 2/5 | TASK-022, TASK-029 | TASK-021, TASK-027, TASK-028 |
| [SPRINT-05](sprints/SPRINT-05.md) | Escalabilidade + Compliance + Polimento | Não iniciada 0/7 | — | TASK-033, 035, 036, 037, 038, 039, 040 |

---

## Pronto para Implementar

**Pendentes de SPRINT-03** (fechar sprint antes de avançar):
- **TASK-025** — Fila/retry para envio de e-mails (🟡 Médio | EPIC-002)
- **TASK-026** — Testes de integração — billing e auth completos (🟡 Médio | EPIC-008)

**Pendentes de SPRINT-04**:
- **TASK-021** — Alertas no Prometheus/Grafana (🟡 Médio | EPIC-005)
- **TASK-027** — Pre-signed URLs S3 para uploads diretos (🟡 Médio | EPIC-007)
- **TASK-028** — Processamento assíncrono de chamadas IA (🟡 Médio | EPIC-007)

---

## Em Execução

_Vazio_

---

## Em Validação

_Vazio_

---

## Concluído

| ID | Título | Prioridade | Épico |
|----|--------|-----------|-------|
| TASK-001 | Persistir chaves RSA JWT | 🔴 Crítico | EPIC-001 |
| TASK-003 | Implementar ShedLock nos jobs agendados | 🔴 Crítico | EPIC-002 |
| TASK-005 | Desabilitar Swagger/OpenAPI em produção | 🟠 Alto | EPIC-001 |
| TASK-009 | Validar X-Org-Id contra claims do JWT | 🟠 Alto | EPIC-003 |
| TASK-011 | Restringir endpoints do Actuator em produção | 🟠 Alto | EPIC-001 |
| TASK-013 | Adicionar security headers HTTP | 🟠 Alto | EPIC-001 |
| TASK-010 | Auditar e rotacionar secrets no repositório | 🟠 Alto | EPIC-001 |
| TASK-012 | Verificar e corrigir profile de e-mail em produção | 🟠 Alto | EPIC-002 |
| TASK-006 | Rate limiting em auth, reset e IA | 🟠 Alto | EPIC-001 |
| TASK-014 | Restrição CORS para domínio de produção | 🟠 Alto | EPIC-003 |
| TASK-007 | Validação robusta de webhook Asaas | 🟠 Alto | EPIC-001 |
| TASK-002 | Migrar JWT de localStorage para cookie HttpOnly | 🔴 Crítico | EPIC-001 |
| TASK-004 | Testes mínimos para billing e tenant isolation | 🔴 Crítico | EPIC-008 |
| TASK-008 | Circuit breaker para serviços externos | 🟠 Alto | EPIC-002 |
| TASK-015 | Banner de trial expirando no dashboard | 🟠 Alto | EPIC-006 |
| TASK-016 | Tratamento de erro claro no onboarding | 🟠 Alto | EPIC-006 |
| TASK-017 | Enforcement automático de tenant no repository | 🟡 Médio | EPIC-003 |
| TASK-023 | Indicador de uso vs limite de plano no frontend | 🟡 Médio | EPIC-006 |
| TASK-024 | Exportação de relatórios PDF/Excel | 🟡 Médio | EPIC-006 |
| TASK-030 | Tela de comparação de planos (upgrade page) | 🟡 Médio | EPIC-006 |
| TASK-031 | Notificações in-app (lista no header) | 🔵 Baixo | EPIC-006 |
| TASK-032 | Tour guiado pós-onboarding | 🔵 Baixo | EPIC-006 |
| TASK-034 | Central de ajuda / FAQ in-app | 🔵 Baixo | EPIC-006 |
| TASK-019 | Índices ausentes no banco de dados | 🟡 Médio | EPIC-004 |
| TASK-041 | Configurar defaults globais do React Query | 🟠 Alto | EPIC-009 |
| TASK-042 | Adicionar loading.tsx nas rotas principais | 🟠 Alto | EPIC-009 |
| TASK-043 | Migrar useDashboardData para useQuery | 🟡 Médio | EPIC-009 |
| TASK-044 | Eliminar N+1 de permissões na página de itens | 🟡 Médio | EPIC-009 |
| TASK-045 | Criar middleware.ts para guards de autenticação | 🟡 Médio | EPIC-009 |
| TASK-022 | Sentry em backend e frontend | 🟡 Médio | EPIC-005 |
| TASK-018 | Soft delete nas entidades críticas | 🟡 Médio | EPIC-004 |
| TASK-020 | Schema formal para features JSON em billing_plans | 🟡 Médio | EPIC-004 |
| TASK-029 | Runbook de incidentes e operação | 🟡 Médio | EPIC-005 |
| TASK-046 | PIX: popular QR Code e expiração nas cobranças recorrentes | 🔴 Crítico | EPIC-010 |
| TASK-047 | PIX: e-mail de lembrete no PAYMENT_OVERDUE | 🟠 Alto | EPIC-010 |
| TASK-048 | PIX: exibir QR Code pendente na página de billing | 🔴 Crítico | EPIC-010 |
