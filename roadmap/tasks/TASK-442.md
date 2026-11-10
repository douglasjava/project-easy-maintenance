# TASK-442 — Manutenção com custo: "Lançar também como despesa" com vínculo e sem duplicidade

## Tipo
FULL_STACK

## Categoria
Financeiro / Manutenção

## Prioridade
🟠 Alto — IN-01 do Tiago.

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Decisão de 10/11/2026 ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 7, pergunta 3): o custo da manutenção é valor pago e pode virar despesa.

## Escopo
- Lançamento ganha `maintenance_id` opcional; vínculo visível nos dois sentidos.
- Web e cartão do Samu: com custo, oferecem [Lançar também como despesa] (categoria pelo tipo da manutenção).
- Não lança duas vezes a mesma manutenção; cancelar a manutenção pergunta o que fazer com a despesa.

## Critérios de Aceite
- [ ] Confirmar com despesa cria o lançamento vinculado
- [ ] Segundo lançamento da mesma manutenção é bloqueado
- [ ] Contrato ou garantia: basta não lançar

## Dependências
[TASK-441](TASK-441.md).

## Riscos
Parcelas e recorrência ficam na [TASK-446](TASK-446.md).

## Status
⬜ Backlog
