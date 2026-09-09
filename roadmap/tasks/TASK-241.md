# TASK-241 — BACKEND: Entidades `Supplier`/`SupplierOrganizationLink` + migration

## Tipo
BACKEND

## Categoria
Fornecedores / Cadastro

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Cadastro de Fornecedores pelos Usuários + Pontuação

## QA obrigatório
Sim — confirmar que a constraint única em `(supplier_id, organization_id)` realmente impede
duplicata, e que `cnpj` único no `Supplier` impede duas linhas com o mesmo CNPJ.

---

## Contexto

Base de dado do épico: primeira entidade persistida do módulo `supplier` (hoje só opera sobre DTOs
do Google Places). Detalhe completo em
`docs/superpowers/specs/2026-09-08-supplier-registry-design.md`.

## Escopo

- Nova migration: tabela `suppliers` — `cnpj` (único, obrigatório), `name`, `phone`, `category`,
  `city`, `state`, `registration_count` (default 0), `created_at`/`updated_at`.
- Nova migration: tabela `supplier_organization_links` — `supplier_id` (FK), `organization_id`
  (FK), `created_at`, constraint única em `(supplier_id, organization_id)`.
- Novo pacote `domain/` dentro do módulo `supplier` existente: entidades `Supplier` e
  `SupplierOrganizationLink` (JPA), sem tocar nos arquivos existentes do módulo (DTOs/serviços do
  fluxo Google Places continuam intocados).
- Repositories JPA pras duas entidades (`infrastructure/persistence/`).

## Critérios de Aceite

- [x] Migration aplica limpo (validar contra MySQL real, mesmo cuidado da TASK-230 — não confiar só
      na suíte H2)
- [x] `cnpj` único no `Supplier` — segunda tentativa de criar com mesmo CNPJ falha/é tratada pela
      camada de serviço (TASK-242), não deixa constraint estourar sem tratamento
- [x] Constraint única em `(supplier_id, organization_id)` impede vínculo duplicado
- [x] Entidades seguem o padrão já usado no schema (timestamps, nullability coerente com a spec)
- [x] `mvn test` sem regressão

## Dependências
Nenhuma técnica. TASK-242 depende desta task pronta.

## Riscos
Baixo — aditivo, tabelas novas, nenhum fluxo existente é alterado. Mesmo cuidado da TASK-230:
validar a migration contra MySQL real antes de considerar pronta (suíte de teste roda em H2).

## Esforço
Baixo

## Implementação

### Arquivos criados

| Arquivo | Descrição |
|---|---|
| `db/migration/V109__create_suppliers.sql` | tabelas `suppliers` (cnpj único) e `supplier_organization_links` (FK pra `suppliers`/`organizations`, unique `(supplier_id, organization_id)`) |
| `supplier/domain/Supplier.java` | entidade JPA — `cnpj` (`@Column(unique = true)`), `name`, `phone`, `category`, `city`, `state`, `registrationCount` (default 0), timestamps `@CreationTimestamp`/`@UpdateTimestamp` |
| `supplier/domain/SupplierOrganizationLink.java` | entidade JPA — `supplierId`, `organizationId` (Long simples, sem `@ManyToOne` — mesmo estilo já usado em `ResidentTicket.organizationId`), `@UniqueConstraint` em `(supplier_id, organization_id)` |
| `supplier/infrastructure/persistence/SupplierRepository.java` | `JpaRepository<Supplier, Long>` + `findByCnpj` |
| `supplier/infrastructure/persistence/SupplierOrganizationLinkRepository.java` | `JpaRepository<SupplierOrganizationLink, Long>` + `existsBySupplierIdAndOrganizationId` |
| `test/.../supplier/infrastructure/persistence/SupplierPersistenceTest.java` | `@DataJpaTest` (H2, `ddl-auto=create-drop`, mesmo padrão de `BillingAccountRepositoryPersistenceTest`) — 4 testes: cnpj único falha ao duplicar, `findByCnpj` sem match retorna vazio, vínculo único falha ao duplicar `(supplierId, organizationId)`, mesmo supplier com organizações diferentes persiste os dois |

### Decisões tomadas durante a implementação
- `category` ficou como `String` simples (não enum) — não existe hoje um enum de categoria de
  fornecedor no código (`SupplierCategoryKeywords` é um mapeador de `serviceKey` → string de busca
  do Google Places, não uma taxonomia fechada); a spec permite `String/Enum`. Validação de valores
  aceitos fica pra TASK-242 (camada de serviço), sem travar o schema agora.
- `cnpj` como `VARCHAR(20)` — cabe tanto o formato só-dígitos (14) quanto formatado
  (`99.999.999/9999-99`, 18); normalização exata (guardar formatado ou só dígitos) fica decidida na
  TASK-242, que é quem valida/recebe o request.
- `SupplierOrganizationLink.organizationId` é um `Long` simples, sem relação JPA `@ManyToOne` pra
  `Organization` — mesmo padrão já usado em `ResidentTicket.organizationId`, evita acoplar o módulo
  `supplier` (compartilhado entre organizações, exceção deliberada ao isolamento multi-tenant) ao
  grafo de entidades do `org_users`.
- Nenhum método de busca por `city`/`state`/ordenação por `registrationCount` foi adicionado aos
  repositories agora — está fora do escopo desta task (`GET /suppliers` é TASK-242); `findByCnpj` e
  `existsBySupplierIdAndOrganizationId` são os únicos métodos, ambos usados diretamente pelos testes
  de constraint desta task.

### Verificação
- `mvn clean test` → **942/942, 0 falhas** (938 da TASK-244 + 4 novos testes desta task, sem
  regressão em nenhum módulo existente).
- Migration `V109` aplicada diretamente contra o MySQL real do docker local (mesmo cuidado da
  TASK-230 — suíte de teste roda em H2, que não pega problema de sintaxe/constraint específico do
  MySQL): aplicou limpo; segunda tentativa de `INSERT` com `cnpj` duplicado falhou
  (`ERROR 1062 ... Duplicate entry ... for key 'suppliers.uk_suppliers_cnpj'`); segunda tentativa de
  vínculo `(supplier_id, organization_id)` duplicado falhou
  (`ERROR 1062 ... for key 'supplier_organization_links.uk_supplier_org_links_supplier_organization'`);
  FK inválida (`organization_id` inexistente) também falhou como esperado
  (`ERROR 1452 ... foreign key constraint fails`). Tabelas revertidas (`DROP TABLE`) depois da
  validação manual — banco local voltou pro estado limpo em V108, sem conflitar com o Flyway quando
  a app rodar de verdade nessa branch (senão o Flyway tentaria recriar as tabelas e falharia com
  "table already exists").

Branch renomeada de `feature/TASK-241-supplier-entities-migration` para
`feature/EPIC-028-supplier-registry` (a partir de `staging`) — commit `056c35d` preservado. A partir
daqui TASK-242 e TASK-243 seguem na mesma branch (decisão do Douglas: uma PR só cobrindo o épico
completo, com QA manual ponta a ponta no final em vez de QA por task). PR individual
[api#87](https://github.com/douglasjava/easy-maintenance-api/pull/87) fechada sem merge por causa
disso — reabre no final, como PR do EPIC-028.

## Status
🟢 Implementado, testado (`mvn test` 942/942) e validado manualmente contra MySQL real — QA
obrigatório desta task (as duas constraints) já confirmado com evidência. Aguardando TASK-242/243
(mesma branch) antes de abrir a PR final do EPIC-028.
