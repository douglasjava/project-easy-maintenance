# TASK-165 — Backend: lista paginada/filtrável de leads + troca de status

## Tipo
BACKEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status)

## QA obrigatório
Sim — validar cada filtro isoladamente e combinado, e que a troca de status persiste de verdade.

---

## Contexto

A lista individual de leads (parte do mini-CRM) precisa de paginação, filtros combináveis e a ação
de trocar status — é o que torna o status útil na prática, não só um campo estático.

---

## Objetivo

`GET /admin/leads` (lista paginada/filtrável) e `PATCH /admin/leads/{id}/status` (troca de status).

---

## Escopo

### 1. Repositório
- `LandingLeadRepository extends JpaRepository<LandingLead, Long>, JpaSpecificationExecutor<LandingLead>`
  (mesmo padrão de `PaymentRepository`).
- Specifications estáticas: `hasStatus(LeadStatus)`, `hasSource(String)` (igualdade exata, não
  `LIKE`), `hasCampaign(String)` (igualdade exata), `createdBetween(Instant, Instant)`.

### 2. Serviço
- `listLeads(status, source, campaign, start, end, pageable)`: combina as specifications não-nulas
  (mesmo padrão `Specification.where(...).and(...)` condicional já usado em `PaymentRepository`).
- `updateStatus(Long id, LeadStatus newStatus)`: busca o lead (404 se não existir), atualiza,
  salva.

### 3. Controller
- `GET /easy-maintenance/api/v1/private/admin/leads` — query params `status`, `source`,
  `campaign`, `createdFrom`, `createdTo`, `Pageable`. Retorna `PageResponse<LeadDTO.LeadResponse>`.
- `PATCH /easy-maintenance/api/v1/private/admin/leads/{id}/status` — corpo `{ status: LeadStatus }`.
  Retorna o lead atualizado.
- Mesmo padrão de autenticação do resto de `/admin/*`.

### 4. Testes
- Cada filtro isolado retorna só os leads esperados.
- Filtros combinados (ex. status + source) aplicam AND, não OR.
- `updateStatus` com id inexistente retorna 404.
- `updateStatus` persiste o novo valor (`save` chamado com o status correto).

---

## Critérios de Aceite

- [x] `GET /admin/leads` pagina e filtra corretamente (status, source, campaign, período)
- [x] Filtros combinados aplicam AND
- [x] `PATCH /admin/leads/{id}/status` persiste a troca e retorna o lead atualizado
- [x] Id inexistente retorna 404
- [x] Suíte de testes backend passa, sem regressão

**Decisão de teste**: os filtros foram testados com `@DataJpaTest` (H2 real), não só Mockito — mesmo
padrão de `MaintenanceCancelPersistenceTest`. Mockar `repository.findAll(spec, pageable)` provaria
só que o método foi chamado, não que a `Specification` filtra o dado certo nem que múltiplos
filtros combinam com AND (que é exatamente um dos critérios de aceite desta task).

## Dependências
- **TASK-163** — precisa do enum `LeadStatus` existir.

## Riscos
Baixo — CRUD/listagem sobre uma tabela já existente, mesmo padrão de `Specification` já usado em
`PaymentRepository`.

## Esforço
Médio

## Status
Em Validação — branch `feature/EPIC-021-leads-dashboard`, commit `dd959b0`.
