# TASK-260 — BACKEND: Generaliza `Supplier` pra CPF/CNPJ + campos de marketplace

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — coberto pela rodada de QA manual única no final do épico (ver TASK-QA-MAN a criar).

---

## Contexto

Primeira task da Fase 2 do EPIC-028 (abrir o cadastro interno de fornecedores como marketplace
pago). Detalhe completo em
`docs/superpowers/specs/2026-09-11-supplier-marketplace-monetization-design.md` e plano em
`docs/superpowers/plans/2026-09-11-supplier-marketplace-monetization.md`.

O campo `cnpj` de `Supplier` (EPIC-028 v1) vira `document` (aceita CPF ou CNPJ via `@Doc`) —
fornecedor pequeno/informal frequentemente não tem CNPJ. Também adiciona os campos base pra
monetização: `email`, `marketplace_enabled`, `activated_at`, `activation_source`.

## Escopo

- Migration `V111`: `ALTER TABLE suppliers` (`cnpj` → `document`, + `email`,
  `marketplace_enabled`, `activated_at`, `activation_source`), unique constraint trocada de
  `uk_suppliers_cnpj` pra `uk_suppliers_document`.
- `Supplier.java`: campo `document` (era `cnpj`), + `email`, `marketplaceEnabled` (default
  `false`), `activatedAt`, `activationSource` (enum `ActivationSource`: `SELF_REGISTERED` /
  `MANUALLY_ACTIVATED`).
- `RegisterSupplierRequest`/`SupplierRegistryResponse`: `cnpj` → `document`, validador `@CNPJ` →
  `@Doc` (aceita CPF ou CNPJ).
- `SupplierRepository.findByCnpj` → `findByDocument`.

## Critérios de Aceite

- [x] `document` aceita CPF válido e CNPJ válido, rejeita documento inválido
- [x] Migration valida contra MySQL real (collation/sintaxe) — aplicada e revertida no docker de dev
- [x] Suíte de fornecedor sem regressão

## Dependências
Nenhuma (primeira task da Fase 2).

## Riscos
Baixo — rename de coluna/campo em cadeia (entidade, DTOs, repositório, testes), sem mudança de
comportamento de negócio. Risco real era esquecer algum consumidor do campo antigo.

## Esforço
Pequeno

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier/domain/enums/ActivationSource.java` | `SELF_REGISTERED`, `MANUALLY_ACTIVATED` |
| `db/migration/V111__generalize_supplier_document_and_marketplace.sql` | rename `cnpj`→`document` + novos campos + troca de unique constraint |
| `test/.../supplier/application/dto/RegisterSupplierRequestTest.java` | 3 testes: CNPJ válido, CPF válido, documento inválido |

### Arquivos modificados
`Supplier.java`, `RegisterSupplierRequest.java`, `SupplierRegistryResponse.java`,
`SupplierRepository.java`, `SupplierRegistryService.java`, `SupplierRegistryServiceTest.java`,
`SupplierPersistenceTest.java` (este último não estava no plano original — encontrado via grep
por `cnpj`/`findByCnpj` remanescente depois do rename dos demais arquivos).

### Decisões tomadas durante a implementação
- `SupplierPersistenceTest.java` precisou de ajuste manual (rename de teste e helper) — gap real
  do plano, que não listou esse arquivo no escopo da Task 1.

### Verificação
`mvn test -Dtest=Supplier*Test,RegisterSupplierRequestTest` → PASS, sem regressão.

Branch `feature/EPIC-028-fase2-marketplace` (épico consolidado numa branch só, mesmo padrão dos
épicos anteriores).

## Status
🟢 Implementado e testado.
