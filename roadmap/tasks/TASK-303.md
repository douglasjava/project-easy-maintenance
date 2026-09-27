# TASK-303 — Classificador + transcrição + crédito de IA

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
TASK-299

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-303-<descricao-curta>`.

**Escopo**
- Atalhos determinísticos (menu numerado, botões, sim/corrigir/cancelar, ATIVAR, PARAR).
- IA com saída estruturada (JSON schema) na lista fechada de intenções + extração de campos
  (item, data, custo, tipo, responsável, período). Saída inválida → `FORA_DO_ESCOPO`.
- Transcrição de áudio via Spring AI (OpenAI), com limite de 2 min; o arquivo é descartado depois.
- Desconto no crédito de IA do plano; sem crédito → só menu/botões.

**Critérios de aceite**
- [ ] "Como faço isso em Python?" → `FORA_DO_ESCOPO` com resposta fixa.
- [ ] Nenhum texto da IA chega ao usuário (teste de contrato do montador de resposta).
- [ ] IA fora do ar → menu funciona.
- [ ] Áudio acima do limite é recusado sem transcrever.

**Prompt**: `execute a TASK-303 (EPIC-031): classificador de intenção com lista fechada e saída
estruturada, atalhos sem IA e transcrição de áudio.`

## Execução (27/09/2026)
Mesma branch da fundação — atalhos sem IA (menu, números, botões, saudações), classificador só com o provedor OpenAI e lista fechada (saída malformada = FORA_DO_ESCOPO, texto da IA nunca chega ao usuário), transcrição Whisper (1º áudio da rajada, até 1 MB, descartado após uso), crédito de IA do pagador da organização (áudio custa 300).
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#123](https://github.com/douglasjava/easy-maintenance-api/pull/123).

## Status
🟡 Em validação — mergeada em `staging`; promoção para `main` em api#124 / web#105
