# EPIC-015 — Notificações via WhatsApp (Meta Cloud API)

## Status
**Concluído** (24/07/2026) — 6/6 tasks de implementação (122, 129, 130, 131, 128, 132) validadas em
staging via [TASK-QA-MAN-010](../QA/tasks/TASK-QA-MAN-010.md) (suíte de QA manual, 13 cenários) e
aprovadas por Douglas: opt-in, janela de urgência de 48h, idempotência, quota mensal, rate limit
diário, fallback automático para e-mail, horário comercial e webhook de status (handshake,
delivered/read, payload de falha 130497, rejeição de assinatura inválida/ausente).
⚠️ Pendência que **não** bloqueou o fechamento: envio real com `status=SENT` contra a Meta em
produção segue dependente da aprovação do template HSM "vencimento_manutencao_v2" — hoje qualquer
tentativa de envio real falha permanentemente (esperado, não é bug) e cai no fallback de e-mail,
que foi o próprio caminho validado pelo cenário C8 da suíte de QA.

## Objetivo
Implementar de ponta a ponta o envio de notificações via WhatsApp para eventos operacionais urgentes
(itens/manutenções vencendo em até 48h ou já vencidos), respeitando consentimento do usuário (LGPD),
limites de envio por plano/conta, política de templates do WhatsApp Business (HSM) e sem gerar custo
não controlado — além do webhook de retorno de status de entrega/leitura, já que a decisão foi ir direto
com a Meta (sem BSP intermediário cuidando dessa camada).

## Descrição

O sistema já tem a **estrutura preparada** para o canal WhatsApp, mas **sem implementação real**:

- `NotificationType.WHATSAPP` e `NotificationChannel.WHATSAPP` já existem nos enums.
- `WhatsAppNotificationProvider` já existe e já é registrado no Spring (`@Component`), mas o método
  `send()` só faz `log.info(...)` — não chama nenhuma API externa
  (`infrastructure/notification/provider/WhatsAppNotificationProvider.java`, comentário
  `// TODO: Implement Twilio or Meta WhatsApp Business API integration`).
- `NotificationOrchestratorService.dispatch()` já tem o `case WHATSAPP` no switch, mas só loga um
  warning e ignora o envio.
- `NotificationChannelResolver.resolveChannels()` **nunca** retorna `NotificationChannel.WHATSAPP` para
  nenhum `NotificationEventType` — o canal é estruturalmente inalcançável hoje.
- **Não existe campo de telefone/WhatsApp no `User`**, nem opt-in, nem qualquer mecanismo de
  preferência de notificação (nem para EMAIL/PUSH — seria o primeiro do tipo).

Ou seja: o "esqueleto" (enum, interface, provider vazio, ponto de disparo no orchestrator) existe para
não quebrar compilação/arquitetura quando o canal for ligado, mas falta **tudo que faz o canal funcionar
de fato**. Esse trabalho foi originalmente desenhado como um card único (TASK-122) e depois quebrado
neste épico em 18/07/2026, por ter crescido demais para um card só — cobre dado de usuário, integração
com provedor, orquestração/urgência/idempotência/retry/fallback, quota, e webhook de status.

---

## Decisão Técnica: Provedor (confirmada por Douglas em 18/07/2026)

### Tabela comparativa de provedores de WhatsApp Business API

> Valores e limites são de referência (variam por volume, negociação e mudam com frequência —
> **confirmar cotação atualizada com cada provedor antes de qualquer renegociação futura**, não usar
> este quadro como orçamento fechado). Foco em provedores com boa presença/documentação para o Brasil.

