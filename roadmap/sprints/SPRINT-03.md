# SPRINT-03 — Integridade de Dados + Estabilidade

> **Período:** Semana 6–8 (estimado)
> **Objetivo:** Preparar o banco de dados e as integrações para crescimento com segurança — sem dados perdidos, sem queries lentas, sem e-mails falhando silenciosamente
> **Capacidade estimada:** 6 tasks
> **Critério de saída:** Soft delete em entidades críticas, índices críticos adicionados, e-mails com retry, testes de integração cobrindo billing e auth

---

## Meta da Sprint

> "Ao final desta sprint, o banco está preparado para os primeiros 12 meses de crescimento, nenhum e-mail crítico se perde silenciosamente, e temos confiança automatizada no billing e no isolamento de tenants."

---

## Tasks da Sprint

---

### 🟡 TASK-017 — Enforcement automático de tenant no repository
**Arquivo:** [TASK-017.md](../tasks/TASK-017.md)
**Épico:** EPIC-003 — Multi-tenant

**Objetivo nesta sprint:** Garantir que nenhuma query acidental cruze tenants, mesmo sem filtro explícito.

**Por que está na Sprint 3:**
Complementa a TASK-009 (IDOR no header) com proteção em nível de repositório — segunda linha de defesa contra vazamento de dados entre tenants.

**Dependências:** TASK-009 concluída ✅

**Como validar:**
- [ ] Query sem filtro de tenant em repository lança exceção ou retorna vazio
- [ ] Anotação `@RequireTenant` ou equivalente aplicada nos repos críticos
- [ ] Teste de integração confirmando isolamento automático

**Área impactada:** Backend (repositories JPA, TenantContext)

**Esforço:** 4-8h

---

### 🟡 TASK-018 — Soft delete nas entidades críticas
**Arquivo:** [TASK-018.md](../tasks/TASK-018.md)
**Épico:** EPIC-004 — Banco de Dados e Persistência

**Objetivo nesta sprint:** Preservar histórico de dados para auditoria regulatória.

**Por que está na Sprint 3:**
No domínio de manutenção regulatória, deletar dados de execução pode ser uma violação legal. Soft delete é pré-requisito para conformidade.

**Dependências:** Nenhuma

**Como validar:**
- [ ] DELETE em manutenção, item ou usuário define `deleted_at`, não remove o registro
- [ ] Listagens por padrão excluem registros soft-deleted
- [ ] Registro soft-deleted não aparece em consultas normais
- [ ] Admin consegue ver/restaurar registros deletados

**Área impactada:** Backend (entities: MaintenanceItem, MaintenanceExecution, User), Flyway migration

**Esforço:** 6-10h

---

### 🟡 TASK-019 — Índices ausentes no banco de dados
**Arquivo:** [TASK-019.md](../tasks/TASK-019.md)
**Épico:** EPIC-004 — Banco de Dados e Persistência

**Objetivo nesta sprint:** Eliminar full scans em queries críticas antes do volume crescer.

**Por que está na Sprint 3:**
Índices ausentes têm custo zero para adicionar agora e custo crescente de performance a cada usuário novo. Melhor adicionar antes do lançamento.

**Dependências:** Nenhuma

**Como validar:**
- [ ] `EXPLAIN` das queries do dashboard sem `type: ALL` em tabelas com dados > 1k linhas
- [ ] Índices em `organization_code`, `user_id`, `status`, `due_date` nas tabelas críticas
- [ ] Flyway migration criada para cada índice novo

**Área impactada:** Backend (Flyway migrations, queries JPA)

**Esforço:** 3-5h

---

### 🟡 TASK-020 — Schema formal para features JSON em billing_plans
**Arquivo:** [TASK-020.md](../tasks/TASK-020.md)
**Épico:** EPIC-004 — Banco de Dados e Persistência

**Objetivo nesta sprint:** Evitar bugs silenciosos quando estrutura de features de plano muda.

