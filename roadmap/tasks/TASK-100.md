# TASK-100 — Frontend: `/users` — listagem de usuários da org com CRUD actions

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

Não existe `/app/users/page.tsx`. A tela de listagem de usuários por organização precisa ser criada do zero.
O backend já expõe `GET /easy-maintenance/api/v1/organizations/{orgCode}/users` que retorna a lista de
usuários vinculados à org do `X-Org-Id`.

Esta página é o hub central da gestão de usuários: exibe a lista, o uso vs. limite do plano, e
oferece ações de convite, edição e remoção (apenas para ADMIN).

---

## O que fazer

### Layout geral

```
[Header: "Usuários da organização"] [Botão "Convidar usuário" — só ADMIN]
[UsageMeter: currentUsers / maxUsers]
[Tabela ou lista de cards: avatar, nome, email, role, status, ações]
[Empty state se não há usuários além do próprio admin]
```

### Comportamentos

1. **Fetch**: `GET /organizations/{orgCode}/users` usando `orgCode` do contexto atual.
2. **UsageMeter**: exibir `currentUsers / features.maxUsers` igual ao que existe em `/users/new`.
3. **Guard ADMIN**: o botão "Convidar usuário" e as ações de "Editar" e "Remover" são visíveis
   apenas para `permissions?.isAdmin`. Usuários sem ADMIN veem a lista mas sem ações.
4. **Editar**: link para `/users/{id}/edit` (TASK-102).
5. **Remover**: botão que chama `DELETE /organizations/{orgCode}/users/{id}` com confirmação
   (`confirm()` nativo ou modal simples) — atualiza a lista após sucesso.
6. **Convidar**: link para `/users/new` (TASK-101).
7. **Loading / Empty / Error states**: obrigatório.
8. **Role badge**: exibir role com badge colorido (ADMIN = azul, USER = cinza).
9. **Status badge**: ACTIVE = verde, INACTIVE = vermelho.

### Responsividade
- Desktop: tabela com colunas Nome / E-mail / Role / Status / Ações
- Mobile: cards empilhados com as mesmas informações

---

## Critérios de Aceite

- [ ] Página `/users` renderiza a lista de usuários da org atual
- [ ] UsageMeter exibe `currentUsers / maxUsers` do plano
- [ ] Loading state exibido durante fetch
- [ ] Empty state exibido quando a org não tem outros usuários
- [ ] Usuário ADMIN vê botões "Convidar", "Editar" e "Remover"
- [ ] Usuário não-ADMIN vê apenas a lista, sem ações destrutivas
- [ ] Remover aciona `DELETE` com confirmação e atualiza lista
- [ ] Role e status exibidos com badges visuais
- [ ] Responsivo (mobile e desktop)
- [ ] Nenhuma regressão em outras páginas

## Esforço Estimado
Médio — nova página com fetch, estados e CRUD condicional.

## Dependências
- TASK-098 (backend DELETE endpoint e guard)
- TASK-101 (link para `/users/new`)
- TASK-102 (link para `/users/[id]/edit`)
