# TASK-036 — Paginação cursor-based em listagens grandes

## Tipo
Performance / Escalabilidade

## Categoria
Backend / Performance

## Prioridade
🔵 Baixo

## Fase
3 — Escala

## Épico
EPIC-007 — Performance e Escalabilidade

## Descrição
A paginação atual usa `OFFSET/LIMIT` via Spring Data Pageable. Para páginas tardias (ex: página 50 de 5.000 itens),
o banco precisa contar e pular 4.950 registros antes de retornar os 50 corretos — performance degrada proporcionalmente.

Cursor-based pagination usa um campo ordenado (ex: `id` ou `created_at`) como referência, eliminando o OFFSET.

## Critérios de Aceite
- [x] Endpoints de listagem de `maintenance_items` e `maintenances` suportam cursor pagination
- [x] Resposta inclui `nextCursor` para paginação forward
- [x] Backward pagination (para "voltar página") suportada opcionalmente via `prevCursor`
- [x] Frontend migrado para usar cursor em vez de número de página para listagens longas
- [x] OFFSET pagination mantida como fallback para primeira página (sem cursor)

## Implementação
- `CursorPageResponse<T>` — DTO unificado com `nextCursor`, `prevCursor`, `hasMore` + campos OFFSET como sentinels (-1 em cursor mode)
- `MaintenanceItemService.findAllCursor()` — cursor stack: forward (id > cursor), backward (id < prevCursor), OFFSET fallback
- `MaintenanceService.listByItemCursor()` — mesma lógica para manutenções
- `ItemsController.list()` — migrado para `CursorPageResponse`, params `cursor`/`prevCursor`/`size`
- `MaintenancesController.list()` — migrado para `CursorPageResponse`, params `cursor`/`prevCursor`/`size`
- `items/page.tsx` — cursor stack state, navegação Anterior/Próximo sem Pagination component
- `maintenances/page.tsx` — cursor stack para lista principal e combo de itens; filtros resetam cursor

## Esforço
Médio (1-2 dias)

## Status
Concluído
