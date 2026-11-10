# TASK-429 — Limite de IA por persona (mensagens por dia + teto mensal)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / IA

## Prioridade
🟠 Alto — pré-requisito para liberar persona sem login para todos.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D11 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): crédito de IA sai do plano do condomínio; o morador é o público mais numeroso.

## Escopo
- (a) Máximo de mensagens pela IA por persona por dia (ex.: morador 10/dia).
- (b) Teto mensal em créditos para todas as personas sem login somadas (ex.: 30% do crédito do plano).
- Números por configuração; acima do limite o bot oferece o menu sem IA.

## Critérios de Aceite
- [ ] Passou do limite diário: menu sem IA, sem consumir crédito
- [ ] Teto mensal das personas respeitado sem afetar ADMIN/SYNDIC
- [ ] Limites configuráveis sem deploy

## Dependências
[TASK-417](TASK-417.md).

## Riscos
Calibrar no piloto.

## Status
⬜ Backlog
