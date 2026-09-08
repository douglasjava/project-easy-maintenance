# EPIC-029 — Teste de Carga Estrutural (achar gargalos de código, sem hardware/infra)

## Status
Desenhado via brainstorm com Douglas (08/09/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-09-08-load-testing-epic-design.md`.

## Objetivo
Descobrir, com evidência (não suposição), o que a aplicação aguenta estruturalmente hoje — isolando
gargalos que vêm do próprio código (queries N+1, falta de índice, algoritmo ineficiente, pool mal
dimensionado) de qualquer questão de hardware/escala de infra. Derivado do item #6b do feedback do
cliente Rogerio Dantas ([TASK-218](../tasks/TASK-218.md), já fechada) — em vez de esperar acesso
Railway/Sentry pra investigar produção, ataca primeiro o que dá pra provar localmente.

## Descrição

Três peças, cada uma virando uma task:

1. **Seed sintético** — `db/queries/loadtest-seed.sql`, gerado em lote via SQL (não pela camada de
   serviço), escala média (~500 organizações, ~50 mil itens, ~150 mil manutenções — uma ordem de
   grandeza acima do que a base real deve ter hoje). Roda só contra um banco descartável (MySQL
   local via Docker), nunca staging/produção.
2. **Instrumentação** — novo profile Spring `loadtest` (opt-in, `--spring.profiles.active=loadtest`,
   zero efeito em dev/staging/produção) liga `hibernate.generate_statistics=true` + log de
   contagem de query por request — o sinal mais direto de N+1. Pool de conexão (HikariCP) já é
   visível via Micrometer/Actuator, sem trabalho extra.
3. **Scripts de carga (k6) + relatório** — três fluxos priorizados: login/autenticação,
   listagem/busca de itens (`/items`), detecção/disparo de notificações
   (`NotificationEventDetectionJob`, acionável sob demanda via o endpoint já existente da
   [TASK-132](../tasks/TASK-132.md)). Mede p50/p95/p99 + taxa de erro por endpoint em rampa de
   carga crescente. Scripts ficam versionados no repo (`easy-maintenance-api/loadtest/`) pra reuso
   futuro — checagem de regressão de performance antes de releases grandes.

**Entregável: só diagnóstico.** O épico produz um relatório de achados (gargalo, evidência, causa
raiz, sugestão) — corrigir cada gargalo encontrado vira task própria depois, priorizada por Douglas.
Mesmo padrão já usado no projeto (achar → task separada pra corrigir, ex.: TASK-224 nasceu assim).

---

## Contexto Técnico

- API já tem `spring-boot-starter-actuator` + `micrometer-core` + `micrometer-registry-prometheus`
  no `pom.xml`, com `/actuator/prometheus` exposto — métricas de JVM/HTTP/pool já disponíveis.
- `hibernate.generate_statistics` está desligado hoje — precisa ser ligado, só sob o profile
  `loadtest`, nunca no comportamento padrão.
- TASK-224 (01/09/2026) já corrigiu um N+1 real em produção (`resolveNormInfo` na listagem de
  itens) — só apareceu como sintoma visível ("log letra a letra"). Precedente direto de que esse
  tipo de problema existe e passa despercebido sem instrumentação ativa.
- `db/queries/` já é o diretório estabelecido pra scripts SQL reutilizáveis versionados (TASK-227,
  `qa-fornecedor-whatsapp-v3.sql` da TASK-174) — mesmo padrão serve pro seed deste épico.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-233](../tasks/TASK-233.md) | Seed sintético de dados (`loadtest-seed.sql`, escala média) | INFRA/CONFIG | 🟡 Médio |
| [TASK-234](../tasks/TASK-234.md) | Profile `loadtest` — Hibernate statistics + contagem de query por request | BACKEND | 🟡 Médio |
| [TASK-235](../tasks/TASK-235.md) | Scripts k6 (login, `/items`, detecção de notificação) + execução + relatório de achados | INFRA/CONFIG | 🟡 Médio |

Ordem: TASK-233 e TASK-234 são independentes entre si (podem andar em paralelo). TASK-235 depende
das duas — precisa do dado semeado e da instrumentação ligada pra produzir um relatório com causa
raiz, não só tempo de resposta.

---

## Critério de Conclusão do Épico

- [ ] Seed sintético roda contra um banco local descartável e monta a hierarquia
      org→usuário→item→manutenção em escala média, respeitando FKs/multi-tenant
- [ ] Profile `loadtest` liga contagem de query por request sem alterar comportamento padrão de
      dev/staging/produção
- [ ] Scripts k6 cobrindo os 3 fluxos priorizados, versionados no repo, com README de como rodar
- [ ] Relatório final de achados: cada gargalo reportado com sintoma + causa raiz + evidência +
      sugestão (sem implementar a correção)
- [ ] `mvn test`/`npm run build` sem regressão (nenhuma mudança deste épico deve afetar o
      comportamento padrão da aplicação)

---

## Fora de Escopo

- Frontend (Next.js) — performance de renderização é disciplina de teste diferente.
- Checkout/billing (Asaas) e qualquer fluxo fora dos 3 priorizados — podem virar continuação depois.
- Corrigir os gargalos encontrados — cada um vira task própria, priorizada por Douglas depois do
  relatório.
- Teste de carga contra staging ou produção.
- Dashboard/observabilidade nova — usa o que já existe (Actuator/Prometheus) + saída do próprio k6.
- Autoscaling, dimensionamento de infra, ou qualquer decisão de hardware.

## Riscos
Baixo pro código de produção — tudo aditivo e opt-in (profile novo, scripts novos, seed contra
banco descartável), nada roda por padrão. Risco real é de esforço: seed de ~200 mil linhas
relacionadas pode exigir iteração pra ficar rápido de rodar repetidamente; e a escala sintética
escolhida (média) pode não bastar pra denunciar todo gargalo real — se não bastar, sobe pra uma
escala maior numa iteração futura, sem bloquear o fechamento deste épico.
