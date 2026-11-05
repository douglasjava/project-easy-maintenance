# Blog de Conteúdo (SEO) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao Easy Maintenance um blog mínimo (`/blog` + posts individuais) usando MDX nativo do Next.js, provando o pipeline de ponta a ponta com um primeiro post real, pra competir por buscas informacionais nas mesmas keywords que o concorrente Condo Guardian já ataca com o blog dele.

**Architecture:** `@next/mdx` habilita `.mdx` como página do App Router. Cada post é uma pasta própria (`src/app/blog/<slug>/page.mdx`, sem rota dinâmica), envolvida por um componente compartilhado (`BlogPostShell`) que dá a moldura visual. Um registro manual (`src/app/blog/posts.ts`) alimenta tanto o índice (`/blog`) quanto `sitemap.ts` — mesmo padrão de lista hand-maintained que `sitemap.ts` já usa hoje para `/termos`, `/privacidade` etc.

**Tech Stack:** Next.js 16 App Router / TypeScript / Bootstrap (classes já usadas em `termos/page.tsx`) / `@next/mdx`.

## Global Constraints

- Sem CMS, sem rota dinâmica `[slug]`, sem paginação/categorias/tags/posts relacionados/comentários/RSS/multi-autor/busca — fora de escopo do MVP (`docs/superpowers/specs/2026-08-17-blog-content-design.md`).
- Sem suíte de teste automatizada nova — este projeto não testa componentes React (nenhum `@testing-library/react` instalado, nenhum `*.test.tsx` em `src/components`) nem páginas de conteúdo estático (`/termos`, `/privacidade` não têm teste próprio). A validação de cada task é `npm run build` (e `npx tsc --noEmit` quando aplicável), mesmo padrão já usado nas últimas mudanças de SEO deste projeto.
- **Todo novo `metadata` export precisa de `robots: { index: true, follow: true }` explícito.** O `src/app/layout.tsx` raiz tem hoje `robots: { index: false, follow: false }` como default (mudança de uma PR anterior de SEO) — qualquer página nova que não sobrescrever isso fica noindex por herança silenciosa. Vale para o índice do blog (Task 4) e para cada post (Task 3).
- Redação dos posts 2–5 (temas já aprovados na spec) fica fora deste plano — só o primeiro post real é escrito aqui, para provar o pipeline MDX ponta a ponta.
- Tom de voz: direto, sem jargão de SaaS genérico, português do Brasil sem anglicismo, sem prova social numérica (zero clientes pagantes confirmados — `docs/produto/contexto-comercial.md`), sem promessa de reembolso.

---

### Task 1: Instalar e configurar `@next/mdx`

**Files:**
- Modify: `easy-maintenance-web/package.json`
- Modify: `easy-maintenance-web/next.config.ts`

**Interfaces:**
- Consumes: nada de outras tasks.
- Produces: `next.config.ts` com `pageExtensions` incluindo `"mdx"` e `createMDX()` aplicado — Task 3 depende disso para que `page.mdx` seja reconhecido como rota.

- [ ] **Step 1: Instalar as dependências**

Rodar dentro de `easy-maintenance-web/`:
```bash
npm install @next/mdx @mdx-js/loader --save
```

- [ ] **Step 2: Configurar `next.config.ts`**

Ler o arquivo atual antes de editar (ele já tem `withSentryConfig` envolvendo o config). Resultado esperado após a edição:

```ts
import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs";
import createMDX from "@next/mdx";

const nextConfig: NextConfig = {
  reactCompiler: true,
  pageExtensions: ["ts", "tsx", "mdx"],

  // Serve static images directly without the optimizer.
  // Avoids issues with /_next/image redirects on Railway + custom domain.
  images: {
    unoptimized: true,
  },

  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          {
            key: "Strict-Transport-Security",
            value: "max-age=31536000; includeSubDomains",
          },
          {
            key: "Referrer-Policy",
            value: "strict-origin-when-cross-origin",
          },
          {
            key: "Permissions-Policy",
            value: "camera=(), microphone=(), geolocation=()",
          },
        ],
      },
    ];
  },
};

const withMDX = createMDX({});

export default withSentryConfig(withMDX(nextConfig), {
  // Suppress non-error SDK output during build
  silent: !process.env.CI,

  // Do not upload source maps (requires SENTRY_AUTH_TOKEN — configure when needed)
  // org: process.env.SENTRY_ORG,
  // project: process.env.SENTRY_PROJECT,

  // Reduce client bundle size by removing Sentry SDK logger statements
  disableLogger: true,

  // Opt out of Sentry telemetry
  telemetry: false,

  // Do not auto-instrument Vercel Cron Monitors
  automaticVercelMonitors: false,
});
```

