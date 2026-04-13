# Roadmap — Easy Maintenance SaaS

> Última atualização: 12/04/2026
> Status: Pré-lançamento
> Versão do produto: 0.9 (Release Candidate)

---

## Visão Geral do Produto

O **Easy Maintenance** é uma plataforma SaaS multi-tenant para gestão de manutenção regulatória e preventiva. Permite que organizações (condomínios, hospitais, escolas, indústrias) controlem ativos, registrem manutenções, monitorem conformidade com normas técnicas brasileiras e recebam recomendações inteligentes via IA.

**Mercado:** B2B brasileiro  
**Gateway de pagamento:** Asaas (PIX, Boleto, Cartão)  
**Diferenciais:** Multi-tenant, RBAC por organização, IA integrada (GPT-4o-mini + DeepSeek), notificações push Firebase

---

## Situação Atual

| Dimensão | Nota | Estado |
|----------|------|--------|
| Arquitetura | 7.5/10 | Sólida, com pontos de melhoria |
| Segurança | 5.5/10 | Bloqueadores críticos existentes |
| Performance | 6.5/10 | Aceitável para early stage |
| UX | 6.5/10 | Funcional, precisa de polish |
| Produto | 7.0/10 | Features principais prontas |
| Prontidão para mercado | 5.5/10 | Requer resolução de bloqueadores |

**Veredicto:** Pode lançar com ressalvas — bloqueadores críticos precisam ser resolvidos primeiro.

---

## Fases do Roadmap

---

### Fase 1 — Antes do Lançamento
**Objetivo:** Resolver bloqueadores de segurança e confiabilidade para um soft launch seguro  
**Prazo estimado:** 2–4 semanas  
**Critério de saída:** Zero bloqueadores críticos e altos abertos

**Principais entregas:**
- Chaves RSA persistidas (sem logout em deploy)
- JWT migrado para cookie HttpOnly
- ShedLock em todos os jobs agendados
- Rate limiting em auth, reset e AI
- Swagger desabilitado em produção
- Webhook Asaas com validação robusta
- Circuit breaker para integrações externas
- Secrets auditados e rotacionados
- Testes mínimos nos fluxos críticos de billing
- Banner de trial expirando no dashboard
- Tratamento de erro no onboarding

**Épicos da Fase 1:**
- EPIC-001: Segurança Crítica
- EPIC-002: Confiabilidade Operacional
- EPIC-003: Multi-tenancy e Autorização
- EPIC-008: Qualidade e Testes (mínimo viável)

---

### Fase 2 — Estabilização Pós-Lançamento
**Objetivo:** Consolidar a experiência do cliente e reduzir fricções de produto  
**Prazo estimado:** 1–2 meses após lançamento  
**Critério de saída:** NPS > 7, Churn < 5%/mês, zero incidentes críticos recorrentes

**Principais entregas:**
- Exportação de relatórios (PDF/Excel)
- Notificações in-app (lista no header)
- Tour guiado pós-onboarding
- Central de ajuda básica (FAQ)
- Alertas configurados no Prometheus/Grafana
- Status page básica
- Soft delete em entidades críticas
- Índices de banco de dados otimizados
- Sentry para rastreamento de erros
- Configuração global do React Query (cache e refetch)
- Skeletons de carregamento nas rotas principais
- Eliminação do padrão N+1 na listagem de itens
- Middleware de autenticação no edge

**Épicos da Fase 2:**
- EPIC-004: Banco de Dados e Persistência
- EPIC-005: Observabilidade e Operação
- EPIC-006: Produto SaaS
- EPIC-007: Performance e Escalabilidade (inicial)
- EPIC-009: Performance Frontend

---

### Fase 3 — Escala e Maturidade
**Objetivo:** Preparar o sistema para crescimento, compliance e expansão  
**Prazo estimado:** 3–6 meses  
**Critério de saída:** Pronto para campanhas de marketing em escala

**Principais entregas:**
- Pre-signed URLs S3 para uploads diretos
- Jobs de billing assíncronos com fila (SQS/RabbitMQ)
- LGPD: exportação e exclusão de dados pessoais
- API pública com webhooks de saída
- Onboarding com tour interativo (Shepherd.js)
- 2FA para acesso corporativo
- Multi-idioma (en-US para expansão)
- Paginação cursor-based para listas grandes
- Testes de carga antes de campanhas
- Pentest formal

**Épicos da Fase 3:**
- EPIC-007: Performance e Escalabilidade (completo)
- EPIC-009: Compliance e LGPD (futuro)
- EPIC-010: Expansão de Produto (futuro)

---

## Épicos

| ID | Nome | Fase | Status |
|----|------|------|--------|
| EPIC-001 | Segurança Crítica | 1 | Quase concluído (TASK-039 pendente) |
| EPIC-002 | Confiabilidade Operacional | 1 | Parcial — 3/4 (TASK-025 pendente) |
| EPIC-003 | Multi-tenancy e Autorização | 1 | Parcial — 3/4 (TASK-038 pendente) |
| EPIC-004 | Banco de Dados e Persistência | 2 | Parcial — 3/4 (TASK-035 pendente) |
| EPIC-005 | Observabilidade e Operação | 2 | Parcial — 2/4 (TASK-021, TASK-033 pendentes) |
| EPIC-006 | Produto SaaS | 2 | Quase concluído — 8/9 (TASK-040 pendente) |
| EPIC-007 | Performance e Escalabilidade | 2–3 | Não iniciado — 0/4 |
| EPIC-008 | Qualidade e Testes | 1–2 | Parcial — 1/2 (TASK-026 pendente) |
| EPIC-009 | Performance Frontend | 2 | Concluído ✅ |
| EPIC-010 | PIX como Método de Pagamento Funcional | 2 | Concluído ✅ |

---

## Métricas de Sucesso do Lançamento

- Taxa de ativação: % de novos usuários que completam o onboarding em 24h (meta: > 60%)
- Conversão trial → pago: % de trials que convertem (meta: > 15%)
- Churn mensal: (meta: < 5%)
- Disponibilidade: (meta: > 99.5%)
- Tempo médio de resposta da API: (meta: < 500ms no P95)
- Taxa de erro da API: (meta: < 0.5%)
