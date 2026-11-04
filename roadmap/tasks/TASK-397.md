# TASK-397 — BACKEND: bloqueio de login por AccessMode — dono e "filhos" sem billing próprio (EPIC-041)

## Tipo
BACKEND

## Categoria
Controle Administrativo de Acesso

## Prioridade
🔴 Crítico

## Épico
[EPIC-041](../epics/EPIC-041.md) — Controle Administrativo de Acesso do Usuário

## QA obrigatório
Sim — crítico porque toca o login de **todo** usuário do sistema, não só dos 2 pilotos. Testar
login pra cada valor de `SubscriptionStatus` existente (ACTIVE, TRIAL, PAST_DUE, CANCELED,
PENDING_PAYMENT, PAYMENT_FAILED, NONE, PENDING_ACTIVATION, TRIAL_EXPIRED, MEMBER, BLOCKED) e
confirmar que só `BLOCKED` passa a impedir login — os demais continuam exatamente como hoje.
Testar também o caso de membro de equipe (sem item `USER` próprio) em organização bloqueada, e em
organização saudável.

---

## Contexto
Hoje nada no sistema impede login por status de assinatura — `UsersService.authenticate()` só
verifica e-mail/senha. O único enforcement real de acesso é o `SubscriptionAccessAspect`, que
bloqueia apenas escrita, via `@RequiresFullAccess`. Isso significa que mesmo um usuário com
assinatura `BLOCKED` continua entrando e navegando a aplicação inteira em modo leitura.

**Complicador encontrado no builder check da spec**: não basta chamar
`SubscriptionAccessService.resolveUserAccessMode(userId)` direto no login. Essa função devolve
`READ_ONLY` sempre que o usuário não tem item `BillingSubscriptionItem` tipo `USER` próprio — e
isso é o caso de **todo membro de equipe convidado** (papel diferente de `ADMIN`, vinculado à
organização de quem paga, sem billing individual). Se a checagem de login usasse essa função
direto, bloquear o dono nunca bloquearia o login dos membros da equipe dele — ficariam órfãos: a
organização já surda (TASK-399 corta notificação/assistente) mas eles continuando a entrar numa
tela sem função nenhuma.

## Decisão de design desta task
Novo método `SubscriptionAccessService.resolveLoginAccessMode(User user)`:
- Se o usuário tem item `USER` próprio (é dono de conta) → usa `resolveUserAccessMode` direto.
- Senão (é membro de equipe) → resolve `resolveOrganizationAccessMode(orgCode)` para cada
  organização em que o usuário está (`user.getOrganizations()`); login só é negado (`NO_ACCESS`) se
  **todas** as organizações dele estiverem em `NO_ACCESS`. Um membro que também está em outra
  organização saudável continua conseguindo entrar — só perde o que depende da organização
  bloqueada (igual já acontece hoje em escrita).

`UsersService.authenticate()` e `verifyTwoFactor()` chamam esse método depois de validar a senha;
se `NO_ACCESS`, rejeita com `ProblemDetail` claro ("Acesso suspenso, contate o suporte") — nunca a
mensagem genérica de senha incorreta.

Bloqueio vale a partir da próxima tentativa de login — sem invalidar token/sessão já emitida
(decisão confirmada por Douglas, fora de escopo nesta entrega).

## Escopo
- `SubscriptionAccessService.resolveLoginAccessMode(User user)`.
- `UsersService.authenticate()` e `verifyTwoFactor()` chamam o novo método e rejeitam em
  `NO_ACCESS`.
- Novo `ProblemDetail`/exceção dedicada (não reaproveitar a de senha incorreta).

## Critérios de Aceite
- [ ] Dono de conta com assinatura `BLOCKED` não consegue logar
- [ ] Dono com qualquer outro status continua logando exatamente como hoje
- [ ] Membro de equipe de organização `BLOCKED` sem outra organização não consegue logar
- [ ] Membro de equipe com pelo menos uma organização saudável continua logando
- [ ] Mensagem de erro do bloqueio é distinta da de senha incorreta
- [ ] 2FA (`verifyTwoFactor`) tem a mesma proteção
- [ ] Teste de regressão cobrindo todos os valores de `SubscriptionStatus` no login
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma — usa `SubscriptionAccessService` já existente. Testável antes ou depois do TASK-396.

## Riscos
Alto impacto se mal testado — é o login de todo o sistema. Mitigado pelo teste de regressão
explícito por status exigido nos critérios de aceite.

## Esforço
Médio

## Status
🟢 Implementado (03/11/2026) — branch `feature/EPIC-041-admin-access-control`
(`easy-maintenance-api`, commit `67d5e3b`). `resolveLoginAccessMode` cobre dono e "filhos";
testes dedicados cobrindo login pra cada `AccessMode` (via `UsersServiceLoginAccessTest`) e todo
cenário dono/filho/multi-org (via `SubscriptionAccessServiceLoginAccessTest`). Suíte completa
(1693 testes) sem regressão. Branch ainda não mergeada em `staging`.
