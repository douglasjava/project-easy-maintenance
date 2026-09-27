# TASK-300 — `WhatsAppClient` ampliado + cota

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
—

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-300-<descricao-curta>`.

**Escopo**
- Envio de texto livre, botões de resposta (até 3), lista (até 10 opções), documento (PDF/XLSX),
  marcar como lida com indicador de digitação e download de mídia (`GET /{media-id}` → URL →
  bytes).
- Respeito à janela de 24h: fora da janela, recusa o envio livre (erro claro).
- Mensagens de resposta dentro da janela **não** consomem a cota mensal de WhatsApp do plano.

**Critérios de aceite**
- [ ] Cada tipo de envio coberto por teste com o `WebClient` mockado (payload conforme a Graph API).
- [ ] Download de mídia com limite de tamanho e timeout.
- [ ] Cota do plano inalterada ao responder dentro da janela.

**Prompt**: `execute a TASK-300 (EPIC-031): ampliar WhatsAppClient para texto, botões, lista,
documento, lida/digitando e download de mídia, sem consumir cota dentro da janela de 24h.`

## Execução (27/09/2026)
Mesma branch da fundação — `WhatsAppClient` com texto, botões, lista, lida+digitando e download de mídia (buffer de 16 MB, limite por tamanho). Envio de documento (PDF/XLSX) movido para a TASK-309, onde é usado pela primeira vez.
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#123](https://github.com/douglasjava/easy-maintenance-api/pull/123).

## Status
✅ Concluída — em produção desde 27/09/2026 (api#124 / web#105); validada no piloto com o número do Douglas.