| Provedor                                    | Tipo                                  | Custo aproximado                                                                                                                                                                                                                     | Usabilidade / Setup                                                                                                             | Suporte BR / Documentação                                                | Observações                                                                                                                                         |
|---------------------------------------------|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| **Meta Cloud API (direto)** ✅ **Escolhido** | Oficial, sem intermediário            | Só a tarifa por conversa da Meta (Brasil ~R$0,03–0,10 conversa de utilidade/autenticação, ~R$0,80 marketing; conversas de serviço iniciadas pelo cliente são gratuitas na janela de 24h) — sem markup, mas sem SLA/suporte comercial | Setup mais técnico (Meta Business Manager, verificação de negócio, webhook próprio); requer mais trabalho de engenharia inicial | Documentação em inglês, suporte só via Meta Business Help Center (lento) | Menor custo recorrente, mas maior esforço de implementação e maior risco operacional (é você quem lida com verificação de número, qualidade, filas) |
| Twilio                                      | BSP (Business Solution Provider)      | Tarifa Meta + markup Twilio por mensagem (histórico ~US$0,005/msg) + taxa mensal do número                                                                                                                                           | SDK maduro, ótima documentação, fácil integração (Java SDK disponível)                                                          | Documentação em inglês/parcial PT, suporte pago em planos superiores     | Boa opção se o time já usa Twilio para SMS/outros canais; overhead de custo perceptível em alto volume                                              |
| 360dialog                                   | BSP oficial (parceiro Meta)           | Repasse do preço Meta sem markup por conversa + assinatura mensal fixa por número (~€39–49/mês)                                                                                                                                      | Setup simples, API REST direta, self-service                                                                                    | Documentação em inglês, comunidade ativa, sem suporte em PT dedicado     | Modelo "pass-through" — bom para volume médio/alto; sem camada de conveniência (templates, etc. você monta)                                         |
| Zenvia                                      | BSP nacional (Brasil)                 | Pacotes pré-pagos ou pay-as-you-go em R$ (~R$0,09–R$0,35 por mensagem conforme categoria) + possível mensalidade                                                                                                                     | Painel em PT-BR, API REST simples, também oferece SMS/e-mail no mesmo ecossistema                                               | Suporte em português, contrato e nota fiscal em BRL                      | Boa opção "primeira escolha" para SaaS BR pequeno/médio; preço por mensagem mais alto que 360dialog/Meta direto                                     |
| Take Blip                                   | BSP nacional, foco enterprise/chatbot | Modelo contratual, geralmente com mínimo mensal                                                                                                                                                                                      | Plataforma robusta com builder visual de chatbot (mais do que o Easy Maintenance precisa)                                       | Suporte em português, forte presença enterprise no Brasil                | Provavelmente over-engineering e caro para notificação transacional simples                                                                         |
| Gupshup                                     | BSP global, self-service              | Preço competitivo, cobrança por mensagem próxima ao custo Meta + pequena margem                                                                                                                                                      | Onboarding rápido, painel simples, API bem documentada                                                                          | Documentação em inglês, suporte via ticket                               | Boa relação custo-benefício, mas suporte/SLA mais fracos que Twilio/Infobip                                                                         |
| Infobip                                     | CPaaS global, enterprise              | Preço competitivo por volume, geralmente negociado                                                                                                                                                                                   | API robusta, mas onboarding mais burocrático para contas pequenas                                                               | Suporte 24/7 em vários idiomas (inclui PT via parceiros)                 | Provavelmente overkill para o volume inicial do Easy Maintenance                                                                                    |

### Decisão

**Meta Cloud API direta** (sem BSP intermediário) — acesso em configuração por Douglas (Meta Business
Manager / WhatsApp Business Platform). **Número remetente: `+55 31 97213-9145`** (`5531972139145` em
E.164, sem símbolos/máscara para uso na API).

Implicações da escolha direta (sem BSP), válidas para todas as tasks deste épico:
- Verificação de negócio (Meta Business Verification) e aprovação do número são responsabilidade direta
  do Easy Maintenance — sem suporte comercial de um BSP para acelerar/mediar esse processo.
- Templates HSM (mensagens de utilidade/marketing) são submetidos e aprovados diretamente no Meta
  Business Manager — pode levar de horas a poucos dias, não é configurável em runtime, precisa ser
  planejado no cronograma.
- Webhook próprio necessário para receber status de entrega/leitura e respostas (não há painel de BSP
  fazendo essa camada) — TASK-128.
- Sem markup por conversa de um BSP — custo é só a tarifa da Meta por conversa, mas sem SLA de suporte
  comercial em caso de problema com o número/conta.

---

## Regras de Negócio

