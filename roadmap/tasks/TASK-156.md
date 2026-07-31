# TASK-156 — Frontend: scaffolding de eventos de conversão (Lead/Contact) — pendente de IDs de pixel

## Tipo
FRONTEND

## Categoria
Marketing / Tracking

## Prioridade
🟡 Médio

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim, mas limitado: sem IDs de pixel reais, QA valida só que as funções são chamadas nos momentos
certos (via `console.log`/mock), não que o Meta Ads Manager/Google Ads recebe o evento de verdade.

---

## Contexto

Nenhum Meta Pixel ou Google Tag está instalado no site (confirmado por busca no código). Douglas
precisa fornecer os IDs — **não inventar/adivinhar** IDs de pixel. Esta task entrega a
infraestrutura de disparo de evento pronta para plugar, deixando a instalação real do pixel/gtag
base como pendência explícita.

---

## Objetivo

Criar `trackLead()`/`trackContact()` como no-ops defensivos (checam se `window.fbq`/`window.gtag`
existem antes de chamar) e cabear nos pontos corretos, para que a ativação real seja só instalar o
pixel base + preencher os IDs.

---

## Escopo

### 1. `src/lib/tracking.ts`
- `trackLead()`: chama `window.fbq?.('track', 'Lead')` e `window.gtag?.('event', 'generate_lead')`
  se existirem; comentário `TODO` explícito marcando que a instalação do pixel/gtag base ainda não
  foi feita (pendente de IDs de Douglas).
- `trackContact()`: mesmo padrão para evento de "Contact"/clique em WhatsApp.

### 2. Disparo dos eventos
- `trackLead()` chamado em `useEffect` no mount de `/obrigado` (TASK-155) — dispara só quando a
  página de confirmação carrega, nunca no clique do botão do form.
- `trackContact()` chamado no `onClick` do botão "Falar com Consultor" (seção CTA final da
  landing). **Fora de escopo desta task**: botão flutuante de WhatsApp e link do rodapé não
  disparam o evento — briefing original citou especificamente o botão "Falar com Consultor"; pode
  virar task futura se Douglas quiser contar todos os cliques de WhatsApp como Contact.

### 3. Documentação da pendência
- Deixar explícito no PR/summary que **PageView** (base install), **Lead** e **Contact** só vão
  gerar dado real no Meta Ads Manager / Google Ads depois que o pixel/gtag base for instalado com
  os IDs reais.

---

## Critérios de Aceite

- [x] `trackLead()` e `trackContact()` existem e não quebram a aplicação mesmo sem
      `fbq`/`gtag` definidos (no-op seguro) — usa optional chaining, validado sem pixel instalado
- [x] `trackLead()` dispara uma única vez no mount de `/obrigado` (`useEffect` com deps vazias)
- [x] `trackContact()` dispara no clique do botão "Falar com Consultor" (cabeado em `landing/page.tsx`
      na TASK-154, commit `5b10aa5`)
- [x] Nenhum ID de pixel foi inventado/hardcoded — instalação real do pixel base documentada como
      pendência aberta (`TODO` explícito em `tracking.ts`)
- [x] `npm run build` limpo
- [x] **Meta Pixel base instalado** (31/07/2026) — Douglas iniciou a 1ª campanha e forneceu o ID
      real (`2228895387905537`). `window.fbq` confirmado funcionando em produção local, com
      requisições reais a `www.facebook.com/tr` validadas via inspeção de rede (`PageView` e
      `Lead`). Ver `src/components/MetaPixel.tsx`.
- [ ] **Google Tag base** — Douglas ainda não forneceu o ID; `window.gtag` continua não existindo,
      `trackLead()`/`trackContact()` seguem no-op só pro lado do Google

## Dependências
- **TASK-155** — `/obrigado` precisa existir para `trackLead()` ter onde disparar.
- **TASK-154** — botão "Falar com Consultor" com contexto de UTM já implementado.

## Riscos
Sem os IDs de pixel fornecidos por Douglas, este scaffolding fica sem efeito prático em produção —
comunicado como pendência aberta, não como "tracking pronto".

## Esforço
Baixo

## Status
Em Validação — Meta Pixel real instalado e validado
([PR #32](https://github.com/douglasjava/easy-maintenance-web/pull/32) para `staging`, urgente:
campanha do Meta já está no ar). Falta: **configurar `NEXT_PUBLIC_META_PIXEL_ID` no Railway**
(produção e staging — Douglas precisa fazer isso, sem acesso via código) e o ID do Google Tag pra
fechar a task por completo.
