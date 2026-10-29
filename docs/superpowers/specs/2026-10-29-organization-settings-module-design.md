# Módulo de Configurações da Organização (SLA de Chamados + Áreas Comuns)

**Data:** 29/10/2026
**Status:** Aprovado por Douglas (brainstorm conduzido 29/10/2026)

## Motivação

Hoje não existe nenhum lugar onde o síndico/admin configure parâmetros da própria organização.
Os dois primeiros casos concretos que motivaram o módulo:

- **SLA de chamados**: `ResidentTicket` (EPIC-027, chamados de morador) não tem prioridade, prazo
  nem noção de atraso — hoje é só status livre (`SOLICITADO` → …). Não há onde configurar quanto
  tempo cada prioridade tem para ser resolvida.
- **Áreas comuns**: não existe nenhuma entidade para cadastrar áreas comuns do condomínio (salão de
  festas, churrasqueira etc.) nem suas regras de uso.

Em vez de resolver cada um isoladamente, Douglas pediu um módulo de configurações genérico — porque
"outras coisas que podem surgir" vão precisar do mesmo padrão (uma tela central, parametrizável,
sem precisar de migration nova a cada configuração simples).

## Escopo

**Dentro desta entrega:**
- Armazenar, validar e editar parâmetros de SLA de chamados (uma configuração por organização).
- Cadastrar/editar/desativar áreas comuns, cada uma com suas próprias regras de reserva.
- Tela nova no frontend (`/configuracoes`), com uma aba por bloco de configuração.
- Multi-tenant (`X-Org-Id`) e permissão `ADMIN` ou `SYNDIC` (mesmo padrão já usado em
  `FinancialEntryService`/`MaintenanceService` — nunca `ADMIN` sozinho, pois normalmente é o
  usuário `SYNDIC` quem opera o dia a dia).

**Fora de escopo (confirmado com Douglas, fica para quando os módulos consumidores existirem):**
- Nenhuma automação **usa** essas configurações ainda: `ResidentTicket` não ganha campo de
  prioridade/prazo nesta entrega, e não existe fluxo de reserva de área comum (pedido de reserva,
  aprovação, bloqueio de agenda) — só o cadastro da área e suas regras informativas.
- Taxa de uso de área comum é **só informativa**. Sem lançamento financeiro automático, sem
  cobrança via Asaas.
- Sem controle de concorrência/versionamento nas configurações (descartado explicitamente — não há
  necessidade desse nível de controle agora).

## Modelo de dados

> Migrations novas começam em `V128__...` (maior existente hoje é `V127`; confirmar de novo no
> momento da implementação, caso outra task tenha mergeado migrations nesse meio tempo).

### `organization_settings` — parâmetros genéricos, um por categoria

Mecanismo genérico para parâmetros simples tipo chave→JSON, pensado para novas categorias entrarem
sem migration (só uma categoria nova no enum do backend + DTO de validação).

| Campo                       | Tipo                 | Observação                                                                        |
|-----------------------------|----------------------|-----------------------------------------------------------------------------------|
| `id`                        | Long                 | PK                                                                                |
| `organization_id`           | BIGINT NOT NULL      | FK lógica para `Organization`                                                     |
| `category`                  | VARCHAR(50) NOT NULL | validado contra o enum Java `OrganizationSettingCategory` (`TICKETS_SLA` por ora) |
| `config`                    | JSON NOT NULL        | formato validado por categoria no backend, não no banco                           |
| `created_at` / `updated_at` | TIMESTAMP            | `@CreationTimestamp`/`@UpdateTimestamp`, padrão já usado                          |

- `UNIQUE (organization_id, category)` — uma linha por categoria por organização.
- Sem coluna `version` (decisão explícita: não precisa de optimistic lock nem histórico).

Categoria `TICKETS_SLA` — formato do `config`:
```json
{
  "defaultSlaHours": 24,
  "businessHoursOnly": true,
  "businessHours": { "start": "08:00", "end": "18:00" },
  "prioritySla": { "LOW": 72, "MEDIUM": 24, "HIGH": 8, "CRITICAL": 2 }
}
```
Validado no backend por um record Java (`TicketSlaSettings`) espelhando esse formato — `PUT`
rejeita payload fora do formato esperado (400, `ProblemDetail`, padrão já usado no resto da API).

`GET /organizations/settings/{category}` retorna os valores **default hardcoded** (não 404) quando
a organização ainda não salvou nada, para o frontend sempre ter o que renderizar no formulário.

### `common_area` — cadastro de áreas comuns

Entidade própria porque é uma lista (N áreas por organização), diferente do padrão singleton de
`organization_settings`.

| Campo                       | Tipo                          | Observação                                                                                                                                                                          |
|-----------------------------|-------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                        | Long                          | PK                                                                                                                                                                                  |
| `organization_id`           | BIGINT NOT NULL               | FK lógica para `Organization`                                                                                                                                                       |
| `name`                      | VARCHAR(150) NOT NULL         |                                                                                                                                                                                     |
| `capacity`                  | INTEGER NOT NULL              |                                                                                                                                                                                     |
| `active`                    | BOOLEAN NOT NULL DEFAULT TRUE | desativar em vez de apagar (mesmo padrão de soft delete já usado no sistema)                                                                                                        |
| `fee_cents`                 | INTEGER NULL                  | taxa informativa de uso — coluna própria em centavos (padrão de dinheiro já usado em todo o sistema: `value_cents`, `total_cents` etc.), **não** dentro do JSON. `NULL` = sem taxa. |
| `rules`                     | JSON NOT NULL                 | regras de reserva, formato abaixo                                                                                                                                                   |
| `created_at` / `updated_at` | TIMESTAMP                     | padrão já usado                                                                                                                                                                     |

