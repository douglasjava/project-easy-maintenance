# TASK-285 — Frontend: página pública `/para-fornecedores` (divulgação + políticas)

## Tipo
FRONTEND

## Categoria
Marketing / Marketplace de Fornecedores

## Prioridade
🟠 Alto — aquisição de fornecedores pagantes

## Épico
[EPIC-028](../epics/EPIC-028.md) — Marketplace de Fornecedores

## QA obrigatório
Sim — QA manual no browser (acesso deslogado, responsividade, CTAs, eventos de tracking, regressão
do cadastro/pagamento de fornecedor).

---

## Contexto

O marketplace de fornecedores está pronto de ponta a ponta (cadastro, Pix Automático R$ 15,99/mês,
autogestão via link mágico, pedido de orçamento no WhatsApp), mas não existe página para divulgar
ao fornecedor por que participar, quanto custa e quais são as regras. Detalhe completo em
`docs/superpowers/specs/2026-09-24-pagina-para-fornecedores-design.md`.

## Escopo

- Nova rota pública `/para-fornecedores`: hero com foto, por que participar, como funciona (mockups
  do card no marketplace e da mensagem no WhatsApp), preço, políticas (`#politicas`), FAQ, CTA final.
- `Shell.tsx` (allowlist pública), `sitemap.ts`, `metadata` + Open Graph.
- Link "Para fornecedores" no footer da `/landing`; link "Como funciona e políticas" em
  `/fornecedores/cadastro`.
- `lib/tracking.ts`: evento de clique no CTA + `CompleteRegistration` no cadastro concluído.

## Critérios de Aceite

- [x] `/para-fornecedores` acessível deslogado (sem redirect pro `/login`) — `isPublicPath` + teste
- [x] Responsiva — validado 390px (`scrollWidth === clientWidth`) e 1366px no browser
- [x] Todos os CTAs levam a `/fornecedores/cadastro`; `#politicas` funciona; links do footer da
      `/landing` e de `/fornecedores/cadastro` funcionam
- [x] Texto de políticas bate com o comportamento real do backend — revisão final achou a política
      de "3 dias de tolerância" não aplicada (nenhum código marca fornecedor `PAST_DUE`); copy
      ajustada e backend registrado em [TASK-288](TASK-288.md)
- [x] Nenhuma prova social numérica na página (teste em `content.test.ts`)
- [~] Eventos Pixel/GA: clique no CTA validado no browser; `CompleteRegistration` coberto por teste
      unitário, ponta a ponta pendente (API local fora do ar) — conferir no Meta Events Manager
- [x] Fluxo de cadastro/pagamento de fornecedor inalterado (só link + evento)
- [x] `tsc`/`build` limpos, sem erro de lint novo, `npm test` 155/158 (3 falhas pré-existentes de
      `middleware.test.ts`)

## Dependências
Nenhuma.

## Riscos
Baixo — página nova, aditiva, sem backend. Atenção à allowlist do `Shell.tsx` (bug recorrente).

## Esforço
Médio

## Implementação
- Branch: `feature/TASK-285-para-fornecedores` (repo `web`, a partir de `staging`)
- Nova rota `src/app/para-fornecedores/` (`page.tsx`, `content.ts` + teste, mockups em `_components/`,
  `opengraph-image.tsx`), foto `public/para-fornecedores-hero.webp` (Unsplash, Emmanuel Ikwuegbu)
- `src/lib/publicPaths.ts` (+ teste): allowlist pública extraída do `Shell.tsx`
- `src/lib/tracking.ts`: `trackSupplierSignupClick`, `trackCompleteRegistration`
- `sitemap.ts`, footer da `/landing`, link + evento em `/fornecedores/cadastro`
- Revisão final independente: 2 achados importantes corrigidos (copy de tolerância → TASK-288;
  scroll horizontal de 12px em 390px por gutter `g-5`)
- PR: [web#94](https://github.com/douglasjava/easy-maintenance-web/pull/94) (`staging`)

## Status
🟡 Em Validação — implementado, testado, PR aberta contra `staging`.
