# TASK-421 — Persona Conselheiro no bot: leituras, custo, resumo financeiro e índice

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Conselheiro

## Prioridade
🟡 Médio.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D5 e D10 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): o conselheiro vê vencimentos, histórico com custo, resumo financeiro e índice/relatório.

## Escopo
- Consultas só leitura da matriz para o conselheiro.
- Fim do mandato revoga a persona (mandato do EPIC-036, TASK-356, quando existir; até lá, a remoção do cadastro).

## Critérios de Aceite
- [ ] Conselheiro consulta e nunca consegue escrever (teste negativo por capacidade)
- [ ] Histórico mostra custo para o conselheiro
- [ ] Persona revogada não responde mais

## Dependências
[TASK-418](TASK-418.md).

## Riscos
Dado financeiro sensível: ativação só por convite (D19).

## Status
⬜ Backlog
