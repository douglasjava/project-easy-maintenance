# TASK-102 — Frontend: `/users/[id]/edit` — edição + desativação de usuário

## Tipo
FRONTEND

## Categoria
Frontend / Gestão de Usuários

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Usuários por Organização

---

## Contexto

Não existe `/app/users/[id]/edit/page.tsx`. Para completar o CRUD de usuários por organização,
o admin precisa conseguir editar o nome, role e status de um usuário já vinculado à org, além de
poder desativá-lo sem removê-lo completamente.

O backend já expõe `PATCH /organizations/{orgCode}/users/{id}` (TASK-098-A irá adicionar o guard de ADMIN).

---

## O que fazer

### Criar `/app/users/[id]/edit/page.tsx`

1. **Fetch do usuário**: ao montar, buscar `GET /organizations/{orgCode}/users/{id}` e pré-popular
   o formulário com os dados atuais (nome, role, status).

2. **Formulário de edição**:
   - Campo `name` (obrigatório)
   - Select `role` (ADMIN / USER)
   - Select `status` (ACTIVE / INACTIVE)
   - Botão "Salvar alterações" → `PATCH /organizations/{orgCode}/users/{id}`
   - Botão "Voltar" → `/users`

3. **Guard ADMIN**: redirecionar para `/` se `!permissions?.isAdmin`.

4. **Desativação rápida**: além do select de status, exibir botão "Desativar usuário" que seta
   `status: INACTIVE` diretamente, com confirmação. Isso é um atalho visual para a operação mais comum.

5. **Impedir auto-edição**: se o `id` da rota for o mesmo do usuário logado, desabilitar o select
   de role e exibir aviso: "Você não pode alterar sua própria role."

6. **Estados**: loading, not found (404), error de servidor.

### Layout sugerido

```
[Header: "Editar usuário — {nome}"] [Botão Voltar]
[Formulário: nome / role / status]
[Botão Salvar] [Botão Desativar (vermelho, com confirmação)]
```

---

## Critérios de Aceite

- [ ] Página `/users/[id]/edit` exibe dados atuais do usuário pré-populados
- [ ] Salvar chama `PATCH /organizations/{orgCode}/users/{id}` e exibe toast de sucesso
- [ ] Role e status são selects (não inputs livres)
- [ ] Usuário não-ADMIN é redirecionado para `/`
- [ ] Auto-edição de role é bloqueada com aviso (o próprio admin não pode alterar sua própria role)
- [ ] "Desativar usuário" seta `status: INACTIVE` com confirmação antes de executar
- [ ] "Voltar" navega para `/users`
- [ ] Loading, not found (404) e error states tratados
- [ ] Responsivo (mobile e desktop)

## Esforço Estimado
Médio — nova página com fetch, formulário controlado, guard de role e lógica de auto-edição.

## Dependências
- TASK-098-A (guard ADMIN no PATCH backend)
- TASK-100 (link "editar" vem da listagem `/users`)
