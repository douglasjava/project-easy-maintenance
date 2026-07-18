# TASK-122 — Full-Stack: Implementar canal de notificações via WhatsApp

## Tipo
FULL_STACK

## Categoria
Notificações / Produto / Integração Externa

## Prioridade
🟡 Médio

## Épico
EPIC-006 — Produto / Experiência do Usuário

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — canal de comunicação com o cliente final (síndico/gestor), risco de spam/custo se mal implementado.

---

## Contexto

O sistema já tem a **estrutura preparada** para o canal WhatsApp, mas **sem implementação real**:

- `NotificationType.WHATSAPP` e `NotificationChannel.WHATSAPP` já existem nos enums.
- `WhatsAppNotificationProvider` já existe e já é registrado no Spring (`@Component`), mas o método
  `send()` só faz `log.info(...)` — não chama nenhuma API externa
  (`infrastructure/notification/provider/WhatsAppNotificationProvider.java:12-15`, comentário
  `// TODO: Implement Twilio or Meta WhatsApp Business API integration`).
- `NotificationOrchestratorService.dispatch()` já tem o `case WHATSAPP` no switch, mas só loga um
  warning e ignora o envio (`infrastructure/notification/service/NotificationOrchestratorService.java:35`):
  `"[Orchestrator] Canal WHATSAPP ainda não implementado. Ignorando para evento {}"`.
- `NotificationChannelResolver.resolveChannels()` **nunca** retorna `NotificationChannel.WHATSAPP` para
  nenhum `NotificationEventType` — mesmo implementando o provider, nenhum evento hoje dispararia WhatsApp
  sem também alterar o resolver.
- **Não existe campo de telefone/WhatsApp no `User`** (`org_users/domain/User.java`) nem na
  `Organization`. Só existe `phone` em `BillingAccount` (dado do Asaas, para cobrança — não deve ser
  reaproveitado como canal de notificação sem opt-in explícito do usuário).

Ou seja: o "esqueleto" (enum, interface, provider vazio, ponto de disparo no orchestrator) existe para
não quebrar compilação/arquitetura quando o canal for ligado, mas falta **tudo que faz o canal funcionar
de fato**: integração com provedor real, dado de telefone do usuário, consentimento, templates aprovados,
regra de limite/quota e testes.

---

## Objetivo

Implementar de ponta a ponta o envio de notificações via WhatsApp para eventos operacionais
(itens/manutenções próximas do vencimento ou vencidas — os mesmos eventos hoje cobertos por
PUSH/EMAIL) e, opcionalmente, para comunicações críticas (ex.: PIX vencido), respeitando:
consentimento do usuário (LGPD), limites de envio por plano/conta, política de templates do
WhatsApp Business (HSM) e sem gerar custo não controlado.

---

## Escopo

### 1. Backend — Dado do usuário (pré-requisito)

- Migration Flyway: adicionar `phone_number` (E.164, ex.: `+5531999999999`) e `whatsapp_opt_in`
  (boolean, default `false`) em `users`.
- Endpoint para o usuário cadastrar/editar o telefone e opt-in (`PATCH /me` ou endpoint dedicado
  `PATCH /me/notification-preferences`), com validação de formato E.164.
- **Consentimento explícito obrigatório antes do primeiro envio** — WhatsApp Business Platform (Meta)
  exige opt-in verificável para mensagens de marketing/utilidade fora de conversa iniciada pelo usuário;
  enviar sem opt-in pode levar ao bloqueio do número da conta business do Easy Maintenance.
- Fluxo de verificação do número (opcional na v1, recomendado na v2): envio de código via WhatsApp para
  confirmar que o número pertence ao usuário antes de marcar `whatsapp_opt_in = true`.

### 2. Backend — Integração com provedor

- Escolher provedor (ver tabela comparativa abaixo — decisão a ser tomada com Douglas antes do início
  da implementação).
- Implementar `WhatsAppNotificationProvider.send()` de fato: chamada HTTP ao provedor escolhido,
  usando **templates pré-aprovados (HSM)** — WhatsApp não permite texto livre para mensagens
  business-initiated fora da janela de 24h de uma conversa iniciada pelo cliente.
