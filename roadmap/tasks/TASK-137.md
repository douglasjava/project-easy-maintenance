# TASK-137 — Backend: Endpoint de cancelamento de manutenção com motivo obrigatório

## Tipo
BACKEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟠 Alto

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — mexe diretamente no histórico de compliance que é o núcleo do produto; erro aqui tem
consequência direta pra confiabilidade dos dados do cliente.

---

## Contexto

`Maintenance` já tem soft-delete pronto (`@SQLDelete(sql = "UPDATE maintenances SET deleted_at =
now() WHERE id = ?")` + `@SQLRestriction("deleted_at IS NULL")`), mas nenhum endpoint aciona isso —
`MaintenancesController` só tem `POST` (registrar) e `GET` (ler/listar/exportar). Hoje não existe
nenhuma forma de corrigir uma manutenção cadastrada errada.

Esta task cobre só o **cancelamento em si** (persistência do motivo + soft-delete + validações). O
recálculo do item (`nextDueAt`/`lastPerformedAt`/`status`) é a TASK-138, propositalmente separada
pra manter esta task focada e testável isoladamente.

---

## Objetivo

Criar um endpoint que permita cancelar uma manutenção já registrada, exigindo motivo obrigatório e
registrando quem cancelou e quando — sem apagar o registro fisicamente.

---

## Escopo

### 1. Migration (V84)

Nova migration adicionando à tabela `maintenances`:
- `cancelled_at` (`TIMESTAMP`, nullable)
- `cancelled_by` (`BIGINT`, nullable, sem `@ManyToOne` — mesmo padrão de `created_by`/`updated_by`
  já usado nessa mesma tabela, ver TASK-103)
- `cancel_reason` (`TEXT`, nullable)

Não reaproveitar `deleted_at`/`updated_by` genéricos pra isso — eles já têm semântica própria
(soft-delete técnico e "quem editou por último", respectivamente); `cancel_reason` precisa de campo
próprio porque é a peça central do compliance desta feature (é o que documenta *por que* foi
cancelado).

### 2. Endpoint de cancelamento

- `POST /easy-maintenance/api/v1/items/{itemId}/maintenances/{maintenanceId}/cancel` (ou
  equivalente RESTful — decidir durante a implementação se cancelamento é melhor modelado como
  `POST .../cancel` com corpo `{ "reason": "..." }` ou como `DELETE` com motivo via query
  param/corpo; `POST .../cancel` é mais expressivo pra uma ação que não é uma deleção real).
- Corpo da requisição: `{ "reason": string }` — motivo obrigatório, validado (`@NotBlank`, tamanho
  mínimo razoável pra evitar "x" como motivo — ex.: mínimo 5 caracteres).
- Regras de validação:
  - Manutenção precisa existir e pertencer à organização do usuário autenticado (mesmo padrão de
    `validateOrganization` já usado em `MaintenanceService`).
  - Manutenção já cancelada → rejeitar com `ConflictException` (409) — idempotência (RN-016-06).
  - Motivo ausente/vazio → `400` via validação Bean Validation padrão do projeto.
- Persistir `cancelledAt = Instant.now()`, `cancelledBy = currentUserId`, `cancelReason = reason`,
  então acionar o soft-delete (`maintenanceRepository.delete(maintenance)` — o `@SQLDelete` já
  cuida de popular `deleted_at`).

### 3. Restrição de papel (ADMIN/SYNDIC)

- Confirmar durante a implementação qual é o mecanismo de controle de acesso por papel já usado no
  sistema (não há `@PreAuthorize` em uso hoje nos controllers de `assets` — verificar se a
  autorização é feita via filtro/interceptor próprio, ou se precisa ser adicionada aqui pela
  primeira vez nesse módulo).
- TECH não deve conseguir cancelar. Se o mecanismo de enforcement por papel não existir ainda pra
  esse controller, avaliar com Douglas se vale bloquear aqui de forma pontual (ex.: checagem manual
  do papel do usuário autenticado) em vez de esperar uma solução genérica.

### 4. Testes

- Cancelamento bem-sucedido: `deleted_at`/`cancelled_at`/`cancelled_by`/`cancel_reason`
  preenchidos corretamente.
- Motivo vazio/ausente → 400.
- Cancelar manutenção já cancelada → 409.
- Cancelar manutenção de outra organização → 403/404 (mesmo padrão de isolamento multi-tenant já
  usado nos outros endpoints de `assets`).
- Cancelar sem papel autorizado (se o mecanismo de enforcement for implementado nesta task) → 403.

---

## Arquivos impactados (estimativa)

### Backend
- `src/main/resources/db/migration/V84__add_cancel_fields_to_maintenances.sql` — **novo**
- `assets/domain/Maintenance.java` — adicionar `cancelledAt`, `cancelledBy`, `cancelReason`
- `assets/application/service/MaintenanceService.java` — novo método `cancel(orgId, itemId,
  maintenanceId, reason)`
