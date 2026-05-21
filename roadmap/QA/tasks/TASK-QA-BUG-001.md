# TASK-QA-BUG-001 — Bug: Onboarding sem redirect e sem dados da organização após conclusão

## Tipo
BUG

## Categoria
Full-Stack / Onboarding / Session

## Prioridade
🟠 Alto — Grave. Afeta diretamente o usuário no momento mais crítico do produto (primeira impressão)

## Épico
EPIC-006 — Produto SaaS

## Módulos Impactados
- Frontend: fluxo de onboarding (último passo), session/context de organização
- Backend: endpoint de criação da organização (resposta após save)

## Severidade
**GRAVE** — O usuário completa o onboarding mas não chega ao dashboard. Exige re-login para continuar.

---

## Descrição do Bug

Após concluir o último passo do onboarding (cadastro da empresa/organização), ocorre um erro pois:

1. Os dados da organização **não são carregados no contexto da sessão** após o save
2. O **redirect para o dashboard não é realizado**

Ao fazer login novamente, tudo carrega corretamente — confirmando que os dados foram salvos no backend, 
mas o frontend não atualiza seu contexto após a operação de criação.

---

## Passos para Reproduzir

1. Criar uma nova conta (signup)
2. Percorrer todos os passos do onboarding
3. No último passo, preencher os dados da empresa e confirmar o cadastro
4. Observar: erro exibido, sem redirect para o dashboard
5. Fazer logout e logar novamente
6. Observar: dados carregam corretamente e o dashboard é exibido

---

## Comportamento Atual (Errado)

- Após salvar a organização, o frontend exibe erro
- Os dados da organização **não são populados no contexto** (`OrgContext` / `AccessContext`)
- Nenhum redirect para `/dashboard` ocorre
- O usuário precisa fazer login novamente para que tudo funcione

---

## Comportamento Esperado

- Após o save da organização, o frontend deve:
  - Recuperar os dados da organização (via resposta do endpoint ou chamada GET subsequente)
  - Popular o contexto da sessão com os dados retornados
  - Redirecionar automaticamente para `/dashboard`

---

## Hipótese de Root Cause

O frontend provavelmente faz o `POST` de criação da organização mas **não usa o response** para atualizar o contexto. 
O redirect para dashboard pode depender de dados da organização no contexto (`useOrganization` ou equivalente), que está vazio após o save.

**Solução recomendada** (prioridade nessa ordem):
1. Usar o objeto da organização retornado no response do `POST` para popular o contexto direto
2. Ou fazer um `GET /organization` logo após o save e popular o contexto antes de redirecionar

---

## Critérios de Aceite

- [ ] Após concluir o último passo do onboarding, o usuário **é redirecionado automaticamente para o dashboard**
- [ ] Os dados da organização estão disponíveis no contexto logo após o onboarding (sem necessidade de re-login)
- [ ] Nenhum erro é exibido durante o redirecionamento
- [ ] O fluxo funciona com e sem refresh de página (não depende de reload)
- [ ] Teste de regressão: onboarding completo desde o início sem re-login

---

## Evidências Necessárias (para validação)

- [ ] Screenshot ou vídeo do erro exibido após o último passo
- [ ] Screenshot do dashboard sendo exibido corretamente após o fix (sem re-login)
- [ ] Log do network tab mostrando a resposta do endpoint de criação da organização

---

## Relacionado a

- TASK-016 — Tratamento de erro claro no onboarding (concluída)
- EPIC-006 — Produto SaaS

## Status
🔄 Corrigido v2 — Em Validação (02/05/2026)

## Root Cause Real (v2 — confirmado após investigação aprofundada)

O problema era uma **quebra em cadeia entre JWT stale e TenantFilter IDOR**:

1. Login inicial: JWT emitido com `orgs: []` — correto, usuário não tinha empresa ainda
2. Onboarding conclui `POST /me/onboarding/organization` → DB cria `UserOrganization` com `orgCode`
3. Frontend salva `organizationCode` no localStorage → `window.location.replace("/")`
4. Full page reload: `AccessContextProvider` dispara `GET /me/access-context` com `X-Org-Id: <orgCode>`
5. `TenantFilter.validateOrgMembership()` lê `auth.getDetails()` (JWT ainda antigo, `orgs: []`) → **403 Forbidden**
6. apiClient interceptor redireciona para `/login` — usuário precisa re-logar

**O fix anterior** (só `window.location.replace`) resolveu o race condition de navegação mas não o problema de JWT stale. O cookie `accessToken` ainda carregava o JWT sem a org, causando o 403 no TenantFilter.

## Correção Aplicada (v2)

### Fix — Backend (solução de raiz)

**`UsersService.java`** — novo método `issueRefreshedToken(Long userId)`:
- Faz fetch atualizado do usuário no DB (com todas as orgs após o `addOrganization`)
- Chama `buildFullToken()` com a lista atual de orgCodes
- Retorna o JWT atualizado

**`OnboardingController.java`** — `createOrganization()` agora:
- Injeta `UsersService`
- Após `onboardingService.createOrganization()` concluir (transação commitada)
- Chama `usersService.issueRefreshedToken(user.getId())`
- Seta novo cookie `accessToken` (HttpOnly, Secure, SameSite=Strict, 7 dias) — exatamente como no login
- O frontend recebe o cookie renovado na mesma resposta do POST de onboarding

### Fluxo Correto Após Correção (v2)

```
1. Login → JWT{orgs: []} (sem empresa ainda) → cookie accessToken set
2. Onboarding/user → cria BillingAccount + Trial
3. Onboarding/organization →
   a. Cria Organization no DB
   b. usersService.addOrganization(userId, orgCode) → DB: UserOrganization criada
   c. usersService.issueRefreshedToken(userId) → busca user+orgs frescos do DB
   d. buildFullToken → JWT{orgs: ["ORG001"]}
   e. Set-Cookie: accessToken=<JWT atualizado> na response
4. Frontend recebe orgCode + novo cookie
5. window.location.replace("/") → full page reload
6. Browser envia novo accessToken cookie nas próximas requests
7. AccessContextProvider dispara GET /me/access-context com X-Org-Id: ORG001
8. TenantFilter.validateOrgMembership → JWT{orgs:["ORG001"]}.contains("ORG001") → ✅
9. Dashboard carrega corretamente, sem re-login
```

### Fix anterior mantido (v1 — prevenção)
`onboarding/page.tsx`: `window.location.replace("/")` em vez de `router.push` — garante remontagem limpa do `AccessContextProvider`.
