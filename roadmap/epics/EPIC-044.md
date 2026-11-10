# EPIC-044 — Regras de vencimento + Financeiro v2

## Status
⬜ Backlog — criado em 10/11/2026.

## Objetivo
Corrigir a regra do vencimento (dado de norma) e evoluir o financeiro com categorias de manutenção e integração com o registro.

## Descrição
Decisões de produto de 10/11/2026 ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 7) e itens FI-01 a FI-07 e IN-01 do Tiago
([registro](../QA/registro-usabilidade-producao.md), seções 3 e 4).

## Tasks
| ID | Título | Tipo | Prioridade | Depende de |
|---|---|---|---|---|
| [TASK-440](../tasks/TASK-440.md) | Regra do vencimento (ciclo e data antiga) | FULL_STACK | 🔴 | — |
| [TASK-441](../tasks/TASK-441.md) | Categorias fixas ampliadas | FULL_STACK | 🟠 | — |
| [TASK-442](../tasks/TASK-442.md) | Custo → "Lançar também como despesa" | FULL_STACK | 🟠 | 441 |
| [TASK-443](../tasks/TASK-443.md) | Editar e clonar lançamento | FULL_STACK | 🟡 | — |
| [TASK-444](../tasks/TASK-444.md) | Visão mensal e acumulado | FULL_STACK | 🟡 | — |
| [TASK-445](../tasks/TASK-445.md) | Lançar e continuar + filtro e busca | FULL_STACK | 🔵 | — |
| [TASK-446](../tasks/TASK-446.md) | Spec do Financeiro v2 (FI-05) | SPEC | 🔵 | 441, 442 |

## Critério de Conclusão do Épico
- Vencimento nunca recalculado por corretiva (sem exceção marcada) nem por data antiga.
- Manutenção com custo vira despesa vinculada sem duplicidade.

## Fora de Escopo
- Categorias configuráveis por condomínio (decidido: fixas).
- Recálculo em massa do histórico existente.

## Riscos
- A TASK-440 muda o comportamento do vencimento: comunicar aos clientes atuais.