Só duas mudanças reais: a importação de `createMDX`, a linha `pageExtensions: ["ts", "tsx", "mdx"]`, a constante `withMDX` e trocar `withSentryConfig(nextConfig, {...})` por `withSentryConfig(withMDX(nextConfig), {...})`. Tudo o mais permanece idêntico ao arquivo original.

- [ ] **Step 3: Validar que o build ainda passa**

```bash
npm run build
```
Esperado: build limpo, mesmas 48 rotas de antes (nenhuma rota nova ainda — esta task só habilita a capacidade, não cria nenhum `.mdx`).

- [ ] **Step 4: Commit**

```bash
git add package.json package-lock.json next.config.ts
git commit -m "feat(blog): habilita suporte a MDX no App Router (@next/mdx)"
```

---

### Task 2: Criar `BlogPostShell`

**Files:**
- Create: `easy-maintenance-web/src/components/blog/BlogPostShell.tsx`
- Modify: `easy-maintenance-web/src/lib/formatters.ts`

**Interfaces:**
- Consumes: `Logo` de `@/components/Logo` (já existe, usado em `termos/page.tsx`). `parseDateSafe` (função privada já existente em `src/lib/formatters.ts`, usada hoje por `formatDate`/`formatDateTime`) — **reaproveitar**, não reimplementar: já resolve o mesmo bug de fuso horário (`new Date("2026-08-17")` é interpretado como UTC meia-noite e vira 16/08 em fusos negativos como o do Brasil) que uma função de data nova precisaria resolver de novo.
- Produces: `export default function BlogPostShell({ title, date, children }: { title: string; date: string; children: React.ReactNode })` — Task 3 importa e usa exatamente essa assinatura. `date` é uma string `"YYYY-MM-DD"`. Também produz `export function formatDateLong(date: string): string` em `src/lib/formatters.ts` — Task 4 importa essa mesma função pro índice do blog, em vez de duplicá-la.

- [ ] **Step 1: Adicionar `formatDateLong` a `src/lib/formatters.ts`**

Ler o arquivo atual antes de editar — ele já exporta `formatMoney`, `formatDate`, `formatDateTime` e a classe `Formatters`, todos usando a função privada `parseDateSafe` (não exportada) pra evitar o bug de fuso horário acima. Adicionar, junto das outras exportações de data (perto de `formatDateTime`):

```ts
export function formatDateLong(date: string | Date | null | undefined): string {
  if (!date) return "-";
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  }).format(parseDateSafe(date));
}
```

Não duplica `parseDateSafe` — só chama a função privada já existente no mesmo arquivo, do mesmo jeito que `formatDate`/`formatDateTime` já fazem.

- [ ] **Step 2: Criar o componente**

```tsx
import Link from "next/link";
import Logo from "@/components/Logo";
import { formatDateLong } from "@/lib/formatters";

type BlogPostShellProps = {
    title: string;
    date: string;
    children: React.ReactNode;
};

export default function BlogPostShell({ title, date, children }: BlogPostShellProps) {
    return (
        <>
            <nav className="navbar navbar-light bg-white sticky-top shadow-sm">
                <div className="container">
                    <Link href="/landing" className="navbar-brand mb-0">
                        <Logo />
                    </Link>
                </div>
            </nav>
            <div className="container py-5" style={{ maxWidth: 760 }}>
                <Link href="/blog" className="d-inline-block mb-4 small text-muted">
                    ← Voltar pro blog
                </Link>
                <h1 className="fw-bold mb-1">{title}</h1>
                <p className="text-muted small mb-5">{formatDateLong(date)}</p>
                <div className="blog-post-content">{children}</div>
            </div>
        </>
    );
}
```

- [ ] **Step 3: Validar tipos**

```bash
npx tsc --noEmit -p .
```
Esperado: limpo (os mesmos 2 erros pré-existentes em `PendingPixPaymentCard.test.ts` e `useDashboardData.test.ts`, não relacionados, podem continuar aparecendo — não são desta task).

