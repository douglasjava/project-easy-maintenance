# EPIC-022 — Blog de Conteúdo (SEO)

## Status
Implementado, revisado (subagent-driven-development) e em teste manual local por Douglas
(15/08/2026 - 17/08/2026). Branch `feature/blog-content-mdx` em `easy-maintenance-web`, ainda não
mergeada em `staging`.

## Objetivo
Dar ao site público conteúdo indexável em formato blog, pra competir por buscas informacionais nas
mesmas keywords do plano de SEO — motivado por um concorrente direto (Condo Guardian) já rodando um
blog SEO-driven nas mesmas keywords (NBR 5674, manutenção preventiva x corretiva, checklist de
manutenção predial), enquanto o Easy Maintenance não tinha blog nenhum.

## Descrição

Blog mínimo, sem CMS, com Douglas como único autor escrevendo direto no código (decisão confirmada
antes do design — descarta qualquer CMS externo). Arquitetura via `@next/mdx`: cada post é um
arquivo `.mdx` numa pasta própria (`src/app/blog/<slug>/`), sem rota dinâmica `[slug]`; um
componente compartilhado (`BlogPostShell`) dá a moldura visual; um registro manual (`posts.ts`)
alimenta tanto o índice (`/blog`) quanto `sitemap.ts`.

Desenhado via brainstorm com Douglas — spec em
`docs/superpowers/specs/2026-08-17-blog-content-design.md`. Plano de implementação em
`docs/superpowers/plans/2026-08-17-blog-content.md`, executado via subagent-driven-development (5
tasks + 1 fix de revisão final).

**Entrega desta primeira leva**: infraestrutura completa do blog + 1 post real publicado ("NBR 5674
na prática: o que a norma exige do síndico"), provando o pipeline de ponta a ponta.

---

## Contexto Técnico

- `@next/mdx` habilitado no App Router (`next.config.ts`) — `.mdx` vira página como qualquer
  `page.tsx`, inclusive `export const metadata`. **Achado importante**: arquivos `.mdx` não aceitam
  `import type`/anotação de tipo TypeScript (parser acorn do MDX não entende sintaxe TS) —
  `metadata` precisa ser exportado como objeto puro, sem `: Metadata`. Vale pra qualquer post futuro.
- `BlogPostShell` (`src/components/blog/BlogPostShell.tsx`) reaproveita o mesmo navbar+container de
  `/termos`, e reaproveita `parseDateSafe`/`formatDateLong` já existentes em `src/lib/formatters.ts`
  (evita bug de fuso horário já resolvido ali, não reimplementado).
- **Achado crítico corrigido durante a revisão final**: `/blog` não estava no allowlist público do
  `Shell.tsx` (o gate de rota real deste app — `middleware.ts` é um no-op deliberado, ver comentário
  no próprio arquivo). Sem esse ajuste, visitante anônimo era redirecionado pro `/login` e o
  conteúdo nunca chegava a renderizar no DOM — nulificava o propósito inteiro da feature. Nenhuma
  task do plano tocava `Shell.tsx`; só apareceu na revisão de branch inteira, não nas revisões por
  task. Corrigido (`src/components/Shell.tsx`, commit `d1d5982`).
- `robots.txt`/`sitemap.ts` já seguiam um modelo default-deny (de uma mudança de SEO anterior) — só
  precisou de `Allow: /blog` + entradas no sitemap via `.map()` sobre `posts.ts`.

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-170](../tasks/TASK-170.md) | Blog: infraestrutura MDX + primeiro post real (NBR 5674) | FRONTEND | 🟠 Alto |

---

## Critério de Conclusão do Épico (desta primeira leva)

- [x] `@next/mdx` configurado, `.mdx` funcionando como rota do App Router
- [x] `BlogPostShell` criado, reaproveitando padrão visual de `/termos`
- [x] Primeiro post real publicado (`/blog/nbr-5674-responsabilidade-sindico`)
- [x] Índice `/blog` + registro `posts.ts`
- [x] `robots.txt`/`sitemap.ts` expondo `/blog`
- [x] `Shell.tsx` corrigido — `/blog` renderiza publicamente, sem redirect pro `/login`
- [x] Revisão de código completa (5 tasks + revisão final da branch), todas aprovadas
- [ ] **QA manual de Douglas** — em andamento; achados até agora (17/08/2026): link do blog não
      está na landing page, layout dos posts precisa de refinamento visual
- [ ] Merge em `staging`

---

## Fora de Escopo (desta primeira leva — decidir com Douglas se/quando virar task)

- Link para `/blog` na landing page ou navbar (hoje é página órfã, descoberta só via sitemap) —
  achado na revisão final, ainda não resolvido.
- Refinamento visual/tipografia dos posts (`BlogPostShell` hoje usa só Bootstrap padrão, sem CSS
  dedicado pro conteúdo longo) — achado no teste manual de Douglas, escopo ainda não definido.
- Escrever os posts 2-5 (temas já aprovados na spec: manutenção preventiva x corretiva, checklist de
  manutenção predial, planilha de manutenção falha, CMMS Brasil).
- Paginação, categorias/tags, posts relacionados, comentários, RSS, multi-autor, busca interna, CMS.

## Riscos
Baixo — feature aditiva, não altera nenhum fluxo autenticado. Único ponto de atenção já resolvido:
o gap do `Shell.tsx` (ver Contexto Técnico) — sem ele a feature não tinha efeito prático nenhum
apesar do código estar correto.
