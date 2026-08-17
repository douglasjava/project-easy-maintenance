# Blog de Conteúdo (SEO) — Design

**Data**: 2026-08-17
**Status**: Aprovado por Douglas (via diálogo de brainstorm)

## Contexto

Douglas encontrou um concorrente direto, [Condo Guardian](https://condoguardian.com.br/), com
posicionamento quase idêntico ao nosso (NBR 5674, tira o síndico da planilha/WhatsApp, mesmo ICP
central) e um blog ativo (`condoguardian.com.br/blog`, ~quinzenal, 6 posts desde 12/07/2026) com
conteúdo educacional SEO-driven nas mesmas keywords do nosso plano de SEO (NBR 5674, manutenção
preventiva x corretiva, checklist de manutenção predial — ver `docs/produto/contexto-comercial.md`,
seção "Concorrente mais próximo").

O Easy Maintenance não tem blog hoje. A landing estática compete mal por buscas informacionais
("manutenção preventiva x corretiva" é pesquisa, não intenção de compra) contra um concorrente que
já está construindo autoridade orgânica nessas keywords. Este documento desenha a arquitetura
técnica de um blog mínimo pra fechar essa lacuna.

## Decisões de escopo (confirmadas com Douglas)

1. **Autor único, direto no código**: Douglas escreve/publica sozinho, sem necessidade de interface
   de edição pra não-técnico. Isso descarta qualquer CMS externo (Contentful, Sanity, etc.) — seria
   infraestrutura nova resolvendo um problema que não existe aqui.
2. **Conteúdo em MDX nativo do Next.js** (`@next/mdx`), não JSX puro nem CMS. Cada post é um arquivo
   `.mdx` versionado no mesmo repo, escrito em markdown — sem a fricção de fechar `<p>` por
   parágrafo que uma página `.tsx` manual (como `/termos`) teria, mas sem nenhuma dependência de
   infraestrutura externa.
3. **Sem rota dinâmica `[slug]`**: cada post é uma pasta própria (`src/app/blog/<slug>/page.mdx`),
   igual a qualquer outra rota do app hoje (`/termos`, `/privacidade`) — não um sistema genérico de
   carregamento de conteúdo. Se o volume crescer muito (dezenas de posts), revisitar; não antes.
4. **MVP sem cadência fixa**: 5 posts fundação pra começar, publicados quando Douglas tiver
   disponibilidade — sem compromisso de ritmo quinzenal/semanal.
5. **Fora de escopo do MVP** (revisitar só se o volume crescer):
   - Paginação e categorias/tags no índice do blog.
   - Posts relacionados, comentários, RSS, busca interna.
   - Múltiplos autores / bio de autor.
   - Qualquer automação de publicação (agendamento, newsletter).
6. **Temas dos 5 posts fundação** (aprovados por Douglas, mirando as keywords do plano de SEO):
   1. "NBR 5674 na prática: o que a norma exige do síndico" — `software ABNT NBR 5674`,
      `sistema de manutenção para síndicos`
   2. "Manutenção preventiva x corretiva: o impacto real no orçamento do condomínio" —
      `gestão de manutenção para condomínios`
   3. "Checklist de manutenção predial: o que não pode faltar no plano anual" —
      `plano de manutenção predial`
   4. "Por que a planilha de manutenção predial falha (e o que fazer em vez disso)" —
      `sistema de gestão de manutenção predial`
   5. "CMMS: o que é e por que condomínios e empresas de manutenção estão adotando no Brasil" —
      `CMMS Brasil`

   Este documento cobre só a arquitetura técnica para publicar um post — a redação dos 5 textos é
   trabalho separado, feito por Douglas (ou com apoio de IA numa sessão futura), não parte desta spec.

## Arquitetura

### Setup

Adicionar `@next/mdx` (pacote oficial do Next.js, mantido pelo próprio time do framework) e
configurar `next.config.ts` para tratar arquivos `.mdx` como páginas do App Router — permite
`export const metadata` dentro do próprio `.mdx`, igual a qualquer `page.tsx` hoje.

### Estrutura de arquivos

```
src/app/blog/
  page.tsx                        # índice do blog (lista todos os posts)
  posts.ts                        # registro manual: slug, title, description, date
  nbr-5674-responsabilidade-sindico/
    page.mdx                      # post 1 (metadata + conteúdo em markdown)
  manutencao-preventiva-x-corretiva/
    page.mdx                      # post 2
  ...
src/components/blog/
  BlogPostShell.tsx                # moldura visual compartilhada (novo)
```

### `BlogPostShell` (componente novo)

Recebe `title`, `date` e `children` (o markdown já renderizado pelo MDX). Reaproveita o mesmo
navbar+container que `/termos/page.tsx` já usa (navbar com `Logo` linkando pra `/landing`,
`container` com `maxWidth: 760`), adicionando título, data formatada e um link "← Voltar pro blog"
no topo. Cada `page.mdx` importa esse shell e envolve seu conteúdo nele.

### `posts.ts` — registro de posts

```ts
export const BLOG_POSTS = [
  { slug: "nbr-5674-responsabilidade-sindico", title: "...", description: "...", date: "2026-08-XX" },
  // ...
];
```

Mantido à mão — mesma lógica de `sitemap.ts`, que já é uma lista hand-maintained de URLs hoje. Duas
coisas consomem esse array:
- `src/app/blog/page.tsx` — renderiza a lista, mais recente primeiro. Sem paginação/categoria.
- `src/app/sitemap.ts` — um `.map()` sobre `BLOG_POSTS` adicionando cada URL de post, do mesmo jeito
  que `/termos`/`/privacidade` já são adicionados manualmente.

Isso duplica `title`/`date` entre `posts.ts` e o `metadata` de cada `page.mdx`. Aceito como
trade-off pra 3-5 posts — não vale construir leitura automática de frontmatter só pra eliminar essa
duplicação pequena.

### SEO

- Cada `page.mdx` exporta `metadata` (title, description, openGraph, `robots: {index:true,
  follow:true}`, `alternates.canonical`) — mesmo padrão de `landing/layout.tsx` e `termos/page.tsx`.
- `public/robots.txt` ganha `Allow: /blog` — como é prefixo, cobre o índice e todos os posts com uma
  linha só (mesmo raciocínio já usado para `Allow: /indicador/novo`).
- `sitemap.ts` ganha as entradas via `BLOG_POSTS.map(...)`.

### Fluxo de publicação de um post novo

1. Criar a pasta `src/app/blog/<slug>/` com `page.mdx` (metadata + conteúdo).
2. Adicionar uma linha em `posts.ts`.
3. Deploy normal (sem passo de build adicional).

## Testes / Validação

Sem suíte de teste automatizada nova — mesmo padrão já aplicado a `/termos` e `/privacidade`
(páginas de conteúdo estático não têm teste próprio neste projeto). `npm run build` é a validação
suficiente: garante que o MDX compila e que as rotas geram sem erro, mesmo bar de QA usado nas
últimas mudanças de SEO.

## Fora de Escopo (não construir agora)

- Paginação, categorias/tags, posts relacionados, comentários, RSS, multi-autor, busca interna.
- Qualquer CMS ou interface de edição não-técnica.
- Rota dinâmica `[slug]` / sistema genérico de carregamento de conteúdo.
- Redação do conteúdo dos 5 posts (trabalho separado desta spec técnica).