- [ ] **Step 4: Commit**

```bash
git add src/lib/formatters.ts src/components/blog/BlogPostShell.tsx
git commit -m "feat(blog): componente BlogPostShell (moldura visual dos posts)"
```

---

### Task 3: Primeiro post real — "NBR 5674 na prática: o que a norma exige do síndico"

Prova o pipeline MDX de ponta a ponta: `.mdx` como rota, `metadata` exportado de dentro do `.mdx`, `BlogPostShell` consumido de verdade.

**Files:**
- Create: `easy-maintenance-web/src/app/blog/nbr-5674-responsabilidade-sindico/page.mdx`

**Interfaces:**
- Consumes: `BlogPostShell` (Task 2), exatamente a assinatura `{ title, date, children }`.
- Produces: rota pública `/blog/nbr-5674-responsabilidade-sindico`, slug `"nbr-5674-responsabilidade-sindico"` — Task 4 usa esse slug exato em `posts.ts`.

- [ ] **Step 1: Criar o post**

```mdx
import type { Metadata } from "next";
import BlogPostShell from "@/components/blog/BlogPostShell";

export const metadata: Metadata = {
    title: "NBR 5674 na prática: o que a norma exige do síndico",
    description:
        "Entenda o que a NBR 5674 exige do síndico na manutenção predial: plano formal, evidências e responsabilidade civil. Veja como cumprir sem planilha.",
    robots: {
        index: true,
        follow: true,
    },
    alternates: {
        canonical: "https://easymaintenance.com.br/blog/nbr-5674-responsabilidade-sindico",
    },
    openGraph: {
        title: "NBR 5674 na prática: o que a norma exige do síndico | Easy Maintenance",
        description:
            "Entenda o que a NBR 5674 exige do síndico na manutenção predial: plano formal, evidências e responsabilidade civil.",
        url: "https://easymaintenance.com.br/blog/nbr-5674-responsabilidade-sindico",
        images: [
            {
                url: "/dashboard_preview.png",
                width: 1200,
                height: 630,
                alt: "Easy Maintenance — Plataforma de Gestão de Manutenção Preventiva",
            },
        ],
    },
};

<BlogPostShell title="NBR 5674 na prática: o que a norma exige do síndico" date="2026-08-17">

A NBR 5674 é a norma da ABNT que trata da manutenção de edificações. Na prática, ela diz uma coisa simples e incômoda: manter um prédio em condições de uso não é consertar o que quebra — é ter um **sistema de gestão de manutenção**, com plano formal, rotina de inspeção e registro do que foi feito.

## O que a norma realmente exige

Reduzida ao essencial, a NBR 5674 pede três coisas de qualquer edificação:

- Um **plano de manutenção**, com periodicidade definida por sistema — elétrico, hidráulico, estrutural, incêndio, elevadores — normalmente herdado do Manual de Uso, Operação e Manutenção que a construtora deveria ter entregue (esse manual é objeto da NBR 14037, a norma complementar).
- **Inspeções periódicas**, documentadas — não "quando alguém reclama".
- **Registro histórico** de cada intervenção: o que foi feito, quando, e por quem.

Nenhum dos três é opcional. A norma em si não tem poder de multa — ela vira a régua usada em perícia técnica quando algo dá errado: infiltração, queda de reboco, acidente em elevador. É nesse momento que "eu troquei o filtro mês passado" sem nenhum registro documentado deixa de ser desculpa e vira problema jurídico real, com responsabilidade civil (e em casos graves, criminal) recaindo sobre quem deveria ter mantido o sistema em dia.

## Por que isso recai sobre o síndico

Legalmente, quem responde pela manutenção do condomínio é o síndico — morador ou profissional. Administradora terceirizada não tira essa responsabilidade, só divide a operação. Isso significa que a exigência da NBR 5674 não é uma preocupação de engenheiro distante: é uma obrigação que o síndico carrega pessoalmente, mesmo sem ser da área técnica.

## O problema raramente é falta de vontade

Na prática, quase todo síndico *tenta* manter isso em dia. O que falha é a ferramenta: uma planilha por prédio, sem histórico consolidado, que some quando o síndico troca. Ordens de manutenção combinadas por WhatsApp, sem rastro formal de execução. Nenhuma evidência fotográfica vinculada ao que foi realmente feito. Quando a fiscalização (ou uma perícia, depois de um incidente) pede o comprovante, não existe nada organizado pra mostrar — mesmo que o serviço tenha sido feito.

## O que muda com um sistema formal

Um plano de manutenção formalizado — com cronograma automático por sistema, evidência fotográfica vinculada a cada execução e histórico que não depende da memória de uma pessoa só — resolve exatamente o ponto onde a maioria dos condomínios falha: não a execução da manutenção em si, mas a comprovação de que ela aconteceu. É a diferença entre responder "sim, está em dia" com um relatório na mão, ou com uma torcida.

---

Se você é síndico ou administra condomínios e quer sair da planilha sem contratar um consultor pra isso, o [Easy Maintenance](/landing) tem um teste grátis de 14 dias, sem cartão de crédito.

</BlogPostShell>
```

