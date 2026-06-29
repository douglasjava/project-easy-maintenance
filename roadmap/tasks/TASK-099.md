# TASK-099 — Frontend: "Usuários" / "Equipe" no UserTopBar dropdown (ADMIN only)

## Tipo
FRONTEND

## Categoria
Frontend / Navegação / UX

## Prioridade
🟠 Alto

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

`UserTopBar.tsx` exibe um dropdown com os links de navegação do usuário logado:
"Minha conta", "Minhas Empresas", "Faturamento", "Relatórios", "Ajuda / FAQ", "Sair".

A funcionalidade de gestão de equipe precisa de um ponto de entrada. O help/page.tsx já descreve
o fluxo de convite ("Usuários → Novo Usuário") mas o link não existe na interface.

A opção deve aparecer **somente para usuários ADMIN**, já que apenas eles gerenciam membros.

---

## O que fazer

1. **Adicionar item "Usuários" no dropdown** — entre "Minhas Empresas" e "Faturamento":
   ```tsx
   { href: "/users", label: "Usuários" }
   ```

2. **Renderizar condicionalmente** com base em `permissions?.isAdmin`:
   ```tsx
   const { permissions } = useCurrentOrganizationAccess();
   // ...
   {permissions?.isAdmin && (
     <DropdownItem href="/users">Usuários</DropdownItem>
   )}
   ```

3. **Sem flash**: durante `isLoading`, `permissions` é null → item não renderiza.

4. **Visual consistente** com os outros itens do dropdown (mesma classe, mesmo espaçamento).

---

## Critérios de Aceite

- [ ] Item "Usuários" aparece no dropdown para usuário com role ADMIN
- [ ] Item "Usuários" não aparece para usuário com role READER/VIEWER/USER
- [ ] Item não aparece durante `isLoading` (sem flash)
- [ ] Clicar navega para `/users`
- [ ] Visual consistente com os outros itens do dropdown
- [ ] Nenhuma regressão nos outros itens

## Esforço Estimado
Baixo — ~10 linhas, mudança cirúrgica.

## Dependências
- TASK-100 (página `/users` precisa existir para validar E2E)
