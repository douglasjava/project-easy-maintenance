# TASK-157 — Fase 2 (backlog): Conversions API (Meta) / Enhanced Conversions (Google) server-side

## Tipo
BACKEND

## Categoria
Marketing / Tracking

## Prioridade
🟡 Médio

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim, quando escopada — validar que eventos server-side batem com os client-side sem duplicar
conversão no Ads Manager (deduplicação por `event_id`).

---

## Contexto

Pixels client-side sozinhos perdem uma parte relevante dos eventos por causa de ad blockers e
restrições do iOS (ITP/Safari). O padrão de mercado é complementar com tracking server-side: Meta
Conversions API (CAPI) e Google Enhanced Conversions. Decisão de Douglas (30/07/2026): tratar como
fase 2, depois que o pixel client-side básico (TASK-156, após IDs fornecidos) estiver validado.

---

## Objetivo

Enviar o evento de Lead também a partir do backend (`LeadService.createLead`, ponto único onde o
lead é persistido), deduplicado com o evento client-side via `event_id` compartilhado.

---

## Bloqueado por (credenciais que Douglas precisa levantar antes desta task poder ser escopada)

- Meta: access token de sistema (Conversions API) + Dataset ID / Pixel ID associado.
- Google: credenciais de Enhanced Conversions (Google Ads API ou upload via Google Tag) + IDs de
  conversão configurados no Google Ads.

**Sem essas credenciais, não implementar com placeholders/valores fictícios** — mesma diretriz já
aplicada ao TASK-156 para o pixel client-side.

---

## Critérios de Aceite (a refinar quando escopada)

- [ ] Evento de Lead enviado ao Meta CAPI a partir do backend, com `event_id` igual ao usado no
      pixel client-side (evita contagem duplicada no Ads Manager)
- [ ] Evento equivalente enviado ao Google via Enhanced Conversions
- [ ] Falha no envio server-side não bloqueia a criação do lead (best-effort, assíncrono/não
      bloqueante)
- [ ] Nenhuma credencial hardcoded no código — via variável de ambiente/secret

## Dependências
- **TASK-156** — pixel client-side básico instalado e validado primeiro.

## Riscos
Escopo real só fica claro depois que Douglas definir qual API/conta será usada — esta task é um
placeholder de backlog, não uma especificação fechada.

## Esforço
A estimar (depende das credenciais/API escolhidas)

## Status
Backlog — bloqueada por credenciais
