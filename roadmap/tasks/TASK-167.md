# TASK-167 — Frontend: lista individual de leads — filtros + troca de status inline

## Tipo
FRONTEND

## Categoria
Admin / Leads

## Prioridade
🟠 Alto

## Épico
[EPIC-021](../epics/EPIC-021.md) — Painel de Leads (visão agregada + mini-CRM de status)

## QA obrigatório
Sim — validar cada filtro isoladamente e combinado, e que a troca de status realmente persiste
(recarregar a página e ver o valor novo).

---

## Contexto

É a parte que torna o status útil de verdade — sem isso, o enum da TASK-163 é só um valor estático
que ninguém consegue mudar pela interface.

---

## Objetivo

Seção na página `/leads` (abaixo da visão agregada da TASK-166) com tabela paginada, filtros e
troca de status inline.

---

## Escopo

### 1. Filtros (topo da seção)
- Status (select com as 4 opções + "todos").
- Fonte (texto — igualdade exata, sem debounce de busca parcial).
- Campanha (texto — igualdade exata).
- Período (date range).

### 2. Tabela
- Colunas: nome, e-mail, fonte, referrer, status, data de criação.
- Status por linha é um `<select>` que já mostra o valor atual; ao trocar, dispara
  `PATCH /admin/leads/{id}/status` na hora (sem botão de "salvar" separado) e atualiza a linha
  otimisticamente, com rollback + toast de erro se a chamada falhar.
- Paginação (mesmo padrão `PageResponse` já usado no resto do admin).

### 3. Testes
- Validar manualmente: cada filtro isolado, filtros combinados, troca de status persiste após
  reload.

---

## Critérios de Aceite

- [x] Filtros de status/fonte/campanha/período funcionam isolados e combinados (delegam pro backend testado na TASK-165; `appliedFilters` só muda via botão Filtrar/Limpar, todos enviados juntos)
- [x] Troca de status por linha persiste (dispara `PATCH .../status` direto no `onChange`, sem botão salvar separado — endpoint já validado na TASK-165)
- [x] Falha na troca de status mostra erro claro e reverte a seleção visual (update otimista + rollback pro status anterior + `toast.error` no `catch`)
- [x] Paginação funciona (reaproveita o componente `Pagination` já usado em Faturas admin, mesmo contrato `PageResponse`)
- [x] `npm run build` limpo

**QA manual**: mesma limitação já registrada na TASK-166 — sem `OPENAI_API_KEY`/`DEEPSEEK_API_KEY`/Postgres locais não dá pra subir o backend e testar contra dado real. Validado via `npm run build` + revisão de código. Um bug de closure obsoleta foi encontrado e corrigido durante a implementação: ver "Achado durante a implementação" abaixo. Fica pendente teste manual com dado real por Douglas.

**Achado durante a implementação**: a primeira versão do "Limpar" (`handleClear`) chamava `setFilters(EMPTY_FILTERS)` e, na mesma função, tentava disparar a busca lendo o estado `filters` — como `setState` é assíncrono, a busca ainda usaria os valores antigos (não os limpos). Corrigido separando o rascunho dos inputs (`filters`) do que foi de fato submetido (`appliedFilters`, único gatilho do `useEffect` que busca os dados) — `handleFilter`/`handleClear` sempre atualizam os dois juntos, sem depender de leitura de estado defasado.

## Dependências
- **TASK-165** — precisa do endpoint de lista/troca de status existir.
- **TASK-166** — a página precisa existir antes de adicionar essa seção nela.

## Riscos
Baixo — CRUD/listagem sobre endpoint já pronto, mesmo padrão de filtros combináveis de outras
telas admin.

## Esforço
Médio

## Status
Em Validação — branch `feature/EPIC-021-leads-dashboard`, commit `e6c9795` (easy-maintenance-web). QA manual com dado real pendente. Última task do EPIC-021 — épico com implementação completa.
