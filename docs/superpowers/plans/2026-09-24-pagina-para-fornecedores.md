# Página `/para-fornecedores` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Página pública de divulgação para fornecedores (`/para-fornecedores`) com proposta, preço, políticas verificadas e FAQ, levando ao cadastro existente, com tracking de conversão.

**Architecture:** 100% frontend no repo `easy-maintenance-web` (Next.js App Router + Bootstrap 5). Conteúdo textual (benefícios, passos, políticas, FAQ, preço) fica num módulo de dados `.ts` testável; a página é um Server Component (para `metadata`) que compõe componentes visuais pequenos; o único trecho client é o CTA com tracking. A lista de rotas públicas do `Shell.tsx` é extraída para `src/lib/publicPaths.ts` com teste — esse guard já quebrou 4 vezes (TASK-272/273/274 e `/agendar`).

**Tech Stack:** Next.js (App Router), React, TypeScript, Bootstrap 5, lucide-react, Jest (`ts-jest`, `testEnvironment: node`, só `*.test.ts`), `next/og` (`ImageResponse`) para Open Graph, `sharp` (já em `node_modules`) para converter a foto.

**Spec:** `docs/superpowers/specs/2026-09-24-pagina-para-fornecedores-design.md`

## Global Constraints

- Repo: `D:\workpaces\EASY_MAINTENANCE\easy-maintenance-web`. Branch `feature/TASK-285-para-fornecedores` criada a partir de `origin/staging`. PR contra `staging`.
- Rota: `/para-fornecedores` (não usar prefixo `/fornecedores/...` nem o termo "parceiro").
- Preço: **R$ 15,99/mês**; ancoragem **"cerca de R$ 0,53 por dia"**.
- Políticas: cancelamento a qualquer momento sem multa/fidelidade; **zero comissão**; **sem garantia de volume** de pedidos; ao revogar o Pix Automático o perfil **sai do marketplace na hora** (comportamento atual — TASK-286 mudará isso depois).
- **Nenhuma prova social numérica** ("X prédios", "Y pedidos", "Z fornecedores").
- **Nenhuma promessa que o sistema não cumpre** — todo texto de política corresponde à tabela "Políticas → comportamento verificado" do spec.
- Navbar da `/landing` **não** muda (link novo só no footer).
- `/fornecedores/cadastro`: única mudança visual é o link "Como funciona e políticas"; formulário/cobrança inalterados.
- Mobile obrigatório: sem scroll horizontal em 390px.
- Todo commit termina com a linha `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- `next.config` usa `images.unoptimized: true` → a foto precisa ser commitada já otimizada em `.webp`.

## Review Focus

1. **Acesso deslogado** a `/para-fornecedores` (e a `/para-fornecedores#politicas`) — deve renderizar, nunca redirecionar pro `/login`. Coberto em Task 1 (`publicPaths.test.ts`).
2. **Refactor do guard não pode mudar nenhuma rota existente** — todas as rotas públicas atuais continuam públicas e rotas privadas (`/items`, `/fornecedores` do marketplace logado, `/private/...`) continuam privadas. Coberto em Task 1.
3. **Tracking sem Pixel/GA carregado** (ad-blocker, SSR, ID não configurado) — CTA e cadastro continuam funcionando, sem exceção. Coberto em Task 2.
4. **Texto de política/FAQ contradizendo o sistema** (ex.: dizer "até o fim do mês pago", prometer volume, prova social numérica). Coberto em Task 3 (`content.test.ts`).
5. **Mockups/tabela quebrando layout no celular (390px)** — scroll horizontal. Coberto no QA manual da Task 6 (sem teste automatizado possível: Jest roda em `node`, sem DOM).

---

## File Structure

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `src/lib/publicPaths.ts` | Create | `isPublicPath(pathname)` — única fonte da allowlist de rotas públicas |
| `src/lib/publicPaths.test.ts` | Create | Rotas públicas/privadas, incluindo `/para-fornecedores` |
| `src/components/Shell.tsx` | Modify (~L21-38) | Usa `isPublicPath` no lugar da expressão inline |
| `src/lib/tracking.ts` | Modify | `trackSupplierSignupClick()`, `trackCompleteRegistration()` |
| `src/lib/tracking.test.ts` | Modify | Testes das duas funções novas |
| `src/app/para-fornecedores/content.ts` | Create | Preço, benefícios, passos, políticas, FAQ (dados puros) |
| `src/app/para-fornecedores/content.test.ts` | Create | Regras de copy (preço, políticas obrigatórias, sem prova social numérica) |
| `src/app/para-fornecedores/page.tsx` | Create | Server Component: `metadata` + composição das seções |
| `src/app/para-fornecedores/_components/SupplierSignupCta.tsx` | Create | Client: `<Link>` pro cadastro + `trackSupplierSignupClick` |
| `src/app/para-fornecedores/_components/MarketplaceCardMockup.tsx` | Create | Mockup HTML/CSS do card do fornecedor no marketplace |
| `src/app/para-fornecedores/_components/WhatsAppMessageMockup.tsx` | Create | Mockup HTML/CSS da mensagem de pedido no WhatsApp |
| `src/app/para-fornecedores/opengraph-image.tsx` | Create | OG 1200×630 via `next/og` |
| `public/para-fornecedores-hero.webp` | Create | Foto do hero (Unsplash/Pexels, licença comercial) |
| `src/app/sitemap.ts` | Modify | Entrada `/para-fornecedores` |
| `src/app/landing/page.tsx` | Modify (footer ~L621-628) | Link "Para fornecedores" |
| `src/app/fornecedores/cadastro/page.tsx` | Modify | Link pra `#politicas` + `trackCompleteRegistration()` no sucesso |

