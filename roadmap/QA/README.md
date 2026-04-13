# QA — Easy Maintenance

> Atualizado em: 12/04/2026
> Gerado a partir do QA Execution Report pós SPRINT-06

---

## Estrutura

```
QA/
├── README.md          ← este arquivo (índice geral)
├── Flow/              ← mapeamento de fluxos por criticidade
├── MTD/               ← documentos de teste manual (Manual Test Documents)
└── tasks/             ← tasks de QA (manuais e automatizadas)
```

---

## Resumo do Escopo

| Sprints avaliadas | Tasks concluídas | Módulos cobertos |
|------------------|------------------|-----------------|
| SPRINT-01, 02, 03 (parcial), 04 (parcial), 06 | 36 tasks | Auth, Multi-tenant, Billing, PIX, Onboarding, Trial, Segurança HTTP, Jobs, Frontend |

---

## Flows Mapeados

| ID | Flow | Criticidade |
|----|------|------------|
| [FLOW-001](Flow/FLOW-001.md) | Autenticação e Sessão | CRITICAL |
| [FLOW-002](Flow/FLOW-002.md) | Isolamento Multi-Tenant | CRITICAL |
| [FLOW-003](Flow/FLOW-003.md) | PIX End-to-End Recorrente | CRITICAL |
| [FLOW-004](Flow/FLOW-004.md) | Onboarding | CRITICAL |
| [FLOW-005](Flow/FLOW-005.md) | Trial Lifecycle e Conversão | HIGH |
| [FLOW-006](Flow/FLOW-006.md) | Webhook Asaas e Idempotência | HIGH |
| [FLOW-007](Flow/FLOW-007.md) | Segurança HTTP e Headers | HIGH |
| [FLOW-008](Flow/FLOW-008.md) | Jobs Agendados com ShedLock | HIGH |
| [FLOW-009](Flow/FLOW-009.md) | Soft Delete e Histórico Regulatório | MEDIUM |
| [FLOW-010](Flow/FLOW-010.md) | Performance Frontend e Cache | MEDIUM |
| [FLOW-011](Flow/FLOW-011.md) | Funcionalidades SaaS | MEDIUM |

---

## Manual Test Documents (MTD)

| ID | Documento | Flow relacionado |
|----|-----------|-----------------|
| [MTD-001](MTD/MTD-001.md) | Autenticação com cookie HttpOnly | FLOW-001 |
| [MTD-002](MTD/MTD-002.md) | Isolamento Multi-Tenant via X-Org-Id | FLOW-002 |
| [MTD-003](MTD/MTD-003.md) | PIX End-to-End com sandbox Asaas | FLOW-003 |
| [MTD-004](MTD/MTD-004.md) | Onboarding com cenários de erro | FLOW-004 |
| [MTD-005](MTD/MTD-005.md) | Trial banner e indicador de uso | FLOW-005 |
| [MTD-006](MTD/MTD-006.md) | Security headers e rate limiting | FLOW-007 |
| [MTD-007](MTD/MTD-007.md) | Soft delete e integridade de dados | FLOW-009 |
| [MTD-008](MTD/MTD-008.md) | Performance frontend e cache React Query | FLOW-010 |

---

## Tasks de QA

### Manuais

| ID | Título | Prioridade |
|----|--------|-----------|
| [TASK-QA-MAN-001](tasks/TASK-QA-MAN-001.md) | Validação manual do fluxo de autenticação com cookie HttpOnly | 🔴 Crítico |
| [TASK-QA-MAN-002](tasks/TASK-QA-MAN-002.md) | Teste de isolamento multi-tenant com X-Org-Id manipulado | 🔴 Crítico |
| [TASK-QA-MAN-003](tasks/TASK-QA-MAN-003.md) | Teste E2E do fluxo PIX com sandbox Asaas | 🔴 Crítico |
| [TASK-QA-MAN-004](tasks/TASK-QA-MAN-004.md) | Validação do onboarding em cenários de erro | 🟠 Alto |
| [TASK-QA-MAN-005](tasks/TASK-QA-MAN-005.md) | Validação de security headers e rate limiting em produção | 🟠 Alto |
| [TASK-QA-MAN-006](tasks/TASK-QA-MAN-006.md) | Validação do banner de trial e indicador de uso de plano | 🟠 Alto |
| [TASK-QA-MAN-007](tasks/TASK-QA-MAN-007.md) | Validação de soft delete e integridade de histórico | 🟡 Médio |

### Automatizadas

| ID | Título | Tipo | Prioridade |
|----|--------|------|-----------|
| [TASK-QA-AUTO-001](tasks/TASK-QA-AUTO-001.md) | Testes de integração — isolamento multi-tenant via MockMvc | Integração | 🔴 Crítico |
| [TASK-QA-AUTO-002](tasks/TASK-QA-AUTO-002.md) | Testes unitários — handler PIX e PAYMENT_OVERDUE borda | Unitário | 🟠 Alto |
| [TASK-QA-AUTO-003](tasks/TASK-QA-AUTO-003.md) | Testes de integração — rate limiting nos endpoints de autenticação | Integração | 🟠 Alto |
| [TASK-QA-AUTO-004](tasks/TASK-QA-AUTO-004.md) | Testes de integração — webhook Asaas idempotência e token | Integração | 🟠 Alto |
| [TASK-QA-AUTO-005](tasks/TASK-QA-AUTO-005.md) | Testes de integração — soft delete e filtro automático | Integração | 🟡 Médio |
| [TASK-QA-AUTO-006](tasks/TASK-QA-AUTO-006.md) | Testes E2E — performance React Query sem requisições redundantes | E2E | 🟡 Médio |

---

## Gaps de Cobertura

| Área | Gap | Risco |
|------|-----|-------|
| Jobs agendados (ShedLock) | Sem teste automatizado de lock em múltiplas instâncias | ALTO |
| PIX — pagamentos múltiplos pendentes | Comportamento com 2+ PENDING não coberto | MÉDIO |
| Circuit breaker (TASK-008) | Sem teste automatizado de OPEN/CLOSED | MÉDIO |
| E-mail produção (TASK-012) | Sem monitoramento contínuo de entrega | ALTO |
| Exportação PDF/Excel | Sem teste automatizado do formato do arquivo | MÉDIO |
| Notificações in-app | Zero testes identificados | MÉDIO |
| CORS em produção | Sem teste automatizado de origem bloqueada | MÉDIO |

---

## Riscos de Launch

| Risco | Severidade | Ação |
|-------|-----------|------|
| RSA keys não configuradas no Railway | CRÍTICO | Verificar env vars antes do launch |
| ShedLock sem validação em staging | ALTO | Subir 2 instâncias em staging |
| E-mail de trial/cobrança sem retry (TASK-025 pendente) | ALTO | Monitorar MailerSend dashboard |
| TASK-026 pendente — sem testes de integração billing | MÉDIO | Priorizar imediatamente pós-launch |
