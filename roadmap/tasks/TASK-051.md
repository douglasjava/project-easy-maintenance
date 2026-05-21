# TASK-051 — Padronizar uso de logos no frontend (Brand Kit) - Experiência do Usuário e Identidade Visual

## Tipo

Frontend / UI

## Categoria

Design System / Branding

## Prioridade

🟡 Médio

## Fase

2 — Pré-produção / Refinamento UX

## Épico

EPIC-009 — Performance Frontend

## Descrição

Atualmente as logos foram geradas em múltiplas variações (horizontal, ícone e stacked), porém ainda não existe um padrão estruturado de uso dentro do frontend.

É necessário organizar os arquivos no projeto e criar um componente reutilizável para garantir consistência visual em toda a aplicação.

## Problema

Sem padronização:

* Cada tela pode usar uma versão diferente da logo
* Dificulta manutenção e troca de branding no futuro
* Risco de uso incorreto (cor errada, proporção errada, etc.)
* Duplicação de código ao usar `<Image />` diretamente

## Impacto

* Inconsistência visual no produto
* Dificuldade para evoluir para white-label no futuro
* Aumento de débito técnico no frontend
* Perda de percepção de profissionalismo do SaaS

## Dependências

* Kit de logos já gerado (PNG)

## Critérios de Aceite

* [ ] Logos organizadas dentro de `public/assets/brand/logos`
* [ ] Nome dos arquivos padronizado (`logo-{variant}-{tone}.png`)
* [ ] Criado componente `BrandLogo` reutilizável
* [ ] Nenhuma tela usa caminho direto da logo (uso centralizado via componente)
* [ ] Header usa versão horizontal
* [ ] Sidebar usa versão ícone
* [ ] Tela de login usa versão stacked
* [ ] Suporte a dark mode (uso automático da versão branca)
* [ ] Documentação de uso do componente

## Subtasks

* [ ] Criar estrutura de pastas:

```txt
public/assets/brand/logos
```

* [ ] Renomear arquivos para padrão:

```txt
logo-horizontal-color.png
logo-horizontal-white.png
logo-horizontal-black.png

logo-icon-color.png
logo-icon-white.png
logo-icon-black.png

logo-stacked-color.png
logo-stacked-white.png
logo-stacked-black.png
```

* [ ] Criar componente `BrandLogo.tsx`
* [ ] Implementar props:

    * `variant` (horizontal | icon | stacked)
    * `tone` (color | white | black)
* [ ] Substituir usos diretos de `<Image>` nas telas
* [ ] Aplicar no:

    * Header
    * Sidebar
    * Login
* [ ] Testar responsividade (mobile + desktop)

## Exemplo de implementação

```tsx
<BrandLogo variant="horizontal" tone="color" />
<BrandLogo variant="icon" tone="white" width={40} height={40} />
<BrandLogo variant="stacked" tone="color" width={180} height={180} />
```

## Arquivos afetados

* `public/assets/brand/logos/*`
* `components/ui/BrandLogo.tsx`
* `app/layout.tsx`
* `app/login/page.tsx`
* `components/layout/sidebar.tsx`

## Esforço

Pequeno (2–3h)

## Risco de não fazer

* UI inconsistente
* Aumento de retrabalho ao evoluir design
* Dificuldade futura para white-label / multi-brand

## Status

✅ Concluído — 04/05/2026

### O que foi implementado (v2 — SVG)

**Assets:**
- `public/assets/brand/logos/logo-icon.svg` — engrenagem 6 dentes (azul #2563EB) + checkmark verde (#10B981), fundo transparente, viewBox 40×40
- `public/assets/brand/logos/logo-horizontal.svg` — ícone + EASY / MAINTENANCE, viewBox 210×44
- `public/assets/brand/logos/logo-stacked.svg` — ícone centralizado + texto abaixo, viewBox 160×84
- SVGs com `<style>` + `@media (prefers-color-scheme: dark)` ativo — dark mode funciona automaticamente

**Componente `BrandLogo.tsx` (v2 — simplificado):**
- **Server component** — sem "use client", sem `useEffect`, sem `useState`
- Usa `<img>` com `width`/`height` HTML attributes + `object-fit: contain` (sem distorção)
- `priority` mapeado para `loading="eager"` (sem depender de next/image)
- Prop `tone` removida (dark mode gerenciado pelos próprios SVGs via CSS media query)
- Zero flicker: não há estado que muda após hidratação
- API retrocompatível com todos os callers existentes

**Middleware fix (feito como parte desta tarefa):**
- `matcher` atualizado para excluir `.*\\.[a-z]{2,5}$` — assets estáticos não são mais bloqueados
- `firebase-messaging-sw.js` e todos os outros arquivos da pasta `public` acessíveis diretamente
