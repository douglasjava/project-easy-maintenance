# TASK-257 — UX: remover botão "Exportar PDF" desabilitado antes do merge

## Tipo
FRONTEND

## Categoria
Dashboard / Compliance

## Prioridade
🔵 Baixo

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Não — mudança puramente visual, coberta por build/lint.

---

## Contexto
Pedido do Douglas antes de mergear pra staging: o botão "Exportar PDF" (decisão #4 do EPIC-030,
`ComplianceFilterBar.tsx`) ficava sempre desabilitado com um tooltip explicando que a funcionalidade
chega depois. Mesmo desabilitado, um botão visível convida clique e passa a impressão de recurso
quebrado — melhor não mostrar nada até existir de verdade.

## Escopo
- [x] Remover o botão (e o import não usado de `Download`, `lucide-react`) de `ComplianceFilterBar.tsx`.
- [x] Atualizar `EPIC-030.md` (decisão #4) e `TASK-QA-MAN-021.md` pra não descreverem mais um botão
      desabilitado que não existe mais na tela.

## Implementação
`easy-maintenance-web`, branch `feature/EPIC-030-compliance-dashboard`. Só remoção de JSX/import,
sem mudança de lógica. `npx tsc --noEmit`, `eslint` e `npm run build` limpos.

## Status
🟢 Feito.
