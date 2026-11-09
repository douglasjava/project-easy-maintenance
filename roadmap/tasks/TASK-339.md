# TASK-339 — Evidência obrigatória para itens críticos + registro em etapa única

## Tipo
FULL_STACK

## Prioridade
🔴 Crítico

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 1**

## Depende de
Decisão da lista de sistemas críticos

## QA obrigatório
Sim.

## Contexto
Sem evidência o produto vira agenda. Hoje foto/anexo é opcional e fica numa segunda etapa.
Base: `staging` · branch `feature/TASK-339-<descricao-curta>`.

## Escopo
- Backend: registro de manutenção de item crítico exige pelo menos 1 anexo (ProblemDetail claro).
- Web: dados + anexos na mesma tela.
- WhatsApp: o fluxo da TASK-306 pede a foto antes de concluir item crítico.
- Itens não críticos continuam sem obrigatoriedade.

## Critérios de aceite
- [ ] Item crítico sem anexo é recusado (web, API e WhatsApp)
- [ ] Item não crítico continua aceitando sem anexo
- [ ] Mensagem de erro clara
- [ ] Sem regressão nos testes de manutenção

## Status
Backlog
