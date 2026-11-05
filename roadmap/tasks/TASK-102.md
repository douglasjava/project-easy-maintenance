# TASK-102 — Frontend: `/users/[id]/edit` — editar membro + gerenciar orgs vinculadas

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

Não existe `/app/users/[id]/edit/page.tsx`. O dono (ADMIN) precisa conseguir alterar
o nome, role e quais organizações o membro acessa — incluindo adicionar novas orgs ou
remover acesso de orgs existentes.

O backend (TASK-098-C) expõe `PATCH /me/team/users/{id}` que aceita `orgCodes` como
lista completa (replace, não merge).

---

## O que fazer

### Fetch inicial

Ao montar, buscar `GET /me/team/users` e filtrar pelo `id` da rota (ou adicionar endpoint
`GET /me/team/users/{id}` se necessário). Pré-popular:
- Nome
- Role atual
- Orgs vinculadas (checkadas no multi-select)

### Formulário

```
[Nome]
[Role: select]
[Organizações: multi-select/checkboxes das orgs do dono, com as atuais pré-marcadas]
[Botão "Salvar alterações"]
[Botão "Voltar" → /users]
```

### Lógica de orgs

Ao salvar, enviar a lista **completa** de `orgCodes` selecionados:
- Orgs adicionadas: backend cria novo `UserOrganization`
- Orgs removidas: backend deleta o vínculo

O frontend apenas envia a lista final; o backend faz o diff.

### Desativação rápida (opcional)

Exibir botão "Desativar acesso" que define `status: INACTIVE` no membro,
com confirmação antes de executar. Isso remove o acesso sem desvincular das orgs.

### Guard ADMIN

Se `!permissions?.isAdmin` → redirecionar para `/`.

### Proteção: dono não edita a si mesmo

Se o `id` da rota for o mesmo do usuário autenticado → exibir aviso e desabilitar
o formulário. O dono não pode alterar sua própria role via este fluxo.

---

## Critérios de Aceite

- [ ] Página `/users/[id]/edit` exibe dados atuais do membro pré-populados
- [ ] Multi-select de orgs do dono com as atuais marcadas
- [ ] Salvar envia `PATCH /me/team/users/{id}` com orgCodes completo e exibe toast de sucesso
- [ ] Role é select (sem input livre)
- [ ] Usuário não-ADMIN é redirecionado para `/`
- [ ] Dono não consegue editar a si mesmo (aviso + formulário desabilitado)
- [ ] Orgs adicionadas e removidas refletem corretamente após salvar
- [ ] "Voltar" navega para `/users`
- [ ] Loading, not found (404) e error states tratados
- [ ] Responsivo (mobile e desktop)

## Esforço Estimado
Médio — nova página com fetch, multi-select de orgs, guard de role e lógica de diff via backend.

## Dependências
- TASK-098-A (para buscar dados do membro)
- TASK-098-C (endpoint `PATCH /me/team/users/{id}`)
- TASK-100 (link "editar" vem da listagem `/users`)
