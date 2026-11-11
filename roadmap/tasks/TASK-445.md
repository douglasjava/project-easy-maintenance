# TASK-445 — Financeiro: lançar e continuar + filtro por categoria e busca

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🔵 Baixo — FI-06 e FI-07.

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
FI-06 e FI-07 do [registro](../QA/registro-usabilidade-producao.md).

## Escopo
- Botão "Salvar e lançar outro" que mantém data e tipo.
- Filtro por categoria e busca por descrição na lista.

## Critérios de Aceite
- [x] Lançar vários em sequência sem reabrir o modal
- [x] Filtro e busca combinados com o período

## Dependências
Nenhuma.

## Riscos
—

## Implementação (11/11/2026)
[api#221](https://github.com/douglasjava/easy-maintenance-api/pull/221) e [web#154](https://github.com/douglasjava/easy-maintenance-web/pull/154), mergeadas em `staging`.
- `GET /finance/entries` aceita `category` e `q` (trecho da descrição, sem diferenciar maiúsculas). O `q` vem com os curingas escapados e no máximo 100 caracteres.
- Web: filtros de Categoria (acompanha o tipo) e Buscar (espera 350 ms enquanto digita).
- "Salvar e lançar outro" mantém tipo, categoria e data, limpa valor e descrição e deixa o modal aberto.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
