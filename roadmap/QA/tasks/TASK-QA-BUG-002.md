# ~~TASK-QA-BUG-002~~ — Bug Blocante: Loop infinito no primeiro login — troca de senha falha com 403 via /v1/me/access-context

## Tipo
BUG

## Categoria
Full-Stack / Autenticação / Primeiro Login

## Prioridade
🔴 Crítico — **BLOCANTE**. O usuário não consegue realizar o primeiro login. Impede acesso total ao produto.

## Épico
EPIC-001 — Segurança e Autenticação / EPIC-003 — Multi-tenancy e Autorização

## Módulos Impactados
- Frontend: fluxo de primeiro login, `AccessContextProvider` ou `middleware.ts`, página de troca de senha
- Backend: endpoint `/v1/me/access-context` (requer usuário autenticado com permissões completas)

## Severidade
**BLOCANTE** — Usuário novo fica em loop e não consegue acessar o produto. Afeta 100% dos novos usuários com troca de senha obrigatória.

---

## Descrição do Bug

Quando um usuário realiza o **primeiro login** e é obrigado a trocar a senha (`MUST_CHANGE_PASSWORD`):

1. O fluxo **redireciona corretamente** para a página de troca de senha
2. Porém, durante esse estado intermediário, o frontend realiza uma chamada para `GET /v1/me/access-context`
3. Essa rota **exige autenticação completa** — o token parcial do estado `MUST_CHANGE_PASSWORD` **não possui as permissões necessárias**
4. O backend retorna **403 Forbidden**
5. O 403 aciona o tratamento de erro de autenticação do frontend, que **redireciona para o login**
6. O ciclo se repete indefinidamente — o usuário fica **preso em loop**

---

## Passos para Reproduzir

1. Criar um usuário com a flag de "trocar senha no primeiro login" habilitada
2. Realizar login com esse usuário
3. Observar: redirecionamento para a página de troca de senha (comportamento correto até aqui)
4. Observar no Network tab: chamada para `GET /v1/me/access-context` sendo disparada
5. Observar: response `403 Forbidden`
6. Observar: redirecionamento de volta para a tela de login
7. Ao logar novamente: ciclo se repete — o usuário nunca consegue trocar a senha

---

## Comportamento Atual (Errado)

- Usuário em estado `MUST_CHANGE_PASSWORD` é redirecionado para a página de troca de senha
- O `AccessContextProvider` ou `middleware.ts` dispara chamada para `/v1/me/access-context`
- Retorno é `403` pois o token parcial não tem permissão para esse endpoint
- Frontend interpreta o 403 como sessão inválida e redireciona para login
- Loop infinito: login → troca de senha → 403 → login → ...

---

## Comportamento Esperado

Quando o usuário está no estado `MUST_CHANGE_PASSWORD`:
- A chamada para `/v1/me/access-context` **não deve ser realizada**, OU
- O endpoint deve reconhecer o estado e retornar uma resposta adequada (ex: `accessMode: MUST_CHANGE_PASSWORD`) **sem retornar 403**, OU
- O `middleware.ts` / `AccessContextProvider` deve **permitir o acesso à página de troca de senha** sem depender do access-context
- O fluxo de troca de senha deve ser completado com sucesso antes de qualquer chamada ao access-context

---

## Hipótese de Root Cause

O `AccessContextProvider` ou o `middleware.ts` provavelmente executa a chamada para `/v1/me/access-context` **em toda navegação ou inicialização**, sem verificar se o usuário está em estado intermediário (`MUST_CHANGE_PASSWORD`).

O token JWT emitido para o estado de troca de senha possui escopo limitado (correto por segurança), mas o frontend não trata esse estado antes de chamar rotas que exigem autenticação completa.

**Solução recomendada** (a avaliar):

