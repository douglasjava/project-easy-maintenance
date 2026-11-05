# EPIC-019 — Product Analytics: motor de eventos próprio (event-driven)

## Status
Em Análise — desenhada a pedido de Douglas em 31/07/2026. Ainda não priorizada/sequenciada no
kanban; este documento é a proposta de arquitetura e o backlog de tasks pronto para quando for
priorizada. Nenhuma task individual foi criada em `roadmap/tasks/` ainda — isso acontece no momento
em que o épico entrar em sprint (ver seção 7/8/9 para os candidatos a TASK-1XX).

---

## 1. Epic

### Nome
Product Analytics — motor de eventos interno, event-driven, para substituir a dependência de
Google Analytics / Microsoft Clarity nos casos de uso internos do time.

### Descrição
Hoje não existe nenhuma instrumentação de analytics própria no Easy Maintenance — nem na landing
pública, nem na aplicação autenticada. O EPIC-018 já criou parte da infraestrutura de baixo nível
que este épico vai reaproveitar diretamente: cookie de atribuição UTM (`em_utm`, `src/lib/utm.ts`),
o checkbox de consentimento LGPD no formulário de lead, e os stubs `trackLead()`/`trackContact()`
em `src/lib/tracking.ts` (hoje só disparam pixels de terceiros — este épico é o que dá a eles um
destino próprio, além do Meta/Google).

O objetivo é ter uma **plataforma de eventos própria**: o frontend (landing pública + aplicação
autenticada) emite eventos de comportamento, um endpoint HTTP no backend recebe e persiste esses
eventos, e um conjunto de dashboards internos (não expostos a clientes nesta fase) permite ao time
responder perguntas de produto e marketing sem depender de ferramentas externas.

Esta é uma base de plataforma, não um dashboard isolado — o desenho tem que aguentar, sem reescrita,
os próximos épicos naturais: funis, heatmaps, session replay, feature usage analytics.

### Valor de Negócio
- Fecha o loop de mensuração que o EPIC-018 abriu: hoje sabemos que uma campanha gerou um lead
  (via UTM no `landing_leads`), mas não sabemos **o que aconteceu na página antes disso** — que
  seção o visitante leu, se rolou até "Diferenciais", se abandonou o formulário no meio.
- Remove dependência de ferramentas de terceiros (GA4/Clarity) para decisões de produto e CRO —
  sem limite de amostragem, sem exportação de dados para fora do nosso controle, sem risco de
  descontinuação de ferramenta gratuita.
- Vira ativo de produto: a mesma infraestrutura de "feature usage" pode, no futuro, virar uma tela
  de analytics **dentro do próprio Easy Maintenance**, vendida como diferencial pra clientes
  (ex.: "veja como sua equipe usa a plataforma") — mesmo padrão de outros SaaS de gestão.

### Métricas de Sucesso
- 100% dos page views e CTA clicks da landing pública capturados em produção, com perda de evento
  (client enviou, servidor não recebeu) **< 5%** medida por comparação de contagem client-side vs
  persistida.
- Latência de ingestão (POST do evento até confirmação 202) com **p95 < 200ms**.
- SDK de analytics no frontend com **< 5kb gzip** e sem impacto mensurável no LCP da landing
  (mesma bateria de Lighthouse já usada no EPIC-018 — não pode fazer o Performance score regredir).
- Dashboard interno respondendo "de onde vêm nossos leads e onde eles abandonam o formulário" sem
  precisar abrir GA4/Clarity, dentro de 1 sprint após o MVP estar em produção.

### Riscos
- **Overengineering de infraestrutura**: MongoDB + RabbitMQ são peças novas no stack (hoje é só
  MySQL/Flyway). Rodar isso em produção é custo operacional novo (mais um serviço pra monitorar,
  fazer backup, atualizar). Mitigação: MVP sem RabbitMQ (ingestão síncrona direto pro Mongo);
  RabbitMQ só entra como task de fase 2, quando o volume justificar desacoplar ingestão de escrita.
- **Poluição de dados por bots/crawlers**: endpoint de ingestão é público (a landing não tem
  login). Sem filtro de bot, os dashboards ficam inúteis. Mitigação: task dedicada de filtro
  (user-agent, honeypot, rate limit) antes de qualquer dashboard ser considerado confiável.