- [ ] **Step 2: Validar o build**

```bash
npm run build
```
Esperado: build limpo, e a tabela de rotas impressa no final inclui
`○ /blog/nbr-5674-responsabilidade-sindico` (estática, prerendered).

- [ ] **Step 3: Commit**

```bash
git add src/app/blog/nbr-5674-responsabilidade-sindico/page.mdx
git commit -m "feat(blog): primeiro post — NBR 5674 na prática"
```

---

### Task 4: `posts.ts` + índice `/blog`

**Files:**
- Create: `easy-maintenance-web/src/app/blog/posts.ts`
- Create: `easy-maintenance-web/src/app/blog/page.tsx`

**Interfaces:**
- Consumes: `formatDateLong` de `@/lib/formatters` (Task 2) — não redefinir localmente. Referencia o slug criado na Task 3 como dado, não como import.
- Produces: `export type BlogPost = { slug: string; title: string; description: string; date: string }` e `export const BLOG_POSTS: BlogPost[]` de `src/app/blog/posts.ts` — Task 5 (`sitemap.ts`) importa exatamente esse nome e formato.

- [ ] **Step 1: Criar o registro de posts**

```ts
export type BlogPost = {
    slug: string;
    title: string;
    description: string;
    date: string;
};

export const BLOG_POSTS: BlogPost[] = [
    {
        slug: "nbr-5674-responsabilidade-sindico",
        title: "NBR 5674 na prática: o que a norma exige do síndico",
        description:
            "Entenda o que a NBR 5674 exige do síndico na manutenção predial: plano formal, evidências e responsabilidade civil. Veja como cumprir sem planilha.",
        date: "2026-08-17",
    },
];
```

- [ ] **Step 2: Criar a página de índice**

```tsx
import type { Metadata } from "next";
import Link from "next/link";
import Logo from "@/components/Logo";
import { formatDateLong } from "@/lib/formatters";
import { BLOG_POSTS } from "./posts";

export const metadata: Metadata = {
    title: "Blog",
    description:
        "Conteúdo sobre manutenção predial preventiva, normas ABNT e gestão de condomínios, hospitais, escolas e indústrias.",
    robots: {
        index: true,
        follow: true,
    },
    alternates: {
        canonical: "https://easymaintenance.com.br/blog",
    },
};

export default function BlogIndexPage() {
    const posts = [...BLOG_POSTS].sort((a, b) => (a.date < b.date ? 1 : -1));

    return (
        <>
            <nav className="navbar navbar-light bg-white sticky-top shadow-sm">
                <div className="container">
                    <Link href="/landing" className="navbar-brand mb-0">
                        <Logo />
                    </Link>
                </div>
            </nav>
            <div className="container py-5" style={{ maxWidth: 760 }}>
                <h1 className="fw-bold mb-5">Blog</h1>
                {posts.map((post) => (
                    <article key={post.slug} className="mb-5 pb-4 border-bottom">
                        <p className="text-muted small mb-1">{formatDateLong(post.date)}</p>
                        <h2 className="h4 fw-bold mb-2">
                            <Link href={`/blog/${post.slug}`} className="text-decoration-none text-dark">
                                {post.title}
                            </Link>
                        </h2>
                        <p className="text-muted mb-0">{post.description}</p>
                    </article>
                ))}
            </div>
        </>
    );
}
```

- [ ] **Step 3: Validar o build**

```bash
npm run build
```
Esperado: build limpo, rota `○ /blog` aparece na tabela final junto com `○ /blog/nbr-5674-responsabilidade-sindico`.

