# TASK-130 — Backend: Orquestração de urgência (48h) + idempotência + fallback para e-mail

## Tipo
BACKEND

## Categoria
Notificações / Orquestração

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — é o coração da lógica de negócio do canal (quando dispara, quanto custa, o que acontece quando
falha); erro aqui gera custo não controlado ou perda silenciosa de notificação urgente.

---

## Contexto

Levantamento do estado atual do orquestrador (`infrastructure/notification/`):

- **`NotificationEvent`** (`dto/NotificationEvent.java`) já carrega `dueDate` (`LocalDate`) e
  `daysOffset` (int: positivo = dias até vencer, 0 = vence hoje, negativo = dias vencido) — a regra de
  urgência pode ser calculada **sem lookup adicional no banco**, direto do evento.
  **Atenção**: `NotificationEventDetectionService` só produz `daysOffset` nos checkpoints fixos
  `{30,15,7,1,0,-7,-15,-30}` (dias, não horas) — não existe sinal contínuo de "horas até vencer". Na
  prática, "dentro de 48h" só vai bater com `daysOffset == 1` ou `daysOffset == 0`. Avaliar com Douglas
  se essa granularidade é aceitável para v1 ou se o detection job precisa de um checkpoint adicional
  (ex.: rodar 2x/dia) para granularidade real de hora — documentar a decisão tomada nesta task.
- **`NotificationChannelResolver`** (`service/NotificationChannelResolver.java`) é hoje um switch simples
  sem acesso a `User`:
  ```java
  case ITEM_NEAR_DUE, MAINTENANCE_NEAR_DUE -> EnumSet.of(NotificationChannel.PUSH);
  case ITEM_OVERDUE, MAINTENANCE_OVERDUE -> EnumSet.of(NotificationChannel.PUSH, NotificationChannel.EMAIL);
  ```
- **`NotificationOrchestratorService.dispatch()`** já isola falha por canal em try/catch individual e
  **sempre** salva notificação in-app, independente do resultado dos outros canais — esse save
  incondicional é o único "fallback" que existe hoje no sistema. **Fallback cross-channel (WhatsApp →
  e-mail) não existe em lugar nenhum do código** — será desenhado do zero nesta task.
- **`BusinessEmailNotificationService`/`BusinessPushNotificationService`** são o padrão a espelhar para
  a nova `BusinessWhatsAppNotificationService`, mas com gaps que **não devem ser copiados**:
  - Nenhum dos dois checa opt-out/preferência de usuário (não existe esse mecanismo hoje — WhatsApp será
    o primeiro).
  - O dedup do e-mail (`business_email_dispatches`) **não tem constraint única** — o "dedup" de hoje é
    implícito (o detection job roda uma vez por checkpoint de dia). Isso é aceitável para e-mail, mas
    **não é aceitável para WhatsApp**, que tem custo direto por mensagem — esta task precisa de
    idempotência real, com constraint única de verdade.
  - Retry de e-mail acontece em dois níveis: Resilience4j no `MailerSendServiceImpl` (nível de chamada) e
    um job de polling separado (`jobs/EmailRetryJob.java`, nível de linha de dispatch). WhatsApp usa só o
    nível de chamada (TASK-129) — esta task não precisa replicar o job de polling, a menos que se decida
    que reprocessamento assíncrono adicional é necessário.

---

## Objetivo

Fazer o WhatsApp disparar somente nos casos urgentes definidos (≤48h do vencimento ou já vencido), com
idempotência real (sem reenvio duplicado e custoso) e fallback automático para e-mail quando o envio
falha permanentemente.

---

## Escopo

### 1. Regra de urgência em `NotificationChannelResolver`

- Adicionar `NotificationChannel.WHATSAPP` ao conjunto resolvido quando:
  - o evento é `ITEM_OVERDUE`/`MAINTENANCE_OVERDUE` (já vencido), **ou**
  - o evento é `ITEM_NEAR_DUE`/`MAINTENANCE_NEAR_DUE` **e** está dentro de
    `notification.whatsapp.urgentThresholdHours` (property configurável, default `48`) — calculado a
    partir de `event.getDueDate()`/`event.getDaysOffset()` já existentes no evento, sem lookup extra.
- `NEAR_DUE` com mais de 48h de prazo continua só `PUSH` (ou `PUSH+EMAIL`, conforme a regra hoje) — **não**
  adicionar WhatsApp nesse caso.
- Tornar o limiar de 48h uma property configurável (`notification.whatsapp.urgentThresholdHours=48`),
  não uma constante hardcoded.
- Documentar no código/PR a limitação de granularidade de dia mencionada no Contexto (decisão tomada
  para v1: aceitar essa granularidade, ou ajustar o detection job — registrar o que foi decidido).