- `assets/application/dto/CancelMaintenanceRequest.java` — **novo** (`reason` com `@NotBlank`)
- `assets/infrastructure/web/MaintenancesController.java` — novo endpoint `POST
  .../maintenances/{maintenanceId}/cancel`

---

## Critérios de Aceite

- [ ] Endpoint cancela a manutenção, preenchendo `cancelled_at`/`cancelled_by`/`cancel_reason` e
      acionando o soft-delete existente (`deleted_at`)
- [ ] Motivo é obrigatório — requisição sem motivo retorna 400
- [ ] Cancelar uma manutenção já cancelada retorna 409, não duplica nem sobrescreve o cancelamento
      original
- [ ] Isolamento multi-tenant respeitado (não é possível cancelar manutenção de outra organização)
- [ ] Mecanismo de restrição por papel confirmado e aplicado (ou decisão documentada de adiar, se
      não houver padrão pronto no sistema para reaproveitar)
- [ ] Testes unitários cobrindo happy path + os 3 cenários de erro acima

## Dependências
Nenhuma — pode começar imediatamente.

## Riscos
- Se o padrão de restrição por papel não existir no sistema hoje, esta task pode precisar de escopo
  extra (criar o mecanismo) ou de uma decisão explícita de produto pra adiar essa trava — não deixar
  isso implícito, documentar a decisão tomada na seção de Implementação ao final.

## Esforço
Médio (migration + endpoint + validações + testes; a incerteza está na restrição por papel)

## Status
**Concluída** — implementado e testado na branch `feature/EPIC-016-cancel-maintenance-reason`
(a partir de `staging`), 713/713 testes backend green (inclui os três bugfixes achados no QA
manual, ver Implementação — persistência dos campos de cancelamento, constraint UNIQUE que
bloqueava reaproveitar o dia após cancelar, e checagem de duplicidade do `register()` usando a
data errada). QA manual (TASK-QA-MAN-011) aprovado. Commitado, com PR aberto para `staging`.

## Implementação

- **Restrição por papel**: seguiu o padrão manual já existente em `TeamMemberService.requireAdmin()`
  (não há `@PreAuthorize` no projeto) — `requireCancelPermission` bloqueia TECH/READER com
  `ForbiddenException`, permite ADMIN/SYNDIC.
- **Endpoint flat, não aninhado em `/items/{itemId}/...`**: `POST
  /items/maintenances/{maintenanceId}/cancel` — decidido durante a implementação por consistência
  com `GET /items/maintenances/{maintenanceId}` (`findById`), que também não exige `itemId` no path
  (deriva do próprio registro).
- **Achado de segurança fora do escopo original da task**: `@SQLRestriction("deleted_at IS NULL")`
  filtra automaticamente manutenções já canceladas de `findById`, então cancelar uma já cancelada
  naturalmente cairia em 404 em vez de 409. Resolvido com `existsCancelledByIdAndOrgCode` (query
  nativa) — com o filtro de organização **embutido na própria query**, não como checagem posterior,
  porque sem isso a diferença entre 404 e 409 vazaria pra um usuário de outra organização se um ID de
  manutenção alheia existe e foi cancelado.
- **Ordem de validação deliberada**: papel (barato, sem tocar banco) → existência/idempotência (404
  vs 409) → posse da organização (403) → persistência. Nenhuma informação vazada a quem não tem
  permissão, mesmo antes de saber se o recurso existe.
- 7 testes novos em `MaintenanceCancelTest.java` (novo arquivo — não havia teste de
  `MaintenanceService` no projeto ainda para nenhum método).
- **Não testado a nível HTTP** (motivo ausente/curto): validação é só `@NotBlank`/`@Size` no
  DTO + `@Valid` no controller — comportamento garantido pelo framework, sem teste dedicado, mesmo
  padrão já usado para `RegisterMaintenanceRequest` neste projeto (nenhum DTO de `assets` tem teste
  de binding HTTP hoje).
- **Correção (achada na TASK-140)**: o código HTTP real de `@Valid @RequestBody` inválido neste
  projeto é `422 Unprocessable Entity` (`GlobalExceptionHandler.handleMethodArgumentNotValidException`),
  não `400` como documentado acima no Escopo/Critérios originais — a mensagem específica do campo
  vem em `response.data.violations[]`, não em `response.data.detail`.
