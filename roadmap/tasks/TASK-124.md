# TASK-124 — Full-Stack: Visão em calendário dos itens (toggle dentro de /items)

## Tipo
FULL_STACK

## Categoria
Produto / Planejamento / Item

## Prioridade
🟡 Médio

## Épico
EPIC-006 — Produto / Experiência do Usuário

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — validar navegação entre meses, agregação correta de itens por dia e escopo por organização.

---

## Contexto e motivação

Discutido com Douglas antes de virar card (brainstorming em 14/07/2026). Hoje `/items` só tem uma
listagem em tabela/cards com filtros por status (`OK`/`NEAR_DUE`/`OVERDUE`), categoria e tipo, com
paginação cursor-based — e o dashboard mostra um recorte dos 10 itens mais urgentes em "Atenção Agora".
Nenhuma das duas telas ajuda a **enxergar a distribuição de vencimentos ao longo do mês** — ex.: "vários
itens vencem juntos na semana do dia 20" só aparece folheando a lista item a item.

**Caso de uso validado**: planejamento — ajudar o síndico/gestor a distribuir o trabalho de manutenção
ao longo do mês em vez de descobrir picos de vencimento só quando eles já estão em cima.

Importante: isso é uma visão **dentro do próprio app**, diferente da TASK-123 (exportar `.ics` de um
item para o Google Calendar/Outlook/Apple do usuário). São features complementares, não a mesma coisa.

### Decisões de escopo (v1, deliberadas)

- **Localização**: toggle "Lista | Calendário" dentro da própria tela `/items`, reaproveitando os
  filtros já existentes (status, categoria, tipo) — não é uma rota nova no menu, para não fragmentar a
  navegação com mais uma tela que o usuário precisa descobrir.
- **Densidade visual**: célula do dia mostra bolinhas coloridas por status (mesma paleta de
  `STATUS_CONFIG` já usada em `/items` — `NEAR_DUE`/`OVERDUE`) + contador total; sem listar nomes de
  item direto na célula (evita poluição visual em dias com muitos itens).
- **Interação**: clique no dia abre um painel lateral/modal com a lista completa de itens daquele dia
  (nome, status, categoria), cada item linkando para `/items/{id}` — reaproveita `StatusBadge` já
  existente.
- **Escopo de dados**: mesma organização ativa (`X-Org-Id`) do restante de `/items` — não é uma visão
  cross-org (isso seria escopo do EPIC-011/`/me/reports`, não deste card).

### Fora de escopo da v1 (registrado para não virar ambiguidade depois)

- Ação de registrar manutenção direto do painel do dia — só link para o detalhe do item.
- Visão cross-org / múltiplas organizações no mesmo calendário.
- Arrastar/soltar para replanejar datas.
- Toggle "histórico + previsão" (mostrar manutenções já realizadas junto do vencimento futuro).

---

## Escopo

### Backend

- O endpoint atual (`GET /me/items`, paginado por cursor) não serve para o calendário — a visão precisa
  de **todos** os itens com `nextDueAt` dentro de uma janela de datas (o mês visível), não uma página de
  N itens.
- Novo parâmetro/endpoint de range de datas — `GET /me/items?fromDate=&toDate=&status=&itemCategory=&itemType=`
  (ou endpoint dedicado, ex.: `GET /me/items/calendar`) retornando todos os itens da organização ativa
  com `nextDueAt` no intervalo informado, sem paginação cursor (volume por mês tende a ser pequeno).
- Itens sem `nextDueAt` não entram no resultado (nada a plotar no calendário).
- Mesmo escopo de organização (`X-Org-Id`) já aplicado em `MaintenanceItemRepository`/`TenantFilterAspect`.

### Frontend (`app/items/page.tsx`)

- Toggle "Lista | Calendário" no topo da tela, ao lado dos filtros já existentes — filtros continuam
  válidos para as duas visões.
- Grid mensal padrão (dom–sáb), navegação mês anterior/próximo, mês atual em destaque.
- Célula do dia: bolinhas coloridas por status + contador (ver decisão de densidade acima).
- Clique no dia: painel lateral/modal com a lista de itens daquele dia, linkando para `/items/{id}`.
- Estado de loading/erro segue o mesmo padrão já usado na listagem atual.

