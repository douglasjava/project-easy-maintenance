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

- [ ] `trackLead()` e `trackContact()` existem e não quebram a aplicação mesmo sem
      `fbq`/`gtag` definidos (no-op seguro)
- [ ] `trackLead()` dispara uma única vez no mount de `/obrigado`
- [ ] `trackContact()` dispara no clique do botão "Falar com Consultor"
- [ ] Nenhum ID de pixel foi inventado/hardcoded — instalação real do pixel base documentada como
      pendência aberta
- [ ] `npm run build` limpo

## Dependências
- **TASK-155** — `/obrigado` precisa existir para `trackLead()` ter onde disparar.
- **TASK-154** — botão "Falar com Consultor" com contexto de UTM já implementado.

## Riscos
Sem os IDs de pixel fornecidos por Douglas, este scaffolding fica sem efeito prático em produção —
comunicado como pendência aberta, não como "tracking pronto".

## Esforço
Baixo

## Status
Pronto para Implementar
