# TASK-QA-BUG-004 — Bug: Atribuição de assinatura a organização no step 2 falha com 500 — rota backend inexistente

## Tipo
BUG

## Categoria
Full-Stack / Admin / Billing / Organizations

## Prioridade
🟠 Alto — Bloqueia a conclusão do cadastro de organizações via área privada do SaaS (step 2 do wizard)

## Épico
EPIC-006 — Produto SaaS / Billing

## Módulos Impactados
- **Backend:** rota `PUT /easy-maintenance/api/v1/private/admin/billing/organizations/{orgCode}/subscription` **não existe**
- **Frontend:** `adminBillingService.updateUserSubscription(orgCode, payload)` chama essa rota e recebe 500
- **Fluxo afetado:** `/private/organizations/new` — Step 2 ("Assinatura")

## Severidade
**ALTA** — O step 2 é inoperante. A organização é criada no step 1, mas nunca recebe assinatura. O usuário fica preso ou tem de abandonar o fluxo.

---

## Descrição do Bug

Ao concluir o Step 1 (dados da empresa) em `/private/organizations/new`, o admin é redirecionado para o Step 2, onde deve configurar:

- Usuário responsável financeiro (`payerUserId`)
- Plano (`planCode`)
- Status inicial (`status`)
- Período (`currentPeriodStart`, `currentPeriodEnd`)

Ao submeter o Step 2, o frontend chama:

```
PUT /easy-maintenance/api/v1/private/admin/billing/organizations/0c77c741-896d-449f-abdd-1f2c0d128d1e/subscription
```

E o backend retorna:

```json
{
    "type": "https://easy-maintenance/api/problems/unexpected",
    "title": "Unexpected error",
    "status": 500,
    "detail": "Unexpected internal error",
    "instance": "/easy-maintenance/api/v1/private/admin/billing/organizations/0c77c741-896d-449f-abdd-1f2c0d128d1e/subscription",
    "properties": {
        "method": "PUT",
        "timestamp": "2026-05-25T18:28:06.287936860Z",
        "requestId": "8f14394c-b19e-40ef-93e5-88fd5e6e79e8"
    }
}
```

**Hipótese confirmada:** a rota `PUT .../organizations/{orgCode}/subscription` simplesmente não existe no backend. O 500 genérico é o fallback de "rota não encontrada" ou exception não mapeada ao tentar roteá-la.

---

## Root Cause

### Frontend (`adminBillingService.updateUserSubscription`)

```ts
async updateUserSubscription(userIdOrOrgCode: string, payload: any) {
    const url = isNaN(Number(userIdOrOrgCode))
        ? `/private/admin/billing/organizations/${userIdOrOrgCode}/subscription`
        : `/private/admin/billing/user/${userIdOrOrgCode}/subscription`;

    const { data } = await api.put(url, payload);
    return data;
}
```

Como `createdOrgCode` é um UUID, `isNaN(Number(uuid))` é `true`, portanto a URL escolhida é a de organizações — **que não existe no backend**.

A rota de usuário (`PUT .../user/{userId}/subscription`) **existe e funciona**.

### Backend

Existe apenas:
- `PUT /private/admin/billing/user/{userId}/subscription` — atribui/atualiza assinatura de um **usuário**

Não existe:
- `PUT /private/admin/billing/organizations/{orgCode}/subscription` — não implementado

---

## Diferenças entre os dois fluxos

| Aspecto | User subscription | Org subscription |
|---------|------------------|------------------|
| Resource ID | `userId` (numérico) | `orgCode` (UUID) |
| Source type | `USER_SUBSCRIPTION` | `ORG_SUBSCRIPTION` |
| Contexto | Plano pessoal do usuário | Plano da organização |
| Pagador | O próprio usuário | Passado via `payerUserId` |
| Já existe no backend | ✅ Sim | ❌ Não |

---

## Payload enviado pelo Frontend

```json
{
  "payerUserId": 42,
  "planCode": "STARTER",
  "status": "ACTIVE",
  "currentPeriodStart": 1748217600,
  "currentPeriodEnd": 1750809600
}
```

---

## O que precisa ser implementado

### Backend (obrigatório)

**1. Controller — novo endpoint:**
```
PUT /private/admin/billing/organizations/{orgCode}/subscription
```
- Autenticação: admin token (mesma validação dos outros endpoints de admin billing)
- Path variable: `orgCode` — código UUID da organização
- Body: `{ payerUserId, planCode, status, currentPeriodStart, currentPeriodEnd }`

