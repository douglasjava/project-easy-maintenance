# TASK-308 — Onboarding conversacional

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-302

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-308-<descricao-curta>`.

**Escopo**: só para conta existente, dentro de `maxOrganizations`. Perguntas: nome, tipo de empresa
(lista), CEP, e perguntas de sim/não geradas do catálogo do tipo (elevador, gerador, piscina, gás…).
Resumo "Vou cadastrar N itens" → Confirmar → `previewFromCatalog` + `apply` (sem IA).

**Critérios de aceite**
- [ ] Os itens criados são os mesmos que o onboarding web criaria para as mesmas respostas.
- [ ] Limite de organizações respeitado com mensagem clara.
- [ ] Abandono no meio não cria nada.

**Prompt**: `execute a TASK-308 (EPIC-031): novo condomínio pelo WhatsApp reaproveitando
catalog-preview e apply do onboarding web.`

## Status
Backlog