---

### Task 1: Extrair allowlist pública para `isPublicPath` e incluir `/para-fornecedores`

**Files:**
- Create: `src/lib/publicPaths.ts`
- Create: `src/lib/publicPaths.test.ts`
- Modify: `src/components/Shell.tsx:21-38`

**Interfaces:**
- Produces: `export function isPublicPath(pathname: string | null | undefined): boolean`

- [ ] **Step 0: Criar a branch**

```bash
cd /d/workpaces/EASY_MAINTENANCE/easy-maintenance-web
git fetch origin && git checkout -b feature/TASK-285-para-fornecedores origin/staging
```

- [ ] **Step 1: Escrever o teste (falha)** — `src/lib/publicPaths.test.ts`

```ts
import { isPublicPath } from "./publicPaths";

describe("isPublicPath", () => {
    it.each([
        "/login",
        "/auth/change-password",
        "/forgot-password",
        "/reset-password",
        "/select-organization",
        "/landing",
        "/agendar",
        "/checkout/abc",
        "/onboarding",
        "/indicador/novo",
        "/blog",
        "/blog/nbr-5674-responsabilidade-sindico",
        "/chamados/xyz",
        "/fornecedores/cadastro",
        "/fornecedores/gerenciar/token123",
        "/privacidade",
        "/termos",
        "/obrigado",
        "/para-fornecedores",
    ])("treats %s as public", (path) => {
        expect(isPublicPath(path)).toBe(true);
    });

    it.each([
        "/",
        "/items",
        "/fornecedores",
        "/fornecedores/gerenciar",
        "/private/admin/leads",
        "/users",
    ])("treats %s as private", (path) => {
        expect(isPublicPath(path)).toBe(false);
    });

    it("returns false for null/undefined pathname", () => {
        expect(isPublicPath(null)).toBe(false);
        expect(isPublicPath(undefined)).toBe(false);
    });
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npx jest src/lib/publicPaths.test.ts`
Expected: FAIL — `Cannot find module './publicPaths'`

- [ ] **Step 3: Implementar** — `src/lib/publicPaths.ts` (condições copiadas 1:1 do `Shell.tsx` atual + `/para-fornecedores`)

```ts
/**
 * Rotas que renderizam em tela cheia, sem sidebar/topbar e sem checagem de login (guard
 * client-side do Shell.tsx -- o middleware não protege rota nenhuma, ver src/middleware.ts).
 * Extraído do Shell.tsx na TASK-285: esquecer uma rota pública aqui já causou redirect indevido
 * pro /login 4 vezes (TASK-272/273/274, /agendar) -- agora coberto por publicPaths.test.ts.
 */
export function isPublicPath(pathname: string | null | undefined): boolean {
    if (!pathname) return false;
    return pathname.endsWith("/login") ||
        pathname.endsWith("/auth/change-password") ||
        pathname.endsWith("/forgot-password") ||
        pathname.endsWith("/reset-password") ||
        pathname.endsWith("/select-organization") ||
        pathname.includes("/landing") ||
        pathname.startsWith("/agendar") ||
        pathname.startsWith("/checkout") ||
        pathname.startsWith("/onboarding") ||
        pathname.startsWith("/indicador") ||
        pathname.startsWith("/blog") ||
        pathname.startsWith("/chamados/") ||
        pathname.startsWith("/fornecedores/cadastro") ||
        pathname.startsWith("/fornecedores/gerenciar/") ||
        pathname.startsWith("/para-fornecedores") ||
        pathname.endsWith("/privacidade") ||
        pathname.endsWith("/termos") ||
        pathname.endsWith("/obrigado");
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npx jest src/lib/publicPaths.test.ts`
Expected: PASS (todos os casos)

- [ ] **Step 5: Usar no `Shell.tsx`** — substituir o bloco `const isAuth = pathname?.endsWith("/login") || ... pathname?.endsWith("/obrigado");` (L21-38, manter o comentário das L19-20 acima) por:

```ts
  const isAuth = isPublicPath(pathname);
```

e adicionar o import junto aos demais: `import { isPublicPath } from "@/lib/publicPaths";`

- [ ] **Step 6: Verificar**

Run: `npx tsc --noEmit && npx jest src/lib/publicPaths.test.ts`
Expected: sem erros de tipo; PASS

- [ ] **Step 7: Commit**

```bash
git add src/lib/publicPaths.ts src/lib/publicPaths.test.ts src/components/Shell.tsx
git commit -m "refactor(shell): extrai allowlist publica para isPublicPath + /para-fornecedores (TASK-285)"
```

---

### Task 2: Funções de tracking do funil de fornecedor

**Files:**
- Modify: `src/lib/tracking.ts`
- Test: `src/lib/tracking.test.ts`

**Interfaces:**
- Produces: `export function trackSupplierSignupClick(): void` e `export function trackCompleteRegistration(): void`

- [ ] **Step 1: Escrever os testes (falham)** — adicionar ao fim de `src/lib/tracking.test.ts` e ajustar o import da L1 para `import { trackLead, trackContact, trackSupplierSignupClick, trackCompleteRegistration } from "./tracking";`

