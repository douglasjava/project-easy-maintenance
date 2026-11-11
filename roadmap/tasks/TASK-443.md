# TASK-443 — Financeiro: editar e clonar lançamento com auditoria

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟡 Médio — FI-01.

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
FI-01 do [registro](../QA/registro-usabilidade-producao.md). Hoje a API só cria, lista, cancela e resume.

## Escopo
- Editar lançamento (valor, data, categoria, descrição) com registro de antes/depois na auditoria.
- Clonar lançamento (abre o formulário preenchido).

## Critérios de Aceite
- [x] Edição auditada (quem, quando, antes e depois)
- [x] Clonar não altera o original
- [x] Só ADMIN/SYNDIC

## Dependências
Nenhuma.

## Riscos
Edição de lançamento vinculado a manutenção: manter o vínculo.

## Implementação (11/11/2026)
[api#219](https://github.com/douglasjava/easy-maintenance-api/pull/219) e [web#152](https://github.com/douglasjava/easy-maintenance-web/pull/152), mergeadas em `staging`.
- `PUT /finance/entries/{id}` edita categoria, valor, descrição e data. O tipo não muda.
- A auditoria grava `FINANCIAL_ENTRY` / UPDATE com antes, depois e o usuário, só quando algo mudou.
- Despesa vinda de manutenção: mantém o vínculo, e o valor fica travado (altera-se o custo na manutenção).
- Clonar (só no web): abre um lançamento novo preenchido, com a data de hoje.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
