# Design — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

**Data:** 30/07/2026
**Épico:** [EPIC-018](../../../roadmap/epics/EPIC-018.md)
**Tasks:** [TASK-152](../../../roadmap/tasks/TASK-152.md) a
[TASK-157](../../../roadmap/tasks/TASK-157.md)

## Contexto e motivação

Tráfego pago (Meta Ads, Google Ads) começa a rodar esta semana. O site público
(`easymaintenance.com.br`, Next.js na Vercel) hoje não persiste UTM, não tem checkbox de
consentimento LGPD no form de captura de lead, não tem página de confirmação (logo não há como
disparar um evento de conversão confiável), e não tem nenhum pixel de rastreamento instalado.

## Descobertas do levantamento (antes do design)

- Backend (`landing_leads` / `CreateLeadRequest` / `LandingLead`) **já suporta** `source`, `medium`,
  `campaign`, `referrer`, `landingPath`, `utmJson` — só falta o frontend enviar e falta
  `consent_accepted_at`.
- Não existe Meta Pixel / Google Tag / `gtag`/`fbq` instalado em nenhum lugar do código.
- Não existe header/footer componentizado na landing — é um arquivo único
  (`src/app/landing/page.tsx`); `/privacidade` replica uma nav simplificada própria.
- Não existe em lugar nenhum do repositório a paleta/tipografia de marca citada no briefing
  original (#0F5497/#7CB62E/#1B2B3B, Playfair Display/DM Sans). O site usa Bootstrap padrão.
- **TASK-151** (29/07/2026) registra decisão explícita de produto de **não** introduzir nova
  identidade visual nas páginas públicas antes do lançamento de tráfego pago desta semana.
- `Shell.tsx` faz auth-gate client-side via whitelist `isAuth`; qualquer rota pública nova precisa
  ser adicionada nela, senão visitante anônimo é redirecionado para `/login` (mesma classe de bug
  que o TASK-151 corrigiu para `/privacidade`).
- Não existe conteúdo de Termos de Uso em nenhum lugar do repositório.

## Decisões (validadas com Douglas em 30/07/2026)

1. **Identidade visual**: manter o Bootstrap padrão atual em tudo que for criado/alterado. Não
   introduzir a paleta/tipografia do briefing original — consistente com o TASK-151.
2. **IDs de pixel (Meta/Google)**: não fornecidos agora. Implementar toda a infraestrutura de
   captura de UTM e os pontos de disparo de evento (`trackLead`/`trackContact`) como no-ops
   defensivos, prontos para ativar assim que os IDs chegarem. Não inventar/hardcodar IDs.
3. **Server-side (Meta Conversions API / Google Enhanced Conversions)**: fase 2, fora desta rodada
   — requer credenciais adicionais que Douglas ainda vai levantar (TASK-157, backlog).
4. **Termos de Uso**: sem conteúdo jurídico disponível — link do rodapé permanece quebrado,
   documentado como pendência conhecida (já flagado, sem relação, no TASK-151). Nenhum conteúdo
   fabricado.

## Arquitetura da solução

### 1. Captura e persistência de UTM (TASK-153)
- `src/lib/utm.ts`: `captureUtm()` lê `utm_source/medium/campaign/content/term` da URL; grava em
  cookie `em_utm` (JSON, via `js-cookie`, `expires: 30, sameSite: 'Lax'` — mesmo padrão já usado
  para o cookie `em_ref` existente). Só grava se a URL atual tiver ao menos um UTM; nunca
  sobrescreve um valor salvo com uma URL sem UTM (preserva atribuição de "primeiro toque" dentro da
  janela de 30 dias).
- `getStoredUtm()`: lê/desserializa o cookie.
- Componente `UtmCapture` (sem render) montado uma vez no `RootLayout`, rodando em toda página.

### 2. Backend — consentimento (TASK-152)
- Migração `V86__add_consent_accepted_at_to_landing_leads.sql`.
- `CreateLeadRequest` ganha `consentAccepted: Boolean`. `LeadService.createLead` rejeita (400) se
  não for `true`; caso contrário grava `consentAcceptedAt = Instant.now()` — **timestamp gerado no
  servidor**, nunca aceito do cliente (não confiável como prova de consentimento).

### 3. Form de demonstração (TASK-154)
- Checkbox obrigatório ao lado do botão de submit: "Li e concordo com a [Política de
  Privacidade](/privacidade)." — bloqueia o submit no cliente se desmarcado.
- `handleSubmit` passa a enviar `source/medium/campaign/utmJson/referrer/landingPath` (via
  `getStoredUtm()` + `document.referrer`/`window.location.pathname`) e `consentAccepted: true`.
- Sucesso: `router.push('/obrigado')` no lugar do `alert()` atual. Erro: mantém tratamento atual.

### 4. Página `/obrigado` (TASK-155)
- Correção pré-requisito: adicionar `/obrigado` à whitelist `isAuth` do `Shell.tsx` (mesma classe
  de bug do TASK-151 — sem isso o redirect para `/login` quebra o fluxo inteiro).
- Estilo Bootstrap padrão, nav simples com `Logo` (mesmo padrão de `/privacidade`, já que não há
  header componentizado).
- Conteúdo: confirmação + aviso de que a equipe entrará em contato + botão secundário de WhatsApp
  (mensagem pré-preenchida com contexto de UTM via `getStoredUtm()`).
- `robots: noindex`, fora do `sitemap.ts` (página de destino de fluxo, não conteúdo de busca).

### 5. Eventos de conversão (TASK-156)
- `src/lib/tracking.ts`: `trackLead()`/`trackContact()` — chamam `window.fbq?.(...)` /
  `window.gtag?.(...)` só se existirem (no-op seguro hoje, já que não há pixel instalado).
- `trackLead()`: `useEffect` no mount de `/obrigado`.
- `trackContact()`: `onClick` do botão "Falar com Consultor" (CTA final da landing) — não aplicado
  ao botão flutuante nem ao link do rodapé (fora do escopo do briefing original; extensível depois
  se desejado).
- PageView: nada a fazer agora — só existirá quando o pixel base for instalado (fora desta rodada).

### 6. Termos de Uso
- Sem mudança de código. Documentado como pendência conhecida no resumo final.

## Riscos e mitigação

- **Sem IDs de pixel, nenhum dado chega ao Ads Manager** até Douglas fornecer as credenciais —
  comunicado explicitamente para não gerar falsa sensação de "campanha já mensurável".
- **Esquecer a whitelist do `Shell.tsx`** quebraria silenciosamente todo o tracking de Lead (mesmo
  risco documentado no TASK-151) — mitigado por ser item explícito do design e da TASK-155.
- Cookie `sameSite: 'Lax'` não é enviado em alguns fluxos cross-site (ex. iframe de terceiros) —
  aceitável, mesmo comportamento já validado em produção para `em_ref`.

## Testes

- Sem infraestrutura de teste de componente React neste projeto (limitação já registrada em tasks
  anteriores) — validação via `npm run build` + teste manual de navegação.
- Backend: teste unitário/integração de `LeadService`/`LeadController` cobrindo aceite/rejeição de
  consentimento (TASK-152).

## Fora de escopo desta rodada

- Instalação real do pixel Meta/Google (IDs pendentes de Douglas).
- Meta Conversions API / Google Enhanced Conversions server-side (TASK-157, backlog).
- Conteúdo de Termos de Uso.
- Nova identidade visual (paleta/tipografia do briefing original).
