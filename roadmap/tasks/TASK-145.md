# TASK-145 — Backend: listar manutenções canceladas de uma organização num período (auditoria)

## Tipo
BACKEND

## Categoria
Relatórios / Compliance e Auditoria

## Prioridade
🟠 Alto

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — a TASK-QA-MAN-012 depende diretamente desta seção pra validar a "auditoria" do PDF.

---

## Contexto

O EPIC-016 já expõe manutenções canceladas, mas só **por item** (`GET
/items/maintenances/cancelled?itemId=X`). O Relatório de Prestação de Contas (TASK-146) precisa da
seção "Manutenções canceladas/corrigidas" de **toda a organização**, filtrada por período — não
existe hoje uma forma de consultar isso sem iterar item por item.

---

## Objetivo

Endpoint (ou extensão de um existente) que retorne as manutenções canceladas de uma organização
inteira, dentro de um intervalo de datas, com motivo/autor/data do cancelamento.

---

## Escopo

- Novo método em `MaintenanceRepository`: query nativa, seguindo o padrão de
  `findCancelledByItemId` (`SELECT * FROM maintenances WHERE deleted_at IS NOT NULL`), mas com
  `JOIN maintenance_items` para filtrar por `organization_code` + intervalo de `performed_at`.
  **Cuidado deliberado**: filtro de organização embutido na própria query (mesmo motivo já
  documentado na TASK-137 — não checagem posterior, pra não vazar dado cross-tenant).
- Endpoint: decidir durante a implementação se estende `GET /items/maintenances/cancelled` (tornando
  `itemId` opcional, adicionando `performedAtFrom`/`performedAtTo`) ou cria um novo `GET
  /maintenances/cancelled` sem o path de item — documentar a decisão tomada.
- Resposta reaproveita `MaintenanceResponse` (já tem `cancelReason`/`cancelledAt`/`cancelledBy`/
  `cancelledByName` da TASK-139/141) — sem DTO novo.
- Resolução de nome de quem cancelou em lote (mesmo padrão de `resolveUserNames`/`resolvedName` já
  usado em `MaintenanceService`) — não reintroduzir N+1.

---

## Critérios de Aceite

- [ ] Endpoint retorna manutenções canceladas de uma organização, filtradas por período
- [ ] Filtro de organização embutido na query (não checagem posterior) — sem vazamento cross-tenant
- [ ] `cancelReason`/`cancelledAt`/`cancelledBy`/`cancelledByName` presentes na resposta
- [ ] Sem N+1 na resolução de nomes de quem cancelou
- [ ] Testes cobrindo: happy path, período sem canceladas (lista vazia), isolamento multi-tenant

## Dependências
- TASK-139 (endpoint por item já existe, ponto de partida) — EPIC-016, concluída.

## Riscos
Nenhum risco técnico relevante além do já mapeado (isolamento multi-tenant na query).

## Esforço
Baixo/Médio (query nova + endpoint; reaproveita DTO e resolução de nomes já existentes)

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(a partir de `staging`, já com EPIC-016 mergeado). 719/719 testes backend green na suíte final do
épico. QA manual (TASK-QA-MAN-012) aprovado. Commitado, com PR aberto para `staging`.

## Implementação

- **Decisão tomada**: estendeu o endpoint existente (`GET /items/maintenances/cancelled`) em vez de
  criar um novo — `itemId` agora é opcional; quando omitido, `performedAtFrom`/`performedAtTo`
  (ambos obrigatórios juntos) buscam canceladas da organização inteira no período. Evita duplicar
  endpoint/DTO pra uma variação do mesmo conceito (canceladas), mantendo a superfície de API menor.
- **Query nativa** (`findCancelledByOrgAndPeriod`), mesmo motivo de `findCancelledByItemId` e
  `avgDaysToResolveLast90`: `@SQLRestriction` não se aplica a `nativeQuery`, então precisa do
  `deleted_at IS NOT NULL` explícito. Filtro de organização embutido via `JOIN maintenance_items` na
  própria query — não checagem posterior (mesmo cuidado da TASK-137/139).
- **Refactor**: extraído `enrichCancelled()` de `findCancelledByItem` — lógica de resolução de nome
  de quem cancelou + anexos/autores em lote (TASK-141/142) agora compartilhada entre as duas
  consultas de auditoria, sem duplicar ~25 linhas. `findCancelledByItem` resolve o tipo do item a
  partir do item já carregado (uma chamada); `findCancelledByOrganization` resolve em lote
  (`buildItemTypeMap`, mesmo helper já usado em `listByItem`/`listByItemCursor`), já que cada
  manutenção cancelada pode pertencer a um item diferente.
- Validação de período (`RuleException` se `performedAtFrom`/`performedAtTo` ausentes ou invertidas)
  segue o mesmo padrão já usado em `MaintenanceItemService` (calendário/export).
- 4 testes novos em `MaintenanceCancelledListingTest.java` (arquivo já existente da TASK-139):
  múltiplos itens diferentes na mesma organização, período vazio, datas ausentes, datas invertidas.
- **Teste adicional com banco real** (`MaintenanceCancelPersistenceTest`, H2 via `@DataJpaTest`):
  Mockito só prova que os parâmetros certos chegam no repositório, não que o `JOIN`/`WHERE` da query
  nativa está correto de verdade. Adicionado teste com duas organizações e datas dentro/fora do
  período, provando isolamento real (`MaintenanceItem` já cai no mesmo `@EntityScan` existente,
  mesmo pacote de `Maintenance`, sem precisar alargar o escopo do teste).
