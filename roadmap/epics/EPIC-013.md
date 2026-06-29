# EPIC-013 — Gestão de Usuários por Organização

## Status
Backlog — 6 tasks mapeadas

## Objetivo
Permitir que usuários com perfil ADMIN convidem, gerenciem e removam usuários dentro das suas organizações,
com enforcement de limite do plano (`maxUsers`) e fluxo de convite por e-mail sem exposição de senha.

## Descrição

O Easy Maintenance já possui o backend de criação de usuários por organização (`UsersOrganizationsController`)
e o mecanismo de convite por e-mail (`AdminService.initializeUserAccess()`), mas esses dois fluxos nunca
foram integrados ao produto para o usuário final. O frontend `/users/new` existe em estado rudimentar
(sem guard de ADMIN, com campo `passwordHash` exposto, sem select de organização, sem fluxo de convite).

O menu de navegação não tem ponto de entrada para "Usuários" — o `help/page.tsx` descreve o fluxo, mas
o caminho não existe. Esta epic entrega o fluxo completo do zero.

## Regras de Negócio

- **Somente ADMIN** pode convidar, editar e remover usuários de uma organização
- Usuários com role USER/VIEWER têm acesso de leitura somente (a definir por permissão)
- O limit `maxUsers` do plano é enforçado na criação (já implementado em `UsersService.addOrganization()` — TASK-097-A)
- O convite gera um `FirstAccessToken` e envia e-mail; o novo usuário nunca vê senha em tela
- O select de organização no formulário de convite lista as organizações do admin autenticado
- Remover usuário da org via DELETE `/organizations/{orgCode}/users/{id}` (não exclui o usuário do sistema)

## Contexto Técnico

- `UsersOrganizationsController` — endpoints POST / GET / PATCH já existem; faltam: guard de role, trigger de e-mail, DELETE
- `AdminService.initializeUserAccess(user)` — cria `FirstAccessToken` + envia e-mail de convite (padrão a seguir)
- `useCurrentOrganizationAccess()` — hook que retorna `permissions.isAdmin` para guard no frontend
- `/app/users/new/page.tsx` — existe mas com `passwordHash` exposto, sem org select, sem guard de ADMIN
- `/app/users/page.tsx` — não existe; precisa ser criada
- `/app/users/[id]/edit/page.tsx` — não existe; precisa ser criada
- `UserTopBar.tsx` — dropdown tem "Minha conta", "Minhas Empresas", "Faturamento", "Relatórios", "Ajuda / FAQ", "Sair" — falta "Usuários"

## Tasks

| ID       | Título                                                              | Tipo        | Prioridade  |
|----------|---------------------------------------------------------------------|-------------|-------------|
| TASK-098 | Backend: guard ADMIN + invitation email + DELETE em UsersOrganizationsController | BACKEND | 🔴 Crítico |
| TASK-099 | Frontend: "Usuários" no UserTopBar dropdown (ADMIN only)            | FRONTEND    | 🟠 Alto     |
| TASK-100 | Frontend: `/users` — listagem de usuários da org com CRUD actions   | FRONTEND    | 🟠 Alto     |
| TASK-101 | Frontend: reescrever `/users/new` — convite por e-mail + org select | FRONTEND    | 🔴 Crítico  |
| TASK-102 | Frontend: `/users/[id]/edit` — edição + desativação de usuário      | FRONTEND    | 🟠 Alto     |
| TASK-QA-MAN-009 | QA Manual: E2E fluxo completo de convite de usuário          | QA          | 🟠 Alto     |

## Critério de Conclusão do Épico

- [ ] Somente ADMIN acessa criação, edição e remoção de usuários na org
- [ ] Convite por e-mail: admin preenche email + nome + role + org → usuário recebe email de primeiro acesso (sem senha em tela)
- [ ] Limite `maxUsers` do plano é exibido no formulário e bloqueio é acionado quando atingido
- [ ] Select de organização no formulário de convite lista orgs do admin autenticado
- [ ] "Usuários" aparece no dropdown do UserTopBar para usuários ADMIN
- [ ] Listagem `/users` exibe usuários da org atual com opções de editar e remover
- [ ] Edição `/users/[id]/edit` permite alterar nome, role e status
- [ ] DELETE remove o vínculo usuário–organização (não exclui o usuário do sistema)
- [ ] Nenhuma regressão nos endpoints existentes
