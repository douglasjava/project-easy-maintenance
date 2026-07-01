# EPIC-013 — Gestão de Equipe por Conta (Team Members)

## Status
Backlog — 6 tasks mapeadas

## Objetivo
Permitir que o usuário com perfil ADMIN (dono da conta) convide, gerencie e remova membros da sua equipe,
vinculando cada membro a uma ou mais das suas organizações. O acesso é controlado pelo limite `maxUsers`
do plano do dono.

## Descrição

O Easy Maintenance é multi-organização por natureza: um usuário ADMIN pode ter várias empresas cadastradas.
O que falta é a capacidade de **compartilhar a operação dessas empresas com outros usuários** — por exemplo,
Fulano (ADMIN, plano STARTED) pode adicionar até 3 membros do tipo READER para ajudar a controlar os
fluxos das suas organizações.

Este épico entrega o ciclo completo:
- Fulano convida João (READER) e define quais das suas orgs João pode acessar
- Fulano pode editar as permissões de João e alterar as orgs vinculadas
- Fulano pode remover João da sua conta (desvincula das orgs de Fulano)
- João recebe e-mail de convite com link de primeiro acesso (sem senha exposta em tela)

## Modelo de Negócio

```
Dono (ADMIN)
  └── Plano STARTED → maxUsers = 3
       ├── João (READER) → vinculado a: Org A, Org B
       ├── Maria (READER) → vinculado a: Org C
       └── [slot disponível]
```

- O dono é quem convida, edita e remove membros
- O limite `maxUsers` é do plano do dono e conta os membros que ele gerencia
- Um membro pode ter acesso a múltiplas orgs do mesmo dono
- Remover um membro desvincula-o das orgs do dono; o usuário continua existindo no sistema

## Regras de Negócio

- Somente usuários com role **ADMIN** podem gerenciar membros da equipe
- O limite `maxUsers` do plano do dono é verificado antes de cada convite
- Ao convidar: dono seleciona nome, e-mail, role (READER/VIEWER) e quais das suas orgs o membro acessará
- O convite gera um `FirstAccessToken` e envia e-mail — sem campo de senha no formulário
- Um membro pode ser vinculado a **uma ou mais** organizações do dono no mesmo ato
- "Remover membro" desvincula das orgs do dono (não exclui a conta do membro do sistema)

## Contexto Técnico

- `BillingPlanFeatures.maxUsers` — limite de membros por plano do dono
- `UsersService.addOrganization()` — valida `maxUsers` por org (TASK-097-A) — referência de enforcement
- `AdminService.initializeUserAccess(user)` — cria `FirstAccessToken` + envia e-mail de convite
- `UserOrganization` — tabela de vínculo user ↔ org com `role` e `status`
- O endpoint ideal é no escopo `/me/team/users` (nível de conta do dono), não `/organizations/{orgCode}/users`
- `useCurrentOrganizationAccess()` — retorna `permissions` com indicador de ADMIN
- `UserTopBar.tsx` — dropdown com "Minha conta", "Minhas Empresas" etc. — falta "Equipe / Usuários"

## Tasks

| ID              | Título                                                                        | Tipo     | Prioridade |
|-----------------|-------------------------------------------------------------------------------|----------|------------|
| TASK-098        | Backend: endpoint `/me/team/users` — CRUD de membros com multi-org assignment | BACKEND  | 🔴 Crítico |
| TASK-099        | Frontend: "Usuários" / "Equipe" no UserTopBar dropdown (ADMIN only)           | FRONTEND | 🟠 Alto    |
| TASK-100        | Frontend: `/users` — listagem de membros da equipe com CRUD actions           | FRONTEND | 🟠 Alto    |
| TASK-101        | Frontend: `/users/new` — formulário de convite com multi-org select           | FRONTEND | 🔴 Crítico |
| TASK-102        | Frontend: `/users/[id]/edit` — editar membro + gerenciar orgs vinculadas      | FRONTEND | 🟠 Alto    |
| TASK-QA-MAN-009 | QA Manual: E2E fluxo completo de convite e gestão de membros da equipe        | QA       | 🟠 Alto    |

## Critério de Conclusão do Épico

- [ ] Dono ADMIN consegue convidar um novo membro, selecionar role e quais orgs ele acessa
- [ ] Membro recebe e-mail de convite sem que senha seja exibida em tela
- [ ] Limite `maxUsers` do plano bloqueado na criação com mensagem clara
- [ ] Listagem `/users` exibe todos os membros gerenciados pelo dono, com suas orgs e status
- [ ] Edição permite alterar nome, role e orgs vinculadas
- [ ] Remover membro desvincula das orgs do dono (usuário permanece no sistema)
- [ ] "Equipe" / "Usuários" no UserTopBar visível apenas para ADMIN
- [ ] Usuário não-ADMIN não acessa nenhuma rota do fluxo (frontend + backend)