**Opção A (Frontend — preferida):**
- No `middleware.ts`, verificar se o token JWT possui o claim `mustChangePassword: true`
- Se sim, redirecionar para `/change-password` e **pular** a chamada ao `/v1/me/access-context`
- A chamada ao access-context só deve ocorrer após a troca de senha ser concluída

**Opção B (Backend):**
- Fazer com que `/v1/me/access-context` retorne um estado especial (`accessMode: MUST_CHANGE_PASSWORD`) em vez de 403 quando o token for parcial
- O frontend trata esse estado e redireciona para a troca de senha sem entrar em loop

---

## Critérios de Aceite

- [ ] Usuário com `MUST_CHANGE_PASSWORD` consegue acessar a **página de troca de senha** sem receber 403
- [ ] O fluxo de troca de senha é **concluído com sucesso** (nova senha salva)
- [ ] Após trocar a senha, o usuário é **redirecionado para o dashboard** automaticamente
- [ ] **Nenhum loop** de login → troca de senha → 403 → login ocorre
- [ ] O endpoint `/v1/me/access-context` **não é chamado** enquanto o usuário está em estado `MUST_CHANGE_PASSWORD` (ou trata o estado sem retornar 403)
- [ ] Teste de regressão: login normal (sem troca de senha obrigatória) não é afetado

---

## Evidências Necessárias (para validação)

- [ ] Vídeo ou screenshots mostrando o fluxo completo de primeiro login com troca de senha funcionando
- [ ] Screenshot do Network tab sem o 403 no `/v1/me/access-context` durante a troca de senha
- [ ] Screenshot do dashboard após a troca de senha (sem re-login)

---

## Relacionado a

- TASK-045 — Criar middleware.ts para guards de autenticação (concluída)
- TASK-049 — Centralizar validação de expiração de TRIAL no /me/access-context (concluída)
- EPIC-001 — Segurança e Autenticação

## Status
✅ Concluído — Validado em 02/05/2026

## Root Cause Real (confirmado após teste)

**O middleware.ts bloqueava `/auth/change-password`** antes de qualquer código de componente executar.

`/auth/change-password` não estava em `PUBLIC_PATHS`. O Next.js Edge Middleware verifica o cookie `accessToken` — se o backend não seta esse cookie para usuários `firstAccess` (ou seta com escopo limitado que o middleware não aceita), a navegação é interceptada e redirecionada para `/login` imediatamente. Os fixes de AccessContextProvider/interceptor nunca chegavam a ser executados.

## Correção Aplicada (5 camadas — v2)

### Fix 1 — `middleware.ts` ← Fix principal
Adicionado `/auth/change-password` ao `PUBLIC_PATHS`. A página tem sua própria proteção via `sessionStorage.getItem("tempIdUser")`.

### Fix 2 — `AuthContext.tsx`
Pula `checkSubscription()` no `login()` quando `data?.firstAccess === true`.

### Fix 3 — `AccessContextProvider.tsx`
Desabilita a query quando `pathname === "/auth/change-password"`.

### Fix 4 — `apiClient.ts`
Não redireciona para `/login` se o usuário está em `/auth/change-password`.

### Fix 5 — `auth/change-password/page.tsx`
- Após sucesso: limpa flags de auth parcial (`isLoggedIn`, `userId`, `userName`)
- Redireciona para `/login` (não para `/dashboard`) com 2s de delay para o toast
- O usuário faz login com a nova senha e recebe um JWT completo

## Fluxo Correto Após Correção

```
1. Primeiro login → backend retorna firstAccess:true
2. middleware.ts → /auth/change-password está em PUBLIC_PATHS → permite acesso
3. change-password/page.tsx renderiza (tempIdUser está em sessionStorage)
4. AccessContextProvider query desabilitada (Fix 3) → sem chamada ao /me/access-context
5. Usuário digita nova senha → POST /auth/change-password → sucesso
6. Limpa isLoggedIn + tempIdUser
7. Redireciona para /login
8. Usuário faz login com nova senha → JWT completo → dashboard
```
