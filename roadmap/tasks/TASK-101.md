# TASK-101 — Frontend: `/users/new` — formulário de convite com multi-org select

## Tipo
FRONTEND

## Categoria
Frontend / Convite de Membro

## Prioridade
🔴 Crítico

## Fase
3 — Produto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Contexto

`/app/users/new/page.tsx` existe mas está incorreto para o modelo atual:

| Problema | Atual | Esperado |
|---|---|---|
| Campo `passwordHash` exposto | Admin define senha manualmente | Removido — backend gera e envia e-mail |
| Org fixada via `ENV.ORG_ID` | Apenas uma org, sem escolha | Multi-select com todas as orgs do dono |
| Sem guard ADMIN | Qualquer um pode acessar | Redireciona se não for ADMIN |
| Role como input livre | Campo de texto `ADMIN / USER` | Select com options READER / VIEWER |
| "Voltar" vai para `/` | Inesperado | Deve ir para `/users` |
| Endpoint errado | `POST /organizations/{ENV.ORG_ID}/users` | `POST /me/team/users` |

---

## O que fazer

### 1. Remover campo `passwordHash`

Backend gera senha aleatória e envia convite. Sem campo de senha no formulário.

### 2. Multi-select de organizações do dono

Ao montar a página, buscar as organizações do dono via `GET /me/organizations` (ou endpoint equivalente
já existente). Exibir checkboxes ou multi-select com as orgs disponíveis.

```tsx
// Exemplo de payload
const payload = {
  email: "joao@empresa.com",
  name: "João Silva",
  role: "READER",
  orgCodes: ["ORGABC", "ORGDEF"]  // orgs selecionadas
};
await api.post("/me/team/users", payload);
```

Ao menos uma org deve ser selecionada (validação frontend).

### 3. Select de role com opções corretas

```tsx
<select name="role">
  <option value="READER">Leitor</option>
  <option value="VIEWER">Visualizador</option>
</select>
```
*(Ajustar conforme os roles reais do sistema)*

### 4. Guard ADMIN

```tsx
const { permissions, isLoading } = useCurrentOrganizationAccess();
if (!isLoading && !permissions?.isAdmin) router.replace("/");
```

### 5. Feedback de convite enviado

Após sucesso:
- Toast: `"Convite enviado! {nome} receberá um e-mail com as instruções de primeiro acesso."`
- Limpar formulário (manter na página para convidar mais membros)
- OU redirecionar para `/users` (a definir na implementação)

### 6. UsageMeter

Manter o `UsageMeter` já existente no topo mostrando `currentUsers / maxUsers`.
Ao atingir o limite, desabilitar o botão de submit com mensagem de upgrade.

### 7. Link "Voltar"

```tsx
<Link href="/users">← Voltar</Link>
```

---

## Critérios de Aceite

- [ ] Campo `passwordHash` removido do formulário e do payload
- [ ] Multi-select (ou checkboxes) lista as orgs do dono; ao menos uma selecionada é obrigatório
- [ ] Role é um select com opções válidas (sem campo de texto livre)
- [ ] Submit envia para `POST /me/team/users` com `orgCodes` array
- [ ] Usuário não-ADMIN é redirecionado para `/`
- [ ] Toast de sucesso menciona e-mail de convite enviado
- [ ] UsageMeter exibe uso atual; botão desabilitado quando limite atingido
- [ ] "Voltar" navega para `/users`
- [ ] Loading, error e estados de limite tratados
- [ ] Responsivo (mobile e desktop)

## Esforço Estimado
Médio — reescrita de página existente + integração com novo endpoint backend.

## Dependências
- TASK-098-B (endpoint `POST /me/team/users`)
- Endpoint `GET /me/organizations` (verificar se existe para popular o select de orgs)

## Risco
Confirmar antes de implementar: qual endpoint retorna as organizações do dono autenticado?
Alternativa se não existir: usar o contexto de sessão/localStorage que já armazena as orgs do usuário.
