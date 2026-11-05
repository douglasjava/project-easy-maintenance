# EPIC-027 — Extensão: Categoria, Protocolo e Notificação ao Morador

**Data:** 28/10/2026
**Status:** Aprovado por Douglas (brainstorm conduzido nesta data)
**Épico:** continuação do [EPIC-027](../../../roadmap/epics/EPIC-027.md) (chamados de moradores já em
produção/QA aprovado) — não é épico novo.

## Motivação

Conversa de Douglas com a síndica **Aliria Emanuela** em 28/10/2026 trouxe duas necessidades que a
v1 do EPIC-027 não cobre:

1. O chamado de morador hoje é só relato livre sem classificação — mas na prática ele serve como
   canal geral de contato morador↔síndico, não só manutenção. Faz sentido o morador já indicar se é
   sugestão, reclamação ou pedido de manutenção.
2. O morador não tem como acompanhar proativamente o chamado — só volta no link e confere o status.
   A síndica pediu um número de protocolo e, junto com ele, notificação por WhatsApp na abertura e
   na resolução.

## Decisões de escopo (brainstorm, 28/10/2026)

1. **Categoria é um enum fixo**, não configurável por organização: `SUGESTAO`, `RECLAMACAO`,
   `MANUTENCAO`. Campo obrigatório no formulário de abertura (tela 2 do fluxo público).
2. **Protocolo é sequencial por organização** (reinicia em cada condomínio, não é global nem tem
   prefixo de ano). Gerado na criação do chamado, exibido na confirmação e na listagem "Meus
   chamados".
3. **Opt-in de WhatsApp é opcional**, não bloqueia a abertura do chamado. Checkbox na tela de
   abertura ("Quero receber atualizações deste chamado pelo WhatsApp"). Sem aceite, chamado abre
   normalmente e nenhuma mensagem é enviada ao morador. **Atualizado na segunda rodada** (ver
   "Decisões abertas resolvidas" abaixo): marcar o checkbox não ativa o opt-in direto — dispara
   envio de um código de confirmação por WhatsApp, só fica ativo depois do morador confirmar esse
   código.
4. **Canal de notificação: mesma infraestrutura do EPIC-031** (WhatsApp Business Cloud API, número
   já em produção) — mas como envio **proativo/fora de sessão de conversa**, precisa de template
   (HSM) próprio, pré-aprovado pela Meta (mesmo padrão exigido pelo EPIC-023 para o template de
   fornecedor `vencimento_manutencao_v3`). **Não é o assistente conversacional do EPIC-031** — é
   outbound simples, sem resposta esperada do morador.
5. **Dois gatilhos de mensagem**: (a) na criação do chamado — confirma o número de protocolo; (b) na
   transição de status para `CONCLUIDO` no kanban interno.
6. **Mantém dentro do EPIC-027** — são tasks novas (TASK-367 em diante) no mesmo épico, não um épico
   separado.

---

## Decisões abertas resolvidas (segunda rodada, 28/10/2026, pós builder-check)

Revisão do desenho por um agente apontou 4 pontos em aberto. Dois foram resolvidos como minha
decisão de implementação (marcados abaixo); dois exigiam decisão do Douglas e foram respondidos:

- **Backfill de chamados antigos** (minha decisão): migration faz backfill retroativo nos chamados
  já existentes em produção — `category = MANUTENCAO` (era o uso de fato até agora, antes de existir
  categoria) e `protocol_number` atribuído por ordem de `created_at` dentro de cada organização.
- **Reenvio de notificação de resolução em reabertura** (minha decisão): se um chamado for reaberto
  (`CONCLUIDO` → `EM_ANDAMENTO`) e concluído de novo, a notificação de resolução é enviada de novo —
  é uma conclusão real nova. Só bloqueia duplicata da *mesma* transição (ex. clique duplo no
  drag-and-drop).
- **Número de WhatsApp compartilhado com o bot do EPIC-031** (decisão do Douglas): se o morador
  responder à mensagem de notificação, o número de origem é verificado contra a base de `User`
  antes de qualquer processamento pelo bot — **se o número não corresponder a um usuário cadastrado,
  a resposta é ignorada**. Isso evita que o assistente conversacional do EPIC-031 tente tratar o
  morador como se fosse um usuário do sistema. Precisa confirmar na implementação (TASK-368) se o
  webhook de entrada do EPIC-031 já faz essa checagem por padrão ou se precisa de uma guarda
  explícita nova.