- **Exposição de LGPD**: estamos capturando comportamento de visitantes anônimos numa página
  pública. Precisa de base legal clara (legítimo interesse para métricas agregadas/anonimizadas;
  consentimento explícito só quando o evento correlaciona com dado identificado, ex. e-mail do
  lead). Mitigação: ver seção de NFRs de Privacidade/LGPD abaixo — isso não é opcional, é
  bloqueante pra ir a produção.
- **"Reinventar a roda"**: Mixpanel/PostHog/Clarity já resolvem isso com anos de maturidade. Este
  épico é justificável porque (a) o caso de uso inicial é interno e pequeno o suficiente pra não
  precisar da sofisticação de uma ferramenta paga, e (b) a visão de produto (feature analytics
  dentro do próprio Easy Maintenance) não é algo que se compra de terceiro. Se o objetivo fosse só
  "ver de onde vêm os visitantes", a resposta certa seria continuar no GA4 gratuito — importante
  deixar isso registrado para não perder de vista o motivo real de construir isso.
- **Custo de manutenção contínuo**: analytics próprio nunca "termina" — é um poço sem fundo de
  features incrementais (ver Roadmap Futuro). Mitigação: escopo do MVP deliberadamente pequeno
  (seção 2), tudo além disso é épico futuro, não backlog deste.

### Considerações Técnicas
- **Poliglota de persistência deliberado**: MongoDB é a escolha certa aqui (schema de evento varia
  por `eventName`, volume de escrita alto, leitura majoritariamente agregada) — não faz sentido
  forçar isso em tabelas MySQL relacionais. Mas isso é uma peça de infra nova rodando ao lado do
  MySQL existente; precisa entrar no `docker-compose` de desenvolvimento e na checklist de
  infraestrutura de produção (ver documento de inventário técnico já existente no projeto).
- **Multi-tenancy**: o padrão `X-Org-Id` já usado no resto da API não se aplica direto aqui, porque
  a maior parte do tráfego (landing pública) não tem organização nem sessão autenticada ainda.
  O conceito equivalente aqui é `visitorId` (anônimo, antes do login) que se resolve pra `userId`/
  `orgId` no momento do login via o evento `IDENTIFY` — é assim que Mixpanel/PostHog fazem essa
  ponte, e é o mesmo problema que o cookie `em_utm`/`em_ref` já resolve parcialmente hoje.
- **Reaproveitamento direto do EPIC-018**: `src/lib/utm.ts` (captura de UTM), o padrão de cookie
  `em_ref`, e os stubs de `src/lib/tracking.ts` são a base de que este épico parte — não é trabalho
  do zero.
- **Padrão de erro já estabelecido**: o endpoint de ingestão deve seguir o mesmo padrão
  `ProblemDetail`/`GlobalExceptionHandler` já usado no resto da API — sem inventar um novo formato
  de erro só pra analytics.

---

## 2. Requisitos Funcionais

1. Capturar eventos de comportamento tanto na landing pública (sem autenticação) quanto na
   aplicação autenticada (com `userId`/`orgId` conhecidos).
2. Atribuir cada evento a uma sessão (`sessionId`, expira após 30min de inatividade) e a um
   visitante (`visitorId`, cookie de longa duração, sobrevive entre sessões).
3. Resolver a identidade do visitante anônimo para usuário autenticado no momento do login
   (evento `IDENTIFY`), permitindo reconstruir o caminho completo "primeiro clique no anúncio →
   virou lead → virou cliente pagante".
4. Persistir a atribuição de campanha (UTM) já capturada pelo `em_utm` em todo evento da sessão,
   não só no lead.
5. Respeitar o consentimento do usuário: eventos de um visitante que não deu consentimento (ou que
   está numa página sem o gate de consentimento, ex. app autenticado) são tratados como
   **agregados/anonimizados por padrão** — nada de rastreamento identificado sem base legal clara
   (ver NFRs).
6. Emitir e receber, no mínimo, os eventos definidos na seção 4 (Modelo de Eventos).
7. Fornecer uma API de consulta agregada (não a coleção bruta) para os dashboards internos:
   visitantes, sessões, funis simples, páginas mais vistas, CTAs mais clicados, campanhas que mais
   convertem, taxa de rejeição, taxa de conversão.
