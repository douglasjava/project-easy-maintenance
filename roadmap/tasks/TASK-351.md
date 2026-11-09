# TASK-351 — Leitura de demonstrativo de despesas (classificar lançamentos)

## Tipo
BACKEND

## Prioridade
🔵 Baixo

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2+**

## Depende de
TASK-347

## QA obrigatório
Sim.

## Contexto
Maior ganho e maiores armadilhas: o formato muda por administradora; com um mês só dá para supor contrato.
Base: `staging` · branch `feature/TASK-351-<descricao-curta>`.

## Escopo
- Descartar o que não é manutenção (concessionárias, tributos, tarifas, administradora) e mostrar o descarte.
- Reconhecer fornecedor conhecido; favorecido genérico ou pessoa física vira pergunta.
- Sinal de contrato só com recorrência em vários meses.

## Critérios de aceite
- [ ] Lançamentos não relacionados são ignorados e listados
- [ ] Nenhum fornecedor criado sem confirmação

## Status
Backlog
