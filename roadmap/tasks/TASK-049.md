# TASK-049 — Centralizar validação de expiração de TRIAL no /me/access-context

## Tipo
BUG + Refatoração Arquitetural

## Categoria
FULL_STACK

## Prioridade
🔴 Crítico

## Fase
1 — Pré-lançamento

## Épico
EPIC-003 — Multi-tenancy e Autorização

---

## Contexto

Durante os testes manuais de QA (16/04/2026), foi identificado um bug de consistência de autorização:

- A rota `GET /easy-maintenance/api/v1/me/access-context` **não valida se o período TRIAL expirou**
- A validação de expiração de TRIAL existe em uma rota separada: `GET /subscription/guard`
- O frontend controla **todo o seu modelo de autorização** (botões, ações, permissões, accessMode) exclusivamente pelo retorno de `/me/access-context`
- Resultado: um usuário com TRIAL expirado recebe `accessMode: READ_WRITE` e permissões completas no frontend, pois `/me/access-context` não reflete o TRIAL expirado

---

## Problema

### Bug de Autorização
Quando o TRIAL expira:
- `/me/access-context` retorna `subscriptionStatus: "TRIAL"` e `accessMode: "READ_WRITE"` como se o TRIAL ainda estivesse ativo
- Apenas `/subscription/guard` valida a expiração e bloqueia operações no backend
- O frontend continua mostrando todos os botões habilitados e permitindo fluxos de escrita

### Inconsistência Arquitetural
- Há **dois guardians de acesso** no sistema: `/me/access-context` (source of truth do front) e `/subscription/guard` (validação de expiração no back)
- Isso cria um modelo de autorização com duas fontes de verdade divergentes
- O `/subscription/guard` não serve ao fluxo atual do produto — o front nunca usa seu retorno para tomar decisões
- Manter a guard separada aumenta a superfície de inconsistência conforme o produto evolui

---

## Comportamento Esperado

Quando o TRIAL expira (`trialExpiresAt < now`), o endpoint `/me/access-context` deve:

### `accountAccess`
```json
{
  "subscriptionStatus": "TRIAL_EXPIRED",
  "accessMode": "READ_ONLY",
  "message": "Seu período de trial encerrou. Assine um plano para continuar.",
  "permissions": {
    "canViewOrganizations": true,
    "canCreateOrganization": false,
    "canManageOwnBilling": true
  }
}
```

### `organizationsAccess[*]`
Cada organização deve retornar:
```json
{
  "subscriptionStatus": "TRIAL_EXPIRED",
  "accessMode": "READ_ONLY",
  "message": "Trial expirado. Visualização apenas.",
  "permissions": {
    "canReadDashboard": true,
    "canCreateItem": false,
    "canEditItem": false,
    "canDeleteItem": false,
    "canRegisterMaintenance": false,
    "canManageOrganizationUsers": false,
    "canUpdateOrganization": false,
    "canManageOrganizationBilling": true
  }
}
```

---

## Escopo de Implementação

### Backend

**1. Centralizar a lógica de TRIAL expirado no serviço/provider de access-context**

O componente responsável por montar o `AccountAccess` e `OrganizationAccess` deve:
- Verificar se `subscriptionStatus == TRIAL` e `trialExpiresAt < LocalDateTime.now()`
- Se expirado: sobrescrever `subscriptionStatus` para `TRIAL_EXPIRED`, `accessMode` para `READ_ONLY`, zerar permissões de escrita

**2. Remover a rota `/subscription/guard`**

- Remover o controller/endpoint `GET /subscription/guard`
- Remover o service/provider correspondente
- Garantir que a lógica de validação de trial não se perca — ela deve ser absorvida pelo passo acima
- Verificar se algum `@SubscriptionGuard` ou `Filter/Interceptor` referencia essa rota e remover

**3. Adicionar `TRIAL_EXPIRED` ao enum de `SubscriptionStatus`** (se ainda não existir)

**4. Garantir que o AccessContextService não chame mais `/subscription/guard` internamente**

### Frontend

**1. Remover chamadas a `/subscription/guard`**

- Procurar em toda a codebase por chamadas a `subscription/guard`
- Remover o service/hook correspondente se existir
- Se houver um componente ou middleware que chama a guard e redireciona, substituir pela lógica de leitura do `accessContext.accountAccess.subscriptionStatus === "TRIAL_EXPIRED"`

**2. Garantir que o `AccessContextProvider` já cobre o redirecionamento**

O `AccessContextProvider` já usa `accessMode: READ_ONLY` para bloquear operações. Com a correção no backend, o front automaticamente receberá `TRIAL_EXPIRED` + `READ_ONLY` e os botões/ações serão desabilitados.

**3. Validar o componente `ReadOnlyBanner`**

- Verificar se `ReadOnlyBanner` exibe mensagem adequada para `TRIAL_EXPIRED`
- Se necessário, adicionar mensagem específica: "Seu trial expirou. [Assinar plano →]"

**4. Validar o componente `TrialBanner`**

- Garantir que ao expirar, o `TrialBanner` mude para o estado de "trial encerrado" com CTA de upgrade

---

## Critérios de Aceite

- [x] `GET /me/access-context` retorna `subscriptionStatus: TRIAL_EXPIRED` e `accessMode: READ_ONLY` quando `trialExpiresAt < now`
- [x] `GET /me/access-context` continua retornando `READ_WRITE` para TRIAL ainda ativo
- [x] A rota `/subscription/guard` foi removida do backend
- [x] Nenhuma referência a `/subscription/guard` persiste no frontend
- [x] `TrialBanner` exibe estado "encerrado" com CTA de assinatura quando `TRIAL_EXPIRED`
- [x] `ReadOnlyBanner` exibe mensagem contextual correta para `TRIAL_EXPIRED`
- [x] Todos os botões de escrita (criar item, registrar manutenção, etc.) ficam desabilitados para usuário com TRIAL expirado
- [x] Usuário com TRIAL expirado pode acessar dashboard (leitura) e página de billing (para assinar)
- [x] Testes unitários no backend cobrem o novo branch de `TRIAL_EXPIRED`
- [x] Nenhuma regressão para usuários com plano ativo (ACTIVE, FREE)

---

## Riscos

- **Regressão em usuários TRIAL ativos**: a lógica de expiração deve ser precisa — testar com `trialExpiresAt` no passado e no futuro
- **Multi-tenant**: validar que a expiração é avaliada por conta (accountAccess) e refletida em todas as organizações do usuário
- **Clock drift**: usar UTC consistentemente na comparação de datas

---

## Subtasks

- [x] Identificar o provider/service de access-context no backend que monta `AccountAccess`
- [x] Adicionar `TRIAL_EXPIRED` ao enum `SubscriptionStatus` (se ausente)
- [x] Implementar validação de expiração no provider de access-context
- [x] Escrever testes unitários (TRIAL ativo / TRIAL expirado / plano ativo)
- [x] Remover controller e service de `/subscription/guard` no backend
- [x] Remover chamadas a `/subscription/guard` no frontend
- [x] Atualizar `ReadOnlyBanner` com mensagem para `TRIAL_EXPIRED`
- [x] Validar `TrialBanner` no estado de trial encerrado
- [ ] Teste de regressão manual completo (happy path, trial expirado, plano ativo)

---

## Esforço
Médio (6-10h) — maior parte no backend; frontend é majoritariamente remoção

## Status
Concluida