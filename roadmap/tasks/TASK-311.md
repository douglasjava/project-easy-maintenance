# TASK-311 — Retenção + métricas

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-299

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-311-<descricao-curta>`.

**Escopo**: job (ShedLock) que apaga o texto das mensagens com mais de 90 dias mantendo os
metadados; métricas: volume, intenções, `FORA_DO_ESCOPO`, tempo de resposta (p50/p95), falhas e
custo de IA estimado.

**Critérios de aceite**
- [ ] Após o job, nenhuma mensagem com mais de 90 dias tem conteúdo.
- [ ] Métricas visíveis no monitoramento existente.

**Prompt**: `execute a TASK-311 (EPIC-031): retenção de 90 dias e métricas do assistente.`

## Status
Backlog
