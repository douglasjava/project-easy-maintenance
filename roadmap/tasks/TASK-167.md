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

- [ ] Filtros de status/fonte/campanha/período funcionam isolados e combinados
- [ ] Troca de status por linha persiste (confirmado após reload da página)
- [ ] Falha na troca de status mostra erro claro e reverte a seleção visual
- [ ] Paginação funciona
- [ ] `npm run build` limpo

## Dependências
- **TASK-165** — precisa do endpoint de lista/troca de status existir.
- **TASK-166** — a página precisa existir antes de adicionar essa seção nela.

## Riscos
Baixo — CRUD/listagem sobre endpoint já pronto, mesmo padrão de filtros combináveis de outras
telas admin.

## Esforço
Médio

## Status
Pronto para Implementar
