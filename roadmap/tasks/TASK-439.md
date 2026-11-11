# TASK-439 — QA do EPIC-043: casos do Tiago (5.6) no conjunto de avaliação + QA manual

## Tipo
QA

## Categoria
Assistente WhatsApp (Samu) / QA

## Prioridade
🟠 Alto.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Seção 5.6 da [Parte B](../QA/registro-usabilidade-producao.md) e o runner da [TASK-411](TASK-411.md).

## Escopo
- Casos 5.6 viram casos novos no `intent-eval.jsonl` (com subconjunto cego).
- Rodar a avaliação antes e depois da [TASK-410](TASK-410.md) (prompt).
- QA manual com o Tiago em `staging`, por papel.

## Critérios de Aceite
- [ ] Todos os casos da 5.6 no conjunto de avaliação
- [ ] Acerto de intenção não piora em nenhuma categoria
- [ ] QA manual aprovado (Douglas e Tiago)

## Dependências
As tasks do EPIC-043 que forem entregues e a [TASK-410](TASK-410.md).

## Riscos
—

## Andamento (11/11/2026)
- Casos da 5.6 que ainda chegam ao classificador entraram no `intent-eval.jsonl` (`reg-19..22`, `ven-07`, `aju-04`; 4 cegos) em [api#216](https://github.com/douglasjava/easy-maintenance-api/pull/216). Os outros casos da 5.6 viraram fluxos determinísticos, com testes unitários nas TASK-431 a 438.
- **Pendente:** a avaliação antes e depois da TASK-410 (chave OpenAI) e o QA manual por papel em `staging` com Douglas e Tiago.

## Status
🟡 Em andamento — casos no conjunto; faltam a avaliação com a chave e o QA manual.
