# Controle Administrativo de Acesso do Usuário (Prorrogar/Cortar) + Gate de Notificações por Plano

**Data:** 03/11/2026
**Status:** Rascunho — aguardando aprovação do Douglas

## Motivação

O trial é fixo em 15 dias para todo mundo e Douglas não quer mudar essa regra geral. Mas estamos em
fase de piloto, cadastrando usuários vindos de leads, e ele precisa de um poder pontual, por
usuário: prorrogar o trial de quem está sendo validado, ou cortar o acesso antes do fim pra quem
não deve continuar. Hoje nenhuma das duas coisas é possível de fato:

- A aba "Billing" da tela `/private/users/[id]` já tem campos de status/período, mas o PUT que ela
  chama (`/private/admin/billing/user/{id}/subscription`, singular) foi removido do backend no
  TASK-206 e nunca foi atualizado no front — salva e falha silenciosamente.
- Nada no sistema bloqueia login por status de usuário ou de assinatura. O único enforcement real
  hoje é o `SubscriptionAccessAspect`, que bloqueia só **escrita**, só em métodos anotados
  `@RequiresFullAccess`, baseado em `AccessMode` (`FULL_ACCESS`/`READ_ONLY`/`NO_ACCESS`) derivado de
  `SubscriptionStatus`.

Separado disso, mas no mesmo pacote: notificações proativas (e-mail, WhatsApp) e o assistente de IA
não podem interagir com quem não está com o plano ativo — isso vale também para os moradores
(`CondoPerson`) vinculados à organização de quem paga, não só para o dono da conta.

## Decisões (confirmadas por Douglas, 03/11/2026)

- **Só o Douglas opera isso**, via `/private/admin` — não é feature exposta ao `ADMIN` de uma
  organização cliente.
- **Escopo: só dono de conta (quem fez o próprio onboarding), não membro de equipe.** Achado no
  builder check: `BillingSubscriptionItem` tipo `USER` só existe pra quem onboardou a conta
  (`OnboardingService.createUser`) — um membro convidado (`Role != ADMIN`) nunca tem item próprio, e
  hoje já cai em `READ_ONLY` por padrão (nenhum item encontrado). Os 2 pilotos atuais são donos da
  própria conta, então a feature cobre só esse caso por agora; dar esse poder sobre um membro de
  equipe exigiria criar um item de assinatura que não existe — fora de escopo.
- **Cortar/prorrogar o dono afeta a conta inteira, de propósito.** O item `USER` do dono e o item
  `ORGANIZATION` da empresa dele apontam para a **mesma** `BillingSubscription` (criados juntos no
  onboarding) — então a ação não é "só o login dele", é a assinatura inteira: perdendo ela, perde
  todos os benefícios (acesso do dono, acesso da organização, assistente, notificações). Confirmado
  por Douglas — é o comportamento esperado, não um efeito colateral a evitar.
- **Bloqueio de login vale a partir do próximo login, não precisa ser imediato.** Um JWT já emitido
  continua válido até expirar naturalmente — sem invalidação de token/sessão nesta entrega (fora de
  escopo; com só 2 usuários de piloto e TTL de poucos dias, não compensa a complexidade agora).
- **Sem campo novo.** Reaproveita `SubscriptionStatus` como já existe hoje. Douglas aceita
  conscientemente o risco de um webhook antigo da Asaas, ou um job automático, reverter/sobrescrever
  esse status manual depois — ele confere no admin e refaz a ação se isso acontecer. Prioridade é
  simplicidade sobre robustez aqui.
- **Notificações de billing (fatura vencida, aviso de bloqueio) continuam disparando** mesmo com o
  plano "desativado" — são justamente o canal que avisa a pessoa disso. O gate novo é só para
  notificações **operacionais** (lembrete de manutenção, chamado de morador, boas-vindas do
  assistente) e para o **chat do assistente** em si.

## Desenho

### 1. Dois níveis de "cortar acesso", reaproveitando status que já existem

| Nível | `SubscriptionStatus` usado | O que já acontece hoje (via `mapToAccessMode`) | O que falta |
|---|---|---|---|
| Somente leitura | `CANCELED` | Já mapeia para `READ_ONLY` — usuário loga, vê tudo, não escreve (gate em `@RequiresFullAccess`) | Nada no gate de escrita; só a ação de admin pra setar isso de propósito |
| Bloqueio total (nem loga) | `BLOCKED` | Já mapeia para `NO_ACCESS`, mas isso nunca é checado no login | Checar `AccessMode` no login e rejeitar quando `NO_ACCESS` |