- Configuração via `application.yml`/variáveis de ambiente (token, número remetente, IDs de template),
  seguindo o mesmo padrão de segredos já usado para MailerSend/Asaas (nunca hardcoded, nunca comitado —
  ver TASK-010).
- Tratamento de erro/circuit breaker seguindo o padrão já usado em `MailerSendServiceImpl` (Resilience4j
  `@Retry`, TASK-025/TASK-008) — falha do provedor não pode derrubar o restante do `dispatch()` (o
  `try/catch` por canal já existe no orchestrator, então isso já está parcialmente coberto, mas o
  provider deve logar contexto suficiente para reprocessamento).
- Idempotência: evitar reenvio duplicado do mesmo evento (mesmo padrão de rastreamento usado em
  `business_email_dispatches` — considerar tabela irmã `business_whatsapp_dispatches` para
  auditoria/retry, reaproveitando `NotificationEventType`).

### 3. Backend — Onde disparar

- `NotificationChannelResolver.resolveChannels()`: adicionar `NotificationChannel.WHATSAPP` para os
  eventos operacionais já existentes, **condicionado a `user.whatsappOptIn == true`** (o resolver hoje
  não tem acesso ao usuário — precisa evoluir a assinatura ou mover a checagem de opt-in para dentro do
  `WhatsAppNotificationProvider`/`BusinessWhatsAppNotificationService` antes de chamar a API externa):
  - `ITEM_NEAR_DUE`, `MAINTENANCE_NEAR_DUE` — aviso preventivo (o WhatsApp é o canal com maior taxa de
    leitura, faz sentido priorizar aqui).
  - `ITEM_OVERDUE`, `MAINTENANCE_OVERDUE` — aviso de atraso.
- Avaliar (decisão de produto, não obrigatório na v1): estender também para eventos críticos hoje
  restritos a e-mail via `CriticalEmailDispatchService` (`PAYMENT_PIX_OVERDUE`, `TRIAL_EXPIRING`) — canal
  com maior conversão para cobrança/reengajamento, mas exige templates de "utility"/"marketing"
  aprovados separadamente pela Meta e tem custo por conversa mais alto.
- **Não** disparar WhatsApp para eventos puramente internos/admin (ex.: `ADMIN_INVITATION`,
  `TWO_FACTOR_RECOVERY`) — canal errado para esse tipo de comunicação.

### 4. Backend — Regras de limite (obrigatório)

- **Limite por plano/conta**: seguir o mesmo padrão de `BusinessEmailQuotaService` — criar
  `BusinessWhatsAppQuotaService` com quota mensal por conta (ex.: N mensagens/mês por plano), já que
  cada mensagem tem custo direto do provedor (diferente de push/in-app, que são de custo ~zero).
  Sem isso, uma conta com muitos itens vencidos pode gerar um volume de disparo não controlado e
  custo inesperado.
- **Rate limiting por usuário/telefone**: evitar disparar múltiplas mensagens para o mesmo número em
  uma janela curta (ex.: agrupar/deduplicar eventos do mesmo dia por usuário antes de despachar —
  hoje o `dispatch()` é chamado por evento individual, então itens/manutenções vencendo no mesmo dia
  para o mesmo usuário podem gerar N mensagens separadas; avaliar agregação em uma única mensagem
  "resumo do dia").
- **Limites do próprio provedor/Meta**: respeitar os tiers de mensagens business-initiated por dia
  (250/1K/10K/100K, escalando por reputação de qualidade do número) — monitorar taxa de bloqueio/opt-out
  para não perder tier.
- **Horário de envio**: não disparar fora de horário comercial razoável (ex.: 8h-20h, horário de
  Brasília) — LGPD/boas práticas de comunicação, evitar mensagens à noite/madrugada.
- **Opt-out**: usuário precisa conseguir desativar o canal a qualquer momento (reaproveitar o mesmo
  endpoint de preferências do item 1); respeitar imediatamente (não enviar a próxima mensagem já em
  fila para esse usuário).

### 5. Frontend

- Tela de perfil/configurações do usuário: campo de telefone (com máscara BR) + toggle "Receber
  notificações por WhatsApp" (opt-in), com texto claro de consentimento (LGPD) explicando o que será
  enviado.
- Se houver fluxo de verificação de número (item 1): UI de "Enviamos um código, digite para confirmar".
- Estado de loading/erro/sucesso ao salvar preferência, seguindo os padrões já usados em
  `users/[id]/edit` (TASK-102).

