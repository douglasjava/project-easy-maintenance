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

- [ ] Migration aplica limpo (validar contra MySQL real, mesmo cuidado da TASK-230 — não confiar só
      na suíte H2)
- [ ] `cnpj` único no `Supplier` — segunda tentativa de criar com mesmo CNPJ falha/é tratada pela
      camada de serviço (TASK-242), não deixa constraint estourar sem tratamento
- [ ] Constraint única em `(supplier_id, organization_id)` impede vínculo duplicado
- [ ] Entidades seguem o padrão já usado no schema (timestamps, nullability coerente com a spec)
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica. TASK-242 depende desta task pronta.

## Riscos
Baixo — aditivo, tabelas novas, nenhum fluxo existente é alterado. Mesmo cuidado da TASK-230:
validar a migration contra MySQL real antes de considerar pronta (suíte de teste roda em H2).

## Esforço
Baixo

## Status
🔴 Não iniciada
