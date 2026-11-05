# TASK-387 — BACKEND: `ResidentIdentityPending` — entidade, migration e repositório

## Tipo
BACKEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Não — coberto por teste de persistência, sem fluxo de UI nesta task.

---

## Contexto
Guarda a solicitação retida enquanto a identidade de quem pediu (via QR Code) não foi confirmada
pelo síndico. Detalhe completo em
`docs/superpowers/specs/2026-10-31-resident-whatsapp-identity-approval-design.md`.

## Escopo
- Migration nova `resident_identity_pendings`: `id`, `organization_id` (BIGINT NOT NULL), `name`
  (VARCHAR NOT NULL), `phone` (VARCHAR NOT NULL), `document` (VARCHAR NULL, CPF), `unit_hint`
  (VARCHAR NULL — apto/bloco informado em texto livre na intake), `request_payload` (JSON NOT
  NULL — conteúdo da solicitação retida, ex. descrição do chamado), `status` (VARCHAR NOT NULL
  DEFAULT 'PENDENTE' — `PENDENTE`/`PROCESSADO`), `created_at`/`updated_at`.
- `UNIQUE (organization_id, phone, status)` com `status` fazendo parte do índice só para o valor
  `PENDENTE` (índice parcial se o banco suportar, ou validação no serviço — decisão de
  implementação) — garante que não existam duas pendências abertas pro mesmo telefone na mesma
  organização ao mesmo tempo (reenvio enquanto pendente atualiza, não duplica, ver TASK-388/390).
- Entidade `ResidentIdentityPending` (módulo `resident_tickets` ou módulo novo `resident_identity`,
  decisão de implementação — mais próximo do fluxo público do EPIC-027, mas sem acoplar à entidade
  `ResidentTicket` em si).
- `ResidentIdentityPendingRepository` com `Optional<ResidentIdentityPending>
  findByOrganizationIdAndPhoneAndStatus(Long organizationId, String phone, String status)` e
  `List<ResidentIdentityPending> findByOrganizationIdAndStatus(Long organizationId, String
  status)` (lista "Pendentes" da TASK-391).

## Critérios de Aceite
- [x] Migration cria a tabela com os campos listados (`V133__create_resident_identity_pendings.sql`)
- [x] Duas pendências `PENDENTE` pro mesmo telefone na mesma organização são impedidas (constraint
      `uk_resident_identity_pending_org_phone_active`, provada em teste)
- [x] `findByOrganizationIdAndPhoneAndStatus` localiza a pendência aberta de um telefone
- [x] `mvn test` sem regressão (1619/1619, 0 falhas)

## Dependências
Depende do EPIC-039 estar implementado (referencia conceitos de `CondoPerson`/`Unit` usados pela
TASK-390, embora esta task em si não tenha FK direta). Desbloqueia TASK-388.

## Riscos
A garantia de unicidade "só um `PENDENTE` por telefone" é a parte mais delicada — se o banco não
suportar índice único parcial facilmente (MySQL), decidir entre coluna computada ou validação
transacional no serviço (lock de linha), documentando a escolha no código.

## Esforço
Médio

## Status
🟢 Implementado (02/11/2026) — branch `feature/EPIC-040-resident-identity-approval`
(`easy-maintenance-api`, a partir de `staging`), commit `b160a7d`. Decisão de implementação: índice
único parcial não suportado pelo MySQL, resolvido com `active_dedup_key` (mesmo padrão do V85).
Desbloqueia TASK-388.
