# TASK-348 — Indicação de fornecedor respeita contrato + lista de bloqueio

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
TASK-346

## QA obrigatório
Sim.

## Contexto
Não sugerir concorrente para quem tem contrato vigente; permitir ao síndico desqualificar um fornecedor.
Base: `staging` · branch `feature/TASK-348-<descricao-curta>`.

## Escopo
- Item com contrato recorrente não recebe indicação.
- Bloqueio por condomínio com motivo (atraso, qualidade, preço, outro); interno, o fornecedor não é avisado.
- Bloqueado nunca aparece em indicação nem em orçamento.

## Critérios de aceite
- [ ] Item com contrato nunca recebe indicação
- [ ] Fornecedor bloqueado nunca aparece
- [ ] Só quem administra o condomínio bloqueia

## Status
Backlog