- **Consentimento explícito obrigatório antes do primeiro envio** — a Meta exige opt-in verificável para
  mensagens de utilidade/marketing fora de conversa iniciada pelo usuário; enviar sem opt-in pode levar
  ao bloqueio do número business do Easy Maintenance (risco alto: afetaria todos os clientes, não só o
  usuário sem opt-in).
- **Janela de urgência de 48h** (decisão de produto, 18/07/2026): WhatsApp só dispara quando o prazo do
  evento estiver a 48h ou menos do vencimento, ou já vencido. Prazos maiores continuam cobertos só por
  e-mail/push. Motivo: controlar custo por conversa e reservar o canal de maior taxa de leitura para o
  momento de maior urgência.
- **Quota mensal por conta**: obrigatório desde a v1, não pode ficar para "fase 2" — cada mensagem tem
  custo direto do provedor (diferente de push/in-app).
- **Fallback para e-mail** em falha permanente de envio (template inválido, número inválido, erro
  `130497`/restrição de país) — nunca para falha transitória, que deve ser resolvida por retry.
- **Opt-out** precisa ser respeitado imediatamente (não enviar a próxima mensagem já em fila).
- **Horário de envio** restrito a horário comercial razoável (8h–20h, horário de Brasília).
- **Não** disparar WhatsApp para eventos puramente internos/admin (ex.: `ADMIN_INVITATION`,
  `TWO_FACTOR_RECOVERY`).

---

## Contexto Técnico

- `infrastructure/notification/dto/NotificationEvent.java` — já carrega `dueDate` (`LocalDate`) e
  `daysOffset` (int, positivo = dias até vencer, 0 = vence hoje, negativo = dias vencido). A regra de
  urgência pode ser calculada **sem lookup adicional no banco**. **Atenção**: `daysOffset` hoje só assume
  os valores fixos `{30,15,7,1,0,-7,-15,-30}` (checkpoints diários do `NotificationEventDetectionService`)
  — não existe sinal contínuo de hora. "Dentro de 48h" na prática só bate com `daysOffset` 1 ou 0;
  avaliar com Douglas se isso é aceitável para v1 ou se o detection job precisa de um checkpoint extra.
- `infrastructure/notification/service/NotificationChannelResolver.java` — hoje é um switch simples sem
  acesso a `User`; `ITEM_NEAR_DUE`/`MAINTENANCE_NEAR_DUE` → `{PUSH}`, `ITEM_OVERDUE`/`MAINTENANCE_OVERDUE`
  → `{PUSH, EMAIL}`.
- `infrastructure/notification/service/NotificationOrchestratorService.java` — `dispatch()` já isola
  falha por canal em try/catch e sempre salva notificação in-app incondicionalmente, independente do
  resultado dos outros canais — esse é o único "fallback" que existe hoje no sistema; fallback
  cross-channel (WhatsApp → e-mail) será novo, sem precedente para reaproveitar.
- `infrastructure/notification/service/BusinessEmailNotificationService.java` /
  `BusinessPushNotificationService.java` — padrão a espelhar para a nova
  `BusinessWhatsAppNotificationService`, mas com gaps que **não** devem ser copiados: nenhum dos dois
  tem opt-out/preferência de usuário, e o dedup do e-mail (`business_email_dispatches`) não tem
  constraint única real (dedup implícito, aceitável para e-mail mas não para WhatsApp, que tem custo por
  mensagem).
- `infrastructure/mail/MailerSendServiceImpl.java` — padrão de retry via Resilience4j (`@Retry` +
  `fallbackMethod`), mas retry-em-qualquer-exceção; WhatsApp precisa de retry seletivo (só falha
  transitória), o que exige configuração nova (`retry-exceptions`/`ignore-exceptions`), sem precedente
  no código atual.
- `jobs/EmailRetryJob.java` — padrão de retry em nível de linha de dispatch (polling `@Scheduled` +
  ShedLock), útil como referência se o WhatsApp precisar de reprocessamento assíncrono além do retry
  síncrono do Resilience4j.
