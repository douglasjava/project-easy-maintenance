# TASK-449 — Financeiro v2: fornecedor e unidade no lançamento + filtro por fornecedor

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🔵 Baixo

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Quebra da [spec do Financeiro v2](../../docs/superpowers/specs/2026-11-11-financeiro-v2-fi05-design.md) (seção 3.3 e D6), aprovada por Douglas em 11/11/2026 ([TASK-446](TASK-446.md)).

## Escopo
- `supplier_id` opcional só em despesa (fornecedores vinculados à organização).
- `unit_id` opcional só em receita (D6: agora, sem inadimplência).
- Filtro por fornecedor na lista (estende a TASK-445).

## Critérios de Aceite
- [x] Só fornecedor e unidade da própria organização
- [x] Fornecedor só em despesa e unidade só em receita
- [x] Filtro por fornecedor combina com os demais

## Dependências
—

## Riscos
Vazamento entre organizações: validar o vínculo do fornecedor e da unidade com o tenant.

## Implementação (11/11/2026)
[api#224](https://github.com/douglasjava/easy-maintenance-api/pull/224) e [web#157](https://github.com/douglasjava/easy-maintenance-web/pull/157), mergeadas em `staging`.
- A migração V155 cria `supplier_id` (só em despesa) e `unit_id` (só em receita), os dois opcionais. ⚠️ Ainda não foi executada num MySQL.
- O fornecedor precisa estar vinculado à organização e a unidade precisa ser dela. Um id de outra organização dá a mesma resposta de um id inexistente.
- Na edição, `null` remove o fornecedor ou a unidade, porque o formulário manda o estado completo.
- Despesa vinda de manutenção herda o fornecedor da manutenção.
- `GET /finance/entries?supplierId=` filtra por fornecedor. Web: selects no formulário, fornecedor ou unidade abaixo da descrição na lista e filtro "Fornecedor".

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