- **Verificação do telefone do morador antes de ativar o opt-in** (decisão do Douglas): em vez de
  aceitar o opt-in direto no formulário, o fluxo exige **confirmação por código enviado via
  WhatsApp** ao telefone informado — só depois de confirmado o opt-in fica realmente ativo (e as
  notificações passam a ser enviadas). Isso adiciona uma task própria (TASK-371, ver abaixo) — não
  cabe dentro da TASK-368 original por mudar o fluxo de abertura do chamado (passa a ter um passo
  extra: criar chamado → se opt-in marcado, pedir código → confirmar código).

### Impacto no modelo de dado

`whatsapp_opt_in` (boolean) deixa de existir como campo isolado — substituído por:

| Campo novo | Tipo | Observação |
|---|---|---|
| `whatsapp_opt_in_status` | Enum: `NAO_SOLICITADO`/`PENDENTE_CONFIRMACAO`/`CONFIRMADO` | Default `NAO_SOLICITADO`. Só `CONFIRMADO` habilita envio de notificação. |
| `whatsapp_confirmation_code` | String (nullable) | Código numérico curto (ex. 6 dígitos), gerado ao solicitar opt-in |
| `whatsapp_confirmation_expires_at` | Instant (nullable) | Código expira após janela curta (ex. 10 min — a definir na implementação) |

Fluxo: morador marca o checkbox na abertura → `whatsapp_opt_in_status=PENDENTE_CONFIRMACAO`, código
gerado e enviado via WhatsApp (template simples, também sujeito a aprovação da Meta — ou, se der pra
enviar como mensagem de sessão/utility sem template dedicado, avaliar na implementação) → tela
pública mostra campo pra digitar o código → `POST
/public/resident-tickets/{id}/whatsapp-opt-in/confirm` valida código+expiração →
`whatsapp_opt_in_status=CONFIRMADO`. Se o morador não confirmar, o chamado já está aberto e
funcional, só sem notificação — mesmo princípio de "opt-in nunca bloqueia a abertura" já decidido na
primeira rodada.

Reenvio de código (se expirar ou morador pedir de novo) e rate limit desse endpoint específico
(evitar abuso de envio de código) ficam a cargo da TASK-371.

---

## Contexto técnico (levantado antes do desenho)

- Módulo `resident_tickets` já existe (`domain`/`application`/`infrastructure` próprios, migration
  `V108__create_resident_tickets.sql`). Entidade `ResidentTicket` tem hoje: `id`, `organizationId`,
  `residentName`, `residentPhone`, `residentCpf`, `description`, `photoUrl`, `status`
  (`SOLICITADO`/`EM_ANDAMENTO`/`CONCLUIDO`), `createdAt`/`updatedAt`.
- A flag `notification.whatsapp.resident-ticket-enabled=false` **já existe** em
  `application.properties` e já é lida por `ResidentTicketAdminNotificationService`, mas é só um
  ponto de extensão preparado e não implementado — o `if (whatsAppEnabled)` hoje só loga, não envia
  nada. Essa flag foi pensada originalmente para notificar os ADMINs por WhatsApp (não o morador);
  vamos reaproveitar o nome/padrão, mas o comportamento novo é notificar o **morador**, então cabe
  reavaliar o nome da flag na implementação (ex. `notification.whatsapp.resident-ticket-enabled`
  pode continuar servindo pros dois, ou separar — decisão de implementação).
- Infra de WhatsApp (`WhatsAppNotificationProvider`, `WhatsAppClient`) já existe e é usada por
  `BusinessWhatsAppNotificationService` (notificação admin↔fornecedor) e
  `WhatsAppWelcomeMessageService`. Ambos giram em torno de `User`/`UserOrganization` (destinatário
  autenticado, com opt-in já modelado em `User.whatsappOptIn`). **O morador não é um `User`** — não
  tem conta, não tem opt-in hoje. Precisa de armazenamento de opt-in próprio na entidade
  `ResidentTicket` (não reaproveita o opt-in de `User`).
- Envio de template HSM é feito via `WhatsAppNotificationProvider.sendTemplateMessage(payload)`,
  recebendo `templateName` + `templateData` (mapa de variáveis). Ver
  `BusinessWhatsAppNotificationService.buildPayload` como referência de uso.
