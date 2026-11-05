# TASK-374 — Backend: `CommonArea` — entidade, migration V129 e repositório

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
—

## QA obrigatório
Sim — tabela/entidade nova, isolamento multi-tenant precisa de teste com banco real.

## Contexto
Desenho completo em [`docs/superpowers/specs/2026-10-29-organization-settings-module-design.md`](../../docs/superpowers/specs/2026-10-29-organization-settings-module-design.md)
e plano de implementação em [`docs/superpowers/plans/2026-10-29-organization-settings-module.md`](../../docs/superpowers/plans/2026-10-29-organization-settings-module.md) (Task 2).

Nova entidade `CommonArea` (migration V129): `organization_id`, `name`, `capacity`, `active`
(default `true` — desativar em vez de apagar, padrão de soft delete já usado no sistema), `fee_cents`
(nullable, coluna própria em centavos — não dentro do JSON, seguindo o padrão `amount_cents`/
`value_cents` já usado em todo o sistema), `rules` (coluna `JSON`, mesmo padrão de coluna de
`OrganizationSetting`/TASK-373). Repositório com `findAllByOrganizationIdOrderByNameAsc(Long)` e
`findByIdAndOrganizationId(Long, Long)`.

**Prompt**: `execute a TASK-374 (EPIC-038): CommonArea entity, migration V129 e repository,
seguindo a Task 2 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `CommonAreaPersistenceTest` (H2 real) prova que `findAllByOrganizationIdOrderByNameAsc` não
      retorna áreas de outra organização e que `findByIdAndOrganizationId` retorna vazio para uma
      área que existe mas pertence a outra organização.
- [ ] `mvn test` sem regressão.

## Execução
Implementado em `feature/EPIC-038-organization-settings` (easy-maintenance-api), a partir de
`staging`. `CommonAreaPersistenceTest` (2 testes, H2 real) verde. PR aberta:
[api#167](https://github.com/douglasjava/easy-maintenance-api/pull/167) (mesma PR cobre
TASK-373 a TASK-376).

## Status
Em Validação — PR aberta, aguardando QA manual de Douglas.
