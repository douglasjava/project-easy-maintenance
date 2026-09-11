# TASK-263 — BACKEND: Endpoint "Solicitar Orçamento" (`POST /suppliers/{id}/budget-request`)

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — coberto pela rodada de QA manual única no final do épico.

---

## Contexto

Decisão de escopo #4 do spec: o botão "Solicitar Orçamento" (grid de busca de fornecedor) grava a
solicitação — base de demanda real, pensada pro ranking futuro — mas o envio de fato pro fornecedor
acontece no frontend via `wa.me` (link direto pro WhatsApp), não neste endpoint.

## Escopo

`POST /easy-maintenance/api/v1/suppliers/{id}/budget-request` (autenticado, mesmo padrão do resto
do módulo): grava `SupplierBudgetRequest` (organização + usuário logado + resumo), retorna o
telefone do fornecedor pro frontend montar o link `wa.me`.

## Critérios de Aceite

- [x] Solicitação válida grava `SupplierBudgetRequest` com `organizationCode`/`requestedByUserId`
      corretos e retorna o telefone do fornecedor
- [x] Fornecedor inexistente → `NotFoundException`
- [x] Sem `X-Org-Id` → `TenantException`

## Dependências
TASK-261 (`SupplierBudgetRequestRepository`).

## Riscos
Baixo — endpoint autenticado, mesmo padrão de segurança do resto do sistema.

## Esforço
Pequeno

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier/application/dto/CreateBudgetRequestRequest.java` | `summary` (`@NotBlank @Size(max=1000)`) |
| `supplier/application/dto/BudgetRequestResponse.java` | `id`, `supplierId`, `supplierPhone`, `summary` |
| `supplier/application/service/SupplierBudgetRequestService.java` | `create(supplierId, request)` |
| `test/.../supplier/application/service/SupplierBudgetRequestServiceTest.java` | 3 testes |

### Arquivos modificados
`SupplierRegistryController.java` — novo endpoint `POST /{id}/budget-request`.

### Verificação
`mvn test -Dtest=Supplier*Test` → PASS, sem regressão.

## Status
🟢 Implementado e testado.
