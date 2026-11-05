# TASK-370 — FRONTEND: Categoria e protocolo no kanban interno

## Tipo
FRONTEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — confirmar categoria (badge) e protocolo visíveis em cada card do kanban, pras 3 categorias,
sem quebrar o drag-and-drop existente.

---

## Contexto

Parte frontend da extensão do EPIC-027 pedida por Douglas após conversa com a síndica Aliria
Emanuela (28/10/2026). Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

- No kanban interno (painel autenticado, `X-Org-Id`): cada card passa a exibir a categoria (badge
  colorido por tipo — sugestão/reclamação/manutenção) e o número de protocolo.
- Sem mudança na lógica de drag-and-drop (`dnd-kit`) já existente — só exibição adicional no card.

## Critérios de Aceite

- [x] Cada card do kanban mostra a categoria do chamado com indicação visual clara (badge colorido
      por tipo)
- [x] Cada card mostra o número de protocolo
- [ ] Drag-and-drop entre colunas continua funcionando sem regressão — só verificado por não ter
      tocado na lógica de `dnd-kit` (`DraggableTicketCard`/`BoardColumn` inalterados); não testado
      em navegador real nesta rodada
- [x] `npm run build`/`tsc --noEmit` sem regressão

## Dependências
TASK-367 (contrato de API com `category`/`protocolNumber`). Independente de TASK-369/371.

## Riscos
Baixo — extensão visual de componente já existente.

## Esforço
Pequeno

## Status
🟡 Implementada, aguardando QA manual e PR — branch
`feature/EPIC-027-categoria-protocolo-notificacao` (`easy-maintenance-web`).