### 6. QA / Testes

- Testes unitários: `WhatsAppNotificationProvider` (mock do client HTTP do provedor), quota service
  (bloqueio ao atingir limite mensal, reset no novo ciclo), resolver (WHATSAPP só quando opt-in true).
- Teste manual E2E: opt-in → item entra em `NEAR_DUE` → mensagem chega no WhatsApp real (ambiente de
  sandbox do provedor) → opt-out → evento seguinte não dispara.
- Verificar que falha do provedor (ex.: token inválido, número não verificado) não derruba envio de
  PUSH/EMAIL do mesmo evento (o `try/catch` por canal do orchestrator já garante isso — só validar).

---

## Tabela comparativa de provedores de WhatsApp Business API

> Valores e limites são de referência (variam por volume, negociação e mudam com frequência —
> **confirmar cotação atualizada com cada provedor antes da decisão final**, não usar este quadro como
> orçamento fechado). Foco em provedores com boa presença/documentação para o Brasil.

| Provedor | Tipo | Custo aproximado | Usabilidade / Setup | Suporte BR / Documentação | Observações |
|---|---|---|---|---|---|
| **Meta Cloud API (direto)** | Oficial, sem intermediário | Só a tarifa por conversa da Meta (Brasil ~R$0,03–0,10 conversa de utilidade/autenticação, ~R$0,80 marketing; conversas de serviço iniciadas pelo cliente são gratuitas na janela de 24h) — sem markup, mas sem SLA/suporte comercial | Setup mais técnico (Meta Business Manager, verificação de negócio, webhook próprio); requer mais trabalho de engenharia inicial | Documentação em inglês, suporte só via Meta Business Help Center (lento) | Menor custo recorrente, mas maior esforço de implementação e maior risco operacional (é você quem lida com verificação de número, qualidade, filas) |
| **Twilio** | BSP (Business Solution Provider) | Tarifa Meta + markup Twilio por mensagem (histórico ~US$0,005/msg) + taxa mensal do número | SDK maduro, ótima documentação, fácil integração (Java SDK disponível) | Documentação em inglês/parcial PT, suporte pago em planos superiores | Boa opção se o time já usa Twilio para SMS/outros canais; overhead de custo perceptível em alto volume |
| **360dialog** | BSP oficial (parceiro Meta) | Repasse do preço Meta sem markup por conversa + assinatura mensal fixa por número (~€39–49/mês) | Setup simples, API REST direta, self-service | Documentação em inglês, comunidade ativa, sem suporte em PT dedicado | Modelo "pass-through" atrai por não ter markup por mensagem — bom para volume médio/alto; sem camada de conveniência (templates, etc. você monta) |
| **Zenvia** | BSP nacional (Brasil) | Pacotes pré-pagos ou pay-as-you-go em R$ (~R$0,09–R$0,35 por mensagem conforme categoria) + possível mensalidade de plataforma | Painel em PT-BR, API REST simples, também oferece SMS/e-mail no mesmo ecossistema | Suporte em português, contrato e nota fiscal em BRL — reduz fricção jurídica/fiscal | Boa opção "primeira escolha" para SaaS brasileiro pequeno/médio; preço por mensagem tende a ser mais alto que 360dialog/Meta direto |
| **Take Blip** | BSP nacional (Brasil), foco enterprise/chatbot | Modelo contratual, geralmente com mínimo mensal — normalmente não é self-service | Plataforma robusta com builder visual de chatbot (mais do que o Easy Maintenance precisa nesta fase) | Suporte em português, forte presença enterprise no Brasil | Provavelmente over-engineering e caro para o caso de uso (notificação transacional simples), mas vale considerar se o produto evoluir para IA/chatbot no WhatsApp |
| **Gupshup** | BSP global, self-service | Preço competitivo, cobrança por mensagem próxima ao custo Meta + pequena margem | Onboarding rápido, painel simples, API bem documentada | Documentação em inglês, suporte via ticket | Boa relação custo-benefício para começar rápido, mas suporte/SLA mais fracos que Twilio/Infobip |
| **Infobip** | CPaaS global, enterprise | Preço competitivo por volume, geralmente negociado; sem self-service simples para volumes baixos | API robusta, mas onboarding mais burocrático para contas pequenas | Suporte 24/7 em vários idiomas (inclui PT via parceiros) | Mais adequado quando o volume já justificar SLA enterprise — provavelmente overkill para o volume inicial do Easy Maintenance |

