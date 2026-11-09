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
- [x] "Nova receita" abre modal sem triângulo vermelho, botão verde (`variant="success"`)
- [x] "Nova despesa" abre modal sem triângulo, botão neutro/primário (`variant="primary"`)
- [x] Modal de cancelar lançamento continua vermelho (é destrutivo) — `variant` padrão `"danger"`, nenhum dos 8 usos mudou
- [x] Validações e estados de carregamento/erro do formulário inalterados (só a aparência mudou)
- [ ] Layout ok em mobile (360px) — **conferir no QA manual (C14)**
- [x] `npm run build` e `tsc` limpos

## Implementação (09/11/2026)
- `components/ConfirmModal.tsx` ganhou `variant?: "danger" | "success" | "primary"` (padrão `"danger"`, o
  comportamento de sempre). Fora do `"danger"`: sem o triângulo de alerta, corpo alinhado à esquerda (é
  formulário) e botão na cor da variante.
- `app/finance/page.tsx`: Nova receita → `success`; Nova despesa → `primary`.
- Sem teste de componente: o jest do web é só de lógica (sem testing-library/DOM). `tsc` limpo, `next build` ok.
- **Achado fora do escopo:** 3 testes de `src/middleware.test.ts` (redirecionar para /login sem cookie) já falham
  na `staging`, sem esta mudança — 238/241 no jest. Candidato a task própria.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-web`, a partir de `staging`), commit `f84105b`.

## Status
🟡 Em Validação — falta a conferência visual (desktop e 360px) no QA manual
[TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) (C14).
