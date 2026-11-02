# EPIC-040 — Esteira de Aprovação de Identidade do Morador (QR Code / WhatsApp)

## Status
🟡 Quase completo (02/11/2026) — EPIC-039 implementado e validado, dependência liberada.
TASK-387 a TASK-391 implementadas em `feature/EPIC-040-resident-identity-approval` (api + web):
entidade da pendência (TASK-387), intake do QR Code desviando pra pendência (TASK-388),
notificação ao síndico por e-mail + WhatsApp fan-out (TASK-389), aprovação/reprovação com lock de
idempotência real + reprocessamento do chamado retido (TASK-390), aba "Pendentes" em `/pessoas`
(TASK-391). TASK-388 exigiu ajuste no frontend público além do escopo original de backend — ver
nota na task — pra não quebrar a tela de abertura de chamado já em produção. Suíte completa:
1648/1648 testes verdes; `tsc`/`build` do web limpos.

**[TASK-392](../tasks/TASK-392.md) (submissão do template à Meta) é a única que não pode ser
concluída por um agente** — exige o Douglas submeter o template no Meta Business Manager; o
conteúdo exato já está documentado e o código (TASK-389) já foi corrigido pra bater com as
variáveis do template (uma divergência real foi encontrada e corrigida ao especificar o template).
Até lá, WhatsApp da esteira fica desligado por flag (e-mail continua cobrindo 100% das
organizações). Também não existe, no épico, uma task que implemente o webhook que recebe o clique
do botão Aprovar/Reprovar — os serviços já estão prontos pra isso (ver nota na TASK-392), mas falta
escrevê-lo quando o template for aprovado. Spec em
`docs/superpowers/specs/2026-10-31-resident-whatsapp-identity-approval-design.md`.

## Objetivo
Dar ao número de WhatsApp de quem abre uma solicitação via QR Code (EPIC-027) o papel `MORADOR`
(`CondoPerson`) com segurança — hoje qualquer pessoa que escaneia o código (visitante, entregador,
vizinho de outro prédio) poderia, sem este gate, ganhar acesso ao chat do assistente (EPIC-031) como
se fosse moradora de fato.

## Descrição

Gate **por pessoa**, não por solicitação: só a primeira solicitação de um número novo passa pela
esteira de aprovação de identidade. Nada é processado (chamado criado de verdade, no futuro reserva
de área comum) enquanto a identidade está pendente — fica retida. Síndico é notificado por dois
canais em paralelo: WhatsApp (botões Aprovar/Reprovar, fan-out para todos os síndicos linkados ao
assistente) e e-mail de fallback aos ADMINs (mesmo canal já usado na criação de chamado); aparece
também numa aba nova "Pendentes" em `/pessoas` (EPIC-039), sempre disponível independente de
WhatsApp.

Síndico aprova → vincula a uma `Unit` existente ou cria uma nova com o apto/bloco informado na
intake; nasce o `CondoPerson` (papel `MORADOR`); a solicitação retida é processada como se fosse
nova agora (chamado cai no kanban normal, notifica ADMINs); morador recebe a confirmação do que
pediu só nesse momento. Síndico reprova → solicitação é descartada, nenhum `CondoPerson` é criado,
nenhum aviso ao morador (silencioso — registra métrica/log). Depois da primeira aprovação, o número
já é reconhecido e pula a esteira nas próximas solicitações.

**Decisão importante**: reserva de área comum em si não existe ainda (`organization-settings-
module-design.md`/EPIC-038 deixou isso para depois) — esta entrega só garante que o gate de
identidade já existe pronto pra quando essa feature nascer.

---

## Contexto Técnico

- Novo campo **apto/bloco** na intake pública do QR Code (`POST /public/resident-tickets`, módulo
  `resident_tickets` do EPIC-027) — texto livre na captura; resolução para `Unit` existente ou nova
  acontece só na aprovação, não na intake.
- Notificação por WhatsApp reaproveita a infra do EPIC-031 (`AssistantLink`) — fan-out para todos os
  síndicos linkados; exige template HSM novo com botões de resposta rápida (Aprovar/Reprovar),
  submissão à Meta separada (mesmo padrão TASK-372/TASK-368, dependência externa sem prazo
  garantido).
- Lock/idempotência entre os dois canais: pendência tem status (`PENDENTE`/`PROCESSADO`); primeira
  ação (por qualquer canal) trava o item, demais tentativas são no-op.
