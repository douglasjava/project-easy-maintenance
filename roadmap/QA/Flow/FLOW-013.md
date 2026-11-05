# FLOW-013 — Controle Administrativo de Acesso (Prorrogar/Cortar) + Gate de Plano Ativo

## Criticidade
🔴 CRITICAL

## Launch Relevance
Toca `UsersService.authenticate()`/`verifyTwoFactor()` — o login de **todo** usuário do sistema,
não só dos pilotos que motivaram a feature. Qualquer regressão aqui é capaz de impedir login de
clientes pagantes reais. Em paralelo, endurece o assistente de IA e 5 serviços de notificação —
risco menor (não bloqueia ninguém de entrar), mas pode silenciar notificação legítima se o
`AccessMode` for mal resolvido.

## Tasks Relacionadas
- TASK-396 — Backend: conserta rota de edição de assinatura + endpoint admin de prorrogar/cortar
  acesso, com auditoria
- TASK-397 — Backend: bloqueio de login por `AccessMode` — dono e "filhos" sem billing próprio
- TASK-398 — Frontend: botões "Prorrogar trial" / "Cortar acesso" no admin de billing
- TASK-399 — Backend: gate de plano ativo no assistente de IA e nas notificações operacionais

## Descrição do Fluxo

Douglas, como admin do SaaS (via `/private/admin/billing/subscriptions`), prorroga o trial de um
usuário (`currentPeriodEnd` para frente, status forçado para `TRIAL`) ou corta o acesso dele em
dois níveis — **somente leitura** (`SubscriptionStatus.CANCELED`) ou **bloqueio total de login**
(`SubscriptionStatus.BLOCKED`) — com motivo obrigatório, registrado em auditoria
(`AuditService.logUpdate`). Nenhum campo/enum novo: tudo reaproveita `SubscriptionStatus`/
`AccessMode` como já existem.

A partir daí, três caminhos reagem ao `AccessMode` resultante:
1. **Login** (`resolveLoginAccessMode`): dono de conta bloqueado (`NO_ACCESS`) não consegue mais
   logar a partir da próxima tentativa (sem invalidar sessão já ativa). Membro de equipe sem
   billing próprio só é bloqueado se **todas** as organizações dele estiverem em `NO_ACCESS` —
   continua logando se pertencer a pelo menos uma organização saudável.
2. **Assistente de IA** (`AssistantAccessGuard.checkRead`): nega leitura (não só escrita) quando a
   organização não está em `FULL_ACCESS` — antes só negava em `NO_ACCESS`.
3. **Notificações operacionais** (5 serviços: identidade de morador, chamado de morador x2,
   boas-vindas WhatsApp, lembrete de vencimento): pulam o envio silenciosamente (log, sem erro)
   quando o `AccessMode` relevante não é `FULL_ACCESS`. Notificações de **billing** (fatura, aviso
   de bloqueio) ficam de fora do gate — continuam incondicionais de propósito.

## Camadas Impactadas
- **Backend:** `BillingSubscriptionItemService` (novos métodos `extendTrial`/`restrictAccess`),
  `AdminBillingController` (2 endpoints novos + 1 rota consertada), `SubscriptionAccessService`
  (`resolveLoginAccessMode`), `UsersService.authenticate()`/`verifyTwoFactor()`,
  `AssistantAccessGuard`, `ResidentIdentityNotificationService`,
  `ResidentTicketAdminNotificationService`, `ResidentTicketWhatsAppNotificationService`,
  `WhatsAppWelcomeMessageService`, `BusinessWhatsAppNotificationService`
- **Frontend:** `/private/admin/billing/subscriptions` (botões "Prorrogar trial"/"Cortar acesso"),
  `admin-billing.service.ts` (rota corrigida + 2 métodos novos)
- **Segurança:** login de todo o sistema, auditoria de ação administrativa, cascata
  dono→organização→"filhos" intencional
- **Integração:** nenhuma automação externa nova; reaproveita `SubscriptionAccessService` já usado
  pelo `SubscriptionAccessAspect`/`@RequiresFullAccess` (EPIC-031)

## Cenários Críticos

