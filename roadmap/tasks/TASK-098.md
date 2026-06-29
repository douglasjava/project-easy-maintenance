# TASK-098 — Backend: guard ADMIN + invitation email + DELETE em UsersOrganizationsController

## Tipo
BACKEND

## Categoria
Backend / Segurança / Convite de Usuário

## Prioridade
🔴 Crítico

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Usuários por Organização

---

## Contexto

`UsersOrganizationsController` expõe `POST /organizations/{orgCode}/users`, `PATCH /organizations/{orgCode}/users/{id}` e `GET` equivalentes, todos com `@RequireTenant`. Três gaps existem:

1. **Sem guard de role**: qualquer usuário autenticado na org pode criar/editar outros usuários.
2. **Sem invitation email**: a criação via controller não aciona `AdminService.initializeUserAccess()`, portanto o novo usuário não recebe e-mail de primeiro acesso e não tem `FirstAccessToken`.
3. **Sem DELETE**: não há como remover o vínculo usuário–org pelo controller.

---

## Subtasks

### TASK-098-A — Guard de role ADMIN nos endpoints de escrita

Adicionar verificação de role em `POST`, `PATCH` e `DELETE` de `UsersOrganizationsController`:
- Recuperar o usuário autenticado via `AuthenticationService.getCurrentUser()`
- Buscar o vínculo `UserOrganization` do usuário autenticado na org do `X-Org-Id`
- Se `userOrganization.getRole() != Role.ADMIN` → lançar `ForbiddenException` (403)
- `GET` endpoints **não** são protegidos por role (qualquer membro da org pode listar)

**Referência de padrão:** verificar como outros controllers usam `AuthenticationService` para obter o usuário atual e validar contexto de org.

---

### TASK-098-B — Trigger de invitation email na criação de usuário

Após `UsersService.addOrganization()` criar com sucesso o usuário e o vínculo:
- Se o usuário foi **criado** (não apenas vinculado a uma org adicional), chamar `adminService.initializeUserAccess(user)`:
  - Gera `FirstAccessToken` via `FirstAccessTokenService.createForUser(user)`
  - Envia e-mail de convite com instruções de primeiro acesso
- Se o usuário já existia no sistema (e-mail duplicado), **não** reenviar o convite
- A distinção "criado vs. existente" deve ser retornada pelo service ou detectada pelo controller

**Referência:** `AdminService.createUser()` → `initializeUserAccess()` (mesmo padrão).

---

### TASK-098-C — DELETE `/organizations/{orgCode}/users/{id}` (remover vínculo)

Adicionar endpoint:
```
DELETE /easy-maintenance/api/v1/organizations/{orgCode}/users/{id}
```
- Remove apenas o `UserOrganization` (vínculo usuário–org), **não** o usuário do sistema
- Se o vínculo não existir → 404 com mensagem clara
- Guard ADMIN obrigatório (mesmo padrão de 098-A)
- Response: 204 No Content

---

## Critérios de Aceite

- [ ] `POST /organizations/{orgCode}/users` retorna 403 quando o caller não é ADMIN da org
- [ ] `PATCH /organizations/{orgCode}/users/{id}` retorna 403 quando o caller não é ADMIN da org
- [ ] `GET /organizations/{orgCode}/users` permanece acessível para qualquer membro da org
- [ ] Novo usuário criado via POST recebe e-mail de convite com link de primeiro acesso
- [ ] Usuário já existente vinculado a nova org **não** recebe segundo e-mail de convite
- [ ] `DELETE /organizations/{orgCode}/users/{id}` remove o vínculo e retorna 204
- [ ] `DELETE` com id inexistente retorna 404
- [ ] Guard ADMIN aplicado no DELETE
- [ ] Testes unitários ou de integração cobrindo: sucesso, 403 sem ADMIN, 404 vínculo inexistente

## Esforço Estimado
Médio — 3 subtasks sequenciais no mesmo controller/service. Guard e DELETE são simples; trigger de e-mail exige cuidado para não reenviar convite para usuários existentes.

## Riscos
- Regressão: `POST` já é usado por outros fluxos (admin interno via `/private`). Garantir que o guard se aplica apenas ao endpoint do controller público, não ao service.
- Invitation dupla: se e-mail já cadastrado, não reenviar convite — validar com `userRepository.existsByEmail()` antes de chamar `initializeUserAccess()`.
