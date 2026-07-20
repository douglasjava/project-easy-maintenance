# TASK-131 — Backend: Quota mensal e rate limiting do canal WhatsApp

## Tipo
BACKEND

## Categoria
Notificações / Custo e Confiabilidade

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — sem essa camada, uma conta com muitos itens vencidos pode gerar volume de disparo e custo não
controlado (cada mensagem WhatsApp tem custo direto do provedor).

---

## Contexto

`BusinessEmailQuotaService` já existe (`infrastructure/notification/service/BusinessEmailQuotaService.java`)
como padrão de quota mensal por conta para e-mail, com `countSentInMonth` via
`BusinessEmailDispatchRepository`. Esta task espelha esse padrão para WhatsApp, usando a tabela
`business_whatsapp_dispatches` criada na TASK-130.

Depende da TASK-130 estar implementada (ou em paralelo avançado) — a checagem de quota precisa ser
plugada dentro de `BusinessWhatsAppNotificationService.sendWhatsapp()`, antes de chamar o provider
(TASK-129).

---

## Objetivo

Garantir que o volume de mensagens WhatsApp por conta/mês respeite o limite do plano, que não haja
disparo excessivo para o mesmo usuário no mesmo dia, e que os limites da própria Meta (tiers de
mensagens business-initiated) sejam respeitados.

---

## Escopo

### 1. Quota mensal por conta

- Nova `BusinessWhatsAppQuotaService`, espelhando `BusinessEmailQuotaService`: quota mensal por conta
  (N mensagens/mês por plano), consultando `business_whatsapp_dispatches` (TASK-130).
- Bloquear envio ao atingir o limite do plano — logar e pular o canal (mesmo padrão de skip limpo da
  TASK-130), sem impedir os outros canais do evento.

### 2. Rate limiting por usuário/telefone

- Evitar disparar múltiplas mensagens para o mesmo número em uma janela curta. Hoje o `dispatch()` é
  chamado por evento individual — itens/manutenções vencendo no mesmo dia para o mesmo usuário podem
  gerar N mensagens separadas.
- Avaliar agregação em uma única mensagem "resumo do dia" por usuário (decisão de produto — documentar
  o que foi decidido nesta task antes de implementar).

### 3. Limites do provedor (Meta)

- Respeitar os tiers de mensagens business-initiated por dia (250/1K/10K/100K, escalando por reputação
  de qualidade do número).
- Monitorar taxa de bloqueio/opt-out para não perder tier (ex.: métrica/alerta simples, aproveitando o
  padrão de `businessMetricsService` já usado em `MailerSendServiceImpl`).

### 4. Horário de envio

- Não disparar fora de horário comercial razoável (8h–20h, horário de Brasília) — LGPD/boas práticas;
  evitar mensagens à noite/madrugada. Eventos gerados fora dessa janela devem ser enfileirados/adiados
  para o próximo horário permitido, não descartados.

### 5. Opt-out (enforcement no momento do envio)

- O endpoint de preferências já existe (TASK-122); esta task garante que o opt-out seja respeitado
  **imediatamente** — não enviar a próxima mensagem já em fila para esse usuário assim que o opt-out for
  registrado.

### 6. Testes

- `BusinessWhatsAppQuotaService`: bloqueio ao atingir limite mensal, reset no novo ciclo.
- Rate limiting: múltiplos eventos no mesmo dia para o mesmo usuário não geram N mensagens separadas
  (conforme decisão tomada no item 2).
- Horário de envio: evento gerado fora da janela permitida não dispara imediatamente.

---

## Arquivos impactados (estimativa)

### Backend
- `infrastructure/notification/service/BusinessWhatsAppQuotaService.java` — **novo**, espelhando
  `BusinessEmailQuotaService`
- `infrastructure/notification/service/BusinessWhatsAppNotificationService.java` — alterar (plugar
  checagem de quota/rate limit/horário antes do envio, da TASK-130)

---

## Critérios de Aceite

- [x] Quota mensal por conta aplicada e testada (bloqueia envio ao atingir limite do plano, reseta no
      novo ciclo — reseta naturalmente porque a contagem é sempre `>= início do mês corrente`)
