# TASK-274 — BUGFIX: Endpoints públicos de fornecedor exigiam X-Org-Id

## Tipo
BUGFIX

## Categoria
Fornecedores / Marketplace / Multi-tenant

## Prioridade
🔴 Alto — terceira e (confirmado) última camada do mesmo bug de ponta a ponta (ver TASK-272/273)

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — Douglas re-testa C4/C6 de [TASK-QA-MAN-022](../QA/tasks/TASK-QA-MAN-022.md) a partir desta
correção.

---

## Contexto

Com o [TASK-272](TASK-272.md) (frontend) e o [TASK-273](TASK-273.md) (Spring Security) corrigidos,
Douglas chegou no terceiro bloqueio: `POST /public/suppliers/register` retornava `400
Bad Request` com `ProblemType` `tenant-missing` / `"Missing X-Org-Id header"`.

### Causa raiz

O mesmo padrão dos dois bugs anteriores, numa camada diferente: `TenantFilter` (filtro global que
roda em toda requisição sob `/easy-maintenance/api/v1/**`) exige `X-Org-Id` por padrão, com
bypass explícito por prefixo de path (`BYPASS_PREFIXES`). `/public/resident-tickets` está na
lista (EPIC-027) — `/public/suppliers` nunca foi adicionado.

Confirmado que não há mais nenhuma camada transversal pendente depois desta:
`ApiRequestContextFilter` só popula MDC, não bloqueia; `BootstrapAdminFilter` é escopado a
`/private/admin`; `RateLimitAspect` (já configurado corretamente nas Tasks 5/7) resolve a chave só
por IP, sem depender de tenant.

## Escopo

```java
// EPIC-028 Fase 2: auto-cadastro/gestão pública de fornecedor -- não pertence a nenhuma
// organização específica, resolvido por document/token, não por X-Org-Id.
"/public/suppliers"
```
Adicionado em `TenantFilter.BYPASS_PREFIXES`.

## Critérios de Aceite

- [x] `POST /public/suppliers/register` sem `X-Org-Id` não retorna mais `tenant-missing`
- [x] `GET`/`PUT /public/suppliers/manage/{token}` idem
- [x] Nenhuma outra rota teve seu requisito de `X-Org-Id` alterado
- [x] Teste de regressão novo (`TenantFilterTest.shouldBypassCheckForPublicSupplierEndpoints`)
- [x] `mvn test` sem regressão

## Dependências
TASK-264, TASK-266 (endpoints), TASK-272/TASK-273 (as duas camadas anteriores do mesmo bug).

## Riscos
Baixo — `BYPASS_PREFIXES` usa `path.contains(prefix)`, então `"/public/suppliers"` cobre
`/public/suppliers/register` e `/public/suppliers/manage/{token}` sem afetar `/suppliers`
(autenticado) nem `/private/admin/suppliers/**` (já coberto por outro prefixo, `/private/admin`).

## Esforço
Trivial

## Implementação

### Arquivos modificados
| Arquivo | Descrição |
|---|---|
| `shared/web/filter/TenantFilter.java` | `/public/suppliers` adicionado a `BYPASS_PREFIXES` |
| `test/.../shared/web/filter/TenantFilterTest.java` | novo teste `shouldBypassCheckForPublicSupplierEndpoints` |

### Verificação
`mvn test` (suíte completa) → PASS, sem regressão.

## Status
🟢 Corrigido. Com esta correção, as 3 camadas do bug de acesso público (frontend/Shell.tsx,
Spring Security, TenantFilter) estão resolvidas — aguardando Douglas confirmar em C4/C6.