8. Filtrar tráfego de bot/crawler antes de persistir (ou marcar como bot e excluir das agregações
   por padrão).
9. Permitir exportação/exclusão de dados de um visitante/usuário específico mediante solicitação
   (direito LGPD), reaproveitando o fluxo de exclusão de conta já existente em `/profile`.
10. Aplicar retenção automática dos dados brutos (TTL), mantendo apenas agregações de longo prazo.

**Fora de escopo do MVP** (ver Roadmap Futuro): heatmap visual, session replay, funil configurável
via UI, A/B testing, alertas de anomalia.

---

## 3. Requisitos Não Funcionais

### Performance
- Chamada de tracking no cliente é **fire-and-forget**, nunca bloqueia renderização ou navegação.
- Eventos são enfileirados no cliente e enviados em lote (batch) a cada N segundos ou ao atingir
  tamanho máximo de fila — não uma requisição HTTP por evento.
- No `unload`/troca de aba, o lote pendente é enviado via `navigator.sendBeacon` (não via `fetch`
  síncrono, que pode ser bloqueado pelo navegador).
- Endpoint de ingestão: p95 < 200ms, aceitando lotes de até ~50 eventos por requisição.

### Escalabilidade
- Serviço de ingestão stateless, horizontalmente escalável (múltiplas instâncias atrás do mesmo
  load balancer já existente).
- Collections do MongoDB desenhadas para volume alto de escrita e leitura majoritariamente via
  agregações pré-computadas (rollups), não queries ad-hoc sobre a coleção bruta em produção.
- RabbitMQ como *fase 2*, não MVP: desacopla o pico de escrita da ingestão do processamento/
  agregação quando o volume justificar (ver Backend Task 10).

### Privacidade / LGPD
- `visitorId` é um UUID aleatório gerado no cliente, **sem PII embutido**, armazenado em cookie
  (mesmo padrão `sameSite: Lax`, 1 ano de expiração — mais longo que o `em_utm` porque aqui é
  identidade, não atribuição de campanha).
- IP do visitante nunca é persistido em texto puro: truncar o último octeto (IPv4) ou usar hash
  com salt rotativo — suficiente para geolocalização aproximada (`country`) sem identificar o
  indivíduo.
- Nenhum campo de evento aceita PII livre (nome, e-mail, telefone) em `customProperties` por
  padrão — isso exige revisão explícita caso a caso, documentada, não uma decisão de código.
- Rastreamento antes de consentimento (na landing) é limitado ao mínimo necessário pra métricas
  agregadas de página (legítimo interesse, LGPD Art. 7º, IX); rastreamento correlacionado com
  identidade (pós-login, ou vinculado a um lead identificado) exige o consentimento já coletado no
  formulário (EPIC-018) ou consentimento equivalente dentro do app.
- Exclusão de conta (já existente em `/profile`) deve, a partir deste épico, também anonimizar
  `visitorId`/`userId` nos eventos já persistidos (job assíncrono, não bloqueia a exclusão).

### Segurança
- Endpoint de ingestão é público (não exige token de autenticação — a landing não tem sessão), mas:
  - Rate limit por IP/visitorId (reaproveitar o padrão de rate limiting já existente na API para
    endpoints de autenticação, ver EPIC-001).
  - Payload com schema validado (Bean Validation) e tamanho máximo de lote/evento — rejeita lotes
    grandes demais ou campos fora do enum de `eventName` conhecido.
  - CORS restrito ao(s) domínio(s) do próprio site (`easymaintenance.com.br` + ambientes de
    staging/local) — não é uma API pública genérica.
- Dashboards internos ficam atrás da autenticação/autorização já existente (área `/private/*`,
  mesmo padrão dos outros paineis administrativos).

### Disponibilidade
- Falha do backend de ingestão (ou do Mongo) **não pode quebrar a experiência do usuário**: o SDK
  do frontend falha silenciosamente, mantém o lote na fila local (localStorage/IndexedDB) e tenta
  reenviar depois (retry com backoff exponencial).

### Armazenamento e Retenção
- Coleção de eventos brutos: TTL de **90 dias**.
- Coleção de sessões (derivada): TTL de **180 dias**.
- Coleção de visitantes (identidade de longo prazo, sem dado de comportamento): sem TTL, mas
  sujeita a anonimização por solicitação LGPD.
