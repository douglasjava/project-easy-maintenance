# TASK-368 — BACKEND: Notificação ao morador por WhatsApp (criação + resolução)

## Tipo
BACKEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — confirmar envio real na criação e na transição pra `CONCLUIDO` (com opt-in confirmado),
confirmar ausência de envio sem opt-in confirmado, confirmar não duplica envio na mesma transição,
confirmar reenvio em reabertura+reconclusão, confirmar resposta de número não cadastrado é ignorada
pelo bot do EPIC-031.

---

## Contexto

Pedido da síndica Aliria Emanuela (28/10/2026, via Douglas): notificar o morador quando o chamado é
criado (confirmando o protocolo) e quando é resolvido. Canal é o mesmo número WhatsApp já em
produção do assistente do EPIC-031, mas como envio outbound/proativo (fora de sessão de conversa) —
exige template (HSM) próprio aprovado pela Meta, mesma exigência já vista no EPIC-023. Detalhe
completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

- Novo serviço `ResidentTicketWhatsAppNotificationService` (módulo `resident_tickets`), separado de
  `BusinessWhatsAppNotificationService` (esse é acoplado a `User`/quota/opt-in de negócio — morador
  não é um `User`).
  - `notifyCreated(ticket)`: na criação, só se `whatsapp_opt_in_status=CONFIRMADO` e
    `notification.whatsapp.resident-ticket-enabled=true`. Template novo (ex.
    `chamado_morador_criado_v1`), variáveis: nome, protocolo, categoria, organização.
  - `notifyResolved(ticket)`: na transição pra `CONCLUIDO`, mesma condição. Template novo (ex.
    `chamado_morador_resolvido_v1`), variáveis: nome, protocolo, organização.
  - Registro de dispatch próprio (reaproveitar o padrão de `BusinessWhatsAppDispatch` ou equivalente
    simplificado) para idempotência: não duplicar envio na mesma transição (ex. clique duplo no
    drag-and-drop), mas **permite reenvio se o chamado for reaberto e concluído de novo**
    (`CONCLUIDO` → `EM_ANDAMENTO` → `CONCLUIDO` é uma conclusão nova e real).
  - Falha de envio é best-effort — loga e segue, não bloqueia a criação/mudança de status.
  - Nome dos templates e variáveis exatas vêm de **TASK-372** (submissão/aprovação na Meta é
    trabalho separado, de configuração, não de código).
- **Guarda no webhook de entrada do EPIC-031**: se o morador responder à mensagem de notificação, o
  número de origem precisa ser verificado contra a base de `User` antes de qualquer processamento
  pelo bot conversacional — se não corresponder a um usuário cadastrado, a resposta é **ignorada**
  (não deixa o assistente tentar tratar o morador como se fosse usuário do sistema). Primeiro passo
  da implementação: confirmar se o webhook já faz essa checagem por padrão ou se precisa de guarda
  explícita nova.
- Os 2 templates novos precisam ser submetidos e aprovados pela Meta — dependência externa, fora do
  controle de prazo do time (mesmo risco já visto no EPIC-023/`vencimento_manutencao_v3`).

## Critérios de Aceite

- [ ] Chamado criado com opt-in `CONFIRMADO` e flag ligada dispara WhatsApp real ao morador
- [ ] Chamado criado sem opt-in `CONFIRMADO` (ou flag desligada) não dispara nada
- [ ] Transição pra `CONCLUIDO` com opt-in `CONFIRMADO` dispara WhatsApp de resolução
- [ ] Clique duplo / reprocessamento da mesma transição não duplica o envio
- [ ] Reabertura (`EM_ANDAMENTO`) seguida de nova conclusão dispara novo envio de resolução
- [ ] Resposta de um número que não corresponde a nenhum `User` cadastrado é ignorada pelo fluxo do
      EPIC-031 (não gera resposta automática confusa pro morador)
- [ ] Falha de envio (ex. API do WhatsApp fora) não impede a criação do chamado nem a mudança de
      status
- [ ] `mvn test` sem regressão

## Dependências
TASK-367 (categoria/protocolo no payload das mensagens) e TASK-371 (só notifica quem já tem opt-in
`CONFIRMADO` — sem isso não há destinatário válido). TASK-372 (templates aprovados pela Meta) bloqueia
o envio real em produção, mas não bloqueia escrever/testar o código contra mock.

## Riscos
Aprovação de template pela Meta (TASK-372) é dependência externa sem prazo garantido — a feature de
categoria/protocolo (TASK-367/369/370) não fica bloqueada por isso, só esta notificação em si.
Compartilhar o número com o bot do EPIC-031 exige a guarda de resposta funcionando corretamente —
testar esse cenário de verdade, não só isoladamente.

## Esforço
Médio

## Status
📋 Backlog