- [ ] **Step 4: Commit**

```bash
git add src/app/blog/posts.ts src/app/blog/page.tsx
git commit -m "feat(blog): índice /blog e registro de posts (posts.ts)"
```

---

### Task 5: `robots.txt` + `sitemap.ts`

**Files:**
- Modify: `easy-maintenance-web/public/robots.txt`
- Modify: `easy-maintenance-web/src/app/sitemap.ts`

**Interfaces:**
- Consumes: `BLOG_POSTS` de `./blog/posts` (Task 4), formato `{ slug, title, description, date }[]`.
- Produces: nada consumido por outra task — última task do plano.

- [ ] **Step 1: Atualizar `robots.txt`**

Estado atual do arquivo (após a PR anterior de SEO):
```
User-agent: *
Allow: /landing
Allow: /login
Allow: /privacidade
Allow: /termos
Allow: /forgot-password
Allow: /reset-password
Allow: /indicador/novo
Disallow: /
Disallow: /api/

Sitemap: https://easymaintenance.com.br/sitemap.xml
```

Adicionar uma linha `Allow: /blog` (cobre `/blog` e `/blog/<qualquer-slug>` por ser prefixo — não precisa de uma linha por post):
```
User-agent: *
Allow: /landing
Allow: /login
Allow: /privacidade
Allow: /termos
Allow: /forgot-password
Allow: /reset-password
Allow: /indicador/novo
Allow: /blog
Disallow: /
Disallow: /api/

Sitemap: https://easymaintenance.com.br/sitemap.xml
```

- [ ] **Step 2: Atualizar `sitemap.ts`**

Ler o arquivo atual antes de editar (ele já tem entradas para `/landing`, `/login`, `/privacidade`, `/termos`, `/indicador/novo` de PRs anteriores). Adicionar o import de `BLOG_POSTS` e, no array retornado, uma entrada pra `/blog` mais uma entrada por post via `.map()`:

```ts
import { MetadataRoute } from "next";
import { BLOG_POSTS } from "./blog/posts";

export default function sitemap(): MetadataRoute.Sitemap {
    return [
        {
            url: "https://easymaintenance.com.br/landing",
            lastModified: new Date(),
            changeFrequency: "monthly",
            priority: 1,
        },
        {
            url: "https://easymaintenance.com.br/login",
            lastModified: new Date(),
            changeFrequency: "yearly",
            priority: 0.5,
        },
        {
            url: "https://easymaintenance.com.br/privacidade",
            lastModified: new Date(),
            changeFrequency: "yearly",
            priority: 0.3,
        },
        {
            url: "https://easymaintenance.com.br/termos",
            lastModified: new Date(),
            changeFrequency: "yearly",
            priority: 0.3,
        },
        {
            url: "https://easymaintenance.com.br/indicador/novo",
            lastModified: new Date(),
            changeFrequency: "monthly",
            priority: 0.6,
        },
        {
            url: "https://easymaintenance.com.br/blog",
            lastModified: new Date(),
            changeFrequency: "weekly",
            priority: 0.6,
        },
        ...BLOG_POSTS.map((post) => ({
            url: `https://easymaintenance.com.br/blog/${post.slug}`,
            lastModified: new Date(post.date),
            changeFrequency: "monthly" as const,
            priority: 0.7,
        })),
    ];
}
```

- [ ] **Step 3: Validar o build**

```bash
npm run build
```
Esperado: build limpo, todas as rotas anteriores + `/blog` + `/blog/nbr-5674-responsabilidade-sindico` presentes, `/sitemap.xml` gera sem erro.

- [ ] **Step 4: Commit**

```bash
git add public/robots.txt src/app/sitemap.ts
git commit -m "feat(blog): expõe /blog no robots.txt e sitemap.ts"
```

---

## Depois deste plano (fora de escopo, não são tasks aqui)

- Redigir e publicar os posts 2–5 já aprovados na spec (manutenção preventiva x corretiva, checklist de manutenção predial, planilha de manutenção falha, CMMS Brasil) — cada um segue exatamente o padrão da Task 3 (pasta nova + `page.mdx` + entrada em `posts.ts`).
- Abrir branch a partir de `origin/staging`, PR pra `staging`, depois PR `staging → main` — mesmo fluxo já usado nas últimas mudanças deste projeto, fora do escopo de um plano de implementação técnica.
