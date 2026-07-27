# TASK-138 — Backend: Recálculo do item após cancelamento de manutenção

## Tipo
BACKEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟠 Alto

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — é a peça que garante que o cancelamento não deixa o item com um cronograma de compliance
errado. Se essa lógica falhar, o cancelamento "resolve" o cadastro errado mas quebra o item de outro
jeito.

---

## Contexto

`MaintenanceService.register()` recalcula `nextDueAt`/`lastPerformedAt`/`status` do item toda vez
que uma manutenção é registrada (`item.setNextDueAt(req.performedAt().plus(period))`, via
`serviceBase.resolvePeriod(item)` + `StatusCalculator.calculate(...)`). Depende da TASK-137 existir
(precisa ter um cancelamento acontecendo pra recalcular depois dele).

Regra de negócio definida (RN-016-03/04): recalcular a partir da manutenção **válida (não
cancelada) mais recente por `performedAt`** — não necessariamente "a próxima que for cadastrada". Se
não sobrar nenhuma manutenção válida, o item volta ao estado "sem manutenção registrada" (o mesmo
estado anterior à primeira manutenção do item — `nextDueAt`/`lastPerformedAt` como vieram da criação
do item).

Exemplo que a lógica precisa cobrir corretamente: item tem M1 (válida, jan), M2 (errada, fev, será
cancelada) e M3 (válida, mar) já registradas nessa ordem. Cancelar M2 deve recalcular a partir de M3
(a mais recente válida por data), não gerar um estado intermediário baseado em M1 nem esperar um
novo cadastro.

---

## Objetivo

Depois de um cancelamento, deixar o item (`nextDueAt`, `lastPerformedAt`, `status`) exatamente como
estaria se a manutenção cancelada nunca tivesse existido.

---

## Escopo

### 1. Serviço de recálculo

- Novo método (ex.: `MaintenanceItemService.recalculateFromValidMaintenances(itemId)` ou dentro do
  próprio `MaintenanceService.cancel(...)` da TASK-137) chamado logo após o soft-delete:
  1. Busca a manutenção válida (`deleted_at IS NULL`) mais recente do item, ordenada por
     `performedAt DESC` (desempate por `id DESC` se houver mais de uma na mesma data).
  2. Se existir: reaplica a mesma lógica de `register()` — `lastPerformedAt = essa.performedAt`,
     `nextDueAt = essa.performedAt + resolvePeriod(item)`, `status =
     StatusCalculator.calculate(nextDueAt)`.
  3. Se não existir nenhuma: reverte `lastPerformedAt`/`nextDueAt` para os valores originais do
     item (o estado anterior à primeira manutenção — conferir na TASK-030/criação de item qual é
     exatamente esse valor inicial, provavelmente os campos enviados na criação do item, possivelmente
     `null`).
- Extrair a lógica de "calcular nextDueAt a partir de uma manutenção" que hoje está inline em
  `register()` para um método privado/utilitário reaproveitável pelos dois fluxos (registrar e
  cancelar) — evita duplicar a regra e ela divergir com o tempo.

### 2. Testes (o coração desta task)

- Cancelar a única manutenção do item → item volta ao estado "sem manutenção registrada".
- Cancelar a manutenção mais recente, havendo uma anterior válida → recalcula a partir da anterior.
- Cancelar uma manutenção do meio, havendo uma mais recente válida depois dela (cenário M1/M2/M3
  do Contexto) → recalcula a partir da mais recente (M3), não da anterior à cancelada (M1).
- Cancelar uma manutenção que não é a mais recente nem afeta o estado atual do item (ex.: cancelar
  M1 quando M3 já é a válida mais recente) → estado do item não muda.

---

## Arquivos impactados (estimativa)

### Backend
- `assets/application/service/MaintenanceService.java` — extrair lógica de cálculo de
  `nextDueAt`/`status`, reaproveitar no cancelamento
- `assets/application/service/MaintenanceItemService.java` — possível novo método de recálculo, se
  optar por colocar essa responsabilidade aqui em vez de `MaintenanceService`
- `assets/infrastructure/persistence/MaintenanceRepository.java` — novo método de busca (ex.:
  `findTopByItemIdOrderByPerformedAtDesc` ou via `Specification` reaproveitando `MaintenanceSpecs`)

---

## Critérios de Aceite

- [ ] Cancelar a única manutenção do item reverte `nextDueAt`/`lastPerformedAt`/`status` para o
      estado "sem manutenção registrada"
- [ ] Cancelar a manutenção mais recente recalcula a partir da manutenção válida imediatamente
      anterior
- [ ] Cancelar uma manutenção do meio do histórico, havendo uma válida mais recente depois dela,
      recalcula a partir dessa mais recente — não da anterior à cancelada
- [ ] Cancelar uma manutenção que não afeta o estado atual do item não altera `nextDueAt` já correto
- [ ] Lógica de cálculo de `nextDueAt` compartilhada entre registro e cancelamento (sem duplicação)
- [ ] Testes cobrindo os 4 cenários acima

## Dependências
- **TASK-137** — precisa existir um cancelamento pra recalcular depois dele.

## Riscos
- Este é o ponto do épico com maior risco de regressão silenciosa — um recálculo errado deixa o
  item com uma data de compliance incorreta sem nenhum sintoma óbvio na tela (o item só vai parecer
  "OK" ou "vencido" no lugar errado). Cobertura de teste dos cenários fora de ordem (M1/M2/M3) não é
  opcional.

## Esforço
Médio (a lógica em si é pequena, o cuidado está nos testes de borda)

## Status
**Concluída** — implementado na mesma branch da TASK-137 (`feature/EPIC-016-cancel-maintenance-reason`),
698/698 testes backend green à época (713/713 na suíte final do épico). QA manual aprovado.
Commitado, com PR aberto para `staging`.

## Implementação

- `MaintenanceRepository.findFirstByItemIdOrderByPerformedAtDescIdDesc(itemId)` — nova query
  derivada; não precisou de query nativa (diferente da TASK-137) porque aqui o comportamento
  correto É respeitar `@SQLRestriction` (nunca considerar canceladas), que é o padrão automático.
- Lógica de "aplicar uma manutenção ao item" extraída de `register()` para
  `applyPerformedMaintenance(item, performedAt)`, reaproveitada pelo recálculo do cancelamento —
  critério de aceite "sem duplicação" atendido. **Comportamento pré-existente preservado
  deliberadamente**: quando `resolvePeriod(item)` retorna `null`, `nextDueAt` fica como estava
  (não é zerado) — isso já era assim em `register()` antes da extração, não é uma decisão nova desta
  task.
- **Achado durante a implementação**: o "estado original antes da primeira manutenção" citado na
  RN-016-04 não é literalmente recuperável — `register()` sobrescreve `lastPerformedAt` do item a
  cada chamada, então depois de pelo menos uma manutenção, o valor de criação do item já foi perdido.
  `resetToNeverPerformedState` usa a mesma fórmula de `MaintenanceItemService.create()` para item sem
  `lastPerformedAt` informado (base = hoje) — a aproximação mais correta disponível, documentada
  explicitamente no código, não assumida silenciosamente.
- **Novo teste de regressão** `MaintenanceRegisterCalculationTest.java` — não havia nenhum teste de
  `register()` antes desta task; como a extração tocou nesse método, adicionei 2 testes travando o
  comportamento (com e sem período configurado) antes de mexer no código.
- 5 novos testes em `MaintenanceCancelTest.java` cobrindo os 4 cenários pedidos (sem remanescente,
  mais recente, cenário M1/M2/M3 fora de ordem, cancelamento que não muda o estado atual) + variante
  sem período configurado.
