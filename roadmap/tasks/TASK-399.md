# TASK-399 — BACKEND: gate de plano ativo no assistente de IA e nas notificações operacionais (EPIC-041)

## Tipo
BACKEND

## Categoria
Controle Administrativo de Acesso

## Prioridade
🟠 Alto

## Épico
[EPIC-041](../epics/EPIC-041.md) — Controle Administrativo de Acesso do Usuário

## QA obrigatório
Sim — confirmar que organização em `FULL_ACCESS` continua recebendo tudo normalmente (não pode
haver regressão aqui, é o caminho feliz de todo cliente); confirmar que organização fora de
`FULL_ACCESS` não recebe nenhuma das 5 notificações nem tem resposta do assistente; confirmar que
notificação de billing continua disparando incondicionalmente nos dois casos.

---

## Contexto
`AssistantAccessGuard.checkRead` hoje só nega leitura do assistente quando `AccessMode == NO_ACCESS`
(ou seja, só quando a assinatura está `BLOCKED`). Organizações em `READ_ONLY`
(`CANCELED`/`PAST_DUE`/`PENDING_*`/`TRIAL_EXPIRED`) continuam conversando normalmente com o bot —
inconsistente com a regra de negócio ("plano desativado, diferente de ativo, não conversa").

Separado disso, 5 serviços de notificação proativa disparam WhatsApp/e-mail sem checar o
`AccessMode` da organização/usuário antes de enviar: `ResidentIdentityNotificationService`,
`ResidentTicketWhatsAppNotificationService`, `ResidentTicketAdminNotificationService`,
`WhatsAppWelcomeMessageService`, `BusinessWhatsAppNotificationService` (lembretes de vencimento,
TASK-130/131). **Esta lista é o ponto de partida encontrado na investigação da spec — reconferir
por grep (`whatsAppClient.sendTemplate`/`sendText` e serviços de e-mail não-billing) no início da
implementação**, não é necessariamente exaustiva.

## Decisão de design desta task
Regra fixa por tipo de serviço (não decidida call site a call site, pra evitar inconsistência):
- `WhatsAppWelcomeMessageService` (mensagem é estritamente sobre o dono que acabou de onboardar) →
  `resolveUserAccessMode(userId)`.
- Os outros quatro (notificam síndico/morador/`CondoPerson` **dentro de uma organização**) →
  `resolveOrganizationAccessMode(orgCode)`. Usar o check de usuário aqui cairia no branch de "sem
  item encontrado" (`READ_ONLY`) mesmo numa organização paga e ativa, suprimindo notificação
  legítima silenciosamente.

Em todos os casos: pular o envio silenciosamente (log, sem lançar erro) quando o modo não for
`FULL_ACCESS` — mesmo padrão de "skip não derruba o resto do fluxo" já usado em
`WhatsAppWebhookService.processChange`.

**Fora de escopo**: `BillingNotificationService` e qualquer e-mail de cobrança/aviso de
bloqueio — esses continuam incondicionais, são o canal que avisa exatamente disso.

## Escopo
- `AssistantAccessGuard.checkRead`: nega também quando `accessMode(orgCode) != FULL_ACCESS` (não
  só `== NO_ACCESS`).
- Grep de confirmação de todos os call sites de envio de WhatsApp/e-mail não-billing.
- Adiciona o check de `AccessMode` (usuário ou organização, conforme a regra acima) nos 5 serviços
  listados, e em qualquer outro achado no grep que se encaixe no mesmo critério (notificação
  operacional, não billing).

## Critérios de Aceite
- [ ] Assistente nega leitura (não só escrita) para organização fora de `FULL_ACCESS`
- [ ] Cada um dos 5 serviços pula o envio quando o `AccessMode` relevante não é `FULL_ACCESS`
- [ ] Nenhum dos 5 lança erro ao pular — loga e segue, sem derrubar o restante do fluxo que
      disparou a notificação
- [ ] `BillingNotificationService`/e-mails de cobrança continuam disparando sempre — teste de
      regressão explícito confirmando isso
- [ ] Organização em `FULL_ACCESS` não tem nenhuma regressão de envio
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma — usa `SubscriptionAccessService`/`AssistantAccessGuard` já existentes. Independente das
outras tasks do épico, mas deve ser testada em conjunto por tocar organizações reais usadas por
elas.

## Riscos
Endurecer o assistente pra tratar `READ_ONLY` como bloqueio também corta organizações que hoje
"funcionam" nesse estado sem ter sido notado — aceitável dado que, nesta fase, só o usuário do
próprio Douglas está realmente ativo em produção, mas vale confirmar antes do deploy que não há
nenhum cliente pagante real em `READ_ONLY` que dependa do assistente hoje.

## Esforço
Médio

## Status
🟢 Implementado (03/11/2026) — branch `feature/EPIC-041-admin-access-control`
(`easy-maintenance-api`, commit `67d5e3b`). `AssistantAccessGuardTest` atualizado pro novo
comportamento (READ_ONLY também nega leitura); os 5 serviços de notificação ganharam teste
dedicado do gate. Suíte completa (1693 testes) sem regressão. Branch ainda não mergeada em
`staging`.
