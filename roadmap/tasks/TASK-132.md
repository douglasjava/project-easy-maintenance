# TASK-132 — Backend: endpoints de disparo manual dos jobs de notificação/WhatsApp (apoio de QA)

## Tipo
BACKEND

## Categoria
Notificações / QA / Ferramental Interno

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Não (ferramental interno, sem UI e sem alterar comportamento de produção) — mas é o que viabiliza
a execução da [TASK-QA-MAN-010](../QA/tasks/TASK-QA-MAN-010.md).

---

## Contexto

Douglas pediu um jeito de validar o EPIC-015 ponta a ponta (opt-in → detecção de urgência →
envio → quota/rate-limit/horário → webhook de status) sem depender de esperar o cron das 5h
(`NotificationEventDetectionJob`) ou a janela de 15min/horário comercial do
`WhatsAppDeferredSendJob`. Levantamento prévio (ver EPIC-015) mostrou que:

- Já existe o padrão `dev/SimulationController` (`@Profile({"dev","staging","debug"})`) para
  simular fluxos inteiros sem depender do provedor externo (Asaas) — usado por afiliados e billing.
- Já existe o padrão `jobs/infrastucture/web/JobController` (`GET /run-jobs/...`, sem `@Profile`,
  mesmo padrão do `execute-trial-expiration` já em produção) para disparar jobs agendados sob
  demanda.
- **Nenhum dos dois padrões cobria os jobs do EPIC-015** — `NotificationEventDetectionJob` e
  `WhatsAppDeferredSendJob` só rodavam via `@Scheduled`, sem endpoint manual.
- Para o webhook (TASK-128) especificamente, **não foi criado nenhum endpoint de simulação** — a
  decisão foi usar o endpoint real (`POST /public/webhooks/whatsapp`) com assinatura HMAC
  calculada de verdade pelo QA (ver TASK-QA-MAN-010, cenários C9-C12), porque simular um bypass de
  assinatura testaria menos do que a própria TASK-128 promete garantir.

---

## Escopo

- `JobController` ganha 2 novos endpoints `GET`, seguindo exatamente o padrão de
  `execute-trial-expiration` (mesmo controller, sem `@Profile`, sujeito às mesmas regras de
  auth/tenant já existentes):
  - `GET /run-jobs/execute-notification-detection` — chama
    `NotificationEventDetectionService.detectEvents()` + `NotificationOrchestratorService.dispatch()`
    dentro de `TenantContext.setSystemContext()` (mesma sequência do
    `NotificationEventDetectionJob`, sem o wrapper de `@Scheduled`/`ShedLock`). Retorna
    `{"eventsDetected": N}`.
  - `GET /run-jobs/execute-whatsapp-deferred-send` — busca todos os
    `BusinessWhatsAppDispatch` em `PENDING_HOURS_WINDOW` e chama `attemptSend()` para cada um
    (mesma sequência do `WhatsAppDeferredSendJob`, sem o guard prévio de horário comercial — cada
    `attemptSend()` já revalida a janela internamente, então rodar fora do horário é um no-op
    seguro). Retorna `{"candidatesProcessed": N}`.
- Nenhuma rota nova para o webhook — o card de QA usa o endpoint real com assinatura calculada.
- Sem testes unitários novos: os dois endpoints são wrappers finos que delegam para serviços já
  cobertos por teste (mesmo padrão do `execute-trial-expiration`, que também não tem teste
  dedicado).

## Riscos
- Os dois endpoints novos herdam o mesmo comportamento pré-existente do `JobController`: sem
  `@Profile` (ativos também em produção) e exigem `X-Org-Id` válido no header mesmo processando
  cross-tenant por dentro (o valor é ignorado, mas precisa ser um UUID de org à qual o usuário
  autenticado pertença) — comportamento herdado do padrão existente, não uma decisão nova desta
  task; fora de escopo revisar a postura de segurança do `JobController` como um todo.
- `execute-whatsapp-deferred-send` sem o guard prévio de horário significa que, se chamado fora do
  horário comercial repetidamente, itera a lista de `PENDING_HOURS_WINDOW` sem enviar nada — custo
  desprezível (poucas linhas esperadas), aceitável para um endpoint de uso manual/QA.

---

## Arquivos impactados

### Backend
- `jobs/infrastucture/web/JobController.java` — 2 novos endpoints

---

## Critérios de Aceite

- [x] `GET /run-jobs/execute-notification-detection` roda a detecção + orquestração e retorna a
      contagem de eventos detectados
- [x] `GET /run-jobs/execute-whatsapp-deferred-send` reprocessa os dispatches em
      `PENDING_HOURS_WINDOW` e retorna quantos foram processados
- [x] Nenhuma regressão nos testes existentes (suíte completa continua verde)
- [x] Nenhum novo segredo ou dado sensível exposto pelos novos endpoints

## Dependências
- EPIC-015 completo (TASK-122/128/129/130/131) — usa os serviços que essas tasks introduziram.

## Esforço
Pequeno (2 endpoints finos, sem lógica nova)

## Status
Concluído — implementado em `feature/TASK-132-whatsapp-qa-manual-triggers`, 672/672 testes
backend green (nenhum teste novo — wrappers finos sem lógica própria). Usado com sucesso para
montar todos os 13 cenários da TASK-QA-MAN-010 em staging, aprovado por Douglas em 24/07/2026.
