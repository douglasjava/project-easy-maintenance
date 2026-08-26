# TASK-206 — BUGFIX Full-stack: rota morta de assinatura por usuário no admin (mostra plano errado)

## Tipo
BUGFIX

## Categoria
Admin / Billing

## Prioridade
🟡 Médio

## Épico
Nenhum — bug pontual, pré-existente, sem relação com EPIC-002 Fase 3 (achado durante o QA dela,
`TASK-QA-MAN-014`, mas não é sobre onboarding/Asaas).

## QA obrigatório
Sim — QA manual: abrir a aba Pagamento de um usuário com plano diferente de STARTER (ex.: BUSINESS
ou ENTERPRISE) e confirmar que o campo "Plano" mostra o plano real, não sempre STARTER.

---

## Contexto

Achado por Douglas (25/08/2026) ao testar `TASK-QA-MAN-014`: abrir a aba "Dados de Faturamento" em
`/private/users/{id}` dispara `GET /private/admin/billing/user/{id}/subscription`, que retorna 500
(`NoResourceFoundException` — rota não existe, cai no handler genérico).

Rastreado via `git log -S` no `AdminBillingController.java`: essa rota foi removida no commit
`815e36e` ("Remove organization and user subscription services... replace with abstract billing
subscription services") — provável parte da consolidação de billing por usuário (EPIC-014). O
frontend (`admin-billing.service.ts`, método `getUserSubscription`) nunca foi atualizado.

**Impacto real:** baixo, mas não zero. A chamada já tem `.catch(() => null)` em
`fetchUserPayment` (`private/users/[id]/page.tsx`), então a tela não quebra — mas o campo "Plano"
cai no fallback `subscriptionData?.planCode || "STARTER"` sempre que a busca falha (ou seja,
sempre). Resultado: a tela mostra **"STARTER" pra qualquer usuário**, mesmo quem está em
BUSINESS/ENTERPRISE — dado incorreto exibido silenciosamente, sem indicar que a busca falhou.

## Objetivo

Ou (a) restaurar a busca do plano real do usuário via uma rota que exista de fato, ou (b) remover a
chamada morta e não fingir que sabe o plano quando não consegue buscar.

## Escopo

Investigar primeiro qual é a fonte de verdade correta pro plano de um usuário no modelo pós-EPIC-014
(provavelmente via `BillingSubscriptionService`/`BillingSubscriptionItemRepository`, dado que a
mensagem do commit menciona "abstract billing subscription services" como substituto) antes de
decidir entre as duas opções:

- **Opção A** — expor um endpoint correto (ex. reaproveitar dado que a aba Assinatura já busca) e
  apontar `getUserSubscription` pra ele.
- **Opção B** — remover a chamada morta de `fetchUserPayment` e mudar o fallback de `"STARTER"` pra
  algo que não minta (ex. `"—"` ou reaproveitar o `planCode` já carregado por `fetchUserBilling`,
  que roda quando a aba "Assinatura" é aberta — conferir se os dados já disponíveis ali resolvem sem
  precisar de chamada nova nenhuma).

## Critérios de Aceite

- [ ] Aba Pagamento não mostra mais "STARTER" fixo pra usuários com outro plano
- [ ] Nenhuma chamada de rede pra rota inexistente (`/user/{id}/subscription`)
- [ ] `mvn test` e `npm run build` sem regressão

## Fora de Escopo

- Qualquer mudança em EPIC-002 Fase 3 (TASK-201 a 205) — bug totalmente independente.
- Endpoint `/subscription-item/{id}` vs `/subscription-items/{id}` (duplicidade notada de
  passagem em `AdminBillingController` durante a investigação) — não investigado, fora do escopo
  desta task.

## Dependências
Nenhuma.

## Riscos
Baixo — mudança isolada na aba Pagamento do admin, sem afetar cobrança real.

## Esforço
Baixo

## Status
🟡 Em validação — implementada em `bugfix/TASK-206-user-subscription-route` nos dois repos,
aguardando teste local.

- api: `714badf` — `BillingSubscriptionItemService.findByUser`, endpoint
  `GET /admin/billing/users/{userId}/subscription` (reaproveita
  `BillingSubscriptionItemRepository.findBySourceTypeAndSourceId` já existente), 2 testes novos
  (813/813 passando)
- web: `a25f247` — `admin-billing.service.ts` aponta pra rota nova (plural). Corrige as duas abas
  que dependiam da rota morta: Assinatura (`fetchUserBilling`) e Pagamento (`fetchUserPayment`).
  `npm run build` limpo.
