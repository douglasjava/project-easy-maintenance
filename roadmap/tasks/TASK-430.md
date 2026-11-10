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
- [x] Matriz inteira coberta por teste automatizado
- [x] Nenhum vazamento encontrado nos testes negativos
- [ ] QA manual aprovado por Douglas

## Dependências
As tasks do EPIC-042 que forem entregues.

## Riscos
—

## Execução (10/11/2026)
- Automatizado:
  - matriz inteira papel × capacidade (`AssistantRolePolicyTest`);
  - testes negativos por persona em cada task (custo escondido do zelador e do fornecedor; morador só vê os próprios chamados; conselheiro não escreve; fornecedor só nos condomínios vinculados; trava de decisão das execuções);
  - regressão do fluxo de login (suíte do `assistant` verde em cada PR). Suíte completa: 1970, 0 falhas.
- QA manual: roteiro em [TASK-QA-MAN-031](../QA/tasks/TASK-QA-MAN-031.md), com os cenários por persona, para o Douglas executar em `staging` com a flag ligada.

## Status
🔵 Em Validação — automatizado ok; falta o QA manual ([TASK-QA-MAN-031](../QA/tasks/TASK-QA-MAN-031.md)).
