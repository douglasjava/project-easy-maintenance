# TASK-425 — Persona Zelador no bot: consultas, atender chamado, enviar execução, sugerir item/local

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Zelador

## Prioridade
🟠 Alto.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D4, D14 e D16 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md). O zelador ocupa o espaço do TECH: vê vencimentos e histórico sem custo, atende
chamado (status e foto, sem reprovar nem apagar), envia execução para validação e sugere item ou local.

## Escopo
- Consultas da matriz sem custo.
- Atender chamado: mudar status (em andamento / resolvido) e mandar foto.
- Enviar execução com foto (TASK-424).
- Sugerir item ou local novo, também pelo fluxo 📝.
- Abrir chamado pela equipe fica na [TASK-433](TASK-433.md).

## Critérios de Aceite
- [ ] Nunca aparece custo para o zelador (teste negativo)
- [ ] Execução do zelador entra como pendente de validação
- [ ] Zelador não reprova nem apaga chamado

## Dependências
[TASK-418](TASK-418.md), [TASK-424](TASK-424.md).

## Riscos
Vazamento de custo por consulta reaproveitada: teste negativo por consulta.

## Status
⬜ Backlog
