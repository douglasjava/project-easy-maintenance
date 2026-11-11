# TASK-441 — Financeiro: categorias fixas ampliadas (receita e despesa)

## Tipo
FULL_STACK

## Categoria
Financeiro

## Prioridade
🟠 Alto — FI-03 do Tiago; pré-requisito da TASK-442.

## Épico
[EPIC-044](../epics/EPIC-044.md) — Regras de vencimento + Financeiro v2

## QA obrigatório
Sim.

---

## Contexto
Decisão de 10/11/2026 ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 7, pergunta 4): categorias fixas, lista ampliada e curada. Hoje
`FinancialEntryCategory` tem 4 categorias de despesa e nenhuma de manutenção.

## Escopo
- Enum ampliado: manutenção preventiva, manutenção corretiva, contratos, folha, consumo, administração, fundo de
  reserva, outras despesas; receita: taxa condominial, multa, aluguel de área comum, outras receitas.
- Migração das categorias existentes sem perder lançamento.
- Web (lista, filtro, formulário) e Samu (escolha da categoria) usam a lista nova.

## Critérios de Aceite
- [x] Lançamentos antigos continuam visíveis com a categoria equivalente
- [x] Receita e despesa só oferecem as categorias do seu tipo
- [x] Samu oferece as categorias novas

## Dependências
Nenhuma.

## Riscos
Mapeamento das 4 antigas: documentar a equivalência na migration.

## Implementação (11/11/2026)
[api#217](https://github.com/douglasjava/easy-maintenance-api/pull/217) e [web#150](https://github.com/douglasjava/easy-maintenance-web/pull/150), mergeadas em `staging`.
- Despesa: manutenção preventiva, manutenção corretiva, contratos e serviços, folha, consumo, administração, fundo de reserva e outras. Receita: taxa condominial, multa, aluguel de área comum e outras.
- O rótulo fica no enum, compartilhado pelo Samu e pelo web.
- V151: `SERVICO_TERCEIRO` vira `CONTRATOS`, sem apagar nenhum lançamento; a equivalência está documentada na migration.
- O filtro por categoria fica para a TASK-445.

## Status
🔵 Em `staging` (11/11/2026) — aguarda a validação de Douglas.
