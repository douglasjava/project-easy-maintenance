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
- [x] Conselheiro consulta e nunca consegue escrever (teste negativo por capacidade)
- [x] Histórico mostra custo para o conselheiro
- [x] Persona revogada não responde mais

## Dependências
[TASK-418](TASK-418.md).

## Riscos
Dado financeiro sensível: ativação só por convite (D19).

## Implementação (10/11/2026)
[api#197](https://github.com/douglasjava/easy-maintenance-api/pull/197), mergeada em `staging`.
- O conselheiro usa o fluxo normal de consultas (vencimentos, vencidos, histórico com custo, conformidade). A política barra escrita.
- Consultas de persona rodam com um principal sintético de leitura no tenant da conversa.
- Resumo financeiro novo no menu (receitas, despesas e saldo do mês), para READER, conselheiro, síndico e admin.
- O custo no histórico aparece só com `VER_CUSTO`.
- Mandato encerrado: a persona deixa de ser reconhecida (TASK-417).
- `mvn test` 1936, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