```ts
describe("trackSupplierSignupClick", () => {
    afterEach(() => {
        // @ts-expect-error test-only global cleanup
        delete global.window;
    });

    it("does not throw when window is undefined (SSR)", () => {
        expect(() => trackSupplierSignupClick()).not.toThrow();
    });

    it("does not throw when fbq/gtag are not installed", () => {
        // @ts-expect-error test-only global stub
        global.window = {};
        expect(() => trackSupplierSignupClick()).not.toThrow();
    });

    it("calls fbq and gtag with the supplier signup click event", () => {
        const fbq = jest.fn();
        const gtag = jest.fn();
        // @ts-expect-error test-only global stub
        global.window = { fbq, gtag };

        trackSupplierSignupClick();

        expect(fbq).toHaveBeenCalledWith("trackCustom", "SupplierSignupClick");
        expect(gtag).toHaveBeenCalledWith("event", "supplier_signup_click");
    });
});

describe("trackCompleteRegistration", () => {
    afterEach(() => {
        // @ts-expect-error test-only global cleanup
        delete global.window;
    });

    it("does not throw when window is undefined (SSR)", () => {
        expect(() => trackCompleteRegistration()).not.toThrow();
    });

    it("does not throw when fbq/gtag are not installed", () => {
        // @ts-expect-error test-only global stub
        global.window = {};
        expect(() => trackCompleteRegistration()).not.toThrow();
    });

    it("calls fbq and gtag with the CompleteRegistration event", () => {
        const fbq = jest.fn();
        const gtag = jest.fn();
        // @ts-expect-error test-only global stub
        global.window = { fbq, gtag };

        trackCompleteRegistration();

        expect(fbq).toHaveBeenCalledWith("track", "CompleteRegistration");
        expect(gtag).toHaveBeenCalledWith("event", "sign_up");
    });
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npx jest src/lib/tracking.test.ts`
Expected: FAIL — `trackSupplierSignupClick is not a function` / erro de import

- [ ] **Step 3: Implementar** — adicionar ao fim de `src/lib/tracking.ts`

```ts
// TASK-285: funil de fornecedor (/para-fornecedores -> /fornecedores/cadastro). Evento custom no
// Meta (não existe evento padrão pra "clicou no CTA"); CompleteRegistration é padrão do Meta.
export function trackSupplierSignupClick(): void {
    if (typeof window === "undefined") return;
    window.fbq?.("trackCustom", "SupplierSignupClick");
    window.gtag?.("event", "supplier_signup_click");
}

export function trackCompleteRegistration(): void {
    if (typeof window === "undefined") return;
    window.fbq?.("track", "CompleteRegistration");
    window.gtag?.("event", "sign_up");
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npx jest src/lib/tracking.test.ts`
Expected: PASS (testes antigos + 6 novos)

- [ ] **Step 5: Commit**

```bash
git add src/lib/tracking.ts src/lib/tracking.test.ts
git commit -m "feat(tracking): eventos do funil de fornecedor (TASK-285)"
```

---

### Task 3: Módulo de conteúdo da página (copy verificada)

**Files:**
- Create: `src/app/para-fornecedores/content.ts`
- Test: `src/app/para-fornecedores/content.test.ts`

**Interfaces:**
- Produces:
  - `SUPPLIER_MONTHLY_PRICE: number` (15.99)
  - `formatBRL(value: number): string`
  - `supplierDailyPrice(): string` → `"R$ 0,53"`
  - `BENEFITS: { icon: "search" | "whatsapp" | "wallet" | "trending"; title: string; text: string }[]`
  - `STEPS: { title: string; text: string }[]` (3 itens, na ordem cadastro → encontrado → WhatsApp)
  - `INCLUDED: string[]` (lista do card de preço)
  - `POLICIES: { title: string; text: string }[]`
  - `FAQ: { question: string; answer: string }[]`

- [ ] **Step 1: Escrever o teste (falha)** — `src/app/para-fornecedores/content.test.ts`

```ts
import {
    SUPPLIER_MONTHLY_PRICE, formatBRL, supplierDailyPrice,
    BENEFITS, STEPS, INCLUDED, POLICIES, FAQ,
} from "./content";

const allCopy = () => [
    ...BENEFITS.flatMap((b) => [b.title, b.text]),
    ...STEPS.flatMap((s) => [s.title, s.text]),
    ...INCLUDED,
    ...POLICIES.flatMap((p) => [p.title, p.text]),
    ...FAQ.flatMap((f) => [f.question, f.answer]),
].join("\n");

describe("preço", () => {
    it("é R$ 15,99/mês", () => {
        expect(SUPPLIER_MONTHLY_PRICE).toBe(15.99);
        expect(formatBRL(SUPPLIER_MONTHLY_PRICE)).toBe("R$ 15,99");
    });

    it("ancora em cerca de R$ 0,53 por dia", () => {
        expect(supplierDailyPrice()).toBe("R$ 0,53");
    });
});

describe("políticas (spec: tabela Políticas → comportamento verificado)", () => {
    const text = POLICIES.map((p) => `${p.title} ${p.text}`).join("\n").toLowerCase();

    it.each([
        ["Pix Automático", "pix automático"],
        ["cidade/UF", "cidade"],
        ["categorias", "categoria"],
        ["ordem da lista por organizações", "organizações"],
        ["WhatsApp", "whatsapp"],
        ["zero comissão", "comissão"],
        ["sem garantia de volume", "garantia"],
        ["3 dias de tolerância", "3 dias"],
        ["cancelamento sem multa", "sem multa"],
        ["link de gerenciamento", "link de gerenciamento"],
    ])("cobre %s", (_label, needle) => {
        expect(text).toContain(needle);
    });

    it("não promete visibilidade até o fim do período pago (TASK-286 ainda não implementada)", () => {
        expect(allCopy().toLowerCase()).not.toMatch(/fim do (mês|período) (já )?pago/);
    });
});

describe("regras de copy da página inteira", () => {
    it("não usa prova social numérica", () => {
        expect(allCopy()).not.toMatch(
            /\d[\d.]*\+?\s*(prédios|condomínios|organizações|fornecedores|clientes|pedidos|empresas|síndicos)/i,
        );
    });

    it("tem 3 passos e 5-6 perguntas no FAQ", () => {
        expect(STEPS).toHaveLength(3);
        expect(FAQ.length).toBeGreaterThanOrEqual(5);
        expect(FAQ.length).toBeLessThanOrEqual(6);
    });
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npx jest src/app/para-fornecedores/content.test.ts`
Expected: FAIL — `Cannot find module './content'`

