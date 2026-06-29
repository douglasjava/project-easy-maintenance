# TASK-100 — Frontend: `/users` — listagem de membros da equipe com CRUD actions

## Tipo
FRONTEND

## Categoria
Frontend / Gestão de Equipe

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

Não existe `/app/users/page.tsx`. Esta página é o hub central para o dono (ADMIN) gerenciar
os membros da sua equipe — pessoas que ajudam a operar as organizações dele.

O backend (TASK-098-A) expõe `GET /me/team/users` que retorna todos os membros vinculados a
qualquer das orgs do dono, com a lista de orgs de cada membro.

---

## O que fazer

### Layout

```
[Header: "Minha Equipe"]          [Botão "+ Convidar membro"]
[UsageMeter: X / maxUsers membros]

[Tabela / cards]
 Nome | E-mail | Role | Orgs vinculadas | Status | Ações (Editar / Remover)
```

### Comportamentos

1. **Fetch**: `GET /me/team/users` (sem `X-Org-Id` na query, endpoint de conta).

2. **UsageMeter**: exibir `membros atuais / features.maxUsers`. Usar `features` do
   `useCurrentOrganizationAccess()` para `maxUsers`.

3. **Orgs vinculadas**: cada membro mostra badges com as orgs que ele acessa.
   Ex.: `[Empresa A] [Empresa B]`.

4. **Guard ADMIN**: se `!permissions?.isAdmin` → redirecionar para `/`. A página inteira
   é exclusiva do ADMIN.

5. **Convidar**: link `href="/users/new"` (TASK-101).

6. **Editar**: link `href="/users/{id}/edit"` (TASK-102).

7. **Remover**: botão que chama `DELETE /me/team/users/{id}` com confirmação antes de
   executar. Atualiza lista localmente após sucesso (sem reload completo).

8. **Empty state**: se a equipe está vazia, exibir mensagem encorajando o convite do primeiro membro.

9. **Loading / Error states**: obrigatório.

10. **Badges visuais**:
    - Role: ADMIN = azul, READER = cinza-azulado, VIEWER = cinza
    - Status: ACTIVE = verde, INACTIVE = vermelho

### Responsividade
- Desktop: tabela com colunas
- Mobile: cards empilhados

---

## Critérios de Aceite

- [ ] Página `/users` renderiza a lista de membros via `GET /me/team/users`
- [ ] UsageMeter exibe `membros / maxUsers` do plano
- [ ] Cada membro mostra as orgs vinculadas em badges
- [ ] Loading e empty states implementados
- [ ] Usuário não-ADMIN é redirecionado para `/`
- [ ] Botão "Remover" aciona DELETE com confirmação e atualiza lista sem reload
- [ ] Badges de role e status com cores distintas
- [ ] Responsivo (mobile e desktop)
- [ ] Link "+ Convidar membro" navega para `/users/new`
- [ ] Link "Editar" navega para `/users/{id}/edit`

## Esforço Estimado
Médio — nova página com fetch de conta, badges multi-org e CRUD condicional.

## Dependências
- TASK-098-A (endpoint `GET /me/team/users`)
- TASK-098-D (endpoint `DELETE /me/team/users/{id}`)
