# Backlog Completo — Easy Maintenance

> Atualizado em: 10/04/2026
> Total de tasks: 45
> Tasks na Sprint 1: 11 (+ 2 em análise)

---

## Como ler este backlog

- Cada linha referencia um arquivo em `/roadmap/tasks/TASK-XXX.md`
- As tasks estão organizadas por épico e dentro de cada épico por prioridade
- O campo **Fase** indica quando a task deve ser executada: 1 = antes do lançamento, 2 = pós-lançamento, 3 = escala

---

## EPIC-001 — Segurança Crítica

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-001 | Persistir chaves RSA JWT | 🔴 Crítico | 1 | Pequeno | S01 |
| TASK-002 | Migrar JWT de localStorage para cookie HttpOnly | 🔴 Crítico | 1 | Médio | S01* |
| TASK-005 | Desabilitar Swagger/OpenAPI em produção | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-006 | Rate limiting em auth, reset e IA | 🟠 Alto | 1 | Médio | S01 |
| TASK-007 | Validação robusta de webhook Asaas | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-010 | Auditar e rotacionar secrets no repositório | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-011 | Restringir endpoints do Actuator em produção | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-013 | Adicionar security headers HTTP | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-039 | Autenticação 2FA | 🔵 Baixo | 3 | Grande | — |

> *TASK-002 está em análise técnica — requer mudanças coordenadas em backend e frontend

---

## EPIC-002 — Confiabilidade Operacional

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-003 | Implementar ShedLock nos jobs agendados | 🔴 Crítico | 1 | Pequeno | S01 |
| TASK-008 | Circuit breaker para serviços externos | 🟠 Alto | 1 | Médio | S02 |
| TASK-012 | Verificar e corrigir profile de e-mail em produção | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-025 | Fila/retry para envio de e-mails | 🟡 Médio | 2 | Médio | — |

---

## EPIC-003 — Multi-tenancy e Autorização

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-009 | Validar X-Org-Id contra claims do JWT | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-014 | Restricão CORS para domínio de produção | 🟠 Alto | 1 | Pequeno | S01 |
| TASK-017 | Enforcement automático de tenant no repository | 🟡 Médio | 1 | Médio | S02 |
| TASK-038 | LGPD: exportação e exclusão de dados pessoais | 🔵 Baixo | 3 | Grande | — |

---

## EPIC-004 — Banco de Dados e Persistência

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-018 | Soft delete nas entidades críticas | 🟡 Médio | 2 | Médio | — |
| TASK-019 | Índices ausentes no banco de dados | 🟡 Médio | 2 | Pequeno | — |
| TASK-020 | Schema formal para features JSON em billing_plans | 🟡 Médio | 2 | Médio | — |
| TASK-035 | Política de retenção para audit_logs | 🔵 Baixo | 2 | Pequeno | — |

---

## EPIC-005 — Observabilidade e Operação

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-021 | Alertas no Prometheus/Grafana | 🟡 Médio | 2 | Médio | — |
| TASK-022 | Sentry em backend e frontend | 🟡 Médio | 2 | Pequeno | — |
| TASK-029 | Runbook de incidentes e operação | 🟡 Médio | 2 | Pequeno | — |
| TASK-033 | Status page básica | 🔵 Baixo | 2 | Pequeno | — |

---

## EPIC-006 — Produto SaaS

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-015 | Banner de trial expirando no dashboard | 🟠 Alto | 1 | Pequeno | S01* |
| TASK-016 | Tratamento de erro claro no onboarding | 🟠 Alto | 1 | Pequeno | S01* |
| TASK-023 | Indicador de uso vs limite de plano | 🟡 Médio | 2 | Médio | — |
| TASK-024 | Exportação de relatórios PDF/Excel | 🟡 Médio | 2 | Grande | — |
| TASK-030 | Tela de comparação de planos (upgrade page) | 🟡 Médio | 2 | Médio | — |
| TASK-031 | Notificações in-app (lista no header) | 🔵 Baixo | 2 | Médio | — |
| TASK-032 | Tour guiado pós-onboarding | 🔵 Baixo | 2 | Médio | — |
| TASK-034 | Central de ajuda / FAQ in-app | 🔵 Baixo | 2 | Médio | — |
| TASK-040 | Acessibilidade básica (WCAG AA) | 🔵 Baixo | 3 | Grande | — |

> *TASK-015 e TASK-016 são pequenas mas importantes para produto — incluídas em S01 como low hanging fruit

---

## EPIC-007 — Performance e Escalabilidade

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-027 | Pre-signed URLs S3 para uploads diretos | 🟡 Médio | 2 | Médio | — |
| TASK-028 | Processamento assíncrono de chamadas IA | 🟡 Médio | 2 | Grande | — |
| TASK-036 | Paginação cursor-based em listagens grandes | 🔵 Baixo | 3 | Médio | — |
| TASK-037 | Jobs de billing assíncronos com fila | 🔵 Baixo | 3 | Grande | — |

---

## EPIC-008 — Qualidade e Testes

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-004 | Testes mínimos para billing e tenant isolation | 🔴 Crítico | 1 | Grande | S01* |
| TASK-026 | Testes de integração — billing e auth completos | 🟡 Médio | 2 | Grande | — |

> *TASK-004 está em análise — definir escopo mínimo antes de executar

---

## EPIC-009 — Performance Frontend

| ID | Título | Prioridade | Fase | Esforço | Sprint |
|----|--------|-----------|------|---------|--------|
| TASK-041 | Configurar defaults globais do React Query | 🟠 Alto | 2 | Pequeno | — |
| TASK-042 | Adicionar loading.tsx nas rotas principais | 🟠 Alto | 2 | Pequeno | — |
| TASK-043 | Migrar useDashboardData para useQuery | 🟡 Médio | 2 | Pequeno | — |
| TASK-044 | Eliminar N+1 de permissões na página de itens | 🟡 Médio | 2 | Médio | — |
| TASK-045 | Criar middleware.ts para guards de autenticação | 🟡 Médio | 2 | Médio | — |

---

## Resumo por Fase

| Fase | Crítico | Alto | Médio | Baixo | Total |
|------|---------|------|-------|-------|-------|
| Fase 1 | 4 | 10 | 1 | 0 | 15 |
| Fase 2 | 0 | 2 | 16 | 7 | 25 |
| Fase 3 | 0 | 0 | 0 | 5 | 5 |
| **Total** | **4** | **12** | **17** | **12** | **45** |
