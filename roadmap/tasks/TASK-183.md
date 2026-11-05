# TASK-183 — Backend: corrige `nextDueAt`/`customPeriod*` divergente em itens REGULATORY do onboarding por IA

## Tipo
BUGFIX

## Categoria
Onboarding por IA / Correção de Dado

## Prioridade
🔴 Crítico

## Épico
[EPIC-025](../epics/EPIC-025.md) — Conteúdo e Governança das Normas Técnicas

## QA obrigatório
Sim — teste automatizado cobrindo o caso exato do bug (item REGULATORY criado via
`AiBootstrapService.apply()` com período do JSON divergente do período real da norma vinculada) +
QA manual criando um item via `/ai-onboarding` e conferindo `nextDueAt` na tela.

---

## Contexto

Spec completa: `docs/superpowers/specs/2026-08-20-onboarding-catalog-filter-design.md`.

**Bug encontrado durante a auditoria do fluxo de IA (independente das outras tasks desta leva —
pode ser implementada e mergeada sem esperar TASK-181/182/184)**: em
`AiBootstrapService.processItem()`, quando o `itemType` gerado pela IA bate com uma norma curada
existente (`itemCategory = REGULATORY`), o `nextDueAt` gravado no `MaintenanceItem` é calculado por
`IAiBootstrapMapper.calculateNextDueAt()` a partir do período que **a IA inventou no JSON**, não do
período real da `Norm` vinculada (`normId`).

Isso diverge do fluxo manual de criação de item (`MaintenanceItemService.create()`), que sempre usa
`ServiceBase.resolvePeriod()` — busca o período real da norma quando `itemCategory == REGULATORY`.
Um item pode nascer citando corretamente "ABNT NBR 5419" mas com data de vencimento calculada por
um número divergente da periodicidade real da norma. Autocorrige na primeira manutenção registrada
(`register()` recalcula certo), mas até lá o dashboard mostra vencimento errado logo na primeira
experiência do cliente novo — momento mais sensível de todos.

Confirmado também: `IMaintenanceItemMapper` (fluxo manual) zera `customPeriodUnit`/`customPeriodQty`
quando o item é REGULATORY (`request.itemCategory().isOperational() ? ... : null`) — o fluxo de IA
não replica essa convenção, deixando dado morto/enganoso salvo.

## Objetivo

Fazer `AiBootstrapService.processItem()` convergir pro mesmo caminho de cálculo já usado e testado
no fluxo manual, eliminando a divergência.

## Escopo

Em `AiBootstrapService.processItem()`, depois de resolver `normId`/`itemCategory` (lógica
existente, sem mudança nesta task):

```java
// 3. Criar MaintenanceItem
MaintenanceItem maintenanceItem = IAiBootstrapMapper.INSTANCE.toMaintenanceItem(item, organizationCode, normId, itemCategory);

// NOVO: para REGULATORY, converge com o fluxo manual — período real da norma, não o do JSON
if (itemCategory == ItemCategory.REGULATORY) {
    maintenanceItem.setCustomPeriodUnit(null);
    maintenanceItem.setCustomPeriodQty(null);
    Period period = serviceBase.resolvePeriod(maintenanceItem);
    maintenanceItem.setNextDueAt(period != null ? LocalDate.now().plus(period) : null);
}

maintenanceItem = maintenanceItemRepository.save(maintenanceItem);
```

`ServiceBase` precisa ser injetada em `AiBootstrapService` (novo `@RequiredArgsConstructor` field).
Base é `LocalDate.now()` — item recém-criado, ainda sem `lastPerformedAt`, mesma convenção já usada
em `MaintenanceItemService.create()` e em `resetToNeverPerformedState()`.

Sem mudança em `IAiBootstrapMapper.calculateNextDueAt()` em si — ela continua existindo e sendo
usada como valor provisório pra itens OPERATIONAL (onde o período vem legitimamente do que a IA/
usuário informou, não de uma norma).

## Critérios de Aceite

- [x] Item REGULATORY criado via `apply()` tem `nextDueAt` calculado a partir do período real da
      `Norm` vinculada, não do período do JSON recebido
- [x] Item REGULATORY criado via `apply()` tem `customPeriodUnit`/`customPeriodQty` nulos
- [x] Item OPERATIONAL criado via `apply()` continua usando o período do JSON normalmente (sem
      regressão)
- [x] Teste cobrindo especificamente: período do JSON = X, período real da norma = Y (X ≠ Y),
      `nextDueAt` bate com Y
- [x] `mvn test` sem regressão (764 testes, 0 falhas)

## Dependências
Nenhuma — pode ser implementada e mergeada independentemente das outras tasks desta leva
(TASK-181/182/184/185). Recomendado priorizar primeiro por ser correção de dado, não feature nova.

## Riscos
Baixo — mudança isolada e pequena, convergindo pro mesmo caminho já testado do fluxo manual
(`ServiceBase.resolvePeriod()`), sem lógica de cálculo nova.

## Esforço
Baixo

## Status
✅ Implementada e commitada (20/08/2026) na branch `feature/ai-onboarding-catalog-filter`
(`easy-maintenance-api`) — mesma branch que reúne toda a Fase 2 (TASK-181 a TASK-185). PR
[#40](https://github.com/douglasjava/easy-maintenance-api/pull/40) aberta em 21/08/2026.
