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
- [x] Confirmar com despesa cria o lançamento vinculado
- [x] Segundo lançamento da mesma manutenção é bloqueado
- [x] Contrato ou garantia: basta não lançar

## Dependências
[TASK-441](TASK-441.md).

## Riscos
Parcelas e recorrência ficam na [TASK-446](TASK-446.md).

## Implementação (11/11/2026)
[api#218](https://github.com/douglasjava/easy-maintenance-api/pull/218) e [web#151](https://github.com/douglasjava/easy-maintenance-web/pull/151), mergeadas em `staging`.
- `financial_entries.maintenance_id` (V152). `createFromMaintenance` usa o valor e a data da manutenção, com a categoria pelo tipo (preventiva ou corretiva).
- Um lançamento ativo por manutenção: o segundo dá 409.
- O resumo não conta duas vezes: as despesas manuais excluem as vinculadas, porque o custo da manutenção já entra no total.
- Samu: depois de um registro com custo, [Lançar despesa] [Não precisa]. Web: caixa no formulário, botão no detalhe, pergunta ao cancelar a manutenção e selo no financeiro.
- Contrato ou garantia: basta não lançar.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
