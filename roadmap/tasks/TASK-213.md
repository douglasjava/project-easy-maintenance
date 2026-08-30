# TASK-213 — BUGFIX Backend: editar `lastPerformedAt` não recalculava `nextDueAt` de verdade

## Tipo
BUGFIX

## Categoria
Backend / Itens (cálculo de próxima manutenção)

## Prioridade
🔴 Crítico

## Épico
Sem épico — achado por Douglas ao validar as normas/itens da TASK-212 em ambiente local, 30/08/2026.

## QA obrigatório
Sim — QA manual: editar um item existente mudando `lastPerformedAt` e conferir que `nextDueAt`
recalcula corretamente a partir da nova data (regulatório e operacional).

---

## Contexto

Douglas editou o item `INSPECAO DE EXTINTORES` (id=61, REGULATORY, norma de 12 meses), mudou
`lastPerformedAt` pra `2025-08-29` e esperava `nextDueAt = 2026-08-29`. Ficou `2026-06-04` — sem
mudar. Segundo exemplo: item com `lastPerformedAt = 2023-08-12` e `nextDueAt = 2025-08-12` (24
meses de diferença, numa norma de 12 meses).

## Causa raiz

`MaintenanceItemService.update()` calculava `nextDueAt` **antes** de aplicar o novo
`lastPerformedAt` do request:

```java
Period period = serviceBase.resolvePeriod(maintenanceItem);
if (period != null) {
    LocalDate base = Optional.ofNullable(maintenanceItem.getLastPerformedAt()).orElse(LocalDate.now());
    maintenanceItem.setNextDueAt(base.plus(period));
}
...
maintenanceItem.setLastPerformedAt(request.lastPerformedAt());  // tarde demais
```

`getLastPerformedAt()` lido pro cálculo ainda era o valor **antigo**, ainda carregado na entidade
vinda do banco — o novo valor só era aplicado depois. Resultado: `nextDueAt` sempre ficava calculado
em cima da data de *antes* da edição, nunca da nova.

`create()` já fazia na ordem certa (`setLastPerformedAt` antes de `resolvePeriod`). Confirmado via
`git show staging:...` que esse bug já existia em `staging` antes da TASK-212 — não foi introduzido
por ela, só ficou mais visível porque a TASK-212 fez a classificação REGULATORY funcionar de
verdade pela primeira vez.

## Objetivo

`update()` recalcula `nextDueAt` sempre a partir do `lastPerformedAt` **novo**, mesma ordem de
`create()`.

## Escopo

`MaintenanceItemService.update()`: move `maintenanceItem.setLastPerformedAt(request.lastPerformedAt())`
pra antes de `resolvePeriod()`/`setNextDueAt()`.

## Critérios de Aceite

- [x] `update()` recalcula `nextDueAt` a partir do `lastPerformedAt` novo do request
- [x] Teste novo (`MaintenanceItemUpdateNextDueAtTest`) comprova a regressão: falha sem o fix
      (reproduz exatamente o `2026-06-04` que Douglas viu), passa com ele
- [x] `mvn clean test` sem regressão (855/855, 0 falhas)
- [ ] QA manual em produção pós-deploy (pendente)

## Dado já afetado

Itens já salvos com `nextDueAt` desatualizado por esse bug (qualquer item editado antes deste fix,
mudando `lastPerformedAt`) continuam com o valor errado até serem editados de novo — não há
migration de dado, já que é ambiente de teste/baixo volume. Basta reabrir e salvar o item de novo
depois do deploy pra recalcular certo.

## Dependências
Nenhuma (achado durante validação da TASK-212, mas bug independente dela).

## Riscos
Baixo — mudança de ordem de duas linhas, sem novo comportamento além de corrigir o cálculo.

## Esforço
Baixo

## Status
Implementado na branch `feature/TASK-212-item-category-derived-from-type` (mesma branch/PR da
TASK-212, por conveniência — achado durante a mesma sessão de validação). Commit `228d2a7`, já no
PR [api#60](https://github.com/douglasjava/easy-maintenance-api/pull/60). Suíte completa: 855/855,
0 falhas.