**Por que está na Sprint 3:**
Features de billing armazenadas como JSON livre quebram silenciosamente ao evoluir o produto. Schema formal com validação evita regressões de billing.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Classe `BillingPlanFeatures` com campos tipados e validação ao deserializar
- [ ] Falha de desserialização lança exceção clara, não `null`
- [ ] Testes unitários para desserialização com schema inválido

**Área impactada:** Backend (BillingPlanFeatures, BillingPlanFeaturesHelper)

**Esforço:** 3-5h

---

### 🟡 TASK-025 — Fila/retry para envio de e-mails
**Arquivo:** [TASK-025.md](../tasks/TASK-025.md)
**Épico:** EPIC-002 — Confiabilidade Operacional

**Objetivo nesta sprint:** Garantir que e-mails críticos (trial expirando, cobrança, reset) sejam entregues mesmo em falha temporária do MailerSend.

**Por que está na Sprint 3:**
E-mail de bloqueio de assinatura ou cobrança que falha silenciosamente é um problema legal e de UX. Retry automático é a solução correta.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Falha no MailerSend enfileira o e-mail para reenvio automático
- [ ] Após 3 tentativas sem sucesso, log de erro com notificação interna
- [ ] E-mails críticos não são perdidos mesmo com indisponibilidade de 30 minutos do MailerSend

**Área impactada:** Backend (BillingNotificationService, EmailService)

**Esforço:** 5-8h

---

### 🟡 TASK-026 — Testes de integração — billing e auth completos
**Arquivo:** [TASK-026.md](../tasks/TASK-026.md)
**Épico:** EPIC-008 — Qualidade e Testes

**Objetivo nesta sprint:** Cobertura de integração real para os fluxos de maior risco com TestContainers + MySQL.

**Por que está na Sprint 3:**
A TASK-004 entregou testes unitários. Esta entrega o complemento: testes que tocam o banco real e validam o isolamento de tenants end-to-end.

**Dependências:** TASK-004 concluída ✅

**Como validar:**
- [ ] Teste de integração: usuário org A não acessa dados da org B via MockMvc
- [ ] Teste de integração: fluxo trial → bloqueio via job
- [ ] TestContainers configurado com MySQL para testes de integração
- [ ] Coverage 70%+ nos módulos billing e kernel

**Área impactada:** Backend (test suite, pom.xml, TestContainers)

**Esforço:** 8-12h

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída:
- [ ] Código implementado e revisado
- [ ] Flyway migrations criadas e testadas localmente
- [ ] Sem regressão nos fluxos de login, onboarding, dashboard e billing
- [ ] Testes unitários ou de integração adicionados para a mudança
- [ ] Task movida para "Concluído" no kanban

---

## Backlog da Sprint (para Sprint 04)

Tasks que ficam para a próxima sprint após concluir S03:
- TASK-021 — Alertas no Prometheus/Grafana
- TASK-022 — Sentry em backend e frontend
- TASK-027 — Pre-signed URLs S3 para uploads diretos
- TASK-028 — Processamento assíncrono de chamadas IA
- TASK-029 — Runbook de incidentes e operação

---

## Status da Sprint

**Parcialmente concluída — 4/6 tasks entregues**

| Task | Status | Observação |
|------|--------|-----------|
| TASK-017 | ✅ Concluída | Enforcement automático de tenant no repository |
| TASK-018 | ✅ Concluída | Soft delete nas entidades críticas |
| TASK-019 | ✅ Concluída | Índices ausentes no banco de dados |
| TASK-020 | ✅ Concluída | Schema formal para features JSON em billing_plans |
| TASK-025 | ⏳ Pendente | Fila/retry para envio de e-mails |
| TASK-026 | ⏳ Pendente | Testes de integração — billing e auth completos |

---

## Retrospectiva (a preencher ao final)

**O que funcionou bem:**
_[preencher após sprint]_

**O que poderia melhorar:**
_[preencher após sprint]_

**Próximos passos:**
- Concluir TASK-025 e TASK-026 para encerrar a sprint
- TASK-025 tem dependência de TASK-012 (concluída) e TASK-008 (concluída)
