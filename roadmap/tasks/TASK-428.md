# TASK-428 — Avisos do prédio: entidade, destinatários, custo antes de enviar, teto mensal

## Tipo
FULL_STACK

## Categoria
Assistente WhatsApp (Samu) / Avisos

## Prioridade
🟡 Médio — tem custo por mensagem.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D7 e D13 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e seção "Custo de mensagens WhatsApp". Aviso é entidade própria, **só enviada** (proativa),
paga por destinatário.

## Escopo
- Entidade de aviso por organização (título, texto, período, destinatários).
- O síndico escolhe os destinatários (todos, bloco, unidade, papel) e vê o **custo estimado antes** de confirmar.
- Teto mensal de envio por organização.
- Envio em fan-out por template HSM de utilidade, com registro de entrega.

## Critérios de Aceite
- [ ] Custo estimado aparece antes de confirmar e bate com o número de destinatários
- [ ] Envio bloqueado acima do teto mensal
- [ ] Só destinatários ativos e com opt-in recebem

## Dependências
[TASK-417](TASK-417.md), [TASK-419](TASK-419.md). Conferir o rate card oficial da Meta antes.

## Riscos
Custo cresce com o número de moradores, não com a receita.

## Status
⬜ Backlog
