# TASK-409 — BUGFIX: modal "Nova receita/despesa" usa visual de ação destrutiva (ícone e botão vermelhos) (EPIC-032)

## Tipo
BUGFIX — FRONTEND

## Categoria
Financeiro (backoffice)

## Prioridade
🔵 Baixo

## Épico
[EPIC-032](../epics/EPIC-032.md) — Controle financeiro · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), item **FI-04**)

## QA obrigatório
Sim — visual, desktop e mobile.

---

## Causa (verificada no código)
`easy-maintenance-web/src/app/finance/page.tsx` monta o formulário de lançamento dentro de
`@/components/ConfirmModal`, que é o modal de **confirmação destrutiva**: ícone de alerta em
`text-danger bg-danger-subtle` e botão `btn-danger` fixos no código. O botão "Nova receita" da tela é
verde; o modal abre vermelho.

## Escopo
- Usar um modal de formulário (ou o `components/admin/ConfirmModal`, que já aceita `confirmVariant`)
  sem ícone de alerta; botão "Lançar" em `success` para receita e `primary` para despesa.
- Não alterar o `ConfirmModal` destrutivo usado por "Cancelar lançamento" e outras telas.

## Critérios de Aceite
- [ ] "Nova receita" abre modal sem triângulo vermelho, botão verde
- [ ] "Nova despesa" abre modal sem triângulo, botão neutro/primário
- [ ] Modal de cancelar lançamento continua vermelho (é destrutivo)
- [ ] Validações e estados de carregamento/erro do formulário inalterados
- [ ] Layout ok em mobile (360px)
- [ ] `npm run build` e lint limpos
