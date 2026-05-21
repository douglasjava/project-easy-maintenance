# TASK-055 — Bug: Sessão do usuário sem organização é apagada após login

## Metadados

| Campo | Valor |
|-------|-------|
| **ID** | TASK-055 |
| **Tipo** | BUGFIX |
| **Prioridade** | 🔴 Crítico |
| **Severidade** | GRAVE |
| **Épico** | EPIC-006 (Onboarding) |
| **Sprint** | Hotfix — fora de sprint |
| **Status** | Ready to Implement |
| **Criado em** | 12/05/2026 |

---

## Problema

Usuário que realiza login pela primeira vez (sem organização vinculada) tem **toda a sua sessão apagada** logo após o redirect para a tela de onboarding, fazendo com que o token e os dados de identificação não sejam persistidos.

### Comportamento atual

1. Usuário loga → backend retorna `organizationCodes: []`
2. `AuthContext.login()` salva corretamente `isLoggedIn`, `userId`, `userName` no storage
3. Chama `checkSubscription()` → faz `GET /me/access-context` **sem `X-Org-Id`** (nenhuma org no storage)
4. `TenantFilter` bloqueia com **400 Bad Request** ("Missing X-Org-Id header") — o endpoint não está na lista de bypass
5. `checkSubscription()` captura o erro → retorna `"UNKNOWN"`
6. Redirect para `/onboarding` parece funcionar (token ainda `"cookie"`)
7. **Na montagem da página** → `initAuth()` roda → acha `isLoggedIn` → chama `checkSubscription()` novamente → mesmo **400** → `"UNKNOWN"` → **`clearLocalState()` apaga** `isLoggedIn`, `userId`, `userName` e seta `token = null`
8. Usuário está em `/onboarding` sem sessão válida. Qualquer navegação ou refresh força novo login

### Comportamento esperado

Usuário logado sem organização deve:
- Ter sessão preservada ao navegar para `/onboarding`
- Conseguir completar o onboarding normalmente
- `checkSubscription()` deve retornar `"ACTIVE"` para usuário com subscription de trial válida, independente de ter org ou não

---

## Root Cause

**Causa primária (backend):** `GET /easy-maintenance/api/v1/me/access-context` não está na lista de bypass do `TenantFilter`. Para usuários sem organização, o frontend não tem `X-Org-Id` para enviar, causando 400.

**Causa secundária (frontend):** `initAuth()` em `AuthContext` trata `"UNKNOWN"` (que pode vir de 400, 503, ou timeout) como cookie expirado e limpa o estado. Deveria limpar **somente** em caso de 401/403.

---

## Arquivos Impactados

### Backend
- `src/main/java/.../shared/web/filter/TenantFilter.java`

### Frontend
- `src/contexts/AuthContext.tsx`

---

## Fix Proposto

### Fix 1 — Backend (obrigatório)

Adicionar `GET /me/access-context` ao `BYPASS_EXACT` no `TenantFilter`:

```java
// TenantFilter.java — adicionar em BYPASS_EXACT:
"GET /easy-maintenance/api/v1/me/access-context"
```

`FeatureAccessService.getAccessContext()` já é seguro sem tenant:
- `buildAccountAccess(userId)` não usa `TenantContext` ✅
- `organizationRepository.findAllByUserId()` retorna lista vazia → `buildOrganizationAccess()` nunca é chamado ✅
- Retorna `organizationsAccess: []` corretamente ✅

### Fix 2 — Frontend (defensivo)

Em `AuthContext.initAuth()`, distinguir UNKNOWN de falha de autenticação real. Não limpar estado em UNKNOWN se o usuário não tem org (está em onboarding):

```typescript
// AuthContext.tsx — initAuth()
// Opção A: não limpar estado em UNKNOWN (mais permissiva)
if (status === "ACTIVE") {
    setToken("cookie");
} else if (status === "TRIAL_EXPIRED") {
    setToken("cookie"); // ainda deixa acessar mas bloqueia via isBlocked
} else {
    // UNKNOWN: não limpar estado — pode ser TenantFilter bloqueando sem X-Org-Id
    // O interceptor 401/403 do apiClient já cuida da expiração real do cookie
    if (window.localStorage.getItem(AUTH_FLAG) || window.sessionStorage.getItem(AUTH_FLAG)) {
        setToken("cookie"); // manter sessão, cookie ainda pode ser válido
    }
}

// Opção B: skip checkSubscription em login() quando não há orgs (mais cirúrgica)
if (!data?.firstAccess && data?.organizationCodes?.length > 0) {
    await checkSubscription();
}
```

> **Recomendação:** Implementar ambos. Fix 1 resolve a causa raiz. Fix 2 é defesa em profundidade.

---

## Critérios de Aceite

- [ ] Usuário sem org consegue fazer login e acessar `/onboarding` com sessão preservada
- [ ] `isLoggedIn`, `userId` e `userName` permanecem no storage após redirect para `/onboarding`
- [ ] `checkSubscription()` retorna `"ACTIVE"` para usuário com trial válido mesmo sem org
- [ ] Onboarding completa com sucesso e dados de org são salvos corretamente
- [ ] Usuário com org ativa continua funcionando normalmente (sem regressão)
- [ ] Cookie realmente expirado ainda limpa a sessão corretamente (sem regressão no logout implícito)

---

## Testes a Validar

- Login com usuário sem org → `/onboarding` → refresh da página → sessão mantida
- Login com usuário sem org → completar onboarding → dashboard acessível
- Login com cookie expirado → redirect para `/login` (comportamento preservado)
- Login com org ativa → dashboard normal (sem regressão)
