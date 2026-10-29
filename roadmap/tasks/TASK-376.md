# TASK-376 — Backend: áreas comuns — DTOs, serviço CRUD e API

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-038](../epics/EPIC-038.md) — Módulo de Configurações da Organização

## Depende de
[TASK-374](TASK-374.md)

## QA obrigatório
Sim — isolamento multi-tenant no update/listagem e validação de payload (incluindo `fee_cents`)
são o núcleo de risco desta task.

## Contexto
Desenho completo na spec/plano citados na TASK-373 (Task 4 do plano).

Records `CommonAreaRules` (`requiresApproval`, `minAdvanceHours`, `maxAdvanceDays`,
`maxDurationHours`), `CommonAreaResponse`, `CreateCommonAreaRequest`, `UpdateCommonAreaRequest`.
`CommonAreaService` reaproveita `SettingsAccessGuard.requireAdminOrSyndic` (criado na TASK-375).
Validação manual (não Bean Validation, mesmo motivo da TASK-375): `name` não vazio, `capacity > 0`,
`feeCents` nulo ou `>= 0`, campos de `rules` todos presentes e não-negativos. `update` por `id`
busca sempre por `(id, organizationId)` — uma área que existe mas é de outra organização deve se
comportar como inexistente (`NotFoundException`), nunca ser encontrada/alterada. `active=false`
continua aparecendo no `GET` de listagem (desativar não é "esconder"). Endpoints: `GET /organizations/common-areas`,
`POST /organizations/common-areas`, `PUT /organizations/common-areas/{id}`.

**Prompt**: `execute a TASK-376 (EPIC-038): common area CRUD service, controller e validação,
seguindo a Task 4 do plano docs/superpowers/plans/2026-10-29-organization-settings-module.md.`

## Critérios de aceite
- [ ] `CommonAreaServiceTest`: rejeita `capacity` não positivo e role fora de ADMIN/SYNDIC, salva
      área escopada à organização corrente, `update` de área de outra organização lança
      `NotFoundException`, listagem inclui área desativada (`active=false`).
- [ ] `mvn test` sem regressão.

## Status
Backlog
