# TASK-352 — Link público com token para o fornecedor enviar a evidência

## Tipo
FULL_STACK

## Prioridade
🟠 Alto

## Épico
[EPIC-035](../epics/EPIC-035.md) — Prestador no fluxo (evidência enviada pelo fornecedor) · **Fase 3**

## Depende de
TASK-346

## QA obrigatório
Sim.

## Contexto
Fornecedor envia foto, nota fiscal e laudo sem login, no padrão do QR de chamados (EPIC-027).
Base: `staging` · branch `feature/TASK-352-<descricao-curta>`.

## Escopo
- Token por manutenção, com expiração e uso limitado.
- Upload no S3 com limite de tamanho/tipo.
- O síndico confirma antes de concluir (regra de ouro).

## Critérios de aceite
- [ ] Link expira e não reabre outra manutenção
- [ ] Upload vira anexo da manutenção após confirmação
- [ ] Rate limit no endpoint público

## Status
Backlog