| Cenário                                                                                 | Tipo                         | Cobertura Atual                                                                                             |
|-----------------------------------------------------------------------------------------|------------------------------|-------------------------------------------------------------------------------------------------------------|
| Prorrogar trial reflete em `/me/access-context` imediatamente                           | Happy path                   | Manual (MTD-010)                                                                                            |
| Cortar acesso nível "somente leitura" — usuário loga mas não escreve                    | Regra de negócio             | Manual (MTD-010)                                                                                            |
| Cortar acesso nível "bloqueio total" — usuário não loga a partir da próxima tentativa   | Regra de negócio / Segurança | Manual (MTD-010)                                                                                            |
| Motivo vazio rejeitado (front e back)                                                   | Validação                    | Manual (MTD-010)                                                                                            |
| Endpoint admin em usuário sem nenhuma assinatura → 404 (não cria do zero)               | Regra de negócio             | Manual (MTD-010)                                                                                            |
| Dono bloqueado cascateia para toda a organização (mesma `BillingSubscription`)          | Regra de negócio             | Manual (MTD-010)                                                                                            |
| Membro de equipe de organização bloqueada, sem outra organização → não loga             | Órfão / Segurança            | Automatizada (`UsersServiceLoginAccessTest`, `SubscriptionAccessServiceLoginAccessTest`) + Manual (MTD-010) |
| Membro de equipe com pelo menos uma organização saudável → continua logando             | Regra de negócio             | Automatizada + Manual (MTD-010)                                                                             |
| Login para cada valor de `SubscriptionStatus` — só `BLOCKED`/`NO_ACCESS` impede         | Regressão                    | Automatizada (`UsersServiceLoginAccessTest`, `@EnumSource`)                                                 |
| Senha incorreta nunca chega a checar `AccessMode` (mensagem genérica preservada)        | Segurança                    | Automatizada                                                                                                |
| 2FA (`verifyTwoFactor`) tem a mesma proteção de login                                   | Segurança                    | Automatizada (`UsersServiceTwoFactorAccessTest`, TASK-QA-AUTO-010) + Manual (MTD-010)                        |
| Assistente nega leitura (não só escrita) para organização fora de `FULL_ACCESS`         | Regra de negócio             | Automatizada (`AssistantAccessGuardTest`)                                                                   |
| Cada um dos 5 serviços de notificação pula envio fora de `FULL_ACCESS`, sem lançar erro | Regra de negócio             | Automatizada (teste dedicado por serviço)                                                                   |
| Notificação/e-mail de billing continua disparando incondicionalmente                    | Regressão                    | Automatizada (teste de regressão explícito por serviço)                                                     |
| Organização em `FULL_ACCESS` — nenhuma regressão de envio/login/assistente              | Regressão                    | Automatizada + Manual (MTD-010)                                                                             |

## Validação Recomendada
- **Manual:** [MTD-010](../MTD/MTD-010.md)
- **Automatizada:** já implementada junto ao código (`mvn test`, 1693 testes) — ver TASK-397/399;
  não há task de automação em backlog separada, mas o gap de 2FA abaixo pode justificar uma.

## Gaps
- ~~Nenhum teste automatizado dedicado cobre `verifyTwoFactor()` rejeitando `NO_ACCESS`~~ — fechado
  em 04/11/2026 por `UsersServiceTwoFactorAccessTest` (TASK-QA-AUTO-010).
- Sem teste de regressão explícito para o caso de um webhook/job automático da Asaas sobrescrever
  um status manual (`BLOCKED`/`CANCELED`) definido por este fluxo — risco aceito pela spec
  (Douglas confere/refaz manualmente), mas não há alarme automático se isso acontecer.
- Nenhuma invalidação de sessão/token já emitido é esperada (decisão de produto, não bug) — não
  testar como se fosse regressão.

## Status de Validação
- [ ] Prorrogar trial — nova data refletida em `/me/access-context`
- [ ] Cortar acesso "somente leitura" — login ok, escrita bloqueada
- [ ] Cortar acesso "bloqueio total" — login bloqueado na próxima tentativa
- [ ] Motivo obrigatório validado (front + back)
- [ ] Endpoint admin em usuário sem assinatura → 404
- [ ] Cascata dono → organização confirmada
- [ ] "Filho" de organização bloqueada sem outra organização → não loga
- [ ] "Filho" com organização saudável → continua logando
- [ ] 2FA tem a mesma proteção de login
- [ ] Assistente nega leitura fora de `FULL_ACCESS`
- [ ] 5 notificações operacionais puladas fora de `FULL_ACCESS`, sem erro
- [ ] Notificação de billing continua incondicional
- [ ] `FULL_ACCESS` sem nenhuma regressão de envio/login/assistente
