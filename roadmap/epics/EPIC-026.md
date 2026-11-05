# EPIC-026 — Investigação de performance (API + Web)

## Status
🟡 Análise concluída (skill `performance-expert`, 01/09/2026), sem código alterado. TASK-224 já
extraída pros dois quick wins de baixo risco; o restante fica documentado aqui pra análise
posterior.

## Objetivo
Registrar a investigação completa de performance disparada pelo item #6 da demo com o cliente
Rogerio Dantas (`roadmap/tasks/TASK-218.md`) — "sistema muito lento" durante o cadastro ao vivo —,
separando o que já tem causa raiz clara e fix de baixo risco (vira task já) do que precisa de mais
investigação, confirmação de acesso (Railway, Sentry) ou decisão de produto antes de virar trabalho.

## Contexto
Metodologia aplicada: Medir → Identificar → Explicar → Priorizar (skill `performance-expert`), só
leitura de código nesta rodada — nenhuma mudança foi feita. Investigação cobriu frontend (React/
Next.js) e backend (Spring Boot) ponta a ponta.

---

## Achados

### 1. Busca de tipo de item sem debounce (P1, frontend) — vai pra TASK-224

Confirmado no log real de produção (4 requisições em ~530ms pra "IN"→"INS"→"INST"→"INSTAL") e no
código: `items/new/page.tsx` — `loadOptions` do `AsyncCreatableSelect` chama `api.get` direto a cada
tecla, sem debounce. `react-select/async` não debounça sozinho — é responsabilidade da aplicação.
Fix: debounce ~250-300ms + cancelamento da chamada anterior. Client-only, risco baixo.

### 2. N+1 confirmado na listagem de itens (P1, backend) — vai pra TASK-224

`MaintenanceItemService.buildOffsetResponse`/`buildCursorResponse`/`findAllForCalendar` chamam
`resolveNormInfo(item.getNormId())` **dentro do `.map()`**, um round-trip de banco por item
(`NormService.findById` → `repo.findById`, sem cache, sem batch). Contraste direto: 3 linhas acima,
no mesmo método, `idsWithMaintenance` já é resolvido em lote — o time já usa esse padrão bem
(`MaintenanceService.enrichCancelled` tem até comentário "sem N+1"). É um ponto isolado que escapou,
não um problema sistêmico.

Fix: batch-fetch (`Set<Long>` → `findAllById` → `Map` de lookup, espelhando o padrão já existente 3
linhas acima) e/ou `@Cacheable("norms")` em `NormService.findById` (`@EnableCaching` já ativo,
mesmo padrão já usado em `SupplierSearchService.java:34`). Normas são catálogo curado e quase
estático (~22 registros, EPIC-025) — cache seguro. Risco baixo nos dois.

### 3. `/events?cee=no` e `_rsc=` (P2, precisa confirmação com acesso a produção)

- `_rsc=`: confirmado — prefetch nativo do Next.js App Router, comportamento esperado do framework,
  não é bug.
- `/events?cee=no`: não é rota desta API. Candidato mais provável pela investigação de código:
  `@sentry/nextjs` com `tracesSampleRate: 0.1` ativo em produção (`sentry.client.config.ts:13`) —
  o SDK ativa tracing automático de `fetch`/navegação sem config explícita. **Não confirmado 100%**
  sem um trace de rede ao vivo. Próximo passo: DevTools → Network → clique direito na linha
  `/events` → "Initiator", com alguém logado em produção.

### 4. `LIKE %termo%` sem índice na busca de tipo de item (P3, só monitorar)

`ItemTypesRepository.findByNormalizedNameContaining` usa wildcard nas duas pontas, não usa índice
B-tree. Irrelevante no tamanho atual do catálogo (centenas de linhas, full scan sub-milissegundo).
Só revisitar (índice trigram/`pg_trgm`) se o catálogo crescer muito.

### Descartado como causa (verificado, não assumido)

- React Query já bem configurado globalmente (`staleTime: 2min`, `refetchOnWindowFocus: false`,
  `retry: 1`) — não é fonte de refetch excessivo ao navegar.
- `GET /items` já usa cursor pagination de verdade (`size` default 20), não é `findAll()` sem
  limite.
- Listagem de manutenções canceladas (`MaintenanceService`) já é explicitamente livre de N+1 — o
  padrão que falta no Achado 2 já existe e é usado corretamente noutro lugar do mesmo módulo.

