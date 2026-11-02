# TASK-390 — BACKEND: aprovação/reprovação — lock, criação de `CondoPerson`+`Unit`, reprocessamento

## Tipo
BACKEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim — aprovar vinculando a unidade existente, aprovar criando unidade nova, reprovar, tentar
aprovar/reprovar duas vezes o mesmo item (confirmar no-op na segunda), confirmar que o morador só
recebe a confirmação do pedido depois da aprovação.

---

## Contexto
O coração da esteira: transforma uma pendência em `CondoPerson` real e processa a solicitação
retida, ou descarta silenciosamente. Consumido pelos dois canais (WhatsApp e tela `/pessoas`).
Detalhe completo na spec da esteira, seção "Fluxo completo", passos 5 e 6, e "Decisões" (lock
idempotente).

## Escopo
- `POST /organizations/resident-identity-pendings/{id}/approve` — corpo: `{ unitId }` (vincula a
  `Unit` existente) **ou** `{ unitNumber, unitFloor, unitType }` (cria `Unit` nova com esses dados,
  TASK-382). Internamente:
  1. Trava a pendência (`status = PENDENTE` → `PROCESSADO`, transação única — qualquer tentativa
     concorrente na mesma pendência já `PROCESSADO` retorna no-op, não erro).
  2. Resolve/cria a `Unit`.
  3. Cria `CondoPerson` (papel `MORADOR`, `name`/`phone`/`document` vindos da pendência, `unit_id`
     resolvido).
  4. Processa o `request_payload` da pendência como uma criação de `ResidentTicket` normal (mesmo
     caminho do EPIC-027 — kanban, e-mail a ADMINs).
  5. Dispara a confirmação ao morador (WhatsApp, reaproveitando o template de criação de chamado já
     existente do EPIC-027/TASK-368, se o morador tiver opt-in — senão nenhuma confirmação, mesmo
     comportamento de hoje).
- `POST /organizations/resident-identity-pendings/{id}/reject` — trava a pendência (mesma regra de
  idempotência), não cria `CondoPerson`, não processa o `request_payload`. Nenhum aviso ao morador.
  Registra evento de métrica/log (`resident_identity_pending.rejected`, com `organization_id`).
- Ambos os endpoints também são o alvo das respostas de botão do WhatsApp (via webhook do
  assistente, TASK-389/EPIC-031) — decisão de implementação: webhook chama o mesmo service, não
  duplica lógica.
- Permissão `ADMIN`/`SYNDIC` nos dois endpoints.

## Critérios de Aceite
- [x] Aprovar com `unitId` existente vincula a unidade certa ao `CondoPerson` criado
- [x] Aprovar com dados de unidade nova cria a `Unit` e já vincula na mesma operação
- [x] Aprovar processa a solicitação retida — chamado real aparece no kanban, ADMINs recebem
      e-mail de chamado (não de pendência)
- [x] Segunda chamada de approve/reject na mesma pendência já `PROCESSADO` é no-op (não cria
      `CondoPerson` duplicado, não reprocessa o chamado)
- [x] Reprovar não cria `CondoPerson`, não cria `ResidentTicket`, não envia nada ao morador
- [x] Evento de reprovação aparece no log/métrica da organização
- [x] `TECH`/`READER` recebem `403`
- [x] `mvn test` sem regressão (1647/1647)

## Dependências
TASK-387/388 (pendência existir) e EPIC-039 completo (`CondoPerson`/`Unit`/serviços de TASK-381 a
383). Desbloqueia TASK-391 (frontend consome estes endpoints).

## Riscos
Ponto mais sensível do épico pra corrida/duplicação — o lock de idempotência precisa ser real
(transação + checagem de status antes de agir), não só checagem otimista no código. Testar
explicitamente a chamada repetida/concorrente nesta task, não deixar só pra QA manual.

## Esforço
Grande

## Status
🟢 Implementado (02/11/2026) — branch `feature/EPIC-040-resident-identity-approval`
(`easy-maintenance-api`), commit `847f001`. Lock via `SELECT ... FOR UPDATE`
(`findByIdAndOrganizationIdForUpdate`, mesmo padrão de `OrganizationRepository.findByIdForUpdate`/
TASK-367). Webhook de resposta do WhatsApp (botão Aprovar/Reprovar) **não foi implementado nesta
entrega** — não existe task própria pra isso no EPIC, e WhatsApp continua desligado por flag até a
TASK-392; os métodos de domínio já recebem `Organization`/id explícito (não dependem de
`TenantContext`) justamente pra esse webhook poder reusar a mesma lógica quando for implementado.
12 testes novos, suíte completa 1647/1647. Desbloqueia TASK-391.
