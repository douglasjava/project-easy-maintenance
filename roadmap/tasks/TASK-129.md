# TASK-129 — Backend: Integração com WhatsApp Cloud API (Meta) — envio de template

## Tipo
BACKEND

## Categoria
Integração Externa / Notificações

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — custo direto por mensagem, segredos de provedor (token/App Secret), e comportamento de retry
incorreto pode gerar reenvio custoso ou mascarar falha real.

---

## Contexto

`WhatsAppNotificationProvider` (`infrastructure/notification/provider/WhatsAppNotificationProvider.java`)
já existe como stub, registrado no Spring (`@Component`), implementando `NotificationProvider`. O método
`send()` só faz `log.info(...)` — não chama nenhuma API externa (comentário
`// TODO: Implement Twilio or Meta WhatsApp Business API integration`). Esta task implementa o `send()`
de verdade.

Decisão de provedor já tomada em [EPIC-015](../epics/EPIC-015.md): **Meta Cloud API direta**, sem BSP,
número remetente `+55 31 97213-9145`.

### Padrão de retry existente (não copiar sem ajuste)

`infrastructure/mail/MailerSendServiceImpl.java` usa Resilience4j `@Retry` (instância `mailersend`, 3
tentativas, backoff exponencial 2s→4s→8s) com `fallbackMethod`, mas **sem `retry-exceptions`/
`ignore-exceptions` configurados** — o Resilience4j do MailerSend hoje faz retry em **qualquer**
exceção. Isso não serve para o WhatsApp: o requisito de negócio aqui é retry só em falha transitória
(5xx, timeout, erro de conexão) e **nunca** em falha permanente (template inválido, número inválido,
erro `130497` — restrição de país, já visto em teste real). Não existe precedente de retry seletivo no
código atual — esta task precisa desenhar isso do zero (ver Escopo item 2).

---

## Objetivo

Implementar o envio real de mensagens via template WhatsApp Business (HSM) usando a Graph API da Meta,
com classificação de falhas que permita retry seletivo (só transitórias) na TASK-130/orquestração.

---

## Escopo

### 1. Envio real via Graph API

- `WhatsAppNotificationProvider.send()`: chamada HTTP `POST /{phone-number-id}/messages` à Graph API da
  Meta, usando template pré-aprovado (nome configurável via `notification.whatsapp.templateName`, ex.
  `vencimento_manutencao`, categoria utility).
- Parâmetros do template (nome do destinatário, nome do item, data de vencimento) — **confirmar a ordem
  exata dos parâmetros contra o que está registrado no WhatsApp Manager** antes de codificar a chamada;
  a Graph API não valida por nome, só por posição.
- Externalizar o nome do template como propriedade (`notification.whatsapp.templateName`) para trocar de
  template sem precisar de deploy de código.
- Retornar/expor o `wamid` (message id) da resposta da Meta em caso de sucesso — necessário para a
  TASK-130 persistir e para a TASK-128 (webhook) atualizar status depois.

### 2. Classificação de falhas (transitória vs. permanente)

- Criar duas exceções distintas (ex.: `WhatsAppTransientException` / `WhatsAppPermanentException`),
  classificando pela resposta da Meta:
  - **Transitória** (deve ter retry): HTTP 5xx, timeout, erro de conexão.
  - **Permanente** (não deve ter retry): template inválido/não aprovado, número inválido, erro `130497`
    (restrição de país), e qualquer 4xx que não seja rate-limit.
- Falha de autenticação (401 / token expirado) é um caso à parte: logar em nível `ERROR` com mensagem
  distinta e "grepável" — ex. `"WHATSAPP_TOKEN_EXPIRED"` — o token é rotacionado manualmente a cada 60
  dias, então essa falha precisa ser barulhenta, não silenciosa.

### 3. Retry seletivo (Resilience4j)

- Nova instância `resilience4j.retry.instances.whatsapp` (mesmo padrão de configuração do `mailersend`
  em `application.properties` — max-attempts, wait-duration, backoff exponencial), **mas com
  `retry-exceptions` apontando só para `WhatsAppTransientException`** (e/ou `ignore-exceptions` para
  `WhatsAppPermanentException`) — diferente do `mailersend`, que retry em qualquer exceção.
- `fallbackMethod` loga a falha final (mesmo padrão do `MailerSendServiceImpl.sendEmailFallback`) e
  propaga a exceção para a camada de orquestração (TASK-130) decidir sobre fallback para e-mail.

### 4. Config

Novas variáveis de ambiente (nunca hardcoded, nunca commitadas — mesmo padrão de segredos já usado para
MailerSend/Asaas, ver TASK-010):
- `WHATSAPP_API_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_WABA_ID`
- `notification.whatsapp.templateName`

**Nunca logar** o access token nem qualquer segredo em texto puro, inclusive em mensagens de
erro/stacktrace.

### 5. Testes

- Unitário: mock do client HTTP — resposta de sucesso retorna `wamid`; resposta 5xx/timeout lança
  `WhatsAppTransientException`; resposta de template/número inválido ou `130497` lança
  `WhatsAppPermanentException`; resposta 401 loga `ERROR` com `"WHATSAPP_TOKEN_EXPIRED"`.
- Unitário: retry do Resilience4j dispara só para `WhatsAppTransientException` (mock de 2 falhas
  transitórias seguidas de sucesso) e não dispara para `WhatsAppPermanentException` (falha imediata, sem
  retry).

---

## Arquivos impactados (estimativa)

### Backend
- `infrastructure/notification/provider/WhatsAppNotificationProvider.java` — implementação real
- `infrastructure/notification/exception/WhatsAppTransientException.java` — **novo**
- `infrastructure/notification/exception/WhatsAppPermanentException.java` — **novo**
- `application.properties` — `resilience4j.retry.instances.whatsapp.*`, novas env vars/propriedades

