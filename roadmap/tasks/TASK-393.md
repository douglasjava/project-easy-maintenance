# TASK-393 — BUGFIX: `TenantFilter` não validava `X-Org-Id` em `condo-people`/`units` (EPIC-039)

## Tipo
BUGFIX — BACKEND

## Categoria
Pessoas e Papéis / Multi-tenant

## Prioridade
🔴 Crítico — endpoints do EPIC-039 inteiros inutilizáveis até este fix.

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Não — coberto por teste de regressão automatizado (`TenantFilterBypassTest`), achado e corrigido
antes do QA manual de TASK-QA-MAN-027 começar.

---

## Contexto
Encontrado ao preparar os dados pra executar [TASK-QA-MAN-027](../QA/tasks/TASK-QA-MAN-027.md)
(QA manual do EPIC-039, já mergeado em `staging`): `GET /organizations/condo-people` e
`GET /organizations/units` retornavam `403` ("Contexto de organização obrigatório. Informe o
header X-Org-Id.") **mesmo enviando o header correto**.

## Causa
`TenantFilter.BYPASS_PREFIXES` tem uma entrada genérica `/organizations/` (pensada para endpoints
de gestão de organização — criar org, listar orgs do usuário). Os dois endpoints novos do
EPIC-039 caem sob esse prefixo e por isso nunca passavam pela validação/população do
`TenantContext` — exatamente a mesma classe de bug que o EPIC-038 teve com
`/organizations/settings` e `/organizations/common-areas`, corrigida adicionando essas rotas a
`TENANT_REQUIRED_EXCEPTIONS`. O EPIC-039 não foi incluído nessa lista na implementação original
(TASK-382/383).

## Escopo da correção
- Adicionado `/organizations/condo-people` e `/organizations/units` a
  `TenantFilter.TENANT_REQUIRED_EXCEPTIONS` (`easy-maintenance-api`).
- 8 cenários novos de regressão em `TenantFilterBypassTest` cobrindo `GET`/`POST`/`PUT`/`DELETE`
  dos dois recursos.
- Gap de cobertura adicional encontrado e corrigido no mesmo commit: `update()`, `delete()` e
  `findSupplierOptionsForCurrentOrganization()` de `CondoPersonService` já chamavam
  `requireAdminOrSyndic()` em produção, mas não tinham teste cobrindo `TECH`/`READER` →
  `ForbiddenException` (diferente de `UnitServiceTest`, que já testava isso em `update`) — 3
  testes novos em `CondoPersonServiceTest`.

## Critérios de Aceite
- [x] `GET`/`POST`/`PUT`/`DELETE` em `/organizations/condo-people` e `/organizations/units`
      exigem `X-Org-Id` válido (400 sem header, 403 com header de outra organização)
- [x] `TenantFilterBypassTest`: 38/38 verde (8 novos cenários)
- [x] `CondoPersonServiceTest`: 38/38 verde (3 novos cenários de permissão)
- [x] Suíte completa (`mvn test`): 1613/1613, 0 falhas
- [x] QA manual (TASK-QA-MAN-027) confirma o fix contra API local de verdade (curl + navegador):
      `GET condo-people`/`units` com `X-Org-Id` correto retornam `200` (antes: `403` sempre)

## Branch
`bugfix/TASK-393-tenant-filter-pessoas-papeis` (`easy-maintenance-api`, a partir de `staging`) —
mergeado direto em `staging` (commits `a207c74`, `ff6c4f3`, `cd89522`), a pedido do Douglas, sem PR
intermediária.

## Riscos
Nenhum — fix aditivo (lista de exceções), sem alterar comportamento de nenhuma outra rota. Suíte
completa confirma zero regressão.

## Status
✅ Corrigido, mergeado em `staging` e validado contra ambiente local real (01/11/2026) — fix
confirmado via curl e navegador, ver [TASK-QA-MAN-027](../QA/tasks/TASK-QA-MAN-027.md).
