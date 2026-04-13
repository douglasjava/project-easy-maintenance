# Easy Maintenance — SaaS de Gestão de Manutenção

Plataforma SaaS multi-tenant para gestão de manutenção regulatória e preventiva. Permite que organizações (condomínios, hospitais, escolas, indústrias) controlem ativos, registrem manutenções, monitorem conformidade com normas técnicas brasileiras e recebam recomendações inteligentes via IA.

**Mercado:** B2B brasileiro  
**Status atual:** Pré-lançamento (Release Candidate 0.9)  
**Gateway de pagamento:** Asaas (PIX, Boleto, Cartão)  
**Diferenciais:** Multi-tenant, RBAC por organização, IA integrada (GPT-4o-mini + DeepSeek), notificações push Firebase

---

## Índice

- [Estrutura do Repositório](#estrutura-do-repositório)
- [Stack Técnica](#stack-técnica)
- [Gestão do Projeto](#gestão-do-projeto)
  - [Roadmap e Fases](#roadmap-e-fases)
  - [Épicos](#épicos)
  - [Tasks](#tasks)
  - [Sprints](#sprints)
  - [Kanban](#kanban)
  - [QA — Fluxos e Métodos de Teste](#qa--fluxos-e-métodos-de-teste)
- [Documentação Operacional](#documentação-operacional)
  - [Runbooks](#runbooks)
  - [Planos e Specs (Superpowers)](#planos-e-specs-superpowers)
- [Desenvolvimento com Claude](#desenvolvimento-com-claude)
  - [Skills Disponíveis](#skills-disponíveis)
  - [Fluxo de Trabalho com Claude](#fluxo-de-trabalho-com-claude)
  - [Convenções do CLAUDE.md](#convenções-do-claudemd)
- [Status Atual](#status-atual)

---

## Estrutura do Repositório

```
EASY_MAINTENANCE/
├── CLAUDE.md                        # Instruções de comportamento para o Claude
├── README.md                        # Este arquivo
│
├── easy-maintenance-api/            # Backend — Spring Boot 3 / Java 21
├── easy-maintenance-web/            # Frontend — Next.js 16 / TypeScript
│
├── docs/                            # Documentação técnica e operacional
│   ├── runbooks/                    # Procedimentos de resposta a incidentes
│   │   ├── README.md                # Índice dos runbooks
│   │   ├── RB-001-*.md              # Job de billing falhou
│   │   ├── RB-002-*.md              # Asaas fora do ar
│   │   ├── RB-003-*.md              # Banco de dados lento
│   │   ├── RB-004-*.md              # OpenAI/DeepSeek quota esgotada
│   │   ├── RB-005-*.md              # Railway em restart loop
│   │   └── RB-006-*.md              # Cobrança duplicada
│   └── superpowers/                 # Planos e specs gerados pelo Claude
│       ├── plans/                   # Planos de implementação detalhados
│       └── specs/                   # Documentos de design e decisão técnica
│
└── roadmap/                         # Gestão de produto e engenharia
    ├── roadmap.md                   # Visão geral — fases 1, 2 e 3
    ├── kanban.md                    # Board de kanban com todas as tasks
    ├── backlog.md                   # Backlog completo organizado por épico
    ├── epics/                       # EPIC-001 a EPIC-010
    ├── sprints/                     # SPRINT-01 a SPRINT-06
    ├── tasks/                       # TASK-001 a TASK-048
    └── QA/
        ├── Flow/                    # Fluxos críticos — FLOW-001 a FLOW-011
        └── MTD/                     # Métodos de teste manual — MTD-001 a MTD-007
```

---

## Stack Técnica

| Camada | Tecnologia |
|--------|-----------|
| Backend | Java 21 + Spring Boot 3 |
| Frontend | Next.js 16 + TypeScript + Bootstrap 5 |
| Pagamentos | Asaas (PIX, Boleto, Cartão de Crédito) |
| Inteligência Artificial | GPT-4o-mini + DeepSeek |
| Notificações | Firebase Cloud Messaging |
| Autenticação | JWT com RSA (cookie HttpOnly), RBAC por organização |
| Banco de dados | PostgreSQL |
| Infra / Deploy | Railway |
| Observabilidade | Sentry, Prometheus/Grafana |
| Testes (backend) | JUnit + Spring Boot Test |
| Testes (frontend) | Jest + ts-jest |

---

## Gestão do Projeto

### Roadmap e Fases

O arquivo principal é [`roadmap/roadmap.md`](roadmap/roadmap.md). O produto está organizado em 3 fases:

| Fase | Objetivo | Critério de Saída |
|------|----------|------------------|
| **Fase 1** — Antes do Lançamento | Resolver bloqueadores de segurança e confiabilidade | Zero bloqueadores críticos e altos abertos |
| **Fase 2** — Estabilização Pós-Lançamento | Consolidar experiência e reduzir fricções | NPS > 7, Churn < 5%/mês, zero incidentes críticos |
| **Fase 3** — Escala e Maturidade | Preparar para crescimento, compliance e expansão | Pronto para campanhas de marketing em escala |

### Épicos

Os épicos ficam em [`roadmap/epics/`](roadmap/epics/). Cada épico agrupa tasks relacionadas por objetivo de negócio:

| Épico | Nome | Fase | Status |
|-------|------|------|--------|
| EPIC-001 | Segurança Crítica | 1 | Quase concluído (TASK-039 pendente) |
| EPIC-002 | Confiabilidade Operacional | 1 | Parcial (TASK-025 pendente) |
| EPIC-003 | Multi-tenancy e Autorização | 1 | Parcial (TASK-038 pendente) |
| EPIC-004 | Banco de Dados e Persistência | 2 | Parcial (TASK-035 pendente) |
| EPIC-005 | Observabilidade e Operação | 2 | Parcial (TASK-021, TASK-033 pendentes) |
| EPIC-006 | Produto SaaS | 2 | Quase concluído (TASK-040 pendente) |
| EPIC-007 | Performance e Escalabilidade | 2–3 | Não iniciado |
| EPIC-008 | Qualidade e Testes | 1–2 | Parcial (TASK-026 pendente) |
| EPIC-009 | Performance Frontend | 2 | Concluído ✅ |
| EPIC-010 | PIX como Método de Pagamento | 2 | Concluído ✅ |

**Estrutura de um arquivo de épico:**
- Objetivo e descrição do épico
- Impacto no produto (com e sem o épico)
- Tabela de tasks relacionadas com prioridades
- Critério de conclusão do épico (checklist)

### Tasks

As tasks ficam em [`roadmap/tasks/`](roadmap/tasks/). São a unidade básica de trabalho. Cada arquivo `TASK-XXX.md` contém:

| Campo | Descrição |
|-------|-----------|
| **Tipo** | Categoria técnica da mudança |
| **Categoria** | Backend / Frontend / Full-Stack / Infra |
| **Prioridade** | 🔴 Crítico / 🟠 Alto / 🟡 Médio / 🔵 Baixo |
| **Fase** | Em qual fase do roadmap se encaixa |
| **Épico** | Épico pai |
| **Descrição** | Contexto e explicação do problema |
| **Problema** | O que está errado atualmente |
| **Impacto** | Consequências de não fazer |
| **Dependências** | Tasks que precisam ser concluídas antes |
| **Critérios de Aceite** | Checklist de quando a task está pronta |
| **Subtasks** | Passos detalhados de implementação |
| **Arquivos alterados** | Quais arquivos foram ou serão modificados |
| **Esforço** | Pequeno / Médio / Grande |
| **Risco de não fazer** | Impacto no produto ou no negócio |
| **Status** | Pendente / Em execução / Concluído |

**Total de tasks:** 48 (TASK-001 a TASK-048)  
**Tasks concluídas:** 36  
**Tasks pendentes:** 12

### Sprints

As sprints ficam em [`roadmap/sprints/`](roadmap/sprints/). Cada sprint tem período, objetivo, capacidade e critério de saída definidos.

| Sprint | Foco | Status |
|--------|------|--------|
| SPRINT-01 | Segurança + Confiabilidade crítica | Concluída ✅ |
| SPRINT-02 | Segurança contínua + Multi-tenancy | Concluída ✅ |
| SPRINT-03 | Integridade de Dados + Estabilidade | Parcial 4/6 |
| SPRINT-04 | Observabilidade + Performance | Parcial 2/5 |
| SPRINT-05 | Escalabilidade + Compliance + Polimento | Não iniciada |
| SPRINT-06 | PIX como método de pagamento | Concluída ✅ |

**Estrutura de um arquivo de sprint:**
- Meta da sprint
- Tabela de tasks com links para os arquivos individuais
- Para cada task: objetivo, por que está nesta sprint, dependências, como validar, área impactada e esforço
- Definition of Done (DoD) da sprint
- Retrospectiva (preenchida ao final)

### Kanban

O arquivo [`roadmap/kanban.md`](roadmap/kanban.md) é o board central de acompanhamento. Ele lista todas as tasks com:

- **Legenda de prioridade:** 🔴 Crítico | 🟠 Alto | 🟡 Médio | 🔵 Baixo
- **Colunas:** Backlog → Pronto para Implementar → Em Execução → Em Validação → Concluído
- **Tasks concluídas** aparecem com tachado (~~TASK-XXX~~)
- **Links para sprints** ao final de cada bloco de sprint concluída

O kanban deve ser atualizado sempre que uma task mudar de estado. O skill `/kanban-update` automatiza isso.

### QA — Fluxos e Métodos de Teste

A pasta [`roadmap/QA/`](roadmap/QA/) contém dois tipos de documento:

#### Flows (`QA/Flow/FLOW-XXX.md`)

Descrevem os fluxos críticos do produto do ponto de vista de QA. Cada flow contém:
- **Criticidade** e relevância para o lançamento
- **Tasks relacionadas** que implementam ou afetam o fluxo
- **Camadas impactadas** (backend, frontend, infra)
- **Cenários críticos** com tipo (happy path, segurança, edge case) e cobertura atual
- **Validação recomendada** (links para MTDs e tasks de automação)
- **Gaps** de cobertura identificados
- **Status de validação** (checklist)

| Flow | Fluxo | Criticidade |
|------|-------|------------|
| FLOW-001 | Autenticação e Sessão | 🔴 CRITICAL |
| FLOW-002 a FLOW-011 | Outros fluxos críticos do produto | Variada |

#### MTDs (`QA/MTD/MTD-XXX.md`)

Métodos de teste manual detalhados. Cada MTD contém:
- **Flow** de referência
- **Objetivo** do teste
- **Pré-condições** necessárias
- **Cenários** com passos passo a passo, resultado esperado e campo para evidência (screenshot)
- **Notas e riscos** de execução

Os MTDs devem ser executados antes de cada lançamento ou mudança crítica nos fluxos relacionados.

---

## Documentação Operacional

### Runbooks

Ficam em [`docs/runbooks/`](docs/runbooks/). São procedimentos operacionais para resposta a incidentes em produção. Qualquer membro da equipe deve conseguir resolver os incidentes documentados seguindo os runbooks, sem depender de quem criou o sistema.

**Formato de cada runbook:**
1. **Sintomas** — como detectar o incidente
2. **Causa provável** — causas mais comuns em ordem de frequência
3. **Passos de diagnóstico** — comandos e queries para confirmar a causa
4. **Passos de resolução** — por caso, com comandos exatos
5. **Como comunicar o cliente** — templates de comunicação prontos

| Runbook | Cenário | Severidade |
|---------|---------|-----------|
| RB-001 | Job de billing falhou | Alta |
| RB-002 | Asaas fora do ar / circuit breaker aberto | Alta |
| RB-003 | Banco de dados lento / pool esgotado | Alta |
| RB-004 | OpenAI / DeepSeek quota esgotada | Média |
| RB-005 | Railway em restart loop | Crítica |
| RB-006 | Cobrança duplicada — identificação e estorno | Alta |

### Planos e Specs (Superpowers)

Ficam em [`docs/superpowers/`](docs/superpowers/). São documentos gerados pelo Claude durante o desenvolvimento:

- **`plans/`** — Planos de implementação detalhados com passos, arquivos a modificar, comandos exatos e checkpoints de validação. São gerados antes da execução de tasks complexas (skill `/execute-task`).
- **`specs/`** — Documentos de design e decisão técnica que antecedem o plano. Descrevem o problema, as decisões de design, a arquitetura proposta e os critérios de aceite.

**Exemplo:** Para a TASK-016 (tratamento de erro no onboarding):
- Spec: [`docs/superpowers/specs/2026-04-09-onboarding-error-handling-design.md`](docs/superpowers/specs/2026-04-09-onboarding-error-handling-design.md)
- Plan: [`docs/superpowers/plans/2026-04-09-onboarding-error-handling.md`](docs/superpowers/plans/2026-04-09-onboarding-error-handling.md)

---

## Desenvolvimento com Claude

Este projeto usa o [Claude Code](https://claude.ai/code) com um conjunto de skills customizadas para acelerar o desenvolvimento. O arquivo [`CLAUDE.md`](CLAUDE.md) define as regras de comportamento e as convenções que o Claude deve seguir.

### Skills Disponíveis

As skills são invocadas com `/nome-da-skill` no chat com o Claude. Cada skill expande para um conjunto de instruções que orientam o Claude a executar um fluxo específico.

| Skill | Quando usar |
|-------|------------|
| `/run-sprint` | Iniciar uma nova sprint — planejar, priorizar e sequenciar tasks |
| `/next-task` | Decidir qual task executar a seguir com base no kanban e prioridades |
| `/execute-task` | Implementar uma task específica (gera spec → plan → implementa) |
| `/review-task` | Revisar uma implementação contra os critérios de aceite da task |
| `/acceptance-check` | Validação final de aceite antes de marcar a task como concluída |
| `/kanban-update` | Atualizar o estado das tasks no `kanban.md` |
| `/execute-qa` | Executar os cenários de QA dos flows e MTDs relevantes |
| `/product-decision` | Tomar decisões de produto com raciocínio estruturado |

### Fluxo de Trabalho com Claude

O fluxo padrão para executar uma task é:

```
/next-task          → Claude identifica a próxima task prioritária
/execute-task       → Claude gera spec + plan e implementa
/review-task        → Claude revisa a implementação
/acceptance-check   → Claude valida os critérios de aceite
/kanban-update      → Claude atualiza o kanban com o novo estado
```

Para iniciar uma nova sprint:

```
/run-sprint         → Claude planeja a sprint e define as tasks
```

Para validação de QA:

```
/execute-qa         → Claude executa os MTDs relevantes e reporta resultados
```

### Convenções do CLAUDE.md

O [`CLAUDE.md`](CLAUDE.md) define regras que o Claude deve seguir em todas as tasks:

**Classificação obrigatória:** Toda task deve ser classificada como `BACKEND`, `FRONTEND`, `FULL_STACK`, `INFRA/CONFIG` ou `BUGFIX`.

**Consciência de camadas:**
- Backend: DTO validation, regras de negócio, multi-tenancy (`X-Org-Id`), segurança, performance de queries
- Frontend: estados (loading, error, empty), responsividade, integração com API, tratamento de erros
- Full-Stack: compatibilidade de contrato de API, sincronização de mudanças entre camadas

**QA mindset obrigatório:** Antes de concluir qualquer task, validar:
- ✅ Happy path funciona
- ❌ Cenários de erro tratados
- ⚠️ Edge cases considerados
- 🔁 Sem regressão introduzida
- 🔐 Segurança não quebrada

**Regras de conclusão:** Uma task NÃO está concluída se:
- Foi implementada mas não validada
- Quebra um fluxo existente
- Falta tratamento básico de erro
- Ignora a integração entre camadas

**Arquitetura específica do projeto:**
- Multi-tenancy via `X-Org-Id` obrigatório em todos os endpoints
- Padrão de erro: `ProblemDetail` (RFC 7807)
- Separação: `service` → `provider` → `orchestrator`
- Erros padronizados com tipo: `https://easy-maintenance/api/problems/{slug}`

---

## Status Atual

| Dimensão | Nota | Estado |
|----------|------|--------|
| Arquitetura | 7.5/10 | Sólida, com pontos de melhoria |
| Segurança | 5.5/10 | Bloqueadores críticos em endereçamento |
| Performance | 6.5/10 | Aceitável para early stage |
| UX | 6.5/10 | Funcional, precisa de polish |
| Produto | 7.0/10 | Features principais prontas |
| Prontidão para mercado | 5.5/10 | Requer resolução de bloqueadores |

**Sprints concluídas:** 1, 2 e 6  
**Tasks concluídas:** 36/48  
**Tasks pendentes:** 12 (distribuídas nas SPRINT-03, 04 e 05)  
**Épicos completos:** EPIC-009 (Performance Frontend), EPIC-010 (PIX)

**Próximas tasks prioritárias:**
- TASK-025 — Fila/retry para envio de e-mails (SPRINT-03)
- TASK-026 — Testes de integração — billing e auth completos (SPRINT-03)
- TASK-021 — Alertas no Prometheus/Grafana (SPRINT-04)

**Métricas de sucesso do lançamento:**
- Taxa de ativação em 24h: meta > 60%
- Conversão trial → pago: meta > 15%
- Churn mensal: meta < 5%
- Disponibilidade: meta > 99.5%
- Tempo de resposta API P95: meta < 500ms
- Taxa de erro da API: meta < 0.5%
