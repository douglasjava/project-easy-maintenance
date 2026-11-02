# TASK-389 — BACKEND: notificação ao síndico — e-mail de fallback + WhatsApp fan-out

## Tipo
BACKEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim — confirmar e-mail disparado a todo ADMIN na criação de pendência, confirmar WhatsApp disparado
a todos os síndicos linkados ao assistente (quando houver mais de um), confirmar que falha de envio
por um canal não impede o outro.

---

## Contexto
Garante que a pendência criada na TASK-388 é vista por alguém — hoje a maioria das organizações não
tem síndico linkado ao assistente (piloto EPIC-031 restrito), por isso o e-mail de fallback é
obrigatório, não opcional. Detalhe completo na spec da esteira, seção "Decisões" (item "E-mail de
fallback na criação da pendência" e "Fan-out de WhatsApp").

## Escopo
- Serviço novo `ResidentIdentityNotificationService`: ao criar uma `ResidentIdentityPending`
  (TASK-388), dispara:
  - **E-mail** a todos os `User` `ADMIN`/`SYNDIC` da organização — mesmo canal/template já usado na
    criação de chamado do EPIC-027, adaptado pro conteúdo da pendência (nome, telefone, apto/bloco
    informado, resumo do que foi pedido).
  - **WhatsApp**: para cada `User` linkado ao assistente (`AssistantLink`, EPIC-031) com `Role`
    `ADMIN`/`SYNDIC` naquela organização, envia o template HSM com botões Aprovar/Reprovar
    (template em si é a TASK-392 — aqui a chamada pode ser codificada contra mock enquanto a
    aprovação da Meta não sai).
- Falha de envio em qualquer um dos dois canais é best-effort — loga e segue, não impede o outro
  canal nem bloqueia a criação da pendência em si (mesmo padrão best-effort já usado em
  `ResidentTicketWhatsAppNotificationService`, EPIC-027/TASK-368).

## Critérios de Aceite
- [x] Criar pendência dispara e-mail a todo `ADMIN`/`SYNDIC` da organização
- [x] Criar pendência numa organização com 2 síndicos linkados ao assistente dispara WhatsApp pros
      2 (fan-out), não só pro primeiro
- [x] Organização sem nenhum síndico linkado ao assistente recebe só o e-mail, sem erro
- [x] Falha simulada no envio de WhatsApp não impede o e-mail de ser enviado, e vice-versa
- [x] `mvn test` sem regressão (1632/1632)

## Dependências
TASK-388 (gatilho da notificação). Integra com `AssistantLink` já existente do EPIC-031. Depende de
TASK-392 só para o envio real em produção (não para codificar/testar contra mock).

## Riscos
Aprovação de template pela Meta (TASK-392) é dependência externa sem prazo garantido — não bloqueia
esta task em si, só o envio real do WhatsApp em produção.

## Esforço
Médio

## Status
🟢 Implementado (02/11/2026) — branch `feature/EPIC-040-resident-identity-approval`
(`easy-maintenance-api`), commit `6a37840`. WhatsApp desligado por padrão
(`notification.whatsapp.resident-identity-pending-enabled=false`) até TASK-392 aprovar o template
`aprovacao_identidade_morador_v1` — código já pronto e testado contra mock, só liga a flag quando
a Meta aprovar. 12 testes novos, suíte completa 1632/1632. Desbloqueia TASK-390.
