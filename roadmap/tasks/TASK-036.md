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
A paginação atual usa `OFFSET/LIMIT` via Spring Data Pageable. Para páginas tardias (ex: página 50 de 5.000 itens), o banco precisa contar e pular 4.950 registros antes de retornar os 50 corretos — performance degrada proporcionalmente.

Cursor-based pagination usa um campo ordenado (ex: `id` ou `created_at`) como referência, eliminando o OFFSET.

## Critérios de Aceite
- [ ] Endpoints de listagem de `maintenance_items` e `maintenances` suportam cursor pagination
- [ ] Resposta inclui `nextCursor` para paginação forward
- [ ] Backward pagination (para "voltar página") suportada opcionalmente
- [ ] Frontend migrado para usar cursor em vez de número de página para listagens longas
- [ ] OFFSET pagination mantida como fallback para listagens pequenas

## Esforço
Médio (1-2 dias)

## Status
Backlog
