# TASK-396 — BACKEND: conserta rota de edição de assinatura do usuário + endpoint admin de prorrogar/cortar acesso (EPIC-041)

## Tipo
BACKEND

## Categoria
Controle Administrativo de Acesso

## Prioridade
🟠 Alto

## Épico
[EPIC-041](../epics/EPIC-041.md) — Controle Administrativo de Acesso do Usuário

## QA obrigatório
Sim — prorrogar trial de um usuário e confirmar em `/me/access-context` que ele volta a
`FULL_ACCESS`; cortar pra somente leitura e confirmar `READ_ONLY`; cortar pra bloqueio total e
confirmar `NO_ACCESS`; confirmar que tudo fica auditado; confirmar 404 (não 500) quando o usuário
não tem nenhuma assinatura.

---

## Contexto
A aba "Billing" de `/private/users/[id]` já tem campos de status/período de assinatura, mas o PUT
que ela chama (`/private/admin/billing/user/{id}/subscription`, singular) foi removido do backend
no TASK-206 (refactor de billing por usuário) e nunca foi substituído — salva e falha
silenciosamente há meses. Esta task conserta isso e adiciona semântica de negócio (prorrogar/cortar)
em cima do PUT genérico, em vez de expor só campos brutos de enum pro admin editar às cegas.

## Escopo
- Novo `PUT /easy-maintenance/api/v1/private/admin/billing/users/{userId}/subscription` (plural,
  consistente com as outras rotas `/users/{userId}/...` já existentes no `AdminBillingController`)
  editando `status`/`currentPeriodEnd` do item de assinatura tipo `USER` do usuário.
  - 404 se o usuário não tiver nenhum `BillingSubscriptionItem` tipo `USER` (não auto-provisiona).
- Corrige `admin-billing.service.ts` (`updateUserSubscription`) pra chamar a rota nova.
- Dois métodos de conveniência no service (reaproveitados pelo TASK-398 na UI, mas já expostos
  aqui como ações de negócio, não só o PUT genérico):
  - `extendTrial(userId, newPeriodEnd)` → seta `status=TRIAL` + `currentPeriodEnd` novo.
  - `restrictAccess(userId, level, reason)` → `level=READ_ONLY` seta `status=CANCELED`;
    `level=BLOCKED` seta `status=BLOCKED`. `reason` é obrigatório (mesmo padrão de
    `DashboardActionsService.postpone`, que já rejeita motivo vazio).
- Toda chamada (extend/restrict, e o PUT genérico) grava em `AuditService`: ação, status
  anterior/novo, `currentPeriodEnd` anterior/novo, motivo, quem fez.

## Critérios de Aceite
- [ ] PUT novo funciona e o front para de falhar silenciosamente
- [ ] `extendTrial` empurra `currentPeriodEnd` e o usuário volta a `FULL_ACCESS` (verificado via
      `SubscriptionAccessService.resolveUserAccessMode`, sem precisar tocar em mais nada —
      `resolveEffectiveStatus` já deriva isso na leitura)
- [ ] `restrictAccess(READ_ONLY)` e `restrictAccess(BLOCKED)` produzem exatamente os `AccessMode`
      esperados
- [ ] Motivo vazio em `restrictAccess` é rejeitado
- [ ] Usuário sem nenhuma assinatura → 404, nunca 500
- [ ] Toda ação grava entrada de auditoria com os dados antes/depois
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma — conserta um gap existente, não depende de outra task deste épico.

## Riscos
Baixo — endpoint novo isolado, não toca em caminho crítico (login, assistente). Risco real é só
confundir `status=CANCELED` (usado aqui pra "somente leitura" administrativo) com um cancelamento
de verdade feito pelo próprio usuário via `SubscriptionItemCancelAdapter` — ambos os caminhos
resultam no mesmo `AccessMode`, o que é esperado, mas vale deixar claro no log de auditoria qual
caminho foi usado.

## Esforço
Médio

## Status
🟢 Implementado (03/11/2026) — branch `feature/EPIC-041-admin-access-control`
(`easy-maintenance-api`, commit `67d5e3b`). `mvn test`: 1693 testes, suíte completa sem
regressão. Branch ainda não mergeada em `staging` (as 4 tasks do EPIC-041 foram feitas juntas
numa única branch por repo, pra homologar tudo de uma vez).
