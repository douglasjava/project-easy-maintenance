# EPIC-018 — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## Status
**Em Validação — 30/07/2026.** TASK-152 a 156 implementadas em `feature/EPIC-018-conversion-
tracking` (ambos os repos), suíte backend completa e `npm run build` do frontend verdes, validação
manual em browser feita (Playwright) — inclusive um bug real encontrado e corrigido nessa validação
(link de WhatsApp em `/obrigado` nunca incluía o contexto de UTM por mismatch de hidratação, ver
TASK-155). Falta: QA manual formal, abrir PR para `staging` em ambos os repos, e os IDs de Meta
Pixel/Google Tag do Douglas para fechar de fato o épico (TASK-156). TASK-157 permanece no backlog,
bloqueada por credenciais.

## Objetivo
Preparar o site público (`easymaintenance.com.br`) para o início de tráfego pago (Meta Ads, Google
Ads) desta semana, com captura de lead compatível com LGPD e dados de atribuição (UTM) persistidos
ponta a ponta — do clique no anúncio até o registro em `landing_leads`.

---

## Descrição

Hoje o formulário "Solicitar Demonstração" da landing captura só `email` (+ `affiliateCode` via
cookie `em_ref`) e mostra um `alert()` de sucesso. Não há: captura/persistência de UTM, checkbox de
consentimento LGPD, página de confirmação (o que impede medir conversão real de formulário, só
clique), nem qualquer pixel de rastreamento (Meta/Google) instalado no site.

**Decisão de escopo (Douglas, 30/07/2026):** manter o estilo visual atual (Bootstrap padrão) nas
páginas novas/alteradas — **não** introduzir a paleta/tipografia de marca (#0F5497/#7CB62E/#1B2B3B,
Playfair Display/DM Sans) citada no briefing original, pois não existe em nenhum lugar do código
hoje e contrariaria a decisão já tomada no TASK-151 (véspera) de não mexer em identidade visual
antes do lançamento de tráfego pago desta semana.

**Decisão de escopo (Douglas, 30/07/2026):** instalação real do Meta Pixel / Google Tag (IDs) e a
integração server-side (Conversions API / Enhanced Conversions) ficam para uma fase 2 — esta rodada
entrega a infraestrutura (captura de UTM, checkbox LGPD, página `/obrigado`, pontos de disparo de
evento já cabeados, porém como no-op até os IDs serem fornecidos).

---

## Contexto Técnico

- Backend (`easy-maintenance-api/leads`) **já tem** colunas/campos para `source`, `medium`,
  `campaign`, `referrer`, `landingPath`, `utmJson` em `LandingLead`/`CreateLeadRequest` — só falta o
  frontend enviá-los. Falta apenas `consent_accepted_at`.
- Frontend (`easy-maintenance-web/src/app/landing/page.tsx`) é hoje um arquivo único, sem
  header/footer componentizados — `/privacidade` replica uma nav simplificada própria. As páginas
  novas seguem esse mesmo padrão local, não um componente compartilhado (que não existe).
- `Shell.tsx` faz o auth-gate client-side via whitelist `isAuth` — qualquer rota pública nova
  (`/obrigado`) precisa entrar nessa lista, senão visitante anônimo é redirecionado para `/login`
  (mesma classe de bug corrigida no TASK-151 para `/privacidade`).
- Nenhum Meta Pixel / Google Tag / `gtag`/`fbq` está instalado em nenhum lugar do código
  (confirmado por busca) — flag explícito para Douglas, não presumir IDs.
- Link "Termos de Uso" no rodapé da landing (`href="#"`) permanece quebrado — não existe conteúdo
  de Termos em nenhum lugar do repositório; já flagado como bug pré-existente não relacionado no
  TASK-151. Fora de escopo deste épico (sem conteúdo jurídico para linkar).

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-152](../tasks/TASK-152.md) | Backend: `consent_accepted_at` em `landing_leads` + validação de consentimento obrigatório | BACKEND | 🟠 Alto |
| [TASK-153](../tasks/TASK-153.md) | Frontend: captura e persistência de UTM (cookie 30 dias) | FRONTEND | 🟠 Alto |
| [TASK-154](../tasks/TASK-154.md) | Frontend: checkbox de consentimento LGPD + envio de UTM no form de demonstração | FRONTEND | 🟠 Alto |
| [TASK-155](../tasks/TASK-155.md) | Frontend: página `/obrigado` + correção da whitelist `isAuth` no `Shell.tsx` | FRONTEND | 🟠 Alto |
| [TASK-156](../tasks/TASK-156.md) | Frontend: scaffolding de eventos de conversão (Lead/Contact) — pendente de IDs de pixel | FRONTEND | 🟡 Médio |
| [TASK-157](../tasks/TASK-157.md) | Fase 2 (backlog): Conversions API (Meta) / Enhanced Conversions (Google) server-side | BACKEND | 🟡 Médio |

Ordem sugerida: TASK-152 e TASK-153 em paralelo (trilhas independentes) → TASK-155 (página, pode
andar em paralelo com as anteriores) → TASK-154 (depende do helper de UTM da TASK-153 e do campo de
consentimento da TASK-152) → TASK-156 (depende de `/obrigado` existir, TASK-155, e do botão
"Falar com Consultor" já capturar UTM, TASK-154). TASK-157 fica no backlog, sem sprint definida,
bloqueada por credenciais que Douglas ainda precisa levantar (Meta CAPI access token + dataset ID,
API de conversões do Google Ads).

---

## Critério de Conclusão do Épico

- [x] UTM da URL é persistido (cookie, 30 dias) e chega até o payload do lead e ao WhatsApp
- [x] Formulário "Solicitar Demonstração" não envia sem o checkbox de consentimento marcado
      (validado no frontend e no backend)
- [x] `landing_leads` grava `consent_accepted_at` com timestamp gerado no servidor
- [x] Submissão bem-sucedida redireciona para `/obrigado`, acessível sem login
- [x] Evento "Lead" dispara (via stub, hoje no-op) só no mount de `/obrigado`; evento "Contact"
      dispara no clique de "Falar com Consultor"
- [ ] Douglas forneceu os IDs de Meta Pixel / Google Tag e a instalação real foi concluída
      (fecha TASK-156 de fato; sem isso o épico fica "concluído com pendência conhecida")

---

## Riscos

- Sem os IDs de pixel, o épico entrega toda a infraestrutura mas **nenhum dado real chega ao Meta
  Ads Manager / Google Ads** até Douglas fornecer as credenciais — comunicar isso com clareza para
  não gerar falsa sensação de "campanha já mensurável".
- `consent_accepted_at` gerado no servidor (não no cliente) é proposital — timestamp de cliente é
  falsificável/não confiável para fins de comprovação de consentimento LGPD.
- Cookie de UTM com `sameSite: 'Lax'` (mesmo padrão do `em_ref` já existente) não é enviado em
  navegação cross-site via alguns fluxos (ex. iframe de terceiros) — aceitável, é o mesmo
  comportamento já validado em produção para o cookie de afiliado.
