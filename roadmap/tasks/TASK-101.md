# TASK-101 — Frontend: reescrever `/users/new` — convite por e-mail + org select

## Tipo
FRONTEND

## Categoria
Frontend / Convite de Usuário

## Prioridade
🔴 Crítico

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Usuários por Organização

---

## Contexto

`/app/users/new/page.tsx` existe mas tem vários problemas que inviabilizam seu uso em produção:

| Problema | Situação atual | Situação esperada |
|---|---|---|
| Campo `passwordHash` exposto | Admin define senha manualmente | Campo removido — backend gera senha aleatória e envia e-mail |
| Org fixada via `ENV.ORG_ID` | Só cria na org da sessão, sem escolha | Select com as organizações do admin logado |
| Sem guard ADMIN | Qualquer usuário pode acessar | Redirecionar para `/` se não for ADMIN |
| "Voltar" vai para `/` | Comportamento inesperado | "Voltar" deve ir para `/users` |
| Sem feedback de e-mail | Usuário não sabe que e-mail foi enviado | Toast + mensagem explícita sobre envio do convite |

---

## O que fazer

### Remover campo `passwordHash`

O backend (após TASK-098-B) gera a senha aleatória e aciona o fluxo de primeiro acesso. O frontend
não deve capturar ou transmitir senha. Remover o campo completamente do formulário e do payload.

### Adicionar select de organização

1. Ao montar a página, buscar as organizações do usuário logado via `GET /me/organizations` (ou endpoint equivalente que já existe para popular o seletor de orgs).
2. Exibir `<select>` com as orgs disponíveis, pré-selecionando a org ativa da sessão.
3. O `orgCode` selecionado é usado na rota: `POST /organizations/{orgCode}/users`.

### Guard ADMIN

```tsx
const { permissions, isLoading } = useCurrentOrganizationAccess();
if (!isLoading && !permissions?.isAdmin) {
  redirect("/");  // ou router.replace("/")
}
```

### Payload corrigido

```ts
const payload = {
  email: form.get("email"),
  name: form.get("name"),
  role: form.get("role"),
  status: "ACTIVE",
  // sem passwordHash
};
```

### Feedback ao usuário

Após sucesso:
```
"Convite enviado! {nome} receberá um e-mail com as instruções de primeiro acesso."
```
Limpar formulário e manter na página (ou redirecionar para `/users`).

### Link "Voltar"

```tsx
<Link href="/users">← Voltar</Link>
```

### Role select (melhorar UX)

Substituir o `<input name="role" placeholder="ADMIN / USER" />` por um `<select>`:
```tsx
<select name="role">
  <option value="USER">Usuário</option>
  <option value="ADMIN">Administrador</option>
</select>
```

---

## Critérios de Aceite

- [ ] Campo `passwordHash` removido do formulário e do payload
- [ ] Select de organização lista as orgs do admin logado e permite escolha
- [ ] Org ativa da sessão é pré-selecionada no select
- [ ] Role é um select (`ADMIN` / `USER`) em vez de campo livre
- [ ] Usuário não-ADMIN é redirecionado (não consegue acessar a página)
- [ ] Submit chama `POST /organizations/{orgCode}/users` com o orgCode selecionado
- [ ] Após sucesso: toast + mensagem de e-mail enviado
- [ ] "Voltar" navega para `/users`
- [ ] UsageMeter exibe `currentUsers / maxUsers` do plano (já existia — manter)
- [ ] Loading, error e estados de limite atingido tratados
- [ ] Responsivo (mobile e desktop)

## Esforço Estimado
Médio — reescrita de página existente. Principais mudanças: remoção de passwordHash, fetch de orgs, guard de role, select de role.

## Dependências
- TASK-098-B (backend deve enviar e-mail ao criar usuário)
- TASK-098-A (backend deve bloquear POST se caller não for ADMIN)

## Riscos
- `/me/organizations` endpoint: confirmar que existe e retorna a lista de orgs do usuário logado antes de implementar o select. Alternativa: listar de `organizationsContext` ou state global da sessão.