**Prorrogar trial**: edita `currentPeriodEnd` da subscription do usuário pra uma data futura,
mantendo (ou voltando para) `status = TRIAL`. Como `resolveEffectiveStatus()` já deriva
`TRIAL_EXPIRED` **na leitura** (não é persistido — `SubscriptionAccessService.java:75-81`), bastar
empurrar `currentPeriodEnd` pra frente já faz o usuário voltar a ter `FULL_ACCESS` automaticamente,
sem precisar tocar em mais nada.

**Reativar**: a mesma ação de prorrogar (setar `status=TRIAL` + nova `currentPeriodEnd`) serve
também pra desfazer um corte anterior — não precisa de endpoint de "restore" separado.

### 2. Fechar o gap do login (dono **e** "filhos")

`UsersService.authenticate()` (login) e `verifyTwoFactor()` passam a chamar um novo método
`resolveLoginAccessMode(User user)` depois de validar a senha. Se o modo for `NO_ACCESS`, rejeita
com uma mensagem clara ("Acesso suspenso, contate o suporte") — não a mensagem genérica de senha
errada, porque não é isso que aconteceu.

**Por que não dá pra só chamar `resolveUserAccessMode` direto** (achado ao revisar o caso dos
"filhos", 03/11/2026): essa função, quando o usuário não tem item `USER` próprio — ou seja, **todo
membro de equipe convidado pra organização do dono** —, devolve `READ_ONLY` sempre, nunca
`NO_ACCESS`, não importa o estado da assinatura. Se a checagem de login usasse só essa função
direto, bloquear o dono nunca bloquearia o login dos membros da equipe dele — ficariam órfãos: a
organização já surda (sem notificação, sem assistente) mas eles continuando a entrar e navegar numa
tela sem função.

`resolveLoginAccessMode(User user)`:
- Se o usuário tem item `USER` próprio (é dono de conta) → usa `resolveUserAccessMode` direto.
- Senão (é membro de equipe, sem billing próprio) → resolve `resolveOrganizationAccessMode(orgCode)`
  para cada organização em que o usuário está (`user.getOrganizations()`); login só é negado
  (`NO_ACCESS`) se **todas** as organizações dele estiverem em `NO_ACCESS`. (Um membro que por acaso
  também está em outra organização saudável continua conseguindo entrar — só perde o que depende da
  organização bloqueada, igual já acontece hoje em escrita.)

**Risco principal or a regredir**: isso afeta o login de **todo mundo**, não só dos 2 pilotos.
Precisa de teste de regressão explícito cobrindo cada status existente (`ACTIVE`, `TRIAL`,
`PAST_DUE`, `CANCELED`, `PENDING_PAYMENT`, `PAYMENT_FAILED`, `NONE`, `PENDING_ACTIVATION`,
`TRIAL_EXPIRED`, `MEMBER`) — confirmando que só `BLOCKED` passa a impedir login; os demais continuam
exatamente como hoje (login permitido, grau de acesso decidido depois pelo `AccessMode` em cada
ação).

### 3. UI: conserta o formulário morto e adiciona as duas ações

- Conserta a rota: hoje o front chama `PUT /private/admin/billing/user/{id}/subscription`
  (singular) e o backend não tem essa rota (removida no TASK-206). Adiciona
  `PUT /private/admin/billing/users/{userId}/subscription` no `AdminBillingController` editando
  `status`/`currentPeriodEnd` do item de assinatura tipo `USER` do usuário, e corrige
  `admin-billing.service.ts` pra chamar a rota certa (plural, consistente com as outras rotas de
  `/users/{userId}/...` do mesmo controller).
- Em cima desse PUT genérico, adiciona dois botões de atalho — mesmo padrão visual dos já existentes
  "Upgrade"/"Downgrade"/"Cancelar" em `/private/admin/billing/subscriptions` e espelhado na aba
  Billing de `/private/users/[id]`:
  - **"Prorrogar trial"** → modal simples pedindo nova data (ou +N dias), chama o PUT com
    `status=TRIAL` + a nova `currentPeriodEnd`.
  - **"Cortar acesso"** → modal com duas opções (Somente leitura / Bloquear login) + campo de
    motivo obrigatório, chama o PUT com `status=CANCELED` ou `status=BLOCKED`.
- **Auditoria**: toda chamada a esse PUT grava em `AuditService` (mesmo padrão já usado em
  `DashboardActionsService.postpone`) — ação, status anterior/novo, motivo, quem fez. É o que dá a
  Douglas a visibilidade pra "conferir no admin e refazer" se um status for sobrescrito depois por
  engano.

### 4. Gate de notificações operacionais e do assistente