- `webhooks/asaas/` — padrão de webhook existente, mas com uma lacuna de segurança real (nenhuma
  validação de assinatura/token do request recebido) que **não deve ser copiada** — ver TASK-128.

---

## Tasks

| ID                               | Título                                                                     | Tipo       | Prioridade |
|----------------------------------|----------------------------------------------------------------------------|------------|------------|
| [TASK-122](../tasks/TASK-122.md) | Full-Stack: dado do usuário — telefone + opt-in para WhatsApp              | FULL_STACK | 🟡 Médio   |
| [TASK-129](../tasks/TASK-129.md) | Backend: integração com WhatsApp Cloud API (Meta) — envio de template      | BACKEND    | 🟡 Médio   |
| [TASK-130](../tasks/TASK-130.md) | Backend: orquestração de urgência (48h) + idempotência + fallback e-mail   | BACKEND    | 🟡 Médio   |
| [TASK-131](../tasks/TASK-131.md) | Backend: quota mensal + rate limiting do canal WhatsApp                    | BACKEND    | 🟡 Médio   |
| [TASK-128](../tasks/TASK-128.md) | Backend: webhook de status de entrega/leitura do WhatsApp Cloud API (Meta) | BACKEND    | 🟡 Médio   |
| [TASK-132](../tasks/TASK-132.md) | Backend: endpoints de disparo manual dos jobs de notificação/WhatsApp (apoio de QA) | BACKEND    | 🟡 Médio   |
| [TASK-QA-MAN-010](../QA/tasks/TASK-QA-MAN-010.md) | QA Manual: E2E fluxo completo de notificações WhatsApp (13 cenários) | QA         | 🟠 Alto    |

Ordem de implementação sugerida: TASK-122 e TASK-129 podem começar em paralelo (não dependem uma da
outra) → TASK-130 depende de ambas (precisa do telefone/opt-in do usuário e do provider real) → TASK-131
depende da TASK-130 (precisa do `BusinessWhatsAppNotificationService` existir para plugar a checagem de
quota) → TASK-128 pode começar em paralelo com qualquer uma (o endpoint em si não depende de nada), mas
só faz sentido operacionalmente depois da TASK-130 (precisa de `wamid` real sendo gerado).

## Critério de Conclusão do Épico

- [x] Usuário consegue cadastrar telefone e dar opt-in explícito de WhatsApp na tela de perfil
- [ ] Envio real de template via Meta Cloud API funciona em ambiente sandbox — **pendente**: bloqueado
      pela aprovação do template HSM "vencimento_manutencao_v2" pela Meta, fora do controle do time de
      engenharia; classificação de falha/fallback foi validada contra o endpoint real da Meta (C3/C8 da
      TASK-QA-MAN-010), só o `status=SENT` de fato não foi observado ainda
- [x] WhatsApp só é disparado para eventos dentro de 48h do vencimento ou já vencidos — prazos maiores
      continuam só por e-mail/push
- [x] Falha permanente de envio cai automaticamente para e-mail (toggleável)
- [x] Falha transitória tem retry com backoff; falha permanente não tem retry
- [x] Reenvio do mesmo evento não duplica mensagem (idempotência real, com constraint única)
- [x] Quota mensal por conta bloqueia envio ao atingir limite do plano
- [x] Opt-out interrompe imediatamente novos envios
- [x] Webhook de status (TASK-128) recebe e persiste callbacks de entrega/leitura/falha com validação de
      assinatura real
- [x] Nenhum segredo do provedor (token/App Secret) commitado ou logado em texto puro
- [x] Testes unitários cobrindo cada task individualmente (ver critérios de aceite de cada card)

## Riscos (do épico como um todo)

- Templates HSM precisam de aprovação prévia da Meta — pode bloquear testes reais em qualquer task que
  dependa de envio de fato (TASK-129/130).
- Sem BSP intermediário: verificação de negócio, qualidade do número e recuperação de bloqueio são
  geridas diretamente com a Meta, sem suporte comercial dedicado.
- Granularidade de dia do `daysOffset` pode não capturar a janela de 48h com precisão cirúrgica (ver
  Contexto Técnico) — decisão de aceitar ou não essa limitação impacta TASK-130.
