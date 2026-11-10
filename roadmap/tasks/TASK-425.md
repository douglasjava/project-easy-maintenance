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
- [x] Nunca aparece custo para o zelador (teste negativo)
- [x] Execução do zelador entra como pendente de validação
- [x] Zelador não reprova nem apaga chamado

## Dependências
[TASK-418](TASK-418.md), [TASK-424](TASK-424.md).

## Riscos
Vazamento de custo por consulta reaproveitada: teste negativo por consulta.

## Implementação (10/11/2026)
[api#202](https://github.com/douglasjava/easy-maintenance-api/pull/202), mergeada em `staging`.
- Consultas sem custo. "Chamados abertos" (zelador, síndico, admin): os fora do prazo primeiro e status [Em andamento] ou [Resolvido], sem reprovar nem apagar.
- "Enviar execução": texto e foto, item, data nunca presumida, e a execução vai para validação (TASK-424). Foto ou texto de registro do zelador viram execução.
- "Sugerir item ou local": vira chamado de Sugestão no kanban do síndico.
- Pendentes: aviso imediato ao síndico de execução nova e o teste unitário de `AssistantExecutionSubmitService`.
- `mvn test` 1955, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
