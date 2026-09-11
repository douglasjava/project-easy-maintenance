# TASK-268 — BACKEND: Ativação/desativação manual de fornecedor (admin)

## Tipo
BACKEND

## Categoria
Fornecedores / Marketplace / Admin

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Fase 2: Marketplace de Fornecedores (monetização)

## QA obrigatório
Sim — coberto pela rodada de QA manual única no final do épico.

---

## Contexto

Decisão de escopo #2 do spec: fornecedor cadastrado pelo síndico (sem pagar) vira um "lead" — a
equipe Easy Maintenance pode entrar em contato e, se fechar por fora da plataforma, ativar
manualmente sem passar pelo fluxo de checkout/cobrança.

## Escopo

- `POST /easy-maintenance/api/v1/private/admin/suppliers/{id}/activate` — liga
  `marketplace_enabled`, grava `activationSource=MANUALLY_ACTIVATED`.
- `POST /easy-maintenance/api/v1/private/admin/suppliers/{id}/deactivate` — desliga
  `marketplace_enabled` (sem alterar `activationSource`, só a visibilidade).
- Mesmo padrão de autenticação do resto do admin (`AdminLeadController`) — path sob `/private/`
  já é interceptado pelo filtro de admin, sem anotação de auth por método.

## Critérios de Aceite

- [x] Ativação manual liga `marketplace_enabled` + `activationSource=MANUALLY_ACTIVATED` +
      `activatedAt`
- [x] Desativação desliga `marketplace_enabled`
- [x] Fornecedor inexistente → `NotFoundException`

## Dependências
TASK-260 (`ActivationSource`, campos em `Supplier`).

## Riscos
Baixo — endpoint admin, mesmo padrão de autenticação já usado em todo o resto do painel admin.

## Esforço
Pequeno

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `supplier_billing/application/service/SupplierAdminService.java` | `activateManually(id)`, `deactivate(id)` |
| `supplier_billing/infrastructure/web/AdminSupplierController.java` | 2 endpoints, mesmo padrão de `AdminLeadController` (confirmado contra o código real antes de implementar) |
| `test/.../supplier_billing/application/service/SupplierAdminServiceTest.java` | 3 testes |

### Verificação
`mvn test` (suíte completa) → PASS, sem regressão. Com esta task, as 9 tasks de backend do plano
(`docs/superpowers/plans/2026-09-11-supplier-marketplace-monetization.md`) estão concluídas —
restam só as 3 tasks de frontend (TASK-269/270/271).

## Status
🟢 Implementado e testado.