---

## Critérios de Aceite

- [~] Envio real de template funciona em ambiente sandbox da Meta, retornando `wamid` em caso de sucesso
      — implementado e testado contra um servidor HTTP local que reproduz o contrato da Graph API; **não
      verificado contra a Meta real** (template HSM ainda não aprovado / credenciais ainda em configuração,
      ver EPIC-015)
- [x] Falha transitória (5xx/timeout) aciona retry com backoff exponencial; falha permanente não aciona
      retry nenhum
- [x] Erro `130497` e outros erros permanentes são classificados corretamente e logados com código/
      mensagem de erro
- [x] Falha de autenticação (401/token expirado) loga `ERROR` com mensagem grepável
      `"WHATSAPP_TOKEN_EXPIRED"`
- [x] Nenhum segredo (`WHATSAPP_API_TOKEN`) aparece em log, stacktrace ou mensagem de erro (garantido por
      revisão de código — nenhum teste automatizado cobre isso, não há harness de captura de log no projeto)
- [x] Nenhum segredo do provedor commitado no repositório
- [x] Testes unitários cobrindo sucesso, falha transitória, falha permanente e falha de autenticação

## Dependências
- [EPIC-015](../epics/EPIC-015.md) — decisão de provedor e número remetente já definidos
- Template HSM aprovado na Meta antes de qualquer teste real (fora do controle do time, prazo variável
  de horas a poucos dias)
- TASK-010 (auditoria/rotação de segredos) — padrão a seguir para as credenciais do provedor

## Riscos
- Template não aprovado pela Meta bloqueia qualquer teste real end-to-end desta task.
- Classificação incorreta de um erro como transitório (quando é permanente) gera retry desnecessário e
  custo extra por conversa; classificação incorreta no sentido oposto (permanente quando é transitório)
  perde mensagens que poderiam ter sido entregues com uma nova tentativa — a lista de códigos de erro da
  Meta precisa ser mapeada com cuidado, não só os já vistos em teste (`130497`).

## Esforço
Médio (integração externa + classificação de erro + config de retry seletivo)

## Status
Em Validação

## Implementação

- PR aberto para `staging`: [easy-maintenance-api#20](https://github.com/douglasjava/easy-maintenance-api/pull/20).
- Branch `feature/TASK-129-whatsapp-cloud-api-integration` (a partir de `staging`).
- `WhatsAppClient` (novo, `infrastructure/notification/client/`): mesmo estilo do `AsaasClient` — WebClient
  próprio construído no constructor (não bean compartilhado), timeout de 10s por chamada, filtro de log
  que só registra método/URL (nunca headers/token). Retry via `@Retry(name = "whatsapp", ...)` +
  `resilience4j.retry.instances.whatsapp` em `application.properties`, com `retry-exceptions`/
  `ignore-exceptions` restringindo o retry só a `WhatsAppTransientException` — diferente do `mailersend`,
  que retry em qualquer exceção (gap documentado no card, não copiado).
- Classificação de erro: `WhatsAppTransientException` (5xx, timeout/conexão, 429 rate-limit) vs.
  `WhatsAppPermanentException` (demais 4xx, erro `130497`, erro `190`/401 — este último loga `ERROR`
  com `"WHATSAPP_TOKEN_EXPIRED"`). Ambas novas em `commons/exceptions/` (primeira distinção
  transitória/permanente do código — sem precedente para reaproveitar).
- `WhatsAppNotificationProvider.send()` implementado de verdade, delegando para
  `sendTemplateMessage(NotificationPayload)` (método público adicional, não faz parte da interface
  `NotificationProvider`) que retorna `WhatsAppSendResult(wamid)` — necessário porque a interface
  `NotificationProvider.send()` é `void`; TASK-130 deve chamar `sendTemplateMessage(...)` diretamente
  (tipo concreto, mesmo padrão de `BusinessPushNotificationService` injetando `PushNotificationProvider`
  concreto) para conseguir o `wamid`.
- **Nota importante para a TASK-130**: confirmado que `WhatsAppNotificationProvider.send()` continua
  **não sendo chamado por nenhum fluxo real** — `NotificationOrchestratorService` ainda tem o `log.warn`
  no case `WHATSAPP` (troca desse case é escopo explícito da TASK-130, não desta task).
- `WhatsAppProperties` (record, `infrastructure/notification/properties/`, mesmo estilo de
  `AsaasProperties`) + `WhatsAppConfig` (`@EnableConfigurationProperties`, mesmo estilo de
  `MailerSendConfig`/`GooglePlacesConfig`). Novas env vars: `WHATSAPP_API_TOKEN`,
  `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_WABA_ID`, `WHATSAPP_TEMPLATE_NAME` (todas com default vazio/
  valor padrão em `application.properties`, sem hardcode, sem segredo commitado).
- Ordem dos parâmetros do template fixada no provider (nome do destinatário, nome do item, data de
  vencimento) — **ainda precisa ser confirmada contra o template registrado no WhatsApp Manager** antes
  do primeiro envio real (dependência explícita do card, fora do controle desta implementação).
- 15 testes novos: `WhatsAppClientTest` (7, via `com.sun.net.httpserver.HttpServer` local — mesmo padrão
  já usado em `SupplierSearchServiceTest`, sem dependência nova), `WhatsAppRetrySemanticsTest` (3, mesmo
  estilo de `AsaasClientCircuitBreakerTest` — testa o mecanismo de retry seletivo do Resilience4j
  isoladamente, já que `new WhatsAppClient(...)` direto em teste não ativa o proxy AOP do `@Retry`),
  `WhatsAppNotificationProviderTest` (5). 616/616 testes backend green.
