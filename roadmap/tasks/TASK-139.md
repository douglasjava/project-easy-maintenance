# TASK-139 — Backend: Expor manutenções canceladas na consulta/detalhe do item

## Tipo
BACKEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟡 Médio

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — o ponto tecnicamente mais delicado do épico (ver Riscos): errar aqui pode vazar canceladas em
lugares que não deveriam considerá-las (export, KPIs).

---

## Contexto

`Maintenance` tem `@SQLRestriction("deleted_at IS NULL")` — uma restrição global do Hibernate que já
filtra canceladas de **toda** query JPA por padrão (`findById`, `findAll`, specifications, etc.),
sem precisar de `WHERE deleted_at IS NULL` explícito em lugar nenhum. Isso é o comportamento certo
pra praticamente todo o resto do sistema (listagem padrão, export CSV, KPIs do dashboard) — o
problema é que essa mesma restrição impede qualquer query de "mostrar canceladas também" sem um
mecanismo explícito de bypass.

---

## Objetivo

Permitir consultar as manutenções canceladas de um item — sem alterar o comportamento padrão (sem
`includeCancelled`, continua tudo igual: só válidas).

---

## Escopo

### 1. Mecanismo de bypass da restrição

Avaliar e escolher **uma** abordagem (documentar a escolha na Implementação):
- **Hibernate `@Filter`** (`@FilterDef`/`@Filter` na entidade, habilitado/desabilitado por sessão) —
  mais idiomático, mas exige atenção para não vazar pra outras queries que compartilham a mesma
  `Session`/transação.
- **Query nativa** (`@Query(nativeQuery = true)` ignorando o `@SQLRestriction`, que só se aplica a
  queries JPQL/Criteria geradas pelo Hibernate) — mais simples e isolado, only afeta o método
  específico.
- Recomendação inicial: query nativa dedicada (ex.:
  `MaintenanceRepository.findCancelledByItemIdNative(itemId)`), por ser mais fácil de auditar e não
  correr risco de vazar pra outras queries da mesma sessão.

### 2. Endpoint/parâmetro

- Novo parâmetro `includeCancelled` (boolean, default `false`) em `GET
  /items/{itemId}/maintenances` (ou endpoint dedicado `GET
  /items/{itemId}/maintenances/cancelled`, mais explícito e mais fácil de restringir separadamente
  se no futuro precisar de outra permissão) — decidir durante a implementação qual é mais coerente
  com o padrão já usado nos outros filtros de `MaintenancesController`.
- `MaintenanceResponse` ganha campos novos: `cancelled` (boolean), `cancelReason`, `cancelledAt`,
  `cancelledBy` (ou nome resolvido do usuário, mesmo padrão de resolução em batch já usado em
  `TASK-104` para "Registrado por").

### 3. Garantir que canceladas **não** vazam nos outros fluxos

- `GET /maintenances` (listagem padrão) — confirmar que continua sem canceladas (comportamento já
  deveria ser esse por causa do `@SQLRestriction`, mas testar explicitamente).
- `GET /maintenances/export` (CSV) — confirmar que export não inclui canceladas.
- KPIs do dashboard que dependem de manutenções (`MaintenanceItemService`/`dashboard` module) —
  levantar se algum cálculo usa `Maintenance` diretamente e confirmar que não é afetado.

### 4. Testes

- `includeCancelled=false` (ou omitido) → resposta idêntica ao comportamento atual, nenhuma
  cancelada aparece.
- `includeCancelled=true` → canceladas aparecem, com `cancelReason`/`cancelledAt`/`cancelledBy`
  preenchidos, junto com as válidas (ou em lista separada, conforme decisão de shape do DTO).
- Export CSV e listagem padrão nunca incluem canceladas, independente do parâmetro novo.

---

## Arquivos impactados (estimativa)

### Backend
- `assets/domain/Maintenance.java` — nenhuma mudança de schema (campos já vêm da TASK-137), mas
  pode precisar de mapeamento extra se optar por `@Filter`
- `assets/infrastructure/persistence/MaintenanceRepository.java` — novo método de busca incluindo
  canceladas (query nativa ou filtro)
- `assets/application/service/MaintenanceService.java` — novo método/parâmetro em `findById`/`list`
- `assets/application/dto/MaintenanceResponse.java` — novos campos (`cancelled`, `cancelReason`,
  `cancelledAt`, `cancelledBy`)
- `assets/infrastructure/web/MaintenancesController.java` — novo parâmetro/endpoint