- Reenvio do mesmo telefone enquanto a pendência ainda está em aberto atualiza o registro existente
  (chave de unicidade telefone + organização + status `PENDENTE`), não cria duplicata.
- Falha de aprovação via WhatsApp (ex. API fora) não deve travar o caminho pela tela `/pessoas` —
  os dois canais operam sobre o mesmo dado, sem dependência um do outro.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-387](../tasks/TASK-387.md) | Backend: `ResidentIdentityPending` — entidade, migration e repositório (unicidade telefone+org+status) | BACKEND | 🟠 Alto |
| [TASK-388](../tasks/TASK-388.md) | Backend: intake do QR Code — campo apto/bloco + desvio para pendência quando telefone não tem `CondoPerson` | BACKEND | 🟠 Alto |
| [TASK-389](../tasks/TASK-389.md) | Backend: notificação ao síndico — e-mail de fallback + WhatsApp fan-out com botões Aprovar/Reprovar | BACKEND | 🟠 Alto |
| [TASK-390](../tasks/TASK-390.md) | Backend: aprovação/reprovação — lock idempotente, criação/vínculo de `CondoPerson`+`Unit`, reprocessamento do pedido retido | BACKEND | 🟠 Alto |
| [TASK-391](../tasks/TASK-391.md) | Frontend: aba "Pendentes" em `/pessoas` — listar, aprovar (vincular/criar unidade), reprovar | FRONTEND | 🟠 Alto |
| [TASK-392](../tasks/TASK-392.md) | Infra/Config: template WhatsApp de aprovação (botões Aprovar/Reprovar) — submissão Meta | INFRA/CONFIG | 🔴 Crítico |

Ordem: TASK-387 não depende de nada técnico, mas depende do EPIC-039 estar implementado (precisa de
`CondoPerson`/`Unit`). TASK-388 depende da 387. TASK-389 e TASK-392 podem começar em paralelo desde
já (TASK-392 não depende de código, só de configuração externa — quanto antes submeter, melhor,
mesmo raciocínio do TASK-372). TASK-390 depende da 387/388/389. TASK-391 depende da 390 (precisa dos
endpoints de aprovação). O envio real de WhatsApp em produção só funciona depois da aprovação da
Meta (TASK-392), mas TASK-389/390 podem ser codificadas/testadas contra mock antes disso.

---

## Critério de Conclusão do Épico

- [ ] Primeira solicitação de um telefone novo não processa o pedido — fica retida como pendência
- [ ] Síndico linkado ao assistente recebe WhatsApp com botões Aprovar/Reprovar; todo ADMIN recebe
      e-mail de fallback independente de link com o assistente
- [ ] Aprovação cria `CondoPerson` (papel `MORADOR`) vinculado à `Unit` (existente ou nova) e
      processa o pedido retido (chamado real, kanban, notificação a ADMINs)
- [ ] Reprovação não cria `CondoPerson`, não processa o pedido, não avisa o morador — só loga/métrica
- [ ] Segunda solicitação do mesmo telefone, já aprovado, pula a esteira e vai direto pro fluxo
      operacional normal
- [ ] Reenvio enquanto a primeira pendência ainda está aberta atualiza o registro, não duplica
- [ ] Ação simultânea nos dois canais (WhatsApp + tela) nunca processa/descarta o pedido duas vezes
- [ ] `mvn test`/`npm run build`/`tsc --noEmit` sem regressão

## Fora de Escopo
- Reserva de área comum em si (feature não existe ainda, EPIC-038 deixou pra depois).
- Limite de tentativas após reprovação (anti-abuso de reenvio repetido) — rate limit já existente
  do EPIC-027 é a única defesa nesta entrega.
- Expiração/timeout de pendência — fica aberta indefinidamente até ação manual do síndico.
- Qualquer mudança em `Role` (perfil de login) — este fluxo só cria/atualiza `CondoPerson`.

## Riscos
Aprovação de template pela Meta (TASK-392) é dependência externa sem prazo garantido, mesmo risco já
visto em TASK-372/EPIC-023. Enquanto a Onda 2 do assistente (TASK-305/306) não libera todos os
síndicos, o e-mail de fallback é o único canal de aviso pra maioria das organizações — pendência sem
expiração + sem push garantido pode deixar solicitações reais invisíveis por dias; aceito
conscientemente por Douglas (31/10/2026) ao fechar a spec.
