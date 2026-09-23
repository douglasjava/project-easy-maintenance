# TASK-175 — Frontend: página `/agendar` (embed Cal.com) + botão na navbar da landing

## Tipo
FRONTEND

## Categoria
Marketing / Funil Comercial

## Prioridade
🟠 Alto

## Épico
[EPIC-024](../epics/EPIC-024.md) — Agendamento de Demonstração (Cal.com)

## QA obrigatório
Sim — QA manual: testar o embed do Cal.com de ponta a ponta (escolher horário, preencher
formulário, confirmar) e checar que a landing existente (formulário de e-mail, botão "Solicitar
Demonstração", CTA final) continua idêntica.

---

## Contexto

Inspirado no `/agendar` do concorrente Easy Alert. Detalhe completo da decisão em
`docs/superpowers/specs/2026-08-19-agendamento-demo-design.md`. **Não é substituição** do fluxo
atual — é um caminho novo e paralelo.

## Objetivo

Nova página `/agendar` com o widget do Cal.com embutido, e um botão novo na navbar da landing
levando até ela — sem alterar mais nada na landing existente.

## Escopo

### 1. Nova rota `/agendar`
Mesmo padrão visual de `/blog`/`/termos` (navbar simples com `Logo` linkando pra `/landing`).
Embed do Cal.com (`@calcom/embed-react` ou script embed direto) ocupando o corpo da página.

### 2. Propagação de UTM/afiliado
UTM (cookie `em_utm`, `getStoredUtm()` já existente em `src/lib/utm.ts`) e `affiliateCode` (cookie
`em_ref`) são passados como parâmetros de URL pro embed do Cal.com — mesmo dado que o formulário
de e-mail já envia manualmente hoje em `landing/page.tsx` (`handleSubmit`).

### 3. Botão novo na navbar da landing
`src/app/landing/page.tsx` — item novo `<Link href="/agendar">Agendar demonstração</Link>` na
navbar, ao lado de "Login Cliente". **Não tocar** em nenhum outro elemento: formulário de e-mail,
botão "Solicitar Demonstração", CTA final, footer — tudo continua exatamente como está.

## Critérios de Aceite

- [x] `/agendar` acessível publicamente, embed do Cal.com carrega e funciona — validado com link
      de teste (iframe injetado, script carregado); escolher dia/confirmar de ponta a ponta com
      evento real pendente de config do Douglas no Cal.com
- [x] UTM e `affiliateCode` armazenados no navegador chegam como campo de `config` no embed
- [x] Botão "Agendar demonstração" visível na navbar da landing, leva pra `/agendar`
- [x] Formulário de e-mail, botão "Solicitar Demonstração" e CTA final da landing continuam
      idênticos — nenhuma mudança visual ou funcional nesses elementos
- [x] `npm run build` limpo

## Dependências
Nenhuma (independente da TASK-176 do ponto de vista de código).

## Riscos
Baixo — página nova, aditiva. Depende de conta/configuração no Cal.com (fora do código).

## Esforço
Baixo-Médio

## Implementação
- Branch: `feature/EPIC-024-agendamento-calcom` (repo `web`, a partir de `staging`)
- Nova rota `/agendar` (`src/app/agendar/page.tsx`), botão "Agendar demonstração" na navbar da
  landing (`src/app/landing/page.tsx`), `ENV.CALCOM_LINK` novo (`NEXT_PUBLIC_CALCOM_LINK`)
- UTM/afiliado propagados via `config` do embed (`getStoredUtm()`, `Cookies.get('em_ref')`)
- **Achado real durante teste no browser**: shim/init/inline do Cal.com precisou ser injetado
  manualmente via `document.createElement("script")` num `useEffect` — `next/script`
  (`onLoad`/`onReady`) não dispara pra scripts inline (só funcionaria com `src` externo), então
  `window.Cal("init"...)` nunca era chamado e o widget nunca inicializava. Confirmado rodando a
  página de verdade com `NEXT_PUBLIC_CALCOM_LINK` fake: sem o fix, `window.Cal` existia mas nunca
  fora invocado (`hasOwnProperty('loaded') === false`); com o fix, script carregado, iframe
  injetado, tudo funcionando.
- **Segundo achado**: `Shell.tsx` guarda toda rota fora de uma allowlist client-side atrás de
  login (mesma classe de bug da TASK-272/273/274) — `/agendar` não estava lá e redirecionava pra
  `/login`. Corrigido.
- `npx tsc --noEmit`/`npm run build`/`npm run lint`: limpos. `npm test`: 107/110 (3 falhas
  pré-existentes em `middleware.test.ts`).
- PR: [web#90](https://github.com/douglasjava/easy-maintenance-web/pull/90) (`staging`)

## Status
🟡 Em Validação — implementado, testado, validado no browser real (embed carregando de verdade
com link de teste). Falta Douglas configurar o evento real no Cal.com e
`NEXT_PUBLIC_CALCOM_LINK`, testar agendamento de ponta a ponta.
