# TASK-170 — Frontend: Blog — infraestrutura MDX + primeiro post real (NBR 5674)

## Tipo
FRONTEND

## Categoria
Marketing / SEO

## Prioridade
🟠 Alto

## Épico
[EPIC-022](../epics/EPIC-022.md) — Blog de Conteúdo (SEO)

## QA obrigatório
Sim — QA manual de Douglas concluído (17-18/08/2026). Os 2 achados (link ausente na landing, layout
a refinar) viraram [TASK-171](TASK-171.md), já resolvida.

---

## Contexto

Motivado por um concorrente direto, [Condo Guardian](https://condoguardian.com.br/), com
posicionamento quase idêntico ao nosso e um blog SEO-driven ativo nas mesmas keywords do nosso
plano de SEO (ver `docs/produto/contexto-comercial.md`, seção "Concorrente mais próximo"). O Easy
Maintenance não tinha blog algum — a landing estática competia mal por buscas informacionais.

Desenhado via brainstorm com Douglas (spec em
`docs/superpowers/specs/2026-08-17-blog-content-design.md`), implementado via plano detalhado
(`docs/superpowers/plans/2026-08-17-blog-content.md`) executado com subagent-driven-development: 5
tasks de implementação (setup MDX, componente de moldura visual, primeiro post real, índice +
registro, robots/sitemap) + 1 fix de revisão final.

---

## Objetivo

Entregar a infraestrutura técnica completa do blog, com um primeiro post real publicado provando o
pipeline de ponta a ponta — sem CMS (Douglas escreve direto no código), sem rota dinâmica (cada post
é uma pasta própria, mesmo padrão de `/termos`/`/privacidade`).

---

## Escopo

### 1. Setup MDX
`@next/mdx` configurado em `next.config.ts` (`pageExtensions` inclui `mdx`, `createMDX()` envolve o
config, mantendo `withSentryConfig` por fora).

### 2. `BlogPostShell` (`src/components/blog/BlogPostShell.tsx`)
Componente compartilhado — navbar+container reaproveitados de `/termos`, título, data (via
`formatDateLong`, novo export em `src/lib/formatters.ts` que reaproveita `parseDateSafe` já
existente — sem duplicar a lógica de fuso horário), link "voltar pro blog".

### 3. Primeiro post real
`src/app/blog/nbr-5674-responsabilidade-sindico/page.mdx` — artigo completo sobre a norma NBR 5674,
`metadata` (title/description/robots/canonical/openGraph) exportado direto do `.mdx` como objeto
puro (sem anotação de tipo — `.mdx` não aceita `import type`/sintaxe TS, achado durante a
implementação).

### 4. Índice `/blog` + registro de posts
`src/app/blog/posts.ts` (array `BLOG_POSTS` mantido à mão) + `src/app/blog/page.tsx` (lista os
posts, mais recente primeiro).

### 5. SEO
`public/robots.txt` ganha `Allow: /blog`; `src/app/sitemap.ts` ganha entradas via `.map()` sobre
`BLOG_POSTS`, com `lastModified` = data real de cada post (não data de build).

### 6. Fix crítico (achado na revisão final da branch, fora de qualquer task do plano)
`src/components/Shell.tsx` — `/blog` não estava no allowlist de rotas públicas (o gate de auth real
deste app; `middleware.ts` é no-op deliberado). Sem o fix, visitante anônimo era redirecionado pro
`/login` e o conteúdo nunca renderizava — a feature inteira ficava sem efeito prático apesar do
código estar certo. Corrigido, verificado inspecionando o HTML estático gerado (não só lendo o
código).

---

## Critérios de Aceite

- [x] `.mdx` funciona como rota do App Router, com `metadata` reconhecido pelo Next
- [x] `BlogPostShell` reaproveita padrão visual de `/termos`, sem duplicar lógica de data
- [x] Post real publicado em `/blog/nbr-5674-responsabilidade-sindico`, indexável
      (`robots: index:true`)
- [x] `/blog` lista o post, ordenado por data
- [x] `robots.txt`/`sitemap.ts` expõem `/blog` e o post, sem tocar nas entradas já existentes
- [x] `/blog` acessível sem login (fix do `Shell.tsx`) — confirmado no HTML estático gerado, não só
      no código
- [x] `npm run build` limpo em toda task
- [x] Revisão de código: 5 tasks + revisão final da branch, todas aprovadas (subagent-driven-development)
- [x] QA manual de Douglas — 2 achados de UX/design encontrados, resolvidos na [TASK-171](TASK-171.md)

## Dependências
Nenhuma.

## Riscos
Baixo — aditivo, não altera fluxo autenticado. O risco real (rota pública não acessível) já foi
identificado e corrigido durante a própria implementação, não é mais um risco em aberto.

## Esforço
Médio (5 tasks técnicas + 1 fix de revisão)

## Status
Em Validação — implementado, revisado, QA manual concluído (achados viraram TASK-171). Falta só o
merge em `staging`. Branch `feature/blog-content-mdx` (`easy-maintenance-web`), até o commit `d1d5982`.
