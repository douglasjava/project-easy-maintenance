# TASK-395 — BACKEND: webhook consome clique Aprovar/Reprovar do WhatsApp (EPIC-040)

## Tipo
BACKEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim — aprovar e reprovar via clique real de botão (ou payload simulado do webhook), confirmar
idempotência (clique duplicado/reentrega do evento), confirmar que mensagem de outro approver não
é aceita para pendência de terceiros, confirmar que o pipeline geral do assistente (chat) continua
funcionando para mensagens que não são essa correlação.

---

## Contexto
TASK-392 (template aprovado pela Meta) desbloqueou o envio do WhatsApp com os botões
Aprovar/Reprovar (`ResidentIdentityNotificationService.dispatchWhatsApp`), mas **não existe nada
que processe o clique de volta** — isso ficou documentado como gap desde a TASK-392 ("Ponto de
atenção"). O webhook de inbound do WhatsApp (`WhatsAppWebhookController`/`WhatsAppWebhookService`)
já existe e já sabe parsear mensagens tipo `button` (resposta de Quick Reply de template) via
`AssistantInboundIngestor`, mas hoje todo clique cairia direto no pipeline geral do assistente de
IA (`IntentStep`/`DeterministicIntentMatcher`), que não sabe nada sobre `ResidentIdentityPending` —
o clique seria mal interpretado como uma mensagem de chat qualquer.

## Decisões de design desta task (não estavam na spec original — "fica pro builder decidir", ver
TASK-392)

1. **Correlação clique → pendência**: a Meta manda `context.id` (wamid da mensagem original) em
   toda resposta de botão de template. Hoje esse campo nem é parseado no `WhatsAppWebhookDTO`. Esta
   task adiciona `context` ao DTO e persiste, no momento do envio
   (`ResidentIdentityNotificationService.dispatchWhatsApp`), um registro novo
   (`ResidentIdentityApprovalDispatch`: `pendingId`, `organizationId`, `approverUserId`, `waId`,
   `wamid`) — **não** reaproveita `BusinessWhatsAppDispatch` porque essa entidade é modelada em
   torno de `due_date`/`days_offset` (TASK-130/131, lembretes de vencimento), campos que não fazem
   sentido aqui; forçar valores fake nela seria mais confuso que uma tabela própria e pequena.
2. **Segurança**: ao receber o clique, o `wa_id` de quem respondeu precisa ser exatamente o
   `wa_id` persistido no dispatch (o approver pretendido) — mensagem de um número diferente pro
   mesmo `wamid`/`context.id` é descartada (log, sem ação), nunca processada.
3. **Resolução de `Unit` no aprovar por WhatsApp**: diferente da tela `/pessoas` (TASK-391), o
   WhatsApp só tem dois botões — não há como o síndico digitar/escolher a unidade na hora. Decisão:
   reaproveitar automaticamente o `unitHint` (apto/bloco, texto livre, já obrigatório na intake) —
   busca `Unit` existente por número exato (`UnitRepository.findByOrganizationIdAndNumber`); se não
   achar, cria uma `Unit` nova usando o hint como `number` (sem `floor`/`type`, que o síndico pode
   ajustar depois em `/pessoas` se precisar). Aprovação continua disponível com controle total pela
   tela `/pessoas` para quem quiser revisar antes.
4. **Não depende do piloto do assistente de IA** (`assistant.enabled`) — diferente do fluxo de chat
   geral (EPIC-031), que ainda está restrito a um piloto, a correlação de clique de aprovação
   intercepta a mensagem **antes** desse gate, porque é um fluxo determinístico e independente do
   assistente conversacional.
5. **Confirmação ao síndico**: após aprovar/reprovar, envia uma mensagem de texto curta de
   confirmação (`WhatsAppClient.sendText`) — best-effort, falha não desfaz a aprovação/reprovação
   (que já aconteceu).

## Escopo
- `WhatsAppWebhookDTO.InboundMessage`: novo campo `context` (`Context(String id)`).
- Nova entidade `ResidentIdentityApprovalDispatch` + migration (`V134`) + repositório
  (`findByWamid`).
- `ResidentIdentityNotificationService.dispatchWhatsApp`: persiste o dispatch depois do envio bem-
  sucedido (wamid não nulo).
- Novo `ResidentIdentityApprovalButtonReplyHandler`: dado um `InboundMessage` tipo `button`,
  resolve o dispatch por `context.id`, valida remetente, resolve `Organization`/`Unit`, chama
  `ResidentIdentityApprovalService.approve()`/`reject()` (já idempotentes via status `PROCESSADO`,
  nenhuma mudança nelas), envia confirmação. Retorna `true` quando consumiu a mensagem (não deixa
  cair no pipeline do assistente).
- `WhatsAppWebhookService.processChange`: tenta o handler novo antes do
  `assistantInboundIngestor.ingest` para mensagens tipo `button`; se não reconhecer o `wamid`
  (não é resposta de aprovação), segue o fluxo normal sem nenhuma mudança de comportamento.
- `UnitRepository`: novo método `findByOrganizationIdAndNumber`.

## Critérios de Aceite
- [x] Clique em "Aprovar" aprova a pendência certa (via `context.id`) — cria `Unit` (nova ou
      vinculada por número) + `CondoPerson` + `ResidentTicket`, mesmo resultado que aprovar pela
      tela
- [x] Clique em "Reprovar" reprova a pendência certa, nada criado
- [x] Clique de um número diferente do approver esperado para o mesmo `wamid`/`context.id` é
      descartado, sem efeito
- [x] Reentrega do mesmo evento de webhook (`wamid` repetido) não duplica `CondoPerson`/
      `ResidentTicket` — já garantido pelo lock/status `PROCESSADO` de `ResidentIdentityApprovalService`,
      coberto com teste explícito nesta task também
- [x] Mensagens que não correspondem a nenhum dispatch conhecido continuam caindo no pipeline do
      assistente exatamente como antes (sem regressão no chat do EPIC-031)
- [x] `mvn test` sem regressão
- [x] QA manual em produção: clique real de botão no WhatsApp chegando no webhook — confirmado por Douglas em 10/11/2026

## Dependências
TASK-389 (envio), TASK-390 (approve/reject), TASK-392 (template aprovado — sem ele não tem como
testar o clique real, mas o código é testável com payload simulado antes disso).

## Riscos
Baixo/médio — toca o webhook compartilhado do WhatsApp (`WhatsAppWebhookService`), que também serve
o assistente de IA (EPIC-031) e os status de entrega (TASK-128). Mitigado por interceptar só
mensagens `button` com `wamid` reconhecido — qualquer outra mensagem segue o caminho inalterado.

## Esforço
Médio

## Status
✅ Done — em `main` via api#175→api#177; QA manual em produção com clique real feito (confirmado por Douglas em 10/11/2026).

**Histórico (antes de 10/11/2026):**
🟢 Implementado (03/11/2026) — branch `feature/TASK-395-webhook-aprovacao-identidade`
(`easy-maintenance-api`), commit `6dea9a9`, PR #175 mergeada em `staging`. `mvn test`: 40 testes
novos/alterados, suíte completa sem regressão. Falta só QA manual em produção com clique real de
botão (depende do `WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED=true` já ligado, ver TASK-392).
