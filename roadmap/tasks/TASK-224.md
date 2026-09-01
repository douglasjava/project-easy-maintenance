# TASK-224 — FULL_STACK: Debounce na busca de item + fix do N+1 de normas

## Tipo
FULL_STACK

## Categoria
Backend + Frontend / Performance

## Prioridade
🟠 Alto — achados #1 e #2 da investigação de performance (EPIC-026), causa raiz clara e fix de
baixo risco pros dois.

## Épico
[EPIC-026](../epics/EPIC-026.md) — Investigação de performance (API + Web)

## QA obrigatório
Sim — QA manual: digitar um tipo de item novo devagar e confirmar (Network tab) que dispara 1
requisição por pausa, não uma por letra; listar itens numa organização com vários itens REGULATORY
e confirmar (SQL log/Hibernate statistics) que o número de queries não cresce com a quantidade de
itens na página.

---

## Contexto

Achado durante a investigação de performance (item #6 da demo com o cliente Rogerio Dantas,
`TASK-218.md`), detalhe completo em `EPIC-026.md`. Dois problemas com causa raiz confirmada no
código e fix de baixo risco, agrupados numa task só por serem pequenos e independentes entre si.

## Escopo

### Frontend — debounce na busca de tipo de item
- `items/new/page.tsx`: `loadOptions` do `AsyncCreatableSelect` (linha ~84) chama `api.get` direto
  a cada tecla digitada — sem debounce, `react-select/async` não debounça sozinho.
- Adicionar debounce de ~250-300ms, com cancelamento da chamada em andamento a cada nova tecla
  (evita a resposta de uma busca antiga sobrescrever uma mais recente que chegou primeiro).

### Backend — N+1 em `resolveNormInfo`
- `MaintenanceItemService.buildOffsetResponse`/`buildCursorResponse`/`findAllForCalendar`: cada uma
  chama `resolveNormInfo(item.getNormId())` dentro do `.map()` de itens da página — um
  `NormService.findById` (round-trip de banco) por item.
- Fix: batch-fetch — juntar os `normId` da página num `Set<Long>`, uma chamada `findAllById`/
  equivalente, montar um `Map<Long, NormInfo>`, trocar a chamada por item por lookup no mapa.
  Espelha o padrão já usado 3 linhas acima no mesmo método pra `idsWithMaintenance`.
- Complementar (mesma task, baixo custo adicional): `@Cacheable("norms")` em
  `NormService.findById` — `@EnableCaching` já ativo, mesmo padrão já usado em
  `SupplierSearchService.java:34`. Beneficia qualquer outro chamador de `findById`, não só essa
  listagem. Normas são catálogo curado e quase estático (~22 registros, EPIC-025).

## Critérios de Aceite

- [ ] Digitar um tipo de item de N letras dispara 1 requisição (após a pausa), não N
- [ ] `GET /items` com página cheia de itens REGULATORY não cresce em número de queries
      proporcionalmente à quantidade de itens (validar com SQL log/Hibernate statistics
      antes/depois)
- [ ] Resposta da API idêntica à de antes (mesmo `normName`/`normPendingReview` por item) — só
      muda como é obtida, não o resultado
- [ ] `mvn clean test` e `tsc`/`eslint` sem regressão

## Dependências
Nenhuma.

## Riscos
Baixo — mudança client-only no front (debounce) e refatoração de acesso a dado já existente no
back (mesma resposta, só menos round-trips). Sem migração, sem mudança de contrato de API.

## Esforço
Baixo

## Status
✅ Implementada, PRs abertas contra `staging`:
[api#69](https://github.com/douglasjava/easy-maintenance-api/pull/69) (N+1 de normas) e
[web#70](https://github.com/douglasjava/easy-maintenance-web/pull/70) (debounce). Branches
`feature/TASK-224-fix-item-listing-n-plus-1` e `feature/TASK-224-debounce-item-type-search`.

**Backend**: `NormService.findAllByIdsAsMap` (batch) + `@Cacheable("norms")` em `findById`.
`MaintenanceItemService.resolveNormInfoBatch` substitui a chamada por item nos 4 métodos de
listagem. Bug pego durante o TDD (`Map.of()` lança NPE em `getOrDefault(null, ...)`, corrigido pra
`Collections.emptyMap()`) — achado só porque os testes novos rodaram antes de considerar pronto. 9
testes novos/atualizados, confirmados falhando sem o fix. `mvn clean test`: 877/877, 0 falhas.

**Frontend**: extraído utilitário `debounceAsync` (`src/lib/`, testável isoladamente já que o
projeto não tem `@testing-library/react`), debounce 300ms + cancelamento via `AbortController`. 5
testes novos com fake timers, confirmados falhando sem o arquivo. `tsc`/`eslint` sem regressão;
suite completa 110/113 (3 falhas pré-existentes em `middleware.test.ts`, sem relação).

Falta QA manual: Network tab confirmando 1 requisição por pausa (não por letra); conferir contagem
de query numa listagem de itens com REGULATORY via SQL log/Hibernate statistics.