- Agregações/rollups diários: sem TTL — são pequenos (uma linha por dia/página/campanha, não uma
  linha por evento) e são o que realmente importa preservar no longo prazo.

---

## 4. Modelo de Eventos

| Evento | Quando dispara | Por quê importa |
|---|---|---|
| `PAGE_VIEW` | Troca de rota (Next.js router) ou carregamento inicial | Métrica de tráfego básica; uma linha por página vista |
| `SECTION_VIEW` | Uma seção nomeada (`data-analytics-section`) entra 50%+ no viewport (IntersectionObserver) | Mede profundidade de leitura real — resolve "até onde o visitante rolou antes de decidir" (ligação direta com o reposicionamento de seções feito no EPIC-018) |
| `SCROLL_DEPTH` | Marcos de 25/50/75/100% da altura da página, com throttle | Proxy de engajamento quando não há seções nomeadas |
| `CTA_CLICK` | Clique em elemento marcado como CTA (`data-analytics-cta="id"`) | Eventos de conversão nomeados — "Solicitar Demonstração", "Falar com Consultor" |
| `BUTTON_CLICK` | Clique em botão sem marcação de CTA | Ruído de UI geral, menor prioridade que `CTA_CLICK` — não polui a análise de conversão |
| `FORM_START` | Primeiro `focus` em qualquer campo de um formulário rastreado | Início de intenção — base pra medir abandono |
| `FORM_SUBMIT` | Submit bem-sucedido (retorno 2xx da API) | Conversão do formulário |
| `FORM_ERROR` | Erro de validação client-side ou rejeição da API no submit | Diagnóstico de fricção — ex.: quantos tentam submeter sem marcar o checkbox de consentimento |
| `FORM_ABANDON` | `FORM_START` sem `FORM_SUBMIT` até o fim da sessão (computado, não um clique) | Mede abandono real, não só clique |
| `VIDEO_PLAY` / `VIDEO_PAUSE` / `VIDEO_COMPLETE` | Player de vídeo | Relevante se a landing ganhar vídeo explicativo (discussão em aberto do EPIC-018) |
| `DOWNLOAD` | Clique em link para arquivo baixável | Engajamento com conteúdo (ex.: material comercial em PDF) |
| `SEARCH` | Uso de campo de busca dentro do app | Relevante pra `/private/users`, `/items`, etc., que já têm busca |
| `LOGIN` / `LOGOUT` | Ciclo de autenticação | Marca transição de anônimo → identificado |
| `IDENTIFY` | Disparado junto do `LOGIN` (ou cadastro) | Vincula `visitorId` anônimo ao `userId`/`orgId` — é o que fecha o funil "anúncio → lead → cliente" |
| `FEATURE_USED` | Ação de produto dentro do app (ex.: criar manutenção, exportar relatório) | Base do futuro "Feature Usage Analytics"; `customProperties.feature` identifica a ação |
| `ERROR` | Erro JS capturado por Error Boundary no frontend | Qualidade/estabilidade, não é métrica de marketing mas usa a mesma esteira |
| `API_ERROR` | Falha de chamada à API correlacionada (já usa `ProblemDetail`) | Captura `httpStatus` + `problemType`, cruza erro técnico com o que o usuário estava fazendo |
| `SESSION_START` / `SESSION_END` | Início/fim de sessão (timeout de 30min) | Delimita as métricas de sessão (duração, nº de páginas) |
| `CUSTOM_EVENT` | Qualquer coisa fora da lista acima | Escape hatch — `eventName` livre + `customProperties`, usado com moderação |

---

## 5. Payload do Evento

Envelope padrão (todo evento carrega isso, independente do `eventName`):

