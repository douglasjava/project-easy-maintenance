# TASK-261 — BACKEND: Entidades `SupplierSubscription`/`SupplierAccessToken`/`SupplierBudgetRequest`

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

Dados base do domínio de cobrança de fornecedor, isolado do billing de organização (decisão de
escopo #5 do spec) — reaproveita só o `AsaasClient` (HTTP puro), sem tocar nas tabelas/entidades
de billing de organização existentes.

## Escopo

- Migration `V112`: `supplier_subscriptions`, `supplier_access_tokens`, `supplier_budget_requests`.
- Módulo novo `supplier_billing`: `SupplierSubscription` (status `ACTIVE`/`PAST_DUE`/`CANCELED`,
  `externalCustomerId`, `externalPaymentId`, `currentPeriodEnd`), `SupplierAccessToken` (link
  mágico, sem expiração por uso — decisão de escopo #7).
- `SupplierBudgetRequest` fica no módulo `supplier` (não `supplier_billing`) — é dado de demanda
  ("Solicitar Orçamento"), não de cobrança.
- 3 repositórios: `SupplierSubscriptionRepository` (`findBySupplierId`,
  `findByStatusAndCurrentPeriodEndLessThanEqual` — usado pela TASK-268), `SupplierAccessTokenRepository`
  (`findByToken`, `findBySupplierId`), `SupplierBudgetRequestRepository`.

## Critérios de Aceite

- [x] `supplier_subscriptions.supplier_id` é `UNIQUE` (uma assinatura por fornecedor)
- [x] Migration valida contra MySQL real
- [x] Teste de persistência (H2) prova a constraint de unicidade

## Dependências
TASK-260 (campo `document` em `Supplier`).

## Riscos
Baixo. Ponto de atenção real: `organization_code` (FK em `supplier_budget_requests`) exige
`COLLATE=utf8mb4_0900_ai_ci` explícito na tabela — `organizations.code` usa essa collation,
diferente do default do banco (`utf8mb4_unicode_ci`). Sem isso a FK falha com erro 3780
("incompatible collation"), mesmo padrão já visto em `user_organizations`.

## Esforço
Médio

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `db/migration/V112__create_supplier_billing_tables.sql` | 3 tabelas novas |
| `supplier_billing/domain/enums/SupplierSubscriptionStatus.java` | `ACTIVE`, `PAST_DUE`, `CANCELED` |
| `supplier_billing/domain/SupplierSubscription.java` | assinatura mensal do fornecedor |
| `supplier_billing/domain/SupplierAccessToken.java` | link mágico de auto-gestão |
| `supplier/domain/SupplierBudgetRequest.java` | log de "Solicitar Orçamento" |
| `supplier_billing/infrastructure/persistence/SupplierSubscriptionRepository.java` | |
| `supplier_billing/infrastructure/persistence/SupplierAccessTokenRepository.java` | |
| `supplier/infrastructure/persistence/SupplierBudgetRequestRepository.java` | |
| `test/.../supplier_billing/infrastructure/persistence/SupplierBillingPersistenceTest.java` | 2 testes (round-trip + constraint de unicidade) |

### Decisões tomadas durante a implementação
- Bug real encontrado e corrigido durante a validação da migration contra o MySQL real do docker
  de dev: FK de `supplier_budget_requests.organization_code` pra `organizations.code` falhava com
  erro 3780 (collation incompatível) — corrigido com `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci` explícito na tabela, confirmado contra `SHOW CREATE TABLE
  user_organizations` (mesmo padrão já usado nesse relacionamento). Correção aplicada tanto na
  migration real quanto retroativamente no documento do plano.
- Gap real do plano encontrado no teste de persistência: `@DataJpaTest` sem `@EntityScan`/
  `@EnableJpaRepositories` restritos varre TODOS os repositórios da aplicação (incluindo um não
  relacionado — `InAppNotificationRepository` — que falha por outro motivo), e sem
  `spring.flyway.enabled=false` tenta rodar as migrations reais (sintaxe MySQL) contra o H2.
  Corrigido replicando o mesmo escopo restrito já usado em `SupplierPersistenceTest` (TASK-241).

### Verificação
`mvn test -Dtest=SupplierBillingPersistenceTest` → PASS (2/2). Migration validada e revertida
contra `easy_maintenance_mysql` (docker de dev).

## Status
🟢 Implementado e testado.
