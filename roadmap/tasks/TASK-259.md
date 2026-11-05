# TASK-259 — BACKEND: lotear o despacho de notificações (`NotificationOrchestratorService`)

## Tipo
BACKEND

## Categoria
Performance / Notificações

## Prioridade
🟡 Médio — sem incidente hoje (base real é pequena), mas é o job que roda todo dia às 5h e a
tendência é só piorar conforme a base de itens cresce

## Épico
Nenhum — achado de diagnóstico do [EPIC-029](../epics/EPIC-029.md) (Teste de Carga Estrutural),
correção vira task própria por decisão explícita do próprio épico ("só diagnóstico, corrigir vira
task separada, priorizada por Douglas" — mesmo padrão que já gerou a TASK-224).

## QA obrigatório
Sim — rodar de novo o script `loadtest/notification-detection.js` (EPIC-029/TASK-235) com o mesmo
volume de dados (seed da TASK-233) antes/depois da correção e comparar tempo total + contagem de
query, pra confirmar ganho real (não só teórico).

---

## Contexto

Achado #1 do relatório de teste de carga (`docs/superpowers/reports/2026-09-10-load-test-findings.md`,
10/09/2026): rodando `GET /run-jobs/execute-notification-detection` contra ~50.000 itens sintéticos
(500 organizações), a detecção encontrou **5.000 eventos** e o despacho levou **~250 segundos**
(quase 4 minutos só na etapa de despacho, ~305s no total incluindo a detecção), disparando
**17.510 queries SQL** — cerca de 3,5 queries por evento, tudo sequencial.

O job real (`NotificationEventDetectionJob`) roda via cron todo dia às 5h. Na escala testada, uma
execução do cron pode legitimamente levar minutos e competir por conexões do pool de banco com
qualquer outro tráfego que aconteça nesse horário. A base de clientes real de hoje é bem menor que
o volume sintético testado, então não há incidente agora — mas o crescimento é o motivo de ainda
assim tratar isso: no ritmo atual de itens cadastrados por organização, é questão de tempo até a
base real se aproximar da escala que já expôs o problema.

## Causa raiz (já identificada, não precisa reinvestigar)

`NotificationOrchestratorService.dispatch(List<NotificationEvent> events)`
(`infrastructure/notification/service/NotificationOrchestratorService.java:99-108`):

```java
public void dispatch(List<NotificationEvent> events) {
    ...
    events.forEach(this::dispatch);   // sequencial, evento por evento
    ...
}
```

Cada `dispatch(NotificationEvent)` individual resolve os canais em memória (sem custo) mas faz
**até 4 operações com banco por evento**, nenhuma em lote:
- `pushNotificationService.sendPush(event)` — busca token(s) do usuário
- `emailNotificationService.sendEmail(event)` — provavelmente busca dados do usuário/organização
- `whatsAppNotificationService.sendWhatsapp(event, channels)` — dedup contra despachos anteriores
- `saveInApp(event)` → `inAppNotificationService.saveForOrg(...)` — sempre roda, insere a
  notificação in-app

## Escopo

- [ ] Batch de leitura: buscar de uma vez só (não por evento) os dados que hoje são buscados
      individualmente por canal — ex. todos os push tokens dos usuários afetados pela lista inteira
      de eventos, numa única query, antes do loop de despacho.
- [ ] Batch de escrita: inserir as notificações in-app em lote (`saveAll`/insert em lote) em vez de
      uma `INSERT` por evento.
- [ ] Avaliar se os 3 canais de um mesmo evento (push/email/whatsapp) podem rodar em paralelo entre
      si, já que são independentes um do outro — sem paralelizar entre eventos diferentes ainda
      (evitar introduzir problema de concorrência novo só pra resolver este).
- [ ] Preservar o comportamento de negócio atual: cada evento ainda precisa resolver os canais
      corretos (`NotificationChannelResolver`, intocado — não tem custo de banco), e a notificação
      in-app continua sendo salva mesmo se algum canal externo falhar (try/catch já existente,
      não pode virar tudo-ou-nada).

## Critérios de Aceite

- [ ] Rodando `loadtest/notification-detection.js` (mesmo seed, mesmo volume da TASK-233) contra a
      versão corrigida, tempo total e contagem de query caem de forma mensurável — documentar os
      dois números (antes/depois) na implementação desta task
- [ ] Nenhuma mudança de comportamento observável pro usuário final (mesmos eventos gerados, mesmos
      canais escolhidos por evento, notificação in-app continua resiliente a falha de canal externo)
- [ ] `mvn test` sem regressão nos testes existentes de `NotificationOrchestratorService` e
      correlatos

## Viabilidade Técnica

Direto — a causa raiz já está isolada num único método (`dispatch(List)`), sem precisar investigar
mais nada antes de implementar. O risco real é side-effect: os serviços de canal individual
(`BusinessPushNotificationService`, `BusinessEmailNotificationService`,
`BusinessWhatsAppNotificationService`) precisam ganhar uma variante "em lote" ou aceitar uma lista,
o que pode exigir mexer nos três, não só no orquestrador.

## Dependências
Nenhuma técnica. Precisa do seed/script da TASK-233/235 (já existem, versionados) pra validar o
ganho de performance depois de implementado.

## Riscos
Médio — mexer no caminho de disparo de notificação é sensível (afeta push/email/whatsapp reais em
produção); qualquer regressão aqui tem efeito direto no usuário final. Testar bem os casos de
"canal falha, resto continua" antes de mergear.

## Esforço
Médio-Alto — depende de quanto os 3 serviços de canal já suportam operação em lote hoje (não
investigado ainda, é o primeiro passo da implementação).

## Status
🔴 Não iniciada — task criada a partir do achado real do EPIC-029/TASK-235, aguardando priorização.