**Chat do assistente** (`AssistantAccessGuard.checkRead`): hoje só nega leitura quando
`AccessMode == NO_ACCESS` (ou seja, só quando `BLOCKED`). Passa a negar também quando não é
`FULL_ACCESS` — ou seja, `READ_ONLY` (CANCELED/PAST_DUE/PENDING_*/TRIAL_EXPIRED/etc.) também bloqueia
o chat, não só escrita. Isso cobre automaticamente os moradores (`CondoPerson`) da organização,
porque o check já é no nível de `orgCode`, não por pessoa.

**Notificações proativas** (fora do billing): pontos identificados que disparam WhatsApp/e-mail e
hoje não checam `AccessMode` antes de enviar —
`ResidentIdentityNotificationService`, `ResidentTicketWhatsAppNotificationService`,
`ResidentTicketAdminNotificationService`, `WhatsAppWelcomeMessageService`,
`BusinessWhatsAppNotificationService` (lembretes de vencimento, TASK-130/131). Cada um passa a
checar `subscriptionAccessService.resolve{User,Organization}AccessMode(...) == FULL_ACCESS` antes de
disparar, pulando silenciosamente (log, sem erro) quando não for o caso — mesmo padrão de
"falha/skip não derruba o restante do fluxo" já usado em `WhatsAppWebhookService.processChange`.
**Esta lista deve ser reconferida por grep no início da implementação** (buscar todo call site de
`whatsAppClient.sendTemplate`/`sendText` e dos serviços de e-mail não-billing) — é só o ponto de
partida encontrado nesta investigação, não necessariamente exaustivo.

**Regra de qual check usar por serviço** (minha decisão, builder check 03/11/2026): como o escopo é
só dono de conta (ver acima), `resolveUserAccessMode` só se aplica a algo estritamente sobre o dono
em si (`WhatsAppWelcomeMessageService` — a boas-vindas é pro dono que acabou de onboardar). Todos os
outros quatro serviços notificam alguém **dentro de uma organização** (síndico, morador,
`CondoPerson`) — usam `resolveOrganizationAccessMode(orgCode)`. Usar o check de usuário num morador
ou membro de equipe cairia no branch de "sem item encontrado" (`READ_ONLY`) mesmo numa organização
paga e ativa, suprimindo notificação legítima silenciosamente — por isso a regra é fixa por tipo de
serviço, não decidida call site a call site.

**Fora de escopo deste gate**: `BillingNotificationService` e qualquer e-mail de cobrança/bloqueio —
esses continuam incondicionais.

## Fora de Escopo

- Mudar a regra geral de 15 dias de trial.
- Dar esse poder a `ADMIN` de organização cliente (só Douglas).
- Qualquer novo campo/enum — tudo reaproveita `SubscriptionStatus`/`AccessMode` existentes.
- Reverter automaticamente uma ação manual se um webhook/job reativar o status por conta própria —
  aceito como risco conhecido, resolvido manualmente por Douglas conferindo no admin.

## Riscos

- Checar `AccessMode` no login toca um caminho crítico (autenticação de todo usuário, não só os do
  piloto) — mitigado com teste de regressão explícito por status, rodado antes de qualquer merge.
- Endurecer `AssistantAccessGuard` pra tratar `READ_ONLY` como bloqueio também corta o assistente
  pra qualquer organização hoje em `PAST_DUE`/`CANCELED` que porventura já estivesse "funcionando" só
  por sorte de ninguém ter testado isso — comportamento pretendido, mas vale around confirmar que não
  existe cliente pagante real hoje nessa situação antes do deploy (coerente com a memória de que só
  o usuário do Douglas está realmente ativo em produção agora).

## O que fica para o builder decidir

- Nome exato dos novos endpoints/DTOs, desde que sigam o padrão REST já usado no
  `AdminBillingController`.
- Mensagem exata de erro do login bloqueado (`ProblemDetail`), desde que não reutilize a mensagem de
  "senha incorreta".
- Onde exatamente os botões "Prorrogar"/"Cortar" aparecem na UI (lista de assinaturas vs. aba
  Billing do usuário, ou os dois) — pode escolher o que for mais simples de implementar reaproveitando
  os componentes (`ConfirmModal`, `PlanChangeDialog`) já existentes.
- O que o PUT faz se o usuário-alvo ainda não tem nenhum `BillingSubscriptionItem`/
  `BillingSubscription` (ex. lead convidado que não terminou o onboarding): retornar 404 (nada pra
  editar) em vez de criar uma assinatura do zero — mantém o endpoint simples (edita o que existe, não
  provisiona). Se Douglas precisar prorrogar alguém nesse estado, isso vira uma iteração futura.