- Precedente de idempotência: `BusinessWhatsAppDispatch` registra cada tentativa de envio
  (status/wamid) pra não duplicar mensagem em reprocessamento. O novo fluxo de morador deve seguir
  o mesmo princípio — dois gatilhos (criação/resolução), cada um idempotente por si (ex.: não
  reenviar a mensagem de criação se o endpoint for chamado de novo, não reenviar a de resolução se o
  chamado for movido para `CONCLUIDO` mais de uma vez por engano no drag-and-drop).

---

## Arquitetura

### Alterações no modelo de dado (`ResidentTicket`)

Nova migration (`V1xx__add_category_protocol_whatsapp_to_resident_tickets.sql`):

| Campo novo | Tipo | Observação |
|---|---|---|
| `category` | Enum `ResidentTicketCategory` (`SUGESTAO`/`RECLAMACAO`/`MANUTENCAO`) | Obrigatório, preenchido na criação; backfill `MANUTENCAO` nos chamados antigos |
| `protocol_number` | Integer (ou BIGINT), `NOT NULL` | Sequencial por `organization_id` — ver geração abaixo; backfill por ordem de `created_at` |
| `whatsapp_opt_in_status` / `whatsapp_confirmation_code` / `whatsapp_confirmation_expires_at` | ver seção "Decisões abertas resolvidas" acima | Substitui o campo `whatsapp_opt_in` boolean inicialmente planejado — exige confirmação por código (TASK-371) |

Constraint única `(organization_id, protocol_number)` — garante que o protocolo é único dentro da
organização mesmo sob concorrência.

**Geração do protocolo** (decisão de implementação, duas opções válidas — escolher na task):
- (a) `SELECT COALESCE(MAX(protocol_number), 0) + 1 FROM resident_tickets WHERE organization_id = ?`
  dentro da mesma transação de criação, com lock de linha (`SELECT ... FOR UPDATE`) numa linha de
  controle por organização, ou
- (b) tabela auxiliar de contador por organização (`resident_ticket_counters`), incrementada
  atomicamente.
Dado o volume esperado (chamados de condomínio, não alto throughput), (a) com lock é suficiente e
mais simples — evitar concorrência real exige teste de corrida (dois chamados simultâneos na mesma
organização não podem gerar o mesmo protocolo).

### Endpoints afetados

- `POST /public/resident-tickets` — corpo passa a exigir `category`, aceita `whatsappOptIn`
  (boolean, opcional, default `false`). Resposta passa a incluir `protocolNumber`.
- `GET /public/resident-tickets?organizationCode=X&cpf=Y` — resposta de cada chamado passa a
  incluir `category` e `protocolNumber`.
- `GET /resident-tickets` (autenticado, kanban interno) — resposta passa a incluir `category` e
  `protocolNumber` (exibição no card do kanban).
- `PATCH /resident-tickets/{id}/status` (autenticado) — ao transicionar para `CONCLUIDO`, dispara a
  notificação de resolução (se `whatsappOptIn=true` e a flag estiver ligada).

### Notificação ao morador — novo serviço

Novo serviço no módulo `resident_tickets` (não reaproveita `BusinessWhatsAppNotificationService`,
que é acoplado a `User`/quota/opt-in de negócio — morador é um destinatário sem conta, com suas
próprias regras mais simples: sem quota, sem horário comercial decidido ainda — avaliar na
implementação se cabe aplicar a mesma janela de horário comercial do canal de negócio, por ora
replicar por consistência salvo decisão em contrário):

- `ResidentTicketWhatsAppNotificationService`
  - `notifyCreated(ResidentTicket ticket)` — chamado na criação, só se `whatsappOptIn=true` e
    `notification.whatsapp.resident-ticket-enabled=true`. Usa
    `WhatsAppNotificationProvider.sendTemplateMessage` com um template novo (nome a definir, ex.
    `chamado_morador_criado_v1`), variáveis: nome do morador, protocolo, categoria, nome da
    organização.
  - `notifyResolved(ResidentTicket ticket)` — chamado na transição para `CONCLUIDO`, mesma condição
    de opt-in/flag. Template novo (ex. `chamado_morador_resolvido_v1`), variáveis: nome do morador,
    protocolo, nome da organização.
  - Registro de dispatch próprio (reaproveitar o padrão de `BusinessWhatsAppDispatch` ou criar uma
    tabela equivalente simplificada) para idempotência — não reenviar a mesma notificação se o
    endpoint/transição for acionado de novo.
  - Falha de envio é best-effort (não bloqueia a criação do chamado nem a mudança de status) — loga
    e segue, mesmo princípio já usado em `ResidentTicketAdminNotificationService`.

