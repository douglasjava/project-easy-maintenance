# TASK-373 — Backend: `OrganizationSetting` — entidade, migration V128 e repositório

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
—

## QA obrigatório
Sim — tabela/entidade nova, constraint única por `(organization_id, category)` precisa de teste
com banco real (H2 via `@DataJpaTest`, mesmo padrão de `ResidentTicketPersistenceTest`).

## Contexto
Desenho completo em [`docs/superpowers/specs/2026-10-29-organization-settings-module-design.md`](../../docs/superpowers/specs/2026-10-29-organization-settings-module-design.md)
e plano de implementação em [`docs/superpowers/plans/2026-10-29-organization-settings-module.md`](../../docs/superpowers/plans/2026-10-29-organization-settings-module.md) (Task 1).

Nova entidade `OrganizationSetting` (migration V128): `organization_id`, `category` (String),
`config` (coluna `JSON`, mapeada como `String` com `columnDefinition = "json"`, mesmo padrão de
`LandingLead.utmJson` — não o padrão `@JdbcTypeCode` de `AuditLog`), `created_at`/`updated_at`.
Constraint única `(organization_id, category)` — uma linha por categoria por organização. Sem
coluna de versão (decisão explícita do Douglas no brainstorm, sem necessidade de optimistic lock).
Repositório com `findByOrganizationIdAndCategory(Long, String)`.

**Prompt**: `execute a TASK-373 (EPIC-038): OrganizationSetting entity, migration V128 e
repository, seguindo a Task 1 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `OrganizationSettingPersistenceTest` (H2 real) prova que `(organization_id, category)` é
      único e que `findByOrganizationIdAndCategory` não retorna linha de outra organização.
- [ ] `mvn test` sem regressão.

## Execução
Implementado em `feature/EPIC-038-organization-settings` (easy-maintenance-api), a partir de
`staging`. `OrganizationSettingPersistenceTest` (2 testes, H2 real) verde. PR aberta:
[api#167](https://github.com/douglasjava/easy-maintenance-api/pull/167) (mesma PR cobre
TASK-373 a TASK-376).

## Status
Em Validação — PR aberta, aguardando QA manual de Douglas.