```typescript
interface AnalyticsEvent {
  // Identidade
  sessionId: string;      // UUID, renovado após 30min de inatividade
  visitorId: string;      // UUID, cookie de 1 ano, sobrevive entre sessões
  tenantId?: string;      // orgId, presente só após login (equivalente ao X-Org-Id do resto da API)
  userId?: string;        // presente só após IDENTIFY

  // Quando e onde
  timestamp: string;      // ISO 8601, gerado no cliente (servidor registra timestamp de ingestão à parte)
  page: string;           // título/label lógico da página, ex. "landing"
  route: string;          // rota Next.js, ex. "/landing"
  url: string;            // URL completa com querystring
  referrer: string;

  // Ambiente
  userAgent: string;
  device: "mobile" | "tablet" | "desktop";
  browser: string;
  screenResolution: string;   // "1920x1080"
  language: string;           // navigator.language
  country?: string;           // resolvido no servidor via IP truncado, não enviado pelo cliente

  // Atribuição (mesmo shape do em_utm existente)
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  utm_content?: string;
  utm_term?: string;
  gclid?: string;
  fbclid?: string;

  // O evento em si
  eventName: string;      // um dos valores da seção 4
  elementId?: string;     // data-analytics-cta / id do elemento clicado
  elementType?: string;   // "button" | "link" | "input" | ...
  section?: string;       // nome da seção (SECTION_VIEW)
  timeOnPage?: number;    // ms desde o PAGE_VIEW
  scrollDepth?: number;   // 25 | 50 | 75 | 100

  customProperties?: Record<string, string | number | boolean>;
}
```

Notas de implementação:
- `country` **não** é enviado pelo cliente — resolvido no backend a partir do IP (truncado antes de
  persistir), pra evitar confiar em dado de geolocalização client-side falsificável.
- `utm_*`/`gclid`/`fbclid` são lidos do `getStoredUtm()` já existente (`src/lib/utm.ts`) — este
  épico estende esse helper pra também guardar `gclid`/`fbclid` quando presentes na URL, hoje ele
  só guarda os 5 campos `utm_*`.
- O DTO Java correspondente (`AnalyticsEventRequest`) segue o mesmo padrão `record` + Bean
  Validation já usado em `CreateLeadRequest`.

---

## 6. Desenho de Banco de Dados (MongoDB)

### Collections

| Collection | Conteúdo | TTL |
|---|---|---|
| `events` | Evento bruto, um documento por evento | 90 dias (`createdAt`) |
| `sessions` | Documento por sessão, atualizado incrementalmente (nº de páginas, duração, primeira/última página, se converteu) | 180 dias |
| `visitors` | Identidade de longo prazo: `visitorId` → `userId`/`orgId` (quando resolvido via `IDENTIFY`), primeira campanha de atribuição (first-touch) | Sem TTL — sujeito a anonimização sob solicitação LGPD |
| `daily_page_stats` | Rollup: `{date, route, pageViews, uniqueVisitors, avgTimeOnPage, bounceRate}` | Sem TTL |
| `daily_campaign_stats` | Rollup: `{date, utm_source, utm_medium, utm_campaign, sessions, leads, conversions}` | Sem TTL |
| `daily_cta_stats` | Rollup: `{date, elementId, page, clicks, uniqueVisitors}` | Sem TTL |

### Índices
- `events`: composto `{tenantId: 1, timestamp: -1}`, composto `{sessionId: 1, timestamp: 1}`,
  composto `{eventName: 1, timestamp: -1}` (consultas de dashboard filtram por tipo de evento +
  janela de tempo o tempo todo).
- `sessions`: `{visitorId: 1}`, `{startedAt: -1}`.
- `visitors`: índice único em `visitorId`; índice em `userId` (esparso, só existe após login).
- Rollups (`daily_*`): índice único composto na chave de agrupamento (`{date, route}`,
  `{date, utm_source, utm_medium, utm_campaign}`, `{date, elementId, page}`) — upsert idempotente
  no job de agregação.

### Estratégia de Agregação
MVP usa **rollup em batch**, não streaming: um job agendado (Spring `@Scheduled`, rodando de hora
em hora + uma consolidação diária) roda o *aggregation pipeline* do Mongo sobre a janela de tempo
recém-fechada e faz upsert nas coleções `daily_*`. Os dashboards leem só as coleções de rollup —
nunca fazem agregação ad-hoc sobre `events` bruto em produção (isso é o que evita a necessidade de
um Elasticsearch/ClickHouse no MVP). Consultas pontuais de debug sobre `events` bruto são aceitáveis
via ferramenta interna, não via endpoint de dashboard.

### TTL
TTL indexes nativos do MongoDB (`expireAfterSeconds`) nos campos `createdAt` de `events` e
`sessions` — sem necessidade de job de limpeza próprio.

---

## 7. Backend Tasks