### QA / Testes

- Unitário: endpoint de range de datas retorna itens corretos por período, respeita escopo de
  organização e os filtros de status/categoria/tipo.
- Manual: alternar Lista/Calendário, navegar entre meses, clicar num dia com múltiplos itens e conferir
  a lista no painel; conferir que itens sem `nextDueAt` não aparecem no grid.

---

## Arquivos impactados (estimativa)

### Backend
- Controller de itens (novo parâmetro de range de datas ou endpoint dedicado `/calendar`)
- Repository/specification de `MaintenanceItem` — nova query por intervalo de `nextDueAt`

### Frontend
- `app/items/page.tsx` — toggle de visão + novo componente de grid de calendário
- Novo componente de painel lateral/modal de "itens do dia" (reaproveitando `StatusBadge`)

## Critérios de Aceite

- [x] Toggle "Lista | Calendário" funcional dentro de `/items`, preservando os filtros ativos
- [x] Grid mensal exibe corretamente os dias com itens vencendo (bolinhas por status + contador)
- [x] Navegação entre meses funciona e busca os dados do novo intervalo
- [x] Clique no dia abre painel com a lista completa de itens daquele dia, cada um linkando ao detalhe
- [x] Itens sem `nextDueAt` não aparecem no calendário
- [x] Escopo por organização respeitado (não mistura itens de outra org)
- [x] Testes unitários da nova query por range de datas

## Dependências
Nenhuma — feature isolada, reaproveita componentes já existentes (`StatusBadge`, `STATUS_CONFIG`).

## Riscos
Baixo. Risco principal é virar "mais uma tela" sem uso real se o valor de planejamento não se confirmar
na prática — mitigado por já nascer como toggle dentro de `/items` (custo de descoberta baixo) em vez de
rota nova dedicada.

## Esforço
Médio (novo componente de grid de calendário no frontend + query de range de datas no backend — sem
migration, sem integração externa)

## Status
Em Validação

## Implementação (15/07/2026)

Branches `feature/TASK-124` criadas a partir de `staging` em ambos os repositórios (API + Web).

**Backend**: `MaintenanceItemSpecs.dueDateBetween()` (predicado aditivo, não altera `filter()` existente) +
`MaintenanceItemService.findAllForCalendar()` (valida `fromDate<=toDate`, reaproveita resolução batch de
`canUpdate`) + `GET /easy-maintenance/api/v1/items/calendar?fromDate=&toDate=&status=&itemType=&categoria=`.
Itens sem `nextDueAt` são excluídos pelo próprio `BETWEEN` do JPA. 6 testes novos em
`MaintenanceItemServiceCalendarRangeTest` — 571/571 testes backend green.

**Frontend**: por pedido do Douglas, a visão de calendário ficou isolada em componentes próprios (não
poluindo `page.tsx`): `src/components/items/ItemsCalendarView.tsx` (grid mensal + fetch via react-query),
`ItemsCalendarDayPanel.tsx` (painel do dia clicado), `calendarUtils.ts` (funções puras de grid/agrupamento,
9 testes novos em `calendarUtils.test.ts`) e `shared.tsx` (extração de `Item`/`StatusBadge`/`CategoryBadge`/
`STATUS_CONFIG`/`formatDate` de `page.tsx`, reaproveitados também pela listagem — refactor sem mudança de
comportamento). `page.tsx` só ganhou o toggle "Lista | Calendário" e a renderização condicional. tsc/eslint
limpos nos arquivos novos/alterados; `next build` (produção) sem erros. Datas do grid calculadas via
métodos locais (`getFullYear`/`getMonth`/`getDate`), evitando o bug de timezone -1 dia já visto em
TASK-QA-BUG-015.

✅ Validado por Douglas em teste manual real: toggle Lista/Calendário, navegação entre meses, painel do dia
com múltiplos itens, item sem `nextDueAt` ausente do grid.

PRs abertos para `staging`:
- Backend: https://github.com/douglasjava/easy-maintenance-api/pull/15
- Frontend: https://github.com/douglasjava/easy-maintenance-web/pull/13
