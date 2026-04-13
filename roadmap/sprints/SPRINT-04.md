# SPRINT-04 — Observabilidade + Performance

> **Período:** Semana 9–10 (estimado)
> **Objetivo:** Ter visibilidade completa do sistema em produção e eliminar os principais gargalos de performance antes do crescimento de base
> **Capacidade estimada:** 5 tasks
> **Critério de saída:** Alertas configurados, Sentry ativo, uploads não passando pelo backend, IA respondendo de forma assíncrona, runbook documentado

---

## Meta da Sprint

> "Ao final desta sprint, a equipe é notificada de problemas antes dos clientes, o diagnóstico de incidentes leva minutos, e o sistema não tem gargalos óbvios de CPU/memória para uploads e IA."

---

## Tasks da Sprint

---

### 🟡 TASK-021 — Alertas no Prometheus/Grafana
**Arquivo:** [TASK-021.md](../tasks/TASK-021.md)
**Épico:** EPIC-005 — Observabilidade e Operação

**Objetivo nesta sprint:** Ser notificado de problemas antes dos clientes.

**Por que está na Sprint 4:**
Com usuários reais em produção, é crítico saber quando algo está errado antes do suporte receber tickets. Prometheus já está configurado — falta o nível de alerta.

**Dependências:** Prometheus/Grafana operando (existente)

**Como validar:**
- [ ] Alerta disparado quando taxa de erro HTTP > 1% por 5 minutos
- [ ] Alerta disparado quando P95 de latência > 2s
- [ ] Alerta disparado quando job de billing falha
- [ ] Alerta disparado quando quota de IA atinge 80% do limite mensal
- [ ] Canal de notificação configurado (Slack, e-mail ou PagerDuty)

**Área impactada:** DevOps (Grafana alerting, Prometheus rules)

**Esforço:** 4-8h

---

### 🟡 TASK-022 — Sentry em backend e frontend
**Arquivo:** [TASK-022.md](../tasks/TASK-022.md)
**Épico:** EPIC-005 — Observabilidade e Operação

**Objetivo nesta sprint:** Capturar e rastrear erros não tratados em produção.

**Por que está na Sprint 4:**
Sem Sentry, exceções em produção são invisíveis até um usuário reclamar. Instalação é simples — alto impacto de visibilidade com baixo esforço.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Exceção não tratada no backend aparece no Sentry com stack trace
- [ ] Erro JavaScript no frontend aparece no Sentry com contexto do usuário
- [ ] Alertas de Sentry configurados para erros novos
- [ ] DSN configurado via variável de ambiente (não hardcoded)

**Área impactada:** Backend (Spring Boot Sentry integration) + Frontend (Next.js Sentry)

**Esforço:** 3-5h

---

### 🟡 TASK-027 — Pre-signed URLs S3 para uploads diretos
**Arquivo:** [TASK-027.md](../tasks/TASK-027.md)
**Épico:** EPIC-007 — Performance e Escalabilidade

**Objetivo nesta sprint:** Eliminar o backend como intermediário no upload de arquivos.

**Por que está na Sprint 4:**
Atualmente uploads passam pelo backend — isso consome memória, CPU e aumenta a latência. Com pre-signed URLs, o upload vai direto para o S3.

**Dependências:** AWS S3 já configurado (existente)

**Como validar:**
- [ ] Frontend recebe pre-signed URL do backend
- [ ] Upload vai diretamente do browser para o S3
- [ ] Backend não recebe o binário do arquivo
- [ ] URL expira após tempo configurável (ex: 15 minutos)
- [ ] Funciona para os tipos de arquivo aceitos (imagens, PDFs)

**Área impactada:** Backend (S3Service, upload endpoints) + Frontend (upload components)

**Esforço:** 5-8h

---

### 🟡 TASK-028 — Processamento assíncrono de chamadas IA
**Arquivo:** [TASK-028.md](../tasks/TASK-028.md)
**Épico:** EPIC-007 — Performance e Escalabilidade

**Objetivo nesta sprint:** Evitar timeout e bloqueio de threads em chamadas à OpenAI.

**Por que está na Sprint 4:**
Chamadas à IA levam 3-30s. Com processamento síncrono, o usuário espera com o browser travado e há risco de timeout no Railway (30s). Async resolve ambos.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Endpoint de IA retorna imediatamente com `jobId`
- [ ] Frontend faz polling ou usa webhook para obter resultado
- [ ] Resultado fica disponível mesmo após o usuário fechar e reabrir a aba
- [ ] Timeout da OpenAI é tratado com mensagem clara

**Área impactada:** Backend (AiController, OpenAiService) + Frontend (IA components)

**Esforço:** 8-12h

---

### 🟡 TASK-029 — Runbook de incidentes e operação
**Arquivo:** [TASK-029.md](../tasks/TASK-029.md)
**Épico:** EPIC-005 — Observabilidade e Operação

**Objetivo nesta sprint:** Documentar como responder a incidentes comuns em produção.

**Por que está na Sprint 4:**
Com Sentry e alertas configurados nesta mesma sprint, o runbook é o complemento natural — transforma o alerta em ação.

**Dependências:** TASK-021, TASK-022 recomendados antes

**Como validar:**
- [ ] Runbook documenta procedimento para: falha do Asaas, job de billing falho, incidente de segurança, indisponibilidade do banco
- [ ] Cada procedimento tem: diagnóstico, ação imediata, comunicação ao cliente, pós-mortem
- [ ] Runbook acessível à equipe (repositório ou Notion)
- [ ] Testado em simulação (tabletop exercise)

**Área impactada:** Documentação / DevOps

**Esforço:** 4-6h

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída:
- [ ] Código implementado e revisado (onde aplicável)
- [ ] Configurações de infraestrutura documentadas
- [ ] Variáveis de ambiente atualizadas no Railway se necessário
- [ ] Testes unitários para mudanças de lógica de backend
- [ ] Task movida para "Concluído" no kanban

---

## Backlog da Sprint (para Sprint 05)

Tasks que ficam para a próxima sprint após concluir S04:
- TASK-033 — Status page básica
- TASK-035 — Política de retenção para audit_logs
- TASK-036 — Paginação cursor-based em listagens grandes
- TASK-037 — Jobs de billing assíncronos com fila
- TASK-038 — LGPD: exportação e exclusão de dados pessoais
- TASK-039 — Autenticação 2FA
- TASK-040 — Acessibilidade básica (WCAG AA)

---

## Status da Sprint

**Parcialmente concluída — 2/5 tasks entregues**

| Task | Status | Observação |
|------|--------|-----------|
| TASK-021 | ⏳ Pendente | Alertas no Prometheus/Grafana |
| TASK-022 | ✅ Concluída | Sentry em backend e frontend |
| TASK-027 | ⏳ Pendente | Pre-signed URLs S3 para uploads diretos |
| TASK-028 | ⏳ Pendente | Processamento assíncrono de chamadas IA |
| TASK-029 | ✅ Concluída | Runbook de incidentes e operação |

---

## Retrospectiva (a preencher ao final)

**O que funcionou bem:**
_[preencher após sprint]_

**O que poderia melhorar:**
_[preencher após sprint]_

**Próximos passos:**
- Concluir TASK-025 e TASK-026 (SPRINT-03) antes de priorizar as tasks desta sprint
- Sequência recomendada: TASK-021 → TASK-027 → TASK-028