### Hipótese de infraestrutura (P1, precisa confirmação — sem acesso ao painel Railway)

Os 22s observados numa única navegação de volta pra `/items` são grandes demais pra serem
explicados só pelo N+1 (pior caso do Achado 2 soma no máximo algumas centenas de ms). Combina muito
melhor com **cold start**: se o plano do Railway (API e/ou banco) hiberna/escala a zero após
inatividade — plausível num app pré-lançamento com tráfego quase nulo — a primeira requisição após
um período parado paga o custo de subir o container + reconectar o pool, comumente 10-30s. Bate com
o padrão relatado (aconteceu uma vez, não toda navegação). Próximo passo: checar a política de
sleep/idle do serviço direto no painel do Railway.

---

## Tabela de achados

| Prioridade | Camada | Achado | Risco do fix | Status |
|---|---|---|---|---|
| P1 | Frontend | Busca sem debounce | Baixo | → TASK-224 |
| P1 | Backend | N+1 em `resolveNormInfo` | Baixo | → TASK-224 |
| P1 | Infra | Possível cold start (Railway) | N/A (config) | Aguardando Douglas confirmar no painel |
| P2 | Frontend | `/events?cee=no` não identificado com certeza | N/A | Aguardando confirmação via DevTools em produção |
| P2 | Frontend | `_rsc=` | N/A | Nenhuma ação — comportamento esperado |
| P3 | Backend | `LIKE %termo%` sem índice | Baixo | Só monitorar, sem ação agora |

## Plano de ação (fases após a TASK-224)

**Fase 2 — Confirmação de infraestrutura** (precisa acesso do Douglas)
- Verificar política de sleep/idle no Railway (API e banco).
- Confirmar origem de `/events?cee=no` via DevTools Initiator em produção.

**Fase 3 — Observabilidade** (pra medir em vez de estimar da próxima vez)
- Habilitar `hibernate.generate_statistics` (ou equivalente) temporariamente em produção, medir
  contagem de query por request nas rotas mais navegadas (`/items`, `/maintenances`, dashboard).
- Revisar painel do Sentry (Performance, já instalado com tracing 10%) pra p50/p95/p99 reais de
  `GET /items` e `GET /item-types`.

**Fase 4 — Teste de carga** (depois das fases 2-3, nunca direto em produção; ambiente de staging)
- Cenário A: 10-20 usuários virtuais digitando letra a letra em `/item-types?name=X` (think time
  ~150ms) — comparar volume de requisições e p95 antes/depois do debounce da TASK-224.
- Cenário B: `GET /items?size=20` com banco de staging populado com mix realista REGULATORY/
  OPERATIONAL — comparar contagem de query SQL e p95 antes/depois do batch-fetch da TASK-224.
- Volume alvo: baixo (5-20 usuários concorrentes), condizente com o estágio atual do produto (0
  clientes pagantes) — não simular carga de milhares agora.

**Meta de performance sugerida** (ponto de partida, ajustar com dado real do Sentry depois da Fase 3)
```
GET /items       p50 < 150ms   p95 < 500ms
GET /item-types  p50 < 100ms   p95 < 300ms
```

## Tasks
| Task | Descrição | Tipo | Prioridade |
|---|---|---|---|
| [TASK-224](../tasks/TASK-224.md) | Debounce na busca de item + fix do N+1 de normas | FULL_STACK | 🟠 Alto |

## Critério de Conclusão do Épico
- [x] Achados 1 e 2 (causa raiz clara, risco baixo) implementados — TASK-224
- [ ] Achado 3 confirmado (origem de `/events`) e decisão tomada
- [ ] Hipótese de cold start confirmada ou descartada junto com o Douglas
- [ ] Fase 3 (observabilidade) executada, com dado real substituindo as estimativas deste épico
- [ ] Fase 4 (teste de carga) executada em staging, validando o ganho da TASK-224 com número

## Fora de escopo
- Qualquer mudança de infraestrutura (plano do Railway, scaling) sem confirmação e decisão explícita
  do Douglas — é decisão de produto/custo, não só técnica.
- Desabilitar ou reduzir o tracing do Sentry sem confirmar primeiro que é de fato a origem do
  `/events` e que o custo é real (não só teórico).