- [x] Múltiplos eventos urgentes no mesmo dia para o mesmo usuário não geram N mensagens separadas
      além de um cap configurável (rate limit simples — decisão tomada com Douglas: agregação real em
      "resumo do dia" ficou fora do escopo, exigiria template HSM novo aprovado na Meta)
- [x] Envio fora do horário comercial (8h–20h Brasília) é adiado, não descartado (`PENDING_HOURS_WINDOW`
      + `WhatsAppDeferredSendJob`)
- [x] Opt-out interrompe imediatamente novos envios para o usuário, inclusive os já enfileirados
      (`attemptSend` revalida opt-in a cada chamada, inclusive no flush do job)
- [x] Testes unitários cobrindo quota, rate limiting e horário de envio

## Dependências
- **TASK-130** — `BusinessWhatsAppNotificationService` e tabela `business_whatsapp_dispatches` precisam
  existir para a quota/rate limit serem plugados
- **TASK-122** — endpoint de opt-in/opt-out já precisa existir

## Riscos
- Custo por mensagem não controlado se a quota não for implementada junto com o restante do canal — não
  pode ficar para depois do lançamento do canal.
- Perder tier de mensagens da Meta por taxa de bloqueio/opt-out alta reduz o volume diário permitido
  para toda a conta business, afetando todos os clientes.

## Esforço
Médio (quota + rate limiting + testes, reaproveitando bastante o padrão de `BusinessEmailQuotaService`)

## Status
Em Validação

## Implementação

- PR aberto para `staging`: [easy-maintenance-api#22](https://github.com/douglasjava/easy-maintenance-api/pull/22).
- Branch `feature/TASK-131-whatsapp-quota-rate-limit-schedule` (a partir de `staging`).
- **Duas decisões de produto confirmadas com Douglas antes de implementar** (o card já sinalizava que
  precisavam ser tomadas):
  - **Rate limiting**: cap simples configurável (`notification.whatsapp.daily-limit-per-recipient`,
    default 3/dia por telefone) em vez de agregação real em "resumo do dia" — esta última exigiria um
    novo template HSM aprovado na Meta especificamente para múltiplos itens, dependência externa que não
    temos hoje.
  - **Horário de envio**: implementado o mecanismo completo de fila/adiamento (não uma versão reduzida)
    — necessário porque a detecção roda às 5h (fora da janela de 8h–20h), então **toda** mensagem seria
    adiada sem esse mecanismo.
- `BusinessWhatsAppQuotaService` (novo): espelha `BusinessEmailQuotaService`, usando novo
  `whatsappMonthlyLimit` em `BillingPlanFeatures` (default 30 — mais conservador que o de e-mail, dado o
  custo direto por mensagem).
- **Mecanismo de horário de envio** (maior que o esforço estimado no card, que previa só "reaproveitar o
  padrão de quota"): novo status `PENDING_HOURS_WINDOW` + `WhatsAppDeferredSendJob` (mesmo padrão do
  `EmailRetryJob` — ShedLock, `TenantContext.setSystemContext()`, roda a cada 15min). `attemptSend()` foi
  extraído do fluxo de envio para ser reutilizado tanto no caminho imediato quanto pelo job, e revalida
  opt-in/quota/rate-limit "a quente" a cada chamada — satisfaz literalmente "opt-out interrompe
  imediatamente, inclusive os já enfileirados".
- `BusinessWhatsAppDispatch` ganhou `reference_label` (nome do item — o job precisa reconstruir o
  payload do template sem o `NotificationEvent` original, que não é persistido em lugar nenhum) e
  `email_already_covered` (calculado uma vez na criação, a partir do conjunto de canais resolvido —
  necessário porque o job processa o dispatch depois, sem acesso a esse conjunto original). Migration V82.
- `Clock` injetado (novo bean em `WhatsAppConfig`) em vez de `Clock.systemDefaultZone()` direto — único
  jeito de testar a checagem de horário comercial de forma determinística, sem depender do horário real
  de quando o teste roda.
- 25 testes novos/atualizados: `BusinessWhatsAppNotificationServiceTest` ganhou 9 casos (quota,
  rate limit, defer fora de horário, `isWithinBusinessHours` com Clock controlado, re-checagem de
  opt-in no flush, envio bem-sucedido via `attemptSend`), `BusinessWhatsAppQuotaServiceTest` (4),
  `WhatsAppDeferredSendJobTest` (4). 653/653 testes backend green.