Formato de `rules`:
```json
{
  "requiresApproval": true,
  "minAdvanceHours": 24,
  "maxAdvanceDays": 30,
  "maxDurationHours": 6
}
```
Mesmo raciocínio do `TICKETS_SLA`: validado por um record Java (`CommonAreaRules`), não no banco.

## API

Novo módulo backend `settings` (`domain`/`application`/`infrastructure`, mesmo padrão de
`resident_tickets`), com dois controllers novos (não entram no `OrganizationsController`
existente), sob o prefixo real da API (`/easy-maintenance/api/v1/...`, igual ao resto):

- `GET /organizations/settings/{category}` — retorna config atual ou defaults.
- `PUT /organizations/settings/{category}` — valida e faz upsert do JSON inteiro (sem patch
  parcial — o frontend sempre envia o objeto completo).
- `GET /organizations/common-areas` — lista (inclui inativas; frontend decide o que exibir/filtrar).
- `POST /organizations/common-areas` — cria.
- `PUT /organizations/common-areas/{id}` — atualiza todos os campos, incluindo `active`
  (desativar é só mais um PUT, sem endpoint dedicado).

Tenant scoping segue o mesmo padrão de `resident_tickets`/`ResidentTicketAdminService`:
`TenantContext.get()` (código da org) → `organizationRepository.findByCode(...)` → filtra por
`Organization.getId()` (Long). **Não** usar o padrão `@Filter`/`@FilterDef` de `MaintenanceItem`
(é um mecanismo diferente, restrito hoje a `MaintenanceItemRepository`) nem o filtro manual por
`organizationCode` (String) de `FinancialEntry` — nenhum dos dois é o padrão de referência aqui.

Todos os quatro exigem `ADMIN` ou `SYNDIC` — `403` com `ProblemDetail` para `TECH`/`READER`, mesmo
padrão de erro já usado (`MaintenanceService`, `FinancialEntryService`). Rejeição de payload fora do
formato esperado por `TicketSlaSettings`/`CommonAreaRules` deve ser feita lançando `RuleException`
manualmente dentro do service (mesmo padrão de `FinancialEntryService.validateAmount`), **não** via
anotações `@Valid`/Bean Validation — o `GlobalExceptionHandler` atual devolve 422 para erro de Bean
Validation e 400 só para `RuleException`/corpo malformado; a spec pede 400, então a validação
precisa ser manual, não anotada.

## Frontend

Rota nova **`/configuracoes`** (não dentro de `/profile` — decisão explícita do Douglas, porque o
módulo deve crescer e `/profile` ficaria poluído). Entrada nova no menu lateral.

Layout: abas, uma por bloco de configuração, **sem sub-rota por aba** — uma única página
`/configuracoes` com a aba ativa em state local, no mesmo molde do segmented-control já usado em
`reports/page.tsx` (divs/botões controlando `activeTab` em state, sem navegação). **Não** usar
`AdminTabs.tsx`: esse componente existe, mas no único uso real (`BillingAdminLayout.tsx`) cada aba é
uma rota própria (`router.push`) — aqui não há necessidade de URL por aba, e adotar esse padrão
exigiria sub-rotas (`/configuracoes/sla`, `/configuracoes/areas-comuns`) sem ganho para o caso.
(Decisão tomada nesta spec para não deixar em aberto; se Douglas preferir URL por aba, é só trocar
o padrão por cima do mesmo componente de aba.)

- Aba **"SLA de Chamados"**: formulário único ligado ao JSON de `TICKETS_SLA` (horas default,
  horário comercial, horas por prioridade).
- Aba **"Áreas Comuns"**: listagem (nome, capacidade, ativa/inativa) + criar/editar (nome,
  capacidade, taxa opcional, regras de reserva).

Cada aba é um componente independente — adicionar uma configuração nova no futuro é uma aba nova,
sem tocar nas existentes.

Acesso à tela: mesmo guard de role já usado em `financeiro/page.tsx` (`ADMIN`/`SYNDIC`); `TECH`/
`READER` não veem a entrada de menu e são bloqueados se acessarem a rota direto.

## Testes

- Backend: unit test de validação por categoria (`TicketSlaSettings`/`CommonAreaRules` rejeitando
  formato inválido), upsert de `organization_settings` (cria na primeira vez, atualiza depois,
  isolamento por `organization_id`), CRUD de `common_area` (criar, atualizar, desativar, listar só
  da própria organização), e negação de acesso para `TECH`/`READER` nos quatro endpoints.
- Frontend: `tsc --noEmit`/`npm run build` limpos; teste de componente ou Playwright da tela nova
  fica a critério de quem implementar, seguindo o padrão já usado nas telas recentes (`financeiro`,
  `chamados`).

## O que fica para depois (fora desta entrega, mas já desenhado para encaixar)

- `ResidentTicket` ganhar prioridade + prazo calculado a partir de `TICKETS_SLA`, e alerta de
  atraso.
- Fluxo de reserva de área comum (pedido, aprovação, bloqueio de agenda) consumindo `common_area` e
  suas `rules`.
- Cobrança real da taxa de área comum (hoje só informativa) — se um dia for automatizada, decidir
  se via lançamento no módulo Financeiro ou cobrança Asaas, nessa ordem de avaliação.
- Novas categorias em `organization_settings` (ex.: notificações) — só precisam de um novo valor no
  enum de categoria + DTO de validação, sem migration.