**Dependência externa bloqueante**: os 2 templates novos (submetidos em **TASK-372**, task própria,
separada do código) precisam ser aprovados pela Meta antes de qualquer envio real funcionar em
produção — mesmo processo e mesma incerteza de prazo já visto no EPIC-023
(`vencimento_manutencao_v3`). A flag
`notification.whatsapp.resident-ticket-enabled` continua desligada por padrão; a feature de
categoria/protocolo não depende da aprovação (pode ir ao ar sem a notificação funcionando ainda).

### Frontend

- Formulário de abertura (`/chamados/[orgCode]`, tela 2 — rota já renomeada de `/c/[orgCode]`
  durante o QA da v1): novo campo obrigatório de categoria (3 opções: Sugestão/Reclamação/
  Manutenção — radio ou select) e novo checkbox opcional de opt-in de WhatsApp, com o texto
  explicando o que será enviado (criação + resolução).
- Tela de confirmação / listagem "Meus chamados": exibir o número de protocolo em destaque (ex.
  "Protocolo nº 12") junto a cada chamado.
- Kanban interno (painel autenticado): cada card passa a mostrar a categoria (badge/tag colorida) e
  o número de protocolo.

---

## Tasks

| ID (proposto) | Título | Tipo | Depende de |
|---|---|---|---|
| TASK-367 | Backend: migration (com backfill) + categoria + protocolo sequencial por organização (entidade, DTOs, endpoints existentes atualizados) | BACKEND | — |
| TASK-368 | Backend: `ResidentTicketWhatsAppNotificationService` (criação + resolução), flag e templates novos (pendente aprovação Meta) + guarda no webhook do EPIC-031 pra ignorar número não cadastrado como `User` | BACKEND | TASK-367, TASK-371 |
| TASK-369 | Frontend: categoria no formulário público, protocolo exibido na confirmação/listagem | FRONTEND | TASK-367 |
| TASK-370 | Frontend: categoria e protocolo no kanban interno (card) | FRONTEND | TASK-367 |
| TASK-371 | Full-stack: opt-in de WhatsApp do morador com confirmação por código (solicitar código, tela de confirmação, validação/expiração/reenvio) | FULL_STACK | TASK-367 |
| TASK-372 | Infra/Config: submeter e aprovar na Meta os 2 templates WhatsApp necessários — confirmação de código (TASK-371) e protocolo criado/concluído (TASK-368) | INFRA/CONFIG | — |

TASK-369 e TASK-370 são independentes entre si (telas diferentes), ambas dependem só de TASK-367
(contrato de API). TASK-371 depende só de TASK-367 e pode andar em paralelo com TASK-369/370.
TASK-368 depende de TASK-371 porque só notifica quem já tem `whatsapp_opt_in_status=CONFIRMADO` —
sem o fluxo de confirmação pronto, não há destinatário válido pra notificar. **TASK-372 não depende
de código nenhum** (é submissão de configuração à Meta, decisão separada de Douglas, 28/10/2026) —
deve começar o mais rápido possível, em paralelo com TASK-367, porque o prazo de aprovação é externo
e incerto (mesmo risco já visto no EPIC-023). TASK-368 e TASK-371 podem ser implementadas e testadas
contra mock antes da aprovação sair, mas o envio real de WhatsApp em produção depende de TASK-372
concluída.

---

## Fora de Escopo (desta extensão)

- Categorias configuráveis por organização (fica fixo em enum por ora — Douglas decidiu
  explicitamente adiar).
- Notificação de qualquer outra transição de status (ex. `EM_ANDAMENTO`) — só criação e resolução.
- Edição da categoria depois de aberto o chamado.
- Qualquer mudança no fluxo de e-mail aos ADMINs já existente (continua como está).

## Riscos

- **Aprovação de template pela Meta** é dependência externa, fora do nosso controle de prazo —
  mesmo risco já observado no EPIC-023. A feature de categoria/protocolo não fica bloqueada por
  isso (pode entregar sem a notificação ligada); só a notificação em si depende da aprovação.
- **Corrida na geração do protocolo**: dois chamados abertos ao mesmo tempo na mesma organização não
  podem colidir no número — exige teste de concorrência real na implementação (TASK-367), não só
  teste unitário sequencial.
- Baixo risco pro restante do sistema — extensão aditiva de um módulo já isolado
  (`resident_tickets`), sem alterar entidades/fluxos de outros módulos.
