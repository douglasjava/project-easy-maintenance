# TASK-430 — QA do EPIC-042: matriz de papéis, testes negativos por persona e regressão

## Tipo
QA

## Categoria
Assistente WhatsApp (Samu) / QA

## Prioridade
🟠 Alto.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Riscos da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): vazamento entre personas, regressão da identidade e multi-tenant do fornecedor.

## Escopo
- Teste parametrizado papel × capacidade cobrindo toda a matriz.
- Teste negativo por persona em cada consulta (custo, dado de terceiros).
- Regressão do fluxo atual de usuário com login.
- QA manual em `staging` com 1 número por persona.

## Critérios de Aceite
- [ ] Matriz inteira coberta por teste automatizado
- [ ] Nenhum vazamento encontrado nos testes negativos
- [ ] QA manual aprovado por Douglas

## Dependências
As tasks do EPIC-042 que forem entregues.

## Riscos
—

## Status
⬜ Backlog