---

## Critérios de Aceite

- [ ] É possível consultar as manutenções canceladas de um item via parâmetro/endpoint explícito
- [ ] Comportamento padrão (sem pedir canceladas) não muda em nada
- [ ] Export CSV (`/maintenances/export`) nunca inclui canceladas
- [ ] KPIs do dashboard que usam `Maintenance` confirmados como não afetados (ou corrigidos, se
      alguma dependência inesperada for encontrada)
- [ ] Testes cobrindo os 3 cenários acima

## Dependências
- **TASK-137** — precisa dos campos `cancelReason`/`cancelledAt`/`cancelledBy` existirem.
- Pode andar em paralelo com a **TASK-138**.

## Riscos
- É o ponto mais delicado tecnicamente do épico: um bypass malfeito da `@SQLRestriction` pode vazar
  canceladas em queries que não deveriam vê-las (export, KPIs) — validar explicitamente esses fluxos
  em teste, não só o caminho feliz do novo parâmetro.

## Esforço
Médio (a parte de investigação/decisão do mecanismo de bypass pesa mais que a implementação em si)

## Status
**Concluída** — implementado na branch `feature/EPIC-016-cancel-maintenance-reason`, 702/702 testes
backend green à época (713/713 na suíte final do épico). QA manual aprovado (C5, roteiro corrigido
para refletir o endpoint dedicado escolhido aqui em vez de `includeCancelled`). Commitado, com PR
aberto para `staging`.

## Implementação

- **Mecanismo escolhido**: query nativa (`findCancelledByItemId`), como recomendado no card —
  `SELECT * FROM maintenances WHERE item_id = :itemId AND deleted_at IS NOT NULL`. Nenhum
  `@Filter`/`@FilterDef` novo na entidade.
- **Endpoint dedicado**, não parâmetro: `GET /items/maintenances/cancelled?itemId=X` — decisão pela
  opção que o próprio card sugeria como alternativa, pra não tocar em nada da paginação por cursor já
  complexa de `GET /maintenances`. Sem paginação própria (view de auditoria, volume baixo esperado).
- `MaintenanceResponse` ganhou `cancelled`/`cancelReason`/`cancelledAt`/`cancelledBy` — refatorei
  `withItemType` pra ter uma variante de valor único (`String`) além da de mapa, reaproveitada tanto
  por `findById` quanto pelo novo `findCancelledByItem`, evitando duplicar a reconstrução do record.
- **Achado de segurança real, fora do escopo original da task**: `findForExport`,
  `findForExportCrossOrg` (export CSV) e `avgDaysToResolveLast90` (KPI do dashboard) são **queries
  nativas**, que `@SQLRestriction` **não** filtra (a restrição só intercepta JPQL/Criteria gerado
  pelo Hibernate) — nenhuma das três tinha `deleted_at IS NULL` no `WHERE`. Antes da TASK-137 isso
  era inofensivo (nunca existia uma manutenção cancelada); a partir de agora, sem essa correção, o
  export e o KPI de dias-pra-resolver **vazariam manutenções canceladas de verdade**. Corrigido nas
  três queries. Não é possível cobrir isso com teste automatizado — não há `@DataJpaTest` neste
  repositório (mesma lacuna já sinalizada em tasks anteriores do EPIC-015); validação fica por conta
  do cenário C5 da TASK-QA-MAN-011.
- Testes novos em `MaintenanceCancelledListingTest.java` (novo arquivo): retorno com
  motivo/autor/data, lista vazia, isolamento multi-tenant, e regressão confirmando que manutenções
  válidas continuam com `cancelled=false` depois da mudança no DTO.

### Addendum (durante a TASK-141): resolução de nome de quem cancelou

`cancelledBy` original desta task era só o ID cru — a TASK-141 (frontend, exibir "quem cancelou")
deixou claro que isso precisava virar nome, não um número. Adicionado agora, nesta mesma task por
ser extensão direta:
- Novo campo `cancelledByName` em `MaintenanceResponse`.
- `MaintenanceService.findCancelledByItem` ganhou `UserRepository` como dependência e resolve os
  nomes em lote (`resolveUserNames`), mesmo padrão exato de
  `MaintenanceExportService.resolveUserNames` (TASK-104) — evita N+1. Fallback `"—"` quando o
  usuário não é encontrado (removido, por exemplo).
- 1 teste novo cobrindo o fallback de nome não resolvível.