| # | Título | Prioridade | Complexidade | Dependências |
|---|---|---|---|---|
| BE-1 | Endpoint de ingestão `POST /analytics/events` (lote) | 🔴 Crítico | Média | Nenhuma |
| BE-2 | Schema/validação do evento (`AnalyticsEventRequest`, enum `EventName`) | 🔴 Crítico | Baixa | BE-1 |
| BE-3 | Persistência MongoDB (repository, índices, TTL) | 🔴 Crítico | Média | BE-2, infra Mongo no Docker |
| BE-4 | Resolução de sessão (`sessionId`, timeout 30min) | 🟠 Alto | Média | BE-3 |
| BE-5 | Resolução de identidade (`IDENTIFY`, vínculo visitorId→userId/orgId) | 🟠 Alto | Média | BE-4 |
| BE-6 | Filtro de bot/abuso (UA, rate limit, honeypot) | 🔴 Crítico | Média | BE-1 |
| BE-7 | Job de agregação/rollup (`@Scheduled`, pipelines Mongo) | 🟠 Alto | Alta | BE-3 |
| BE-8 | API de consulta pros dashboards (endpoints agregados, não a coleção bruta) | 🟠 Alto | Média | BE-7 |
| BE-9 | Job de retenção/anonimização LGPD (hook na exclusão de conta existente) | 🟠 Alto | Média | BE-3, BE-5 |
| BE-10 *(fase 2)* | Pipeline assíncrono via RabbitMQ (desacopla ingestão de escrita) | 🟡 Médio | Alta | BE-1, volume real que justifique |

**BE-1 — Endpoint de ingestão**
- Descrição: `POST /easy-maintenance/api/v1/analytics/events`, aceita array de eventos (até ~50 por
  lote), sem autenticação, retorna 202 Accepted imediatamente (processamento é fire-and-forget do
  lado do servidor também — não espera a escrita no Mongo pra responder).
- Critérios de aceite: aceita lote válido e retorna 202; rejeita lote vazio ou maior que o limite
  com 400 (`ProblemDetail`); CORS restrito aos domínios do site.
- Dependências: nenhuma (primeira task do épico).

**BE-2 — Schema/validação**
- Descrição: `record AnalyticsEventRequest` com Bean Validation; `enum EventName` com os valores da
  seção 4 + fallback `CUSTOM_EVENT`; eventos com `eventName` desconhecido são aceitos como
  `CUSTOM_EVENT` (não rejeitados — evita quebrar o cliente por um typo).
- Critérios de aceite: evento com campo obrigatório ausente (`sessionId`, `visitorId`, `eventName`)
  é rejeitado; evento com `eventName` fora do enum vira `CUSTOM_EVENT` com o valor original
  preservado em `customProperties.originalEventName`.

**BE-3 — Persistência MongoDB**
- Descrição: dependência `spring-boot-starter-data-mongodb`, configuração de conexão via
  variável de ambiente (mesmo padrão de secrets já usado pro MySQL), `EventDocument` +
  `EventRepository`, criação de índices via `@Indexed`/script de bootstrap.
- Critérios de aceite: evento persistido é recuperável por `sessionId`; índices criados
  automaticamente na subida da aplicação (ambiente local/staging); TTL configurado e validado
  manualmente (documento expira após o tempo configurado em ambiente de teste com TTL reduzido).

**BE-4 — Resolução de sessão**
- Descrição: se o `sessionId` recebido não existe ou está inativo há mais de 30min, gera um novo
  e retorna no corpo da resposta (o cliente atualiza seu cookie/estado local); grava/atualiza
  documento em `sessions`.
- Critérios de aceite: dois eventos no mesmo `sessionId` dentro de 30min contam como a mesma
  sessão; evento após 30min de silêncio gera nova sessão.

**BE-5 — Resolução de identidade**
- Descrição: evento `IDENTIFY` (disparado no login) grava/atualiza documento em `visitors`
  vinculando `visitorId` → `userId`/`orgId`; eventos subsequentes do mesmo `visitorId` (mesmo
  antes deste específico ser recebido) podem ser retroativamente enriquecidos com `userId` via
  job assíncrono (não bloqueia o fluxo de login).
- Critérios de aceite: após `IDENTIFY`, consulta por `userId` retorna também os eventos anteriores
  ao login que tinham o mesmo `visitorId`.