- [ ] **Step 3: Implementar** — `src/app/para-fornecedores/content.ts`

```ts
/**
 * Copy da página /para-fornecedores (TASK-285). Cada item de POLICIES/FAQ corresponde a um
 * comportamento verificado no código em 24/09/2026 -- ver tabela "Políticas → comportamento
 * verificado" em docs/superpowers/specs/2026-09-24-pagina-para-fornecedores-design.md. Se o
 * comportamento mudar (ex.: TASK-286), este arquivo muda junto. Nunca usar prova social numérica.
 */

export const SUPPLIER_MONTHLY_PRICE = 15.99;

export function formatBRL(value: number): string {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" }).replace(/\u00a0/g, " ");
}

export function supplierDailyPrice(): string {
    return formatBRL(Math.round((SUPPLIER_MONTHLY_PRICE / 30) * 100) / 100);
}

export const BENEFITS = [
    {
        icon: "search" as const,
        title: "Clientes que já estão procurando",
        text: "Síndicos e gestores usam o Easy Maintenance pra controlar a manutenção dos prédios. Quando precisam de um serviço, buscam fornecedores da cidade deles — e você aparece.",
    },
    {
        icon: "whatsapp" as const,
        title: "Pedido direto no seu WhatsApp",
        text: "Sem intermediário e sem app novo. O pedido de orçamento chega no WhatsApp que você cadastrou e a conversa segue direto com o cliente.",
    },
    {
        icon: "wallet" as const,
        title: "Zero comissão",
        text: "Você paga só a mensalidade. Todo serviço que fechar é 100% seu.",
    },
    {
        icon: "trending" as const,
        title: "Reputação que cresce com você",
        text: "Cada organização que cadastra ou vincula você ao próprio prédio fortalece seu perfil e te ajuda a aparecer antes na lista.",
    },
];

export const STEPS = [
    {
        title: "Cadastre-se e autorize o Pix Automático",
        text: "Informe CPF ou CNPJ, WhatsApp, cidade e os serviços que você faz. A mensalidade é debitada automaticamente todo mês — sem boleto pra lembrar.",
    },
    {
        title: "O gestor da sua cidade te encontra",
        text: "Seu perfil aparece pras organizações da sua cidade que buscam fornecedores nas categorias que você escolheu.",
    },
    {
        title: "O pedido chega no seu WhatsApp",
        text: "O gestor descreve o que precisa e a mensagem já abre no seu WhatsApp. Daí pra frente, a negociação é entre vocês.",
    },
];

export const INCLUDED = [
    "Perfil visível pras organizações da sua cidade",
    "Pedidos de orçamento direto no WhatsApp",
    "Zero comissão sobre os serviços fechados",
    "Link pra atualizar seus dados quando quiser",
    "Sem fidelidade — cancele quando quiser",
];

export const POLICIES = [
    {
        title: "Cobrança",
        text: `R$ 15,99 por mês, cobrados por Pix Automático: você autoriza uma vez no app do seu banco e o débito acontece todo mês. O primeiro mês é pago na própria autorização.`,
    },
    {
        title: "Onde seu perfil aparece",
        text: "Pras organizações que usam o Easy Maintenance na mesma cidade e estado do seu cadastro, quando elas buscam fornecedores de uma das categorias que você escolheu.",
    },
    {
        title: "Ordem da lista",
        text: "Fornecedores cadastrados ou vinculados por mais organizações aparecem primeiro; em caso de empate, a ordem é alfabética. Não existe posição paga.",
    },
    {
        title: "Pedidos de orçamento",
        text: "Chegam no WhatsApp que você cadastrou. A negociação, o preço e a execução do serviço são combinados direto entre você e o cliente — o Easy Maintenance não intermedeia.",
    },
    {
        title: "Zero comissão",
        text: "Não cobramos nenhuma comissão sobre os serviços que você fechar. O único valor é a mensalidade.",
    },
    {
        title: "Sem garantia de volume",
        text: "A mensalidade garante que seu perfil fique visível. A quantidade de pedidos depende da demanda da sua região e categoria, por isso não prometemos um número mínimo de pedidos.",
    },
    {
        title: "Se o débito falhar",
        text: "Você tem 3 dias de tolerância. Depois disso, seu perfil sai do marketplace até a situação ser regularizada.",
    },
    {
        title: "Cancelamento",
        text: "Cancele quando quiser, sem multa e sem fidelidade: é só revogar a autorização do Pix Automático no app do seu banco. A partir daí nenhuma cobrança nova é feita e seu perfil sai do marketplace.",
    },
    {
        title: "Seus dados",
        text: "Depois do cadastro você recebe um link de gerenciamento pra atualizar telefone e categorias sem precisar de senha. Guarde esse link.",
    },
];

export const FAQ = [
    {
        question: "Preciso ter CNPJ?",
        answer: "Não. Dá pra se cadastrar com CPF ou CNPJ.",
    },
    {
        question: "Em quanto tempo meu perfil aparece?",
        answer: "Assim que a autorização do Pix Automático é confirmada pelo seu banco — nela você já paga o primeiro mês.",
    },
    {
        question: "Vocês ficam com parte do serviço?",
        answer: "Não. Zero comissão: você paga só a mensalidade de R$ 15,99 e tudo que fechar é seu.",
    },
    {
        question: "Quantos pedidos vou receber?",
        answer: "Depende da demanda da sua cidade e das categorias que você atende. A mensalidade garante sua visibilidade, não um número de pedidos.",
    },
    {
        question: "Como eu cancelo?",
        answer: "Revogue a autorização do Pix Automático no app do seu banco, quando quiser, sem multa. Nenhuma cobrança nova é feita e seu perfil sai do marketplace.",
    },
    {
        question: "Como altero meus dados?",
        answer: "Pelo link de gerenciamento que você recebe ao se cadastrar — dá pra trocar telefone e categorias sem senha.",
    },
];
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npx jest src/app/para-fornecedores/content.test.ts`
Expected: PASS. Se o teste de prova social falhar, ajuste a **copy** (nunca o regex).

