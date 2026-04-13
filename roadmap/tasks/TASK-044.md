# TASK-044 — Eliminar N+1 de permissões na página de itens

## Tipo
FULL_STACK

## Categoria
Performance / API / Frontend

## Prioridade
🟡 Médio

## Fase
2 — Estabilização Pós-Lançamento

## Épico
EPIC-009 — Performance Frontend

## Descrição
A página `src/app/items/page.tsx` faz N+1 requisições HTTP para carregar a listagem de itens:
1. `GET /items` — lista paginada (1 requisição)
2. `GET /items/{id}/can-update` — verificação de permissão por item (N requisições)

Para a configuração padrão de 10 itens por página, isso resulta em **11 requisições HTTP** antes que a página possa renderizar completamente. O `Promise.all` paraleliza as chamadas de permissão, mas ainda impõe latência adicional proporcional ao item mais lento.

**Soluções possíveis (em ordem de preferência):**

**Opção A — Embutir `canUpdate` no response do `GET /items` (preferencial)**
- Backend inclui `canUpdate: boolean` em cada item da listagem
- Requisições reduzidas de 11 para 1
- Requer mudança no backend: `ItemResponseDto` + lógica no service

**Opção B — Endpoint de permissões em bulk**
- `POST /items/permissions` com body `{ ids: string[] }`
- Retorna `{ [id]: { canUpdate: boolean } }`
- Requisições reduzidas de 11 para 2

**Opção C — Remover verificação por item (mínimo viável)**
- Usar apenas o contexto de acesso da organização para `canEditItem` / `canDeleteItem`
- Requisições reduzidas de 11 para 1
- Perde granularidade de permissão por item, mas pode ser aceitável dependendo das regras de negócio

## Critérios de Aceite
- [ ] Página de itens realiza no máximo 2 requisições HTTP na carga inicial (lista + permissões em bulk, ou apenas 1 se embutido)
- [ ] Funcionalidade de editar/excluir item preservada com regras de permissão corretas
- [ ] Teste manual: listagem de 10 itens sem requisições `GET /items/{id}/can-update` individuais no Network tab
- [ ] Sem regressão na exibição do botão de edição por item
- [ ] Backend: se Opção A, DTO atualizado com campo `canUpdate`

## Esforço
Médio (1–2 dias — requer coordenação backend/frontend)

## Status
Concluído

## Impacto Esperado
Alto — elimina o pior padrão de data fetching da aplicação. Com 20 itens por página (configuração alternativa), seriam 21 → 1 ou 2 requisições.