### 2. `BusinessWhatsAppNotificationService` (novo)

Mesmo nível de pacote de `BusinessEmailNotificationService`/`BusinessPushNotificationService`
(`infrastructure/notification/service/`). Método `sendWhatsapp(NotificationEvent event)`, chamado do
`Orchestrator.dispatch()` do mesmo jeito que os outros canais (substituindo o `log.warn` atual no
`case WHATSAPP`).

- **Resolução do destinatário**: telefone do `User` (campo `phoneNumber`, da TASK-122); normalizar para
  E.164 (`+55DDXXXXXXXXX`), tratando a inconsistência do 9º dígito do celular brasileiro.
- Se telefone ausente ou inválido: logar `warning` e **pular o canal sem lançar exceção** — é um caso
  esperado (usuário não cadastrou telefone/opt-in), não uma falha; o `try/catch` por canal do
  orchestrator já existe, mas queremos um skip limpo, não uma stacktrace, para este caso.
- **Opt-out**: checar `User.whatsappOptIn` (da TASK-122) antes de enviar — pular silenciosamente se
  `false`.
- **Idempotência**: nova tabela `business_whatsapp_dispatches` (entidade `BusinessWhatsAppDispatch` +
  repository, espelhando `BusinessEmailDispatch`), **com uma constraint única real** por
  `(organization_code, event_type, reference_id, due_date)` — diferente do e-mail, que não tem essa
  constraint; aqui é necessária pelo custo por mensagem. Antes de enviar, checar se já existe um envio
  bem-sucedido para essa combinação exata.
- Ao enviar com sucesso, persistir a linha imediatamente com o `wamid` retornado pela TASK-129 (status
  `SENT`) — usado depois pela TASK-128 (webhook) para atualizar o status via callback da Meta.
- **Fallback para e-mail**: se o envio falhar permanentemente (`WhatsAppPermanentException` da TASK-129,
  ou falha transitória com retries esgotados), disparar e-mail para o mesmo evento **se e-mail ainda não
  estiver no conjunto de canais já resolvido** para esse evento (evitar duplicar aviso quando o evento já
  seria coberto por e-mail de qualquer forma, ex. `OVERDUE`). Toggleável via
  `notification.whatsapp.fallbackToEmail` (default `true`).

### 3. Config

- `notification.whatsapp.urgentThresholdHours` (default `48`)
- `notification.whatsapp.fallbackToEmail` (default `true`)

### 4. Testes

- `resolveChannels` — teste parametrizado cobrindo: `NEAR_DUE` com >48h (sem WhatsApp), `NEAR_DUE` com
  ≤48h (WhatsApp incluído), `OVERDUE` (WhatsApp incluído).
- `BusinessWhatsAppNotificationService`:
  - normalização de telefone (válido, inválido, ausente);
  - skip por opt-out (`whatsappOptIn == false`);
  - skip por idempotência (evento duplicado — mesma combinação organização/tipo/referência/vencimento
    já enviada com sucesso);
  - fallback para e-mail disparado em falha permanente;
  - fallback **não** disparado quando e-mail já está no conjunto de canais resolvido para o evento;
  - comportamento de retry em falha transitória (mock do client da TASK-129).

---

## Arquivos impactados (estimativa)

### Backend
- `infrastructure/notification/service/NotificationChannelResolver.java` — regra de urgência de 48h
- `infrastructure/notification/service/NotificationOrchestratorService.java` — troca do `log.warn` pela
  chamada real a `BusinessWhatsAppNotificationService.sendWhatsapp(event)`
- `infrastructure/notification/service/BusinessWhatsAppNotificationService.java` — **novo**, espelhando
  `BusinessPushNotificationService`/`BusinessEmailNotificationService`
- `infrastructure/notification/domain/BusinessWhatsAppDispatch.java` + repository — **novo**, espelhando
  `BusinessEmailDispatch`, mas com constraint única real
- `db/migration/V8x__create_business_whatsapp_dispatches.sql` — **novo**
- `application.properties` — `notification.whatsapp.urgentThresholdHours`,
  `notification.whatsapp.fallbackToEmail`

---

## Critérios de Aceite

- [x] `resolveChannels` inclui WHATSAPP para `ITEM_NEAR_DUE`/`MAINTENANCE_NEAR_DUE` só quando ≤48h do
      vencimento (property configurável), e sempre para `ITEM_OVERDUE`/`MAINTENANCE_OVERDUE`
- [x] `NEAR_DUE` com mais de 48h de prazo nunca inclui WHATSAPP no conjunto resolvido
- [x] Telefone ausente/inválido gera skip limpo (log warning, sem exceção) — canal simplesmente não
      dispara para esse evento
