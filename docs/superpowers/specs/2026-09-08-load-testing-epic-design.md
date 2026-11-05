# EPIC-029 — Teste de carga estrutural (achar gargalos de código, sem hardware/infra)

**Data:** 08/09/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)

## Motivação

Depois de fechar a [TASK-218](../../../roadmap/tasks/TASK-218.md) (feedback real do cliente Rogerio
Dantas), sobrou um item (#6b) sobre investigação de performance mais ampla — originalmente pensado
como "esperar acesso Railway/Sentry do Douglas pra olhar produção". Douglas quer inverter a ordem:
antes de depender de acesso a infraestrutura real, quer saber **estruturalmente** o que a aplicação
aguenta hoje — ou seja, isolar os gargalos que vêm do próprio código (queries N+1, falta de índice,
algoritmo ineficiente, pool mal dimensionado) de qualquer questão de hardware/escala de infra. Isso
também cria uma ferramenta reutilizável (scripts de carga) pra checar regressão de performance antes
de releases grandes futuras, não só um diagnóstico único.

## Contexto (levantado antes do desenho)

- API já tem `spring-boot-starter-actuator` + `micrometer-core` + `micrometer-registry-prometheus`
  no `pom.xml`, com `/actuator/prometheus` exposto (`management.endpoints.web.exposure.include=health,info,prometheus,metrics`)
  — métricas de JVM, HTTP e pool de conexão (HikariCP, via Micrometer) já disponíveis sem trabalho
  extra.
- **Não** existe hoje: contagem de query por request (`hibernate.generate_statistics` desligado,
  sem `show_sql`) — o sinal mais direto de N+1 sob carga. Precisa ser ligado, mas só sob demanda
  (nunca no comportamento padrão de dev/staging/produção).
- TASK-224 (01/09/2026) já corrigiu um N+1 real em produção (`resolveNormInfo` na listagem de
  itens) — acionado só depois que apareceu como sintoma ("log letra a letra" na busca). Precedente
  direto de que esse tipo de problema existe e passa despercebido sem instrumentação ativa.
- `db/queries/` já é usado como diretório de scripts SQL reutilizáveis, versionados no repo (ex.:
  TASK-227, biblioteca de queries de acompanhamento; `qa-fornecedor-whatsapp-v3.sql` da TASK-174) —
  mesmo padrão serve pro seed de dados sintéticos deste épico.
- `TASK-132` já expõe endpoints de disparo manual de job (`GET /run-jobs/execute-notification-detection`)
  — reaproveitável pra acionar o job de notificação sob carga sem esperar o cron.
- Skill `performance-expert` (já usada nesta sessão pro item #6a) estabelece o princípio orientador:
  medir → identificar → explicar → priorizar, nunca "supor → reescrever → deployar"; e nunca rodar
  teste de carga agressivo direto contra produção.

## Decisões de escopo (brainstorm, 08/09/2026)

1. **Só backend (API Spring Boot).** Frontend (Next.js) fica de fora — carga concorrente e
   contenção de recursos (DB, pool, CPU) se manifestam no backend; performance de renderização é
   uma disciplina de teste diferente, não entra neste épico.
2. **Três fluxos priorizados**, escolhidos por uso real ou risco: login/autenticação (ponto de
   entrada de todo usuário, relevante pra pico de acesso simultâneo), listagem/busca de itens
   (`/items`, tela mais usada no dia a dia, já teve um N+1 corrigido — bom candidato a achar
   outros), e detecção/disparo de notificações (`NotificationEventDetectionJob` +
   `NotificationOrchestratorService`, roda em lote pra todas as orgs, cresce com a base de
   clientes, nunca foi testado sob volume). Checkout/billing (Asaas) e outros fluxos ficam de fora
   deste épico — podem virar um épico de continuação se fizer sentido depois.
3. **Escala sintética alvo: média** — ~500 organizações, ~50 mil itens, ~150 mil manutenções. Uma
   ordem de grandeza acima do que a base real deve ter hoje: suficiente pra denunciar N+1/índice
   faltando sem tornar o setup do seed impraticável de rodar localmente.
4. **Entregável: só diagnóstico.** O épico produz um relatório de achados (gargalo, evidência,
   causa raiz, sugestão) + os scripts de carga reutilizáveis. Corrigir cada gargalo encontrado vira
   task própria, priorizada depois — mesmo padrão já usado no projeto (achar → task separada pra
   corrigir, ex. TASK-224 nasceu assim).
5. **Scripts ficam versionados pra reuso futuro** — não é um teste de uso único. Guardados no repo
   pra rodar de novo antes de releases grandes, como checagem de regressão de performance.
6. **Ambiente: local, com dado sintético — nunca staging/produção pra teste de carga agressivo.**
   Isolar o código da variável de infra/rede é o próprio objetivo (excluir hardware da equação).
   Staging fica reservado pra uma validação pontual e leve depois, se fizer sentido — não é alvo de
   carga deste épico.

---

## Arquitetura

### 1. Ferramenta de carga: k6

Recomendado sobre JMeter (GUI pesada, XML difícil de versionar/revisar em PR) e Gatling (Scala,
mais uma linguagem no stack só pra isso). k6 roda scripts em JavaScript, é um binário único (sem
JVM/GUI), versiona fácil no mesmo padrão de `db/queries/`, e tem suporte nativo a Prometheus
remote-write — encaixa direto no que já está exposto em `/actuator/prometheus`, sem precisar de
peça nova de infra de observabilidade.

Scripts ficam em `easy-maintenance-api/loadtest/` (novo diretório, só scripts k6 + README de como
rodar — não entra no build de produção), um arquivo `.js` por fluxo:
- `login.js`
- `items-search.js`
- `notification-detection.js`

Cada script sobe carga em rampa (ex.: 10 → 50 → 100 usuários virtuais ao longo de alguns minutos,
valor exato a afinar durante a implementação) e registra p50/p95/p99 + taxa de erro por endpoint.
k6 gera um resumo em texto/JSON ao final de cada execução — vai pro relatório de achados, não
precisa de dashboard novo pra essa primeira rodada.

### 2. Seed de dados sintéticos

Gerado via **SQL em lote**, não pela camada de serviço (passar 50 mil registros pelo
`MaintenanceItemService` um por um seria lento demais pro propósito e não é o gargalo que estamos
testando). Um script `db/queries/loadtest-seed.sql` usa geração procedural (`INSERT ... SELECT`
numérico ou stored procedure com loop, a definir na implementação) pra montar a hierarquia
`organization` → `users` → `maintenance_item` → `maintenance` respeitando as constraints reais do
schema (FKs, `X-Org-Id`/multi-tenant).

Roda **só contra um banco descartável** (MySQL local via Docker, mesmo padrão já usado na
verificação da TASK-230 — container efêmero, destruído depois). Nunca aponta pra staging ou
produção.

### 3. Instrumentação — achar o gargalo, não só medir tempo

- k6 mede tempo/throughput por endpoint — já cobre "está lento".
- Novo profile Spring `loadtest` (ativado manualmente via `--spring.profiles.active=loadtest`, opt-in,
  zero efeito em dev/staging/produção) liga `hibernate.generate_statistics=true` + log de
  contagem de query por request — o sinal mais direto de N+1. Fica registrado nos logs da aplicação
  durante a execução do k6, correlacionado por endpoint/timestamp no relatório final.
- Pool de conexão (HikariCP) já é visível via Micrometer/Actuator sem trabalho extra — usado pra
  checar saturação de conexão durante a rampa de carga.

### 4. Critério de "gargalo" (o que entra no relatório final)

Um achado só entra no relatório se tiver evidência, não suposição — nos moldes do
`performance-expert`: sintoma (ex.: p95 sobe de forma não-linear a partir de X usuários
concorrentes) + causa raiz (ex.: N SQL queries por request, número crescente conforme volume) +
sugestão de correção (sem implementá-la aqui).

---

## Tasks do épico

| # | Título | Tipo | Depende de |
|---|---|---|---|
| 1 | Seed sintético (`loadtest-seed.sql`, escala média: ~500 orgs/~50k itens/~150k manutenções) | INFRA/CONFIG | — |
| 2 | Profile `loadtest` (Hibernate statistics + log de contagem de query, opt-in) | BACKEND | — |
| 3 | Scripts k6 pros 3 fluxos (login, `/items`, notificação) + execução + relatório de achados | INFRA/CONFIG | Tasks 1 e 2 |

Tasks 1 e 2 são independentes entre si (podem andar em paralelo); Task 3 depende das duas (precisa
do dado semeado e da instrumentação ligada pra gerar um relatório com causa raiz, não só tempo de
resposta).

## Fora de escopo

- Frontend (Next.js) — performance de renderização é disciplina de teste diferente.
- Checkout/billing (Asaas) e qualquer fluxo fora dos 3 priorizados — podem virar continuação depois.
- Corrigir os gargalos encontrados — cada um vira task própria, priorizada por Douglas depois do
  relatório.
- Teste de carga contra staging ou produção.
- Dashboard/observabilidade nova — usa o que já existe (Actuator/Prometheus) + saída do próprio k6.
- Autoscaling, dimensionamento de infra, ou qualquer decisão de hardware — propositalmente fora,
  esse é o ponto central do épico (isolar código de infra).

## Riscos

Baixo pro código de produção — todas as mudanças (profile `loadtest`, scripts k6, seed SQL) são
aditivas e opt-in, nada roda por padrão. Risco real é de esforço: seed de ~200 mil linhas
relacionadas com FK/multi-tenant correto pode exigir iteração pra ficar rápido de rodar
repetidamente; e "achar o gargalo certo" depende de a escala sintética escolhida realmente
denunciar o problema (se a escala média não bastar, pode precisar subir pra "grande" numa iteração
futura — não bloqueia o fechamento deste épico, só limita o que ele consegue provar).
