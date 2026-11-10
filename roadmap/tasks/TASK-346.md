# TASK-346 — Vínculo item ↔ fornecedor + tipo de contrato

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Hoje o fornecedor é ligado à organização e `performedBy` é texto. Precisamos do fornecedor de referência por item e do tipo de contrato.
Base: `staging` · branch `feature/TASK-346-<descricao-curta>`.

## Escopo
> **10/11/2026 (D15 da matriz):** este vínculo é o fornecedor **habitual** do item, usado como sugestão ("Acionar
> fornecedor", cartão do registro, "serviços que vencem para mim" do fornecedor). O fornecedor **responsável** de cada
> execução fica na manutenção ([TASK-423](TASK-423.md)).

- Migration: vínculo (item, fornecedor, origem `OCR|MANUAL|STATEMENT`, `contract_type` `RECURRING|ON_DEMAND|INTERNAL`, início, fim, valor mensal opcional).
- Endpoints com isolamento por `X-Org-Id`.
- Web: coluna "fornecedor" na lista de itens e bloco no detalhe.

## Critérios de aceite
- [x] Vincular/desvincular fornecedor a um item
- [x] Coluna aparece na lista (mobile ok)
- [x] Acesso cross-tenant bloqueado (teste)

## Implementação (10/11/2026)
[api#213](https://github.com/douglasjava/easy-maintenance-api/pull/213) e [web#149](https://github.com/douglasjava/easy-maintenance-web/pull/149), mergeadas em `staging`. Antecipada por ser dependência da TASK-437 (EPIC-043).
- `item_supplier_links` (V149) guarda um fornecedor habitual por item, com origem, tipo de contrato e vigência e valor (só no recorrente).
- `ItemSupplierService` valida o tenant (item de outra organização dá 404), exige que o fornecedor esteja vinculado à organização e só deixa ADMIN/SYNDIC alterar.
- Endpoints `GET /items/suppliers` e `GET/PUT/DELETE /items/{id}/supplier`.
- Web: coluna Fornecedor na lista (desktop e mobile) e bloco no detalhe.
- Teste cross-tenant em `ItemSupplierServiceTest`; `mvn test` 2006, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — aguarda a validação de Douglas.
