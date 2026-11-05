# Teste de Carga Estrutural — Relatório de Achados (EPIC-029)

**Data:** 10/09/2026
**Escopo:** login/autenticação, busca de itens (`GET /items`), detecção de notificação
(`GET /run-jobs/execute-notification-detection`)
**Ambiente:** API local (`local` + `loadtest` profiles) contra um MySQL 8.0.33 efêmero (Docker),
semeado pela TASK-233 (~500 organizações, ~50.000 itens, ~150.000 manutenções). Container e banco
derrubados ao final — nada disso persiste.

---

## Resumo executivo

| Fluxo | Resultado | Ação recomendada |
|---|---|---|
| Login | ✅ Saudável (3 queries, ~90ms) — mas **não deu pra medir capacidade real**, rate limit de IP satura o teste antes de qualquer gargalo de código aparecer | Nenhuma — comportamento correto do rate limiter |
| Busca de itens (`/items`) | ✅ Saudável — 2-3 queries/request, p95 ~203ms sob 100 VUs concorrentes | Nenhuma — já bem otimizado (TASK-224) |
| Detecção de notificação | 🔴 **Gargalo real encontrado** — 5.000 eventos, 17.510 queries, ~5 minutos numa única execução | TASK própria pra lotear o despacho (ver achado #1) |

---

## Achado #1 (crítico) — `NotificationOrchestratorService.dispatch()` processa eventos um a um, sem lote

**Sintoma (evidência numérica):** uma execução de `GET /run-jobs/execute-notification-detection`
contra os ~50.000 itens semeados detectou **5.000 eventos** e levou **305,7 segundos** (~5min) pra
processar, disparando **17.510 queries SQL** no total (~3,5 queries por evento).

```
[Orchestrator] Iniciando despacho de 5000 eventos.     18:00:30.349
[Orchestrator] Despacho de 5000 eventos finalizado.    18:04:41.008   (250,7s só no despacho)
GET .../execute-notification-detection -> 17510 queries, 305670 ms, status=200
```

**Causa raiz:** `NotificationOrchestratorService.dispatch(List<NotificationEvent> events)`
(`infrastructure/notification/service/NotificationOrchestratorService.java:99-108`) itera a lista
inteira com `events.forEach(this::dispatch)` — **sequencial, um evento por vez**. Cada
`dispatch(NotificationEvent)` individual resolve canais (`PUSH`/`EMAIL`/`WHATSAPP`, em memória, sem
custo) e depois faz **até 4 operações com banco por evento**: envio por push (busca token),
envio por email, envio por whatsapp (dedup), e sempre um `saveForOrg` pra notificação in-app —
nenhuma delas em lote, cada uma abrindo sua própria query (ou mais de uma).

Não é um N+1 clássico de uma única query (o volume de itens em si é bem tratado, ver Achado #3) —
é uma **falta de batching no orquestrador de notificações**: com poucos eventos (dezenas) o custo é
imperceptível; a 5.000 eventos (plausível numa base real de ~50k itens, ou mesmo numa base bem
menor com muitos itens vencendo no mesmo dia), o tempo cresce linearmente e já ultrapassa 5 minutos
numa chamada síncrona.

**Risco concreto:** o job real (`NotificationEventDetectionJob`) roda via cron às 5h — nesse
volume, uma execução do cron pode legitimamente demorar minutos, atrasando o disparo de
notificações e competindo por conexões do pool com o tráfego normal da aplicação no mesmo horário.

**Sugestão (sem implementar aqui, por escopo do épico):**
1. Loteamento: uma query por canal por lote de eventos (ex.: buscar todos os push tokens dos
   usuários afetados de uma vez, uma única inserção em lote pras notificações in-app) em vez de
   uma query por evento.
2. Processamento assíncrono/paralelo por evento (com limite de concorrência), já que os 3 canais
   de um mesmo evento já são independentes entre si.
3. Medir de novo depois de qualquer uma das duas mudanças, com o mesmo volume, pra confirmar ganho
   real (não só teórico).

---

## Achado #2 (informativo) — rate limit de login impede medir capacidade real a partir de uma única origem

**Sintoma:** rodando `login.js` (rampa até 100 VUs) contra a API local, **99,52% das requisições**
retornaram `429` — só ~20-27 login bem-sucedidos por minuto, batendo exatamente no limite
configurado (`rate-limit.limits.login.capacity=10`, por IP, recarga a cada 60s).

**Isso não é um bug** — é o rate limiter anti-força-bruta funcionando exatamente como configurado.
Mas é uma limitação real da metodologia deste teste: k6 rodando numa única máquina sempre bate no
limite de IP antes de qualquer gargalo estrutural de código aparecer. As poucas requisições que
passaram mostraram números saudáveis: **3 queries, ~90ms** por login (medido com o instrumento já
corrigido, ver Achado #4) — nada alarmante na amostra que deu pra observar.

**Se o objetivo futuro for medir a capacidade estrutural real do endpoint de login**, seria
necessário rodar a partir de múltiplas origens (IPs distintos) ou desligar/afrouxar o rate limit
temporariamente só durante o teste — nenhuma das duas opções foi feita aqui, de propósito, pra não
mascarar uma proteção de segurança real. Registrado como limitação conhecida, não como gargalo.

---

## Achado #3 (negativo, mas válido) — `GET /items` não tem gargalo estrutural nesta escala

**Resultado:** sob rampa até 100 VUs concorrentes (pool de 100 usuários pré-autenticados),
`/items` respondeu 100% das vezes com sucesso, **p95 = 203ms**, **2-3 queries por request**
(a query de conteúdo + a de contagem total +, quando aplicável, a query em lote de
`idsWithMaintenance`) — nenhum crescimento de query count com o tamanho da página nem com os
filtros aplicados.

Isso confirma que o trabalho da TASK-224 (lotear `canUpdate` e `resolveNormInfo`, já documentado no
contexto técnico do próprio EPIC-029) segue efetivo tanto no caminho de paginação por offset quanto
no de cursor (`MaintenanceItemService.buildOffsetResponse`/`buildCursorResponse`) — os dois batcham
corretamente. **Resultado negativo é informação válida**: não há necessidade de otimizar este
endpoint na escala testada (~50k itens/500 orgs).

---

## Achado #4 (metodológico) — o instrumento de contagem de query (TASK-234) tinha um bug real sob concorrência

Durante a investigação do Achado #3, a primeira medição de `/items` mostrou queries variando de
**2 a 60** por request — parecia um N+1 grave. Investigando a fundo (leitura de
`MaintenanceItemService`, `IMaintenanceItemMapper`, `resolveNormInfoBatch`): nenhum dos caminhos de
código explicava esse crescimento. Causa raiz real: **`LoadTestQueryCountFilter` usava
`Statistics.getQueryExecutionCount()` do Hibernate, um contador GLOBAL do `SessionFactory` inteiro,
não por-request** — sob carga concorrente (múltiplos VUs simultâneos), uma request contava queries
de *outras* requests acontecendo na mesma janela de tempo.

**Corrigido** (TASK-234, mesma sessão): trocado por `LoadTestStatementInspector`
(`org.hibernate.resource.jdbc.spi.StatementInspector`) com contador `ThreadLocal` — preciso mesmo
sob concorrência, já que o JDBC aqui é síncrono no thread da própria requisição. Teste de
concorrência real (20 threads simultâneas, cada uma "rodando" uma contagem diferente de queries)
prova que threads não se contaminam mais. Depois da correção, `/items` consistentemente mostrou
2-3 queries — o número real, confirmando o Achado #3.

**Lição pra quem for usar `hibernate.generate_statistics` de novo:** o objeto `Statistics` do
Hibernate é sempre agregado no nível do `SessionFactory`; pra contagem por-request sob carga real
(múltiplos threads), `StatementInspector` com `ThreadLocal` é o caminho certo, não
`Statistics.getQueryExecutionCount()`.

---

## O que não foi testado

- **Concorrência real de login** — bloqueada pelo rate limit (Achado #2).
- **Escala maior que "média"** — a spec original já registrava esse risco: se a escala sintética
  (500 orgs/50k itens) não bastasse pra expor todo gargalo relevante, seria sinal de escala
  insuficiente, não de ausência de problema. Pro fluxo de notificação, a escala já bastou (achado
  #1 é real e significativo); pra `/items`, não dá pra descartar que um volume maior por
  organização (não só mais organizações) revele algo — não testado aqui.
- **Concorrência real do job de detecção** — só uma execução foi medida; duas execuções
  sobrepostas (ex.: cron atrasado + disparo manual) não foram testadas.

## Arquivos

- `db/queries/loadtest-seed.sql` + `db/queries/README-loadtest.md` (TASK-233)
- `src/main/resources/application-loadtest.properties`,
  `shared/web/filter/{LoadTestQueryCountFilter,LoadTestStatementInspector,LoadTestHibernateConfig}.java`
  (TASK-234)
- `loadtest/{login,items-search,notification-detection}.js` + `loadtest/README.md` (TASK-235)
