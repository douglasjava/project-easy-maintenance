# TASK-171 — Frontend: Blog — achados de QA (link/layout) + posts 2-5

## Tipo
FRONTEND

## Categoria
Marketing / SEO

## Prioridade
🟠 Alto

## Épico
[EPIC-022](../epics/EPIC-022.md) — Blog de Conteúdo (SEO)

## QA obrigatório
Sim — validado por Douglas em teste manual local (17-18/08/2026), incluindo referência visual
externa ([Easy Alert](https://easyalert.com.br/blog/)) usada pra calibrar o redesenho do índice.

---

## Contexto

Follow-up direto da TASK-170: no teste manual local, Douglas encontrou 2 gaps (link do blog ausente
na landing, layout do índice "ruim") e pediu pra escrever os 4 posts restantes já aprovados na spec.
Durante a conversa, apontou o blog do concorrente Easy Alert como referência de layout — o índice
foi redesenhado com base nessa comparação (ver EPIC-022, seção Descrição).

---

## Escopo

### 1. Link do blog na landing
`src/app/landing/page.tsx` — item "Blog" na coluna "Navegação" do rodapé.

### 2. Redesenho do índice `/blog`
Comparado com o layout do Easy Alert e ajustado com orientação da skill `frontend-design`:
- Hero no topo (selo + título + subtítulo), substituindo o `<h1>` simples.
- Categoria como texto pequeno colorido acima do título ("Categoria · Data · X min"), no lugar do
  tratamento gráfico grande da primeira versão.
- Tempo de leitura calculado automaticamente por contagem de palavras do `.mdx`
  (`src/lib/blogReadingTime.ts`, ~200 palavras/min) — sem campo manual por post.
- Filtro de categoria clicável, client component (`src/components/blog/BlogPostGrid.tsx`).
- Capa do card passa a usar print real do produto (`dashboard_preview.webp`, já existente) em vez
  do bloco de cor abstrato da primeira versão — sem foto de banco de imagem disponível.
- Novo campo `coverImage`/`coverImageAlt` em `BlogPost` (`src/app/blog/posts.ts`).

### 3. Posts 2-5
Últimos 4 temas já aprovados na spec (`docs/superpowers/specs/2026-08-17-blog-content-design.md`),
mesmo padrão da TASK-170 (pasta própria + `page.mdx` + entrada em `posts.ts`):
- `manutencao-preventiva-x-corretiva` (Manutenção Preventiva)
- `checklist-manutencao-predial-plano-anual` (Manutenção Preventiva)
- `planilha-manutencao-predial-falha` (Gestão Predial)
- `cmms-o-que-e-brasil` (Gestão Predial)

Nenhuma edição manual em `robots.txt`/`sitemap.ts` foi necessária — ambos já cobrem `/blog/*`
automaticamente (prefixo no robots.txt, `.map()` sobre `BLOG_POSTS` no sitemap).

---

## Critérios de Aceite

- [x] Link "Blog" visível no rodapé da landing
- [x] Índice com hero, categoria discreta, tempo de leitura, filtro de categoria e capa com print
      real
- [x] 5 posts publicados no total, todos indexáveis, todos no sitemap
- [x] `npm run build` limpo em cada commit
- [x] Validado visualmente por Douglas (referência: layout do Easy Alert)

## Dependências
TASK-170 (infraestrutura do blog).

## Riscos
Baixo — aditivo. Nota não bloqueante: todos os 5 posts compartilham a mesma imagem de capa (única
imagem real disponível hoje), o que deixa o grid repetitivo — registrado como item futuro no
EPIC-022.

## Esforço
Médio

## Status
Em Validação — implementado e aprovado visualmente por Douglas em teste local. Branch
`feature/blog-content-mdx` (`easy-maintenance-web`), commits até `a97a406`, já no
`origin/feature/blog-content-mdx`.