- [ ] **Step 5: Commit**

```bash
git add src/app/para-fornecedores/content.ts src/app/para-fornecedores/content.test.ts
git commit -m "feat(para-fornecedores): copy de beneficios, politicas e FAQ verificada (TASK-285)"
```

---

### Task 4: Página, mockups, CTA com tracking, foto e Open Graph

**Files:**
- Create: `src/app/para-fornecedores/page.tsx`
- Create: `src/app/para-fornecedores/_components/SupplierSignupCta.tsx`
- Create: `src/app/para-fornecedores/_components/MarketplaceCardMockup.tsx`
- Create: `src/app/para-fornecedores/_components/WhatsAppMessageMockup.tsx`
- Create: `src/app/para-fornecedores/opengraph-image.tsx`
- Create: `public/para-fornecedores-hero.webp`

**Interfaces:**
- Consumes: `trackSupplierSignupClick()` (Task 2); `SUPPLIER_MONTHLY_PRICE`, `formatBRL`, `supplierDailyPrice`, `BENEFITS`, `STEPS`, `INCLUDED`, `POLICIES`, `FAQ` (Task 3); `Logo` (`@/components/Logo`)
- Produces: `SupplierSignupCta({ label, className }: { label: string; className?: string })`

Sem teste automatizado de componente (Jest roda em `node`, só `*.test.ts`) — validação por `tsc`/`lint`/`build` aqui e browser na Task 6.

- [ ] **Step 1: Foto do hero**

Escolher 1 foto de técnico/prestador de manutenção predial (ex.: eletricista, técnico de ar-condicionado) no Unsplash ou Pexels — **licença de uso comercial gratuita**. Anotar a URL da página da foto e o autor (vão no commit). Baixar e converter:

```bash
cd /d/workpaces/EASY_MAINTENANCE/easy-maintenance-web
SCRATCH="C:/Users/Casa/AppData/Local/Temp/claude/D--workpaces-EASY-MAINTENANCE/a8b1a3c5-8ea6-429a-8a03-9244099b7ade/scratchpad"
curl -L -o "$SCRATCH/hero-src.jpg" "<URL direta da imagem, tamanho grande>"
node -e "require('sharp')(process.argv[1]).resize({width:1200,height:900,fit:'cover'}).webp({quality:78}).toFile('public/para-fornecedores-hero.webp').then(i=>console.log(i))" "$SCRATCH/hero-src.jpg"
```

Expected: arquivo `.webp` criado, `size` < 200 KB (se maior, baixar `quality` para 70).

- [ ] **Step 2: CTA client com tracking** — `src/app/para-fornecedores/_components/SupplierSignupCta.tsx`

```tsx
"use client";

import Link from "next/link";
import { trackSupplierSignupClick } from "@/lib/tracking";

export default function SupplierSignupCta({ label, className = "btn btn-primary btn-lg rounded-pill px-5" }: { label: string; className?: string }) {
    return (
        <Link href="/fornecedores/cadastro" className={className} onClick={() => trackSupplierSignupClick()}>
            {label}
        </Link>
    );
}
```

- [ ] **Step 3: Mockup do card no marketplace** — `src/app/para-fornecedores/_components/MarketplaceCardMockup.tsx`

Mockup ilustrativo (dados fictícios, sem número de prova social).

```tsx
import { MapPin, MessageCircle, ShieldCheck } from "lucide-react";

export default function MarketplaceCardMockup() {
    return (
        <div className="card border-0 shadow-sm mx-auto" style={{ maxWidth: 340, borderRadius: 16 }} aria-hidden>
            <div className="card-body p-3">
                <div className="small text-muted mb-2">Fornecedores em sua cidade · Elétrica</div>
                <div className="d-flex align-items-start gap-2">
                    <div className="rounded-circle bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center fw-bold flex-shrink-0" style={{ width: 40, height: 40 }}>
                        JS
                    </div>
                    <div className="flex-grow-1" style={{ minWidth: 0 }}>
                        <div className="fw-semibold text-truncate">João Silva Instalações</div>
                        <div className="small text-muted d-flex align-items-center gap-1">
                            <MapPin size={12} /> Sua cidade · UF
                        </div>
                        <div className="small text-success d-flex align-items-center gap-1 mt-1">
                            <ShieldCheck size={12} /> Cadastrado por organizações da região
                        </div>
                    </div>
                </div>
                <div className="btn btn-success btn-sm w-100 rounded-pill mt-3 d-flex align-items-center justify-content-center gap-1">
                    <MessageCircle size={14} /> Solicitar orçamento
                </div>
            </div>
        </div>
    );
}
```

- [ ] **Step 4: Mockup da mensagem no WhatsApp** — `src/app/para-fornecedores/_components/WhatsAppMessageMockup.tsx`