- [x] Opt-out (`whatsappOptIn == false`) impede o envio
- [x] Evento duplicado (mesma organização/tipo de evento/referência/vencimento/days_offset) não gera
      reenvio
- [x] Envio bem-sucedido persiste `wamid` imediatamente com status `SENT`
- [x] Falha permanente aciona fallback para e-mail quando e-mail não estava já no conjunto de canais do
      evento
- [x] Falha do provedor WhatsApp não impede envio dos outros canais (PUSH/EMAIL) do mesmo evento
      (try/catch por canal já existe no orchestrator, preservado)
- [x] Testes unitários cobrindo resolver, normalização de telefone, opt-out, idempotência e fallback

## Dependências
- **TASK-122** — telefone e opt-in do usuário precisam existir para esta task fazer sentido
- **TASK-129** — provider real e classificação de exceção transitória/permanente
- TASK-025 (fila/retry de e-mail) — referência de padrão de dispatch/retry auditável

## Riscos
- Granularidade de dia do `daysOffset` pode não capturar a janela de 48h com precisão cirúrgica (ver
  Contexto) — decisão de aceitar essa limitação para v1 precisa ser explícita, não silenciosa.
- Dedup mal implementado (sem constraint única de verdade) gera reenvio custoso — este é o ponto onde
  o padrão do e-mail **não** deve ser copiado.
- Fallback mal configurado pode duplicar aviso (WhatsApp falhou mas e-mail já tinha sido enviado pelo
  mesmo evento) — mitigado pela checagem explícita de "e-mail já no conjunto de canais" antes de
  disparar o fallback.

## Esforço
Grande (é o núcleo da orquestração do canal — urgência, idempotência, retry, fallback)

## Status
Concluído — validado via QA manual (TASK-QA-MAN-010) em staging, aprovado por Douglas em 24/07/2026.

## Implementação

- PR aberto para `staging`: [easy-maintenance-api#21](https://github.com/douglasjava/easy-maintenance-api/pull/21).
- Branch `feature/TASK-130-whatsapp-urgency-idempotency-fallback` (a partir de `staging`).
- `NotificationChannelResolver`: regra de urgência configurável (`notification.whatsapp.urgent-threshold-hours`,
  default 48). Como `NotificationEvent.daysOffset` só existe em checkpoints fixos de dia ({30,15,7,1}
  para NEAR_DUE), o limiar em horas é arredondado para cima em dias inteiros — com o default de 48h, só
  o checkpoint `daysOffset==1` é alcançado hoje (decisão de v1 documentada no código; ajustar o detection
  job para granularidade de hora ficaria para uma task futura, fora do escopo aqui). `OVERDUE` sempre
  inclui WHATSAPP incondicionalmente.
- `BusinessWhatsAppNotificationService` (novo): mesmo esqueleto de `BusinessEmailNotificationService`
  (resolve destinatário → valida → monta payload → envia → registra dispatch), com dois comportamentos
  que o e-mail não tem, de propósito: idempotência real (find-or-update na mesma linha, não insert
  sempre) e fallback cross-channel.
- **Achado durante a implementação, não previsto originalmente no card**: a chave de dedup proposta no
  card (`organization_code, event_type, reference_id, due_date`) tem um problema — um mesmo item gera
  múltiplos checkpoints de `OVERDUE` (0/7/15/30 dias vencido) com o **mesmo** `due_date` e `event_type`,
  então essa chave trataria o 2º/3º/4º lembrete de atraso como duplicata do 1º e nunca dispararia de
  novo. Corrigido adicionando `days_offset` à chave/constraint única — cada checkpoint de atraso agora é
  um envio legítimo e independente.
- `business_whatsapp_dispatches` (migration V81): constraint única real em `(organization_code,
  event_type, reference_id, due_date, days_offset)` + índice em `wamid` (para a TASK-128 usar depois).
- Fallback para e-mail: disparado tanto em `WhatsAppPermanentException` quanto em
  `WhatsAppTransientException` — esta última só chega ao `BusinessWhatsAppNotificationService` depois
  que o Resilience4j da TASK-129 já esgotou o retry, ou seja, ambas representam falha final do ponto de
  vista da orquestração.
- `NotificationOrchestratorService`: `case WHATSAPP` agora chama `sendWhatsapp(event, channels)` — o
  conjunto de canais já resolvido é passado explicitamente para o serviço decidir se o fallback de
  e-mail duplicaria um envio já previsto.
- 22 testes novos: `NotificationChannelResolverTest` (12, parametrizado) + `BusinessWhatsAppNotificationServiceTest`
  (10 — skip por telefone/opt-out/destinatário, sucesso, idempotência, os 3 cenários de fallback e
  fallback desabilitado via property). 638/638 testes backend green.