- **BUGFIX crítico achado no QA manual (TASK-QA-MAN-011, cenário C1)**: `cancel()` não persistia
  `cancelled_at`/`cancelled_by`/`cancel_reason` — só `deleted_at` (soft delete) era gravado. Causa
  raiz: dentro da mesma transação, `maintenanceRepository.save(maintenance)` seguido de
  `maintenanceRepository.delete(maintenance)` faz o Hibernate descartar o UPDATE de dirty-checking
  da entidade assim que ela é marcada como removida no mesmo ciclo de flush — como `@SQLDelete`
  substitui o DELETE real por um UPDATE que só toca `deleted_at`, os outros campos setados em
  memória nunca chegavam a ser persistidos. `save()` sozinho não falha nem loga nada, então o bug
  passou pelos 7 testes originais de `MaintenanceCancelTest` (Mockito só verifica o objeto Java em
  memória, nunca exercita flush/dirty-checking reais — não pega esse tipo de bug estrutural).
  Corrigido trocando `save()` por `saveAndFlush()` antes do `delete()`, forçando o UPDATE a rodar
  enquanto a entidade ainda está no estado gerenciado normal. Reproduzido e confirmado com teste
  novo de persistência real (`MaintenanceCancelPersistenceTest`, `@DataJpaTest` + H2, escopado a
  `Maintenance`/`MaintenanceRepository` via `@EntityScan`/`@EnableJpaRepositories` pra não colidir
  com uma query de `InAppNotificationRepository` incompatível com H2). Suíte completa revalidada:
  708/708 verde após o fix (adicionado teste de persistência + dependência de teste H2 em `pom.xml`).
  `MaintenanceCancelTest` ajustado para verificar `saveAndFlush` em vez de `save`.
- **Segundo bug crítico achado no mesmo ciclo de QA manual (C1)**: depois do fix acima, cancelar
  funcionava, mas registrar uma NOVA manutenção pro mesmo item no mesmo dia (depois de cancelar a
  anterior) falhava com `409` — `Duplicate entry` do MySQL. Causa raiz: a constraint
  `uq_maint_item_date (item_id, performed_at)` (migration V24, criada bem antes do recurso de
  cancelamento existir) não considera `deleted_at` — soft-delete não remove a linha fisicamente,
  então ela continua "ocupando" aquele par (item, dia) pra sempre, mesmo cancelada. A checagem de
  aplicação (`existsByItemIdAndPerformedAt`) já estava correta (é JPQL, respeita
  `@SQLRestriction("deleted_at IS NULL")` automaticamente) — o erro vinha direto do banco, na hora
  do `INSERT`. Confirmado reproduzindo contra o MySQL local real do projeto (`docker exec` numa
  tabela de teste) antes de decidir a correção.
  Solução considerada e descartada: coluna gerada (`GENERATED ALWAYS AS (IF(deleted_at IS NULL, 0,
  id))`) — MySQL proíbe coluna gerada referenciar coluna `AUTO_INCREMENT` (erro 3109), confirmado
  também contra o MySQL real.
  Solução aplicada (`V85__fix_maintenance_unique_constraint_ignore_cancelled.sql`): troca a
  constraint por `UNIQUE (item_id, performed_at, active_dedup_key)`, onde `active_dedup_key` é uma
  coluna comum (não gerada) que toda manutenção ativa mantém em `0` (preserva a unicidade original
  entre ativas) e que `cancel()` seta para o próprio `id` no momento do cancelamento (nunca colide
  com outra linha, ativa ou cancelada). Migration inclui backfill das linhas já canceladas antes
  dela. Validado de ponta a ponta contra o MySQL real (cenário completo: registrar → cancelar →
  registrar de novo no mesmo dia → OK; registrar uma segunda ATIVA duplicada → continua bloqueado).
  Testes novos: `MaintenanceUniqueConstraintMigrationTest` (H2 puro, prova a constraint antiga
  falhando e a nova funcionando) e `existsByItemIdAndPerformedAt_ignoresCancelledMaintenance` em
  `MaintenanceCancelPersistenceTest`. Suíte completa revalidada: 711/711 verde.
- **Terceiro bug achado no mesmo ciclo de QA manual (C2)**: ao tentar registrar M1 com
  `performedAt` no passado (necessário pro cenário de recálculo do C2), o registro falhava com
  `409 Duplicate` mesmo sem existir NENHUMA manutenção na data informada — bastava existir
  qualquer outra manutenção do item com `performed_at` = **hoje** (data do sistema, não relacionada
  à data sendo registrada). Causa raiz: `register()` chamava
  `existsByItemIdAndPerformedAt(itemId, LocalDate.now())` — conferia a data de HOJE — em vez de
  `existsByItemIdAndPerformedAt(itemId, req.performedAt())`, a data que o usuário está de fato
  registrando. Bug pré-existente, não introduzido nesta sessão, mas só veio à tona porque o cenário
  de QA (C2) foi o primeiro a exercitar `performedAt` diferente de hoje.
  Os 2 testes que já cobriam `register()` (`MaintenanceRegisterCalculationTest`, criados na
  TASK-138) nunca pegaram isso porque os dois usam `performedAt = LocalDate.now()`, onde a data
  errada e a certa coincidem por acidente. Corrigido trocando `LocalDate.now()` por
  `req.performedAt()` na checagem. 2 testes novos: um prova que registrar no passado funciona
  mesmo com outra manutenção do item cravada em "hoje" (sem stub para `LocalDate.now()` — se o
  código voltar a usar a data errada, o teste falha por `UnnecessaryStubbing`/argumento não
  batendo, não só pela asserção); outro confirma que o 409 real (mesma data já usada) continua
  funcionando. Suíte completa revalidada: 713/713 verde.
