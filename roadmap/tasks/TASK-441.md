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
- [ ] Lançamentos antigos continuam visíveis com a categoria equivalente
- [ ] Receita e despesa só oferecem as categorias do seu tipo
- [ ] Samu oferece as categorias novas

## Dependências
Nenhuma.

## Riscos
Mapeamento das 4 antigas: documentar a equivalência na migration.

## Status
⬜ Backlog