### Recomendação preliminar (para validar com Douglas na fase de execução)
Para o volume inicial (poucas centenas/milhares de mensagens/mês, SaaS ainda em crescimento):
**Zenvia** (suporte em PT-BR, nota fiscal BRL, menor fricção operacional/jurídica) ou **360dialog**
(menor custo recorrente se o time tiver mais tolerância a fazer a integração "na unha"). Evitar Take
Blip/Infobip nesta fase (custo/complexidade acima da necessidade atual). Meta direto só se o volume
crescer muito e o custo de markup dos BSPs passar a doer.

---

## Arquivos impactados (estimativa)

### Backend
- `infrastructure/notification/provider/WhatsAppNotificationProvider.java` — implementação real
- `infrastructure/notification/service/NotificationOrchestratorService.java` — remover o `log.warn` de
  "não implementado", checar opt-in antes de despachar
- `infrastructure/notification/service/NotificationChannelResolver.java` — incluir WHATSAPP nos eventos
  aplicáveis
- `infrastructure/notification/service/BusinessWhatsAppNotificationService.java` — **novo**, espelhando
  `BusinessPushNotificationService`/`BusinessEmailNotificationService`
- `infrastructure/notification/service/BusinessWhatsAppQuotaService.java` — **novo**, espelhando
  `BusinessEmailQuotaService`
- `infrastructure/notification/domain/BusinessWhatsAppDispatch.java` + repository — **novo**, espelhando
  `BusinessEmailDispatch`
- `org_users/domain/User.java` — campos `phoneNumber`, `whatsappOptIn`
- `org_users/application/service/UsersService.java` (ou serviço de perfil) — endpoint de preferências
- `db/migration/V8x__add_whatsapp_fields_to_users.sql` — **novo**
- `db/migration/V8x__create_business_whatsapp_dispatches.sql` — **novo**

### Frontend
- Tela de perfil/configurações do usuário — campo telefone + toggle opt-in

---

## Critérios de Aceite

- [ ] Usuário consegue cadastrar telefone e dar opt-in explícito de WhatsApp na tela de perfil
- [ ] `WhatsAppNotificationProvider.send()` envia mensagem real via provedor escolhido (não apenas loga)
- [ ] `NotificationChannelResolver` inclui WHATSAPP para `ITEM_NEAR_DUE`/`ITEM_OVERDUE`/
      `MAINTENANCE_NEAR_DUE`/`MAINTENANCE_OVERDUE`, mas **só dispara se o usuário tiver opt-in ativo**
- [ ] Quota mensal por conta aplicada e testada (bloqueia envio ao atingir limite do plano)
- [ ] Opt-out interrompe imediatamente novos envios para o usuário
- [ ] Falha do provedor WhatsApp não impede envio dos outros canais (PUSH/EMAIL) do mesmo evento
- [ ] Nenhum segredo do provedor (token/API key) commitado no repositório
- [ ] Testes unitários cobrindo provider, quota e resolver
- [ ] Teste manual E2E com número real em ambiente sandbox do provedor escolhido

## Dependências
- Decisão do provedor (tabela acima) — **bloqueante**, precisa ser validada com Douglas antes do início
- TASK-010 (auditoria/rotação de segredos) — padrão a seguir para credenciais do provedor
- TASK-025 (fila/retry de e-mail) — padrão de referência para dispatch/retry auditável

## Riscos
- Envio sem opt-in verificável pode levar ao bloqueio do número business pela Meta (risco alto —
  perderia o canal para todos os clientes, não só o usuário afetado)
- Custo por mensagem não controlado se a quota por plano não for implementada junto (não deixar para
  "fase 2")
- Templates HSM precisam de aprovação prévia da Meta (pode levar de horas a poucos dias) — não é
  configurável em runtime, precisa ser planejado no cronograma de implementação

## Esforço
Grande (integração externa + migration + quota + frontend + testes) — estimar em sprint dedicado após
decisão do provedor

## Status
Backlog
