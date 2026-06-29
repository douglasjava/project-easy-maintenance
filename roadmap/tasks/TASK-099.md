# TASK-099 — Frontend: "Usuários" no UserTopBar dropdown (ADMIN only)

## Tipo
FRONTEND

## Categoria
Frontend / Navegação / UX

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Usuários por Organização

---

## Contexto

`UserTopBar.tsx` exibe um dropdown com os links de navegação do usuário logado:
"Minha conta", "Minhas Empresas", "Faturamento", "Relatórios", "Ajuda / FAQ", "Sair".

Não existe entrada para "Usuários" — o `help/page.tsx` descreve o fluxo de convite mas o ponto
de entrada não existe na interface.

A opção "Usuários" deve aparecer **apenas para usuários com role ADMIN**, pois somente eles
têm permissão para gerenciar membros da organização.

---

## O que fazer

1. **Adicionar item "Usuários" no dropdown de `UserTopBar.tsx`** — entre "Minhas Empresas" e "Faturamento":
   ```tsx
   { href: "/users", label: "Usuários" }
   ```

2. **Renderizar condicionalmente** com base em `permissions?.isAdmin` (ou o campo de role equivalente
   retornado por `useCurrentOrganizationAccess()`):
   ```tsx
   const { permissions } = useCurrentOrganizationAccess();
   // ...
   {permissions?.isAdmin && (
     <Link href="/users" ...>Usuários</Link>
   )}
   ```

3. **Garantir que o item não aparece** durante `isLoading` (evitar flash de navegação).

4. **Alinhar visual** com os outros itens do dropdown (mesma classe, mesmo estilo).

---

## Critérios de Aceite

- [ ] Item "Usuários" aparece no dropdown para usuário com role ADMIN
- [ ] Item "Usuários" **não aparece** para usuário com role USER ou VIEWER
- [ ] Item "Usuários" **não aparece** durante `isLoading` (features/permissions ainda não carregados)
- [ ] Clicar em "Usuários" navega para `/users`
- [ ] Visual consistente com os outros itens do dropdown
- [ ] Nenhuma regressão nos outros itens do dropdown

## Esforço Estimado
Baixo — mudança cirúrgica em um componente, ~10 linhas.

## Dependências
- TASK-100 (página `/users` deve existir para o link funcionar) — pode ser feito em paralelo, mas TASK-099 precisa de TASK-100 para ser validado end-to-end.