**BE-6 — Filtro de bot/abuso**
- Descrição: middleware/interceptor que descarta ou marca (`isBot: true`) requisições com
  user-agent de crawler conhecido, aplica rate limit por IP/visitorId reaproveitando o padrão já
  existente para endpoints de autenticação.
- Critérios de aceite: user-agent de bot conhecido (Googlebot, etc.) não aparece nas agregações
  por padrão; IP que excede o rate limit recebe 429.

**BE-7 — Job de agregação**
- Descrição: `@Scheduled` horário + diário, roda `aggregation pipeline` do Mongo sobre a janela
  fechada, faz upsert idempotente em `daily_page_stats`, `daily_campaign_stats`, `daily_cta_stats`.
- Critérios de aceite: rodar o job duas vezes seguidas sobre a mesma janela não duplica dado
  (idempotente); dashboard reflete dado até a última execução do job (não em tempo real — isso é
  aceitável e documentado no MVP).

**BE-8 — API de consulta**
- Descrição: endpoints REST autenticados (área privada) que leem as coleções de rollup — um
  endpoint por card de dashboard da seção 9, não uma API genérica de query.
- Critérios de aceite: cada endpoint aceita filtro de intervalo de datas; resposta paginada onde
  aplicável (ex.: lista de páginas).

**BE-9 — Retenção/anonimização LGPD**
- Descrição: hook no fluxo de exclusão de conta já existente — ao excluir/anonimizar um usuário,
  dispara job assíncrono que anonimiza `userId`/`visitorId` associados em `events`/`sessions`/
  `visitors` (sem apagar a linha, só removendo a identificação, pra não distorcer as agregações
  históricas).
- Critérios de aceite: após exclusão de conta, nenhuma consulta por `userId` antigo retorna dado;
  contagens agregadas de `daily_*` não mudam (a agregação já era anônima).

---

## 8. Frontend Tasks

| # | Título | Prioridade | Complexidade | Dependências |
|---|---|---|---|---|
| FE-1 | SDK core de analytics (`track`, `identify`, `page`) — agnóstico de framework | 🔴 Crítico | Média | BE-1 |
| FE-2 | Fila de envio em lote + `sendBeacon` no unload | 🔴 Crítico | Média | FE-1 |
| FE-3 | Fila offline (localStorage) + retry com backoff | 🟠 Alto | Média | FE-2 |
| FE-4 | `AnalyticsProvider` (React Context) + `useAnalytics()` hook | 🔴 Crítico | Baixa | FE-1 |
| FE-5 | Tracking automático de `PAGE_VIEW` via App Router | 🔴 Crítico | Baixa | FE-4 |
| FE-6 | Tracking automático de `SCROLL_DEPTH` e `SECTION_VIEW` (IntersectionObserver) | 🟠 Alto | Média | FE-4 |
| FE-7 | Helpers de evento customizado (`data-analytics-cta`, tracking de formulário) | 🟠 Alto | Baixa | FE-4 |
| FE-8 | Gate de consentimento (reaproveita o checkbox LGPD do EPIC-018) | 🔴 Crítico | Baixa | FE-1 |
| FE-9 | Orçamento de performance (< 5kb gzip, sem bloquear main thread) — validado via Lighthouse | 🟠 Alto | Baixa | FE-1..FE-8 |

Notas:
- **FE-1** vive como pacote isolado (`src/lib/analytics/`), sem dependência de React — os hooks
  (FE-4) são uma camada fina por cima, mesmo padrão que `src/lib/utm.ts` e `src/lib/tracking.ts` já
  seguem hoje (lib pura + integração no componente).
- **FE-5** reaproveita exatamente o padrão do componente `UtmCapture` (montado no `RootLayout`,
  sem render visível, efeito de captura) — não é uma abstração nova.
- **FE-8**: enquanto não houver decisão de produto sobre um banner de consentimento genérico
  (fora da landing, onde já existe o checkbox), o tracking em páginas sem gate de consentimento
  explícito fica limitado a eventos agregados/anônimos (ver NFR de Privacidade) — isso é uma
  decisão de política, não só de código, e deve ser validada com Douglas antes do FE-8 ser
  considerado "pronto".

---

## 9. Dashboard Tasks

Painel interno novo em `/private/analytics` (mesmo padrão de autenticação/autorização da área
`/private/*` já existente), com os seguintes cards/telas:

| # | Tela | Descrição |
|---|---|---|
| DASH-1 | Visão geral de visitantes | Visitantes únicos, novos vs. recorrentes, por período |
| DASH-2 | Sessões | Lista de sessões com duração, nº de páginas, origem (UTM) |
| DASH-3 | Funil (MVP fixo) | Funil nomeado fixo: `PAGE_VIEW(landing) → FORM_START → FORM_SUBMIT → IDENTIFY` — funil configurável fica pro Roadmap Futuro |
| DASH-4 | Explorador de eventos | Tabela filtrável por `eventName`/página/período (uso interno/debug) |
| DASH-5 | Páginas mais vistas | Top N por `pageViews`, com tempo médio na página |
| DASH-6 | CTAs mais clicados | Top N por `elementId`, com taxa de clique sobre `PAGE_VIEW` da página onde aparece |
| DASH-7 | Campanhas (UTM) | Top campanhas por sessões e por conversão (lead/`IDENTIFY`) — consome `daily_campaign_stats` |
| DASH-8 | Taxa de rejeição (bounce rate) | % de sessões com uma única `PAGE_VIEW` e sem outro evento de interação |
| DASH-9 | Taxa de conversão | `FORM_SUBMIT` ou `IDENTIFY` sobre `PAGE_VIEW`, por página/campanha |
| DASH-10 | Uso de features | `FEATURE_USED` agregado por organização/plano (semente do futuro "Feature Usage Analytics") |

Heatmap visual e timeline de sessão (replay simplificado) aparecem na lista, mas como
**placeholders desabilitados** nesta fase — a UI já reserva o espaço/rota, a implementação real é
do Roadmap Futuro (seção 10), porque dependem de captura adicional (posição de mouse/scroll bruto)
que este MVP não coleta.

---

## 10. Roadmap Futuro

Épicos candidatos, nesta ordem sugerida de valor/dependência:

1. **Funis configuráveis** — generaliza o DASH-3 fixo pra um builder onde qualquer sequência de
   eventos vira um funil, com taxa de queda por etapa.
2. **Heatmaps** — requer capturar posição de clique/scroll bruto (novo evento de alta frequência,
   provavelmente já justificando o RabbitMQ da BE-10).
3. **Session Replay** — captura de DOM/interação estilo `rrweb`; maior implicação de LGPD de todo
   o roadmap (grava a tela do usuário) — precisa de opt-in explícito, não legítimo interesse.
4. **Cohort Analysis / Retenção** — agrupar visitantes/usuários por semana de primeira visita e
   medir retorno ao longo do tempo.
5. **User Journey** — visualização de caminho entre páginas/eventos (Sankey), construído sobre o
   mesmo `events` bruto.
6. **A/B Testing** — depende de um sistema de feature flags (próximo item) pra variar experiência
   e medir impacto via os mesmos eventos.
7. **Feature Flags** — infraestrutura própria de flags, natural de nascer aqui porque já existe o
   pipeline de eventos pra medir o impacto de cada flag.
8. **Detecção de anomalia** — alertar quando uma métrica (ex.: taxa de conversão de uma campanha)
   sai do padrão histórico.
9. **AI Insights / Predictive Analytics** — camada de cima que interpreta os dados já agregados
   (ex.: prever churn a partir de queda em `FEATURE_USED`) — só faz sentido depois que houver
   volume histórico suficiente nas coleções deste épico.

---

## Regras de Engenharia Aplicadas Neste Desenho

- MVP sem RabbitMQ — ingestão síncrona é suficiente pro volume inicial (interno + landing); fila
  é fase 2, não pré-requisito.
- MVP sem heatmap/session replay/funil configurável — essas são as partes que mais se pareceriam
  com "reconstruir o Mixpanel inteiro"; o valor imediato (saber de onde vêm os visitantes, onde
  abandonam formulário, o que mais é clicado) não depende delas.
- Cada task do backend e do frontend é entregável dentro de uma sprint — nenhuma depende de mais
  de duas outras tasks do mesmo épico.
- Nenhuma decisão de PII/consentimento foi tratada como "detalhe de implementação" — está marcada
  explicitamente como decisão de produto que precisa de validação de Douglas antes de ir a
  produção (ver FE-8 e a seção de Privacidade/LGPD).
