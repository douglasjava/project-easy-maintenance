# TASK-262 — BACKEND: Busca só mostra fornecedor `marketplace_enabled` pra outras organizações

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — validar que a organização que cadastrou continua vendo o próprio fornecedor mesmo sem pagar,
e que outra organização só vê fornecedores com `marketplace_enabled=true`.

---

## Contexto

Decisão de escopo #1 do spec: o cadastro feito pelo síndico continua funcionando exatamente como
antes (visível pra própria organização), mas só fica visível pra **outras** organizações se o
fornecedor pagar (ou for ativado manualmente pelo admin — TASK-269).

## Escopo

`SupplierRepository.findByRegion` → `findByRegionVisibleTo` (novo parâmetro `organizationId`):
fornecedor aparece se `marketplaceEnabled = true` OU se existe `SupplierOrganizationLink` ligando
ele à organização que está buscando.

## Critérios de Aceite

- [x] Organização que cadastrou sempre vê o próprio fornecedor (mesmo sem `marketplace_enabled`)
- [x] Outra organização só vê fornecedor com `marketplace_enabled=true`
- [x] Sem regressão nos testes de busca já existentes

## Dependências
TASK-260 (`marketplaceEnabled` em `Supplier`), TASK-261 (não — usa `SupplierOrganizationLink`
que já existia desde a TASK-241).

## Riscos
Baixo. Nenhum outro consumidor de `findByRegion` (confirmado via grep antes de remover o método).

## Esforço
Pequeno

## Implementação

### Arquivos modificados
| Arquivo | Descrição |
|---|---|
| `SupplierRepository.java` | `findByRegion` removido, `findByRegionVisibleTo` novo (JPQL com `EXISTS` sub-select em `SupplierOrganizationLink`) |
| `SupplierRegistryService.java` | `search()` passa `organization.getId()` pro novo método |
| `SupplierRegistryServiceTest.java` | 2 testes existentes ajustados pro novo método/assinatura + 1 teste novo de gating (`search_hidesNonMarketplaceSupplier_fromOtherOrganization`) |

### Verificação
`mvn test -Dtest=SupplierRegistryServiceTest` → PASS (8/8 — 6 originais + 1 novo de gating, 2
ajustados já contam nos 6).

## Status
🟢 Implementado e testado.