**2. Lógica de negócio:**
- Verificar que a organização existe
- Verificar que o `payerUserId` referencia um usuário válido
- Criar ou atualizar um `billing_subscription_item` do tipo `ORG_SUBSCRIPTION` para a organização
- Linkar o pagador (`payer_account_id`) correto
- Aplicar o plano e período informados
- Retornar o item criado/atualizado (HTTP 200 ou 201)

**3. Referência:** seguir o mesmo padrão da rota existente  
`PUT /private/admin/billing/user/{userId}/subscription`  
Apenas adaptar `sourceType = ORG_SUBSCRIPTION` e trocar o identificador de `userId` para `orgCode`.

### Frontend (verificar)

Verificar se o `adminBillingService.updateUserSubscription` precisa passar o `X-Admin-Token` no header. Comparar com outros endpoints admin que usam:
```ts
headers: { "X-Admin-Token": adminToken, "X-id-User": idUser }
```

Se o endpoint backend exigir o token, adicionar o header antes de chamar `api.put(url, payload)`.

---

## Passos para Reproduzir

1. Acessar `/private/organizations/new` como admin
2. Preencher o Step 1 (dados da empresa) e avançar — organização é criada com sucesso
3. No Step 2, selecionar responsável financeiro, plano, status e período
4. Submeter o formulário
5. Observar: erro 500 retornado — organização fica sem assinatura

---

## Comportamento Atual (Errado)

- Step 2 sempre retorna 500
- A organização é criada (step 1 funciona), mas nunca recebe assinatura
- O admin não consegue concluir o cadastro completo de uma empresa

## Comportamento Esperado

- O Step 2 atribui a assinatura à organização com sucesso
- Backend retorna HTTP 200/201
- Admin é redirecionado para `/private/organizations` com toast de sucesso

---

## Critérios de Aceite

### Backend
- [ ] Rota `PUT /easy-maintenance/api/v1/private/admin/billing/organizations/{orgCode}/subscription` criada e funcional
- [ ] Organização inválida → 404
- [ ] Usuário pagador inválido → 422
- [ ] Admin token inválido/ausente → 401/403
- [ ] Assinatura criada com `sourceType = ORG_SUBSCRIPTION`
- [ ] Retorna HTTP 200 com o subscription item atualizado

### Frontend
- [ ] Step 2 conclui com sucesso após implementação backend
- [ ] Erro de API exibido como toast adequado (sem "Unexpected error" genérico)
- [ ] Admin é redirecionado para `/private/organizations` após sucesso
- [ ] Verificar se `X-Admin-Token` deve ser passado no header da chamada

---

## Arquivos a Modificar

**Backend:**
- Controller responsável por billing admin (provavelmente `AdminBillingController` ou similar)
- Service de billing admin — adicionar método para org subscription
- DTO de request (pode reusar o mesmo DTO do user subscription)

**Frontend:**
- `src/services/private/admin-billing.service.ts` — verificar/adicionar header de admin token se necessário

---

## Relacionado a
- TASK-QA-BUG-003 — Bug anterior no mesmo fluxo (companyType nulo no step 1) — já corrigido
- EPIC-006 — Produto SaaS

## Status
✅ Corrigido — easy-maintenance-api@3fdcf55 (25/05/2026)

## Root Cause Real (confirmado)

Endpoint `PUT /easy-maintenance/api/v1/private/admin/billing/organizations/{orgCode}/subscription` completamente ausente no `AdminBillingController`. O `BootstrapAdminFilter` passava a requisição (X-Admin-Token já era enviado automaticamente pelo `apiClient` para rotas `private/`), mas o Spring não encontrava handler → 500.

## Correção Aplicada

- `AdminBillingController`: injetado `OrganizationsService` + adicionado endpoint `PUT /organizations/{orgCode}/subscription`
- Delega para `OrganizationsService.addOrganizationSubscription` (reutiliza lógica existente sem duplicar)
- Sem cookie/token refresh: contexto admin não altera sessão do usuário
- Proteção `X-Admin-Token` garantida automaticamente pelo `BootstrapAdminFilter`
- Frontend: sem alteração necessária — `apiClient` já injetava o token corretamente
