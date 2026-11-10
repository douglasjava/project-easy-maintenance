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
- [ ] Edição auditada (quem, quando, antes e depois)
- [ ] Clonar não altera o original
- [ ] Só ADMIN/SYNDIC

## Dependências
Nenhuma.

## Riscos
Edição de lançamento vinculado a manutenção: manter o vínculo.

## Status
⬜ Backlog