```tsx
export default function WhatsAppMessageMockup() {
    return (
        <div className="mx-auto p-3" style={{ maxWidth: 340, borderRadius: 16, background: "#e5ddd5" }} aria-hidden>
            <div className="small text-center text-muted mb-2">WhatsApp</div>
            <div className="p-2 px-3 shadow-sm" style={{ background: "#dcf8c6", borderRadius: "12px 12px 2px 12px", marginLeft: "auto", maxWidth: "90%" }}>
                <div className="small">
                    {/* Mesmo template real de /fornecedores (handleBudgetRequest) + um resumo de exemplo */}
                    Olá! Vi seu cadastro no <strong>Easy Maintenance</strong> e gostaria de um orçamento:
                    revisão do quadro elétrico do condomínio.
                </div>
                <div className="text-end text-muted" style={{ fontSize: "0.7rem" }}>09:41 ✓✓</div>
            </div>
        </div>
    );
}
```

- [ ] **Step 5: Página** — `src/app/para-fornecedores/page.tsx`

```tsx
import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Search, MessageCircle, Wallet, TrendingUp, Check } from "lucide-react";
import Logo from "@/components/Logo";
import SupplierSignupCta from "./_components/SupplierSignupCta";
import MarketplaceCardMockup from "./_components/MarketplaceCardMockup";
import WhatsAppMessageMockup from "./_components/WhatsAppMessageMockup";
import {
    SUPPLIER_MONTHLY_PRICE, formatBRL, supplierDailyPrice,
    BENEFITS, STEPS, INCLUDED, POLICIES, FAQ,
} from "./content";

/**
 * TASK-285 (EPIC-028): página pública de divulgação do marketplace pra fornecedores. Leva ao
 * cadastro existente (/fornecedores/cadastro). Copy em ./content.ts -- ver regras lá.
 */
export const metadata: Metadata = {
    title: "Para fornecedores",
    description:
        "Seja encontrado por síndicos e gestores de prédios da sua cidade. R$ 15,99/mês, zero comissão, pedidos de orçamento direto no WhatsApp. Cancele quando quiser.",
    robots: { index: true, follow: true },
    alternates: { canonical: "https://easymaintenance.com.br/para-fornecedores" },
    openGraph: {
        title: "Easy Maintenance para fornecedores",
        description: "Receba pedidos de orçamento de prédios da sua cidade direto no WhatsApp. R$ 15,99/mês, zero comissão.",
        url: "https://easymaintenance.com.br/para-fornecedores",
        type: "website",
        locale: "pt_BR",
    },
};

const BENEFIT_ICONS = {
    search: Search,
    whatsapp: MessageCircle,
    wallet: Wallet,
    trending: TrendingUp,
};

export default function ParaFornecedoresPage() {
    const price = formatBRL(SUPPLIER_MONTHLY_PRICE);
    const stepVisuals = [null, <MarketplaceCardMockup key="card" />, <WhatsAppMessageMockup key="wa" />];

    return (
        <div className="bg-white">
            <style>{`
                .pf-hero { background: linear-gradient(135deg, #eff6ff 0%, #ffffff 60%); }
                .pf-hero-img { border-radius: 24px; object-fit: cover; width: 100%; height: auto; }
                .pf-step-num { width: 36px; height: 36px; }
                .pf-faq summary { cursor: pointer; list-style: none; }
                .pf-faq summary::-webkit-details-marker { display: none; }
                .pf-faq details[open] summary .pf-chevron { transform: rotate(180deg); }
                .pf-chevron { transition: transform .2s; }
            `}</style>

            <nav className="navbar navbar-light bg-white shadow-sm sticky-top">
                <div className="container">
                    <Link href="/landing" className="navbar-brand"><Logo /></Link>
                    <SupplierSignupCta label="Quero me cadastrar" className="btn btn-primary rounded-pill px-3 px-sm-4 text-nowrap" />
                </div>
            </nav>

            {/* Hero */}
            <section className="pf-hero py-5">
                <div className="container py-lg-4">
                    <div className="row align-items-center g-5">
                        <div className="col-lg-6">
                            <span className="badge bg-primary bg-opacity-10 text-primary rounded-pill px-3 py-2 mb-3">Para fornecedores de manutenção predial</span>
                            <h1 className="display-5 fw-bold mb-3">Seja encontrado por quem cuida de prédios na sua cidade</h1>
                            <p className="lead text-muted mb-4">
                                Síndicos e gestores que usam o Easy Maintenance buscam fornecedores pela cidade e pelo tipo de
                                serviço. Apareça pra eles e receba pedidos de orçamento direto no seu WhatsApp.
                            </p>
                            <p className="fw-semibold mb-4">{price}/mês · zero comissão · cancele quando quiser</p>
                            <div className="d-flex flex-column flex-sm-row gap-3">
                                <SupplierSignupCta label="Quero me cadastrar" />
                                <a href="#como-funciona" className="btn btn-outline-secondary btn-lg rounded-pill px-4">Como funciona</a>
                            </div>
                        </div>
                        <div className="col-lg-6">
                            <Image src="/para-fornecedores-hero.webp" alt="Técnico de manutenção predial trabalhando" width={1200} height={900} className="pf-hero-img shadow" priority />
                        </div>
                    </div>
                </div>
            </section>

            {/* Por que participar */}
            <section className="py-5">
                <div className="container">
                    <h2 className="h1 fw-bold text-center mb-5">Por que participar</h2>
                    <div className="row g-4">
                        {BENEFITS.map((b) => {
                            const Icon = BENEFIT_ICONS[b.icon];
                            return (
                                <div className="col-md-6 col-lg-3" key={b.title}>
                                    <div className="card h-100 border-0 shadow-sm p-4" style={{ borderRadius: 16 }}>
                                        <Icon className="text-primary mb-3" size={28} />
                                        <h3 className="h5 fw-bold">{b.title}</h3>
                                        <p className="text-muted mb-0">{b.text}</p>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </section>

            {/* Como funciona */}
            <section id="como-funciona" className="py-5 bg-light">
                <div className="container">
                    <h2 className="h1 fw-bold text-center mb-5">Como funciona</h2>
                    <div className="row g-5">
                        {STEPS.map((s, i) => (
                            <div className="col-lg-4" key={s.title}>
                                <div className="d-flex align-items-center gap-3 mb-3">
                                    <span className="pf-step-num rounded-circle bg-primary text-white fw-bold d-flex align-items-center justify-content-center flex-shrink-0">{i + 1}</span>
                                    <h3 className="h5 fw-bold mb-0">{s.title}</h3>
                                </div>
                                <p className="text-muted">{s.text}</p>
                                {stepVisuals[i]}
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Preço */}
            <section className="py-5">
                <div className="container">
                    <div className="card border-0 shadow mx-auto p-4 p-md-5 text-center" style={{ maxWidth: 480, borderRadius: 24 }}>
                        <h2 className="h4 fw-bold mb-3">Um plano, sem letra miúda</h2>
                        <div className="display-4 fw-bold text-primary">{price}<span className="fs-5 text-muted fw-normal">/mês</span></div>
                        <p className="text-muted mb-4">cerca de {supplierDailyPrice()} por dia</p>
                        <ul className="list-unstyled text-start mb-4">
                            {INCLUDED.map((item) => (
                                <li className="d-flex gap-2 mb-2" key={item}><Check className="text-success flex-shrink-0" size={20} />{item}</li>
                            ))}
                        </ul>
                        <SupplierSignupCta label="Quero me cadastrar" className="btn btn-primary btn-lg rounded-pill w-100" />
                    </div>
                </div>
            </section>

            {/* Políticas */}
            <section id="politicas" className="py-5 bg-light">
                <div className="container" style={{ maxWidth: 880 }}>
                    <h2 className="h1 fw-bold text-center mb-2">Como funciona na prática</h2>
                    <p className="text-muted text-center mb-5">As regras do marketplace, sem juridiquês.</p>
                    <div className="row g-3">
                        {POLICIES.map((p) => (
                            <div className="col-md-6" key={p.title}>
                                <div className="bg-white rounded-4 p-4 h-100 shadow-sm">
                                    <h3 className="h6 fw-bold">{p.title}</h3>
                                    <p className="text-muted small mb-0">{p.text}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* FAQ */}
            <section className="py-5 pf-faq">
                <div className="container" style={{ maxWidth: 720 }}>
                    <h2 className="h1 fw-bold text-center mb-4">Perguntas frequentes</h2>
                    {FAQ.map((f) => (
                        <details className="border-bottom py-3" key={f.question}>
                            <summary className="fw-semibold d-flex justify-content-between align-items-center gap-3">
                                {f.question}<span className="pf-chevron text-muted" aria-hidden>⌄</span>
                            </summary>
                            <p className="text-muted mt-2 mb-0">{f.answer}</p>
                        </details>
                    ))}
                </div>
            </section>

            {/* CTA final */}
            <section className="py-5 bg-primary text-white text-center">
                <div className="container">
                    <h2 className="h1 fw-bold mb-3">Pronto pra ser encontrado?</h2>
                    <p className="lead mb-4 opacity-75">Cadastro em poucos minutos. {price}/mês, sem fidelidade.</p>
                    <SupplierSignupCta label="Quero me cadastrar" className="btn btn-light btn-lg rounded-pill px-5 fw-semibold" />
                </div>
            </section>

            <footer className="py-4 bg-light border-top">
                <div className="container d-flex flex-column flex-md-row justify-content-between gap-2 small text-muted">
                    <span>© {new Date().getFullYear()} Easy Maintenance</span>
                    <span className="d-flex gap-3">
                        <Link href="/landing" className="text-muted text-decoration-none">Página inicial</Link>
                        <Link href="/privacidade" className="text-muted text-decoration-none">Privacidade</Link>
                        <Link href="/termos" className="text-muted text-decoration-none">Termos</Link>
                    </span>
                </div>
            </footer>
        </div>
    );
}
```

- [ ] **Step 6: Open Graph** — `src/app/para-fornecedores/opengraph-image.tsx`

```tsx
import { ImageResponse } from "next/og";

export const alt = "Easy Maintenance para fornecedores — pedidos de orçamento direto no WhatsApp";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
    return new ImageResponse(
        (
            <div style={{ width: "100%", height: "100%", display: "flex", flexDirection: "column", justifyContent: "center", padding: 80, background: "linear-gradient(135deg, #1d4ed8 0%, #2563eb 60%, #3b82f6 100%)", color: "white" }}>
                <div style={{ fontSize: 32, opacity: 0.85 }}>Easy Maintenance · Para fornecedores</div>
                <div style={{ fontSize: 68, fontWeight: 700, marginTop: 24, lineHeight: 1.1 }}>Seja encontrado por quem cuida de prédios na sua cidade</div>
                <div style={{ fontSize: 36, marginTop: 32 }}>R$ 15,99/mês · zero comissão · pedidos no WhatsApp</div>
            </div>
        ),
        size,
    );
}
```

- [ ] **Step 7: Verificar**

Run: `npx tsc --noEmit && npx eslint src/app/para-fornecedores && npm run build`
Expected: sem erros; o build lista `/para-fornecedores` e `/para-fornecedores/opengraph-image`.

- [ ] **Step 8: Commit** (incluir crédito da foto)

```bash
git add src/app/para-fornecedores public/para-fornecedores-hero.webp
git commit -m "feat(para-fornecedores): pagina publica de divulgacao com mockups, precos, politicas e FAQ (TASK-285)

Foto do hero: <autor> via <Unsplash|Pexels> (<URL da pagina da foto>), licenca de uso comercial gratuita."
```

---

### Task 5: Integrações — sitemap, footer da `/landing`, cadastro

**Files:**
- Modify: `src/app/sitemap.ts`
- Modify: `src/app/landing/page.tsx` (footer, lista "Navegação", após o `<li>` do Blog ~L627)
- Modify: `src/app/fornecedores/cadastro/page.tsx` (import, `handleSubmit` após `setResult(response)`, parágrafo de proposta ~L143-146)

**Interfaces:**
- Consumes: `trackCompleteRegistration()` (Task 2)

- [ ] **Step 1: Sitemap** — em `src/app/sitemap.ts`, adicionar após a entrada de `/indicador/novo`:

```ts
        {
            url: "https://easymaintenance.com.br/para-fornecedores",
            lastModified: new Date(),
            changeFrequency: "monthly",
            priority: 0.7,
        },
```

- [ ] **Step 2: Footer da `/landing`** — após `<li><Link href="/blog" className="text-muted text-decoration-none">Blog</Link></li>` no footer (não na navbar):

```tsx
                <li><Link href="/para-fornecedores" className="text-muted text-decoration-none">Para fornecedores</Link></li>
```

Confirmar com `grep -n 'href="/blog"' src/app/landing/page.tsx` que está editando a ocorrência do **footer** (a da navbar tem `className="nav-link ...`).

- [ ] **Step 3: Cadastro — tracking de sucesso** — em `src/app/fornecedores/cadastro/page.tsx`:
  - import: `import { trackCompleteRegistration } from "@/lib/tracking";` e `import Link from "next/link";`
  - em `handleSubmit`, trocar `setResult(response);` por:

```ts
      setResult(response);
      trackCompleteRegistration();
```

- [ ] **Step 4: Cadastro — link pras políticas** — substituir o parágrafo:

```tsx
            <p className="text-muted mb-4" style={{ fontSize: "0.85rem" }}>
              R$ 15,99/mês pra aparecer pras organizações que usam o Easy Maintenance na sua região
              e receber pedidos de orçamento direto no WhatsApp.
            </p>
```

por:

```tsx
            <p className="text-muted mb-4" style={{ fontSize: "0.85rem" }}>
              R$ 15,99/mês pra aparecer pras organizações que usam o Easy Maintenance na sua região
              e receber pedidos de orçamento direto no WhatsApp.{" "}
              <Link href="/para-fornecedores#politicas">Como funciona e políticas</Link>
            </p>
```

- [ ] **Step 5: Verificar**

Run: `npx tsc --noEmit && npx eslint src/app/sitemap.ts src/app/landing/page.tsx src/app/fornecedores/cadastro/page.tsx && npm test`
Expected: sem erros de tipo/lint; `npm test` só com as 3 falhas pré-existentes de `middleware.test.ts` (nenhuma nova).

- [ ] **Step 6: Commit**

```bash
git add src/app/sitemap.ts src/app/landing/page.tsx src/app/fornecedores/cadastro/page.tsx
git commit -m "feat(para-fornecedores): sitemap, link no footer da landing e no cadastro + CompleteRegistration (TASK-285)"
```

---

### Task 6: QA manual no browser, PR e roadmap

**Files:**
- Modify: `D:\workpaces\EASY_MAINTENANCE\roadmap\tasks\TASK-285.md`, `roadmap\kanban.md` (repo raiz)

- [ ] **Step 1: Build de produção limpo**

Run: `npm run build`
Expected: sucesso.

- [ ] **Step 2: Browser (dev server, janela anônima/deslogado)** — validar e anotar resultado de cada item:
  1. `http://localhost:3000/para-fornecedores` renderiza **sem** redirect pro `/login`; idem `/para-fornecedores#politicas` (rola até a seção).
  2. Logado, a página também abre (sem sidebar/topbar).
  3. Em 390, 1024, 1366 e 1920px: `document.documentElement.scrollWidth <= innerWidth` (sem scroll horizontal), foto carregada, mockups legíveis, FAQ abre/fecha.
  4. Todos os botões "Quero me cadastrar" levam a `/fornecedores/cadastro`; "Como funciona" rola até `#como-funciona`.
  5. Footer da `/landing` → "Para fornecedores" funciona; navbar da `/landing` **inalterada**.
  6. `/fornecedores/cadastro` → link "Como funciona e políticas" leva à seção de políticas; formulário igual ao de antes.
  7. Tracking: com `window.fbq = (...a) => console.log('fbq', ...a)` injetado no console, clique no CTA loga `fbq trackCustom SupplierSignupClick`.
  8. `http://localhost:3000/para-fornecedores/opengraph-image` retorna PNG 1200×630.
  9. Ler a seção de políticas e o FAQ contra a tabela do spec — nenhuma divergência, nenhum número de prova social.

- [ ] **Step 3: Push + PR contra `staging`**

```bash
git push -u origin feature/TASK-285-para-fornecedores
gh pr create --base staging --title "feat(landing): pagina publica /para-fornecedores (TASK-285)" --body "<resumo + checklist do QA do Step 2 + crédito da foto>"
```

- [ ] **Step 4: Roadmap** — em `roadmap/tasks/TASK-285.md` marcar critérios de aceite validados, preencher "Implementação" (arquivos, PR) e Status `🟡 Em Validação`; nova entrada no topo de `roadmap/kanban.md`; commit no repo raiz:

```bash
cd /d/workpaces/EASY_MAINTENANCE
git add roadmap/tasks/TASK-285.md roadmap/kanban.md
git commit -m "chore(roadmap): TASK-285 - implementada, PR aberta contra staging"
```
