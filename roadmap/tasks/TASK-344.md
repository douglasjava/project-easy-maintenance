# TASK-344 — Spec + conjunto de avaliação para leitura de documentos

## Tipo
QA / ANÁLISE

## Prioridade
🟠 Alto

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
Autorização das imagens do piloto

## QA obrigatório
Sim.

## Contexto
Antes do código: brainstorm/spec do fluxo e um conjunto fixo de imagens com a resposta esperada, rodado a cada mudança de prompt ou modelo.
Base: `staging` · branch `feature/TASK-344-<descricao-curta>`.

## Escopo
- Spec em `docs/superpowers/specs/`.
- 4 casos iniciais (placa de elevador, etiqueta de extintor, adesivo de hidrante, demonstrativo) + 20 a 30 fotos ruins (torta, reflexo, cortada) + casos adversos (texto tentando dar instrução).
- Metas: datas e CNPJ ≥ 95%; ≥ 80% dos campos aceitos sem correção.

## Critérios de aceite
- [ ] Spec aprovada
- [ ] Conjunto versionado com respostas esperadas (sem dados pessoais)
- [ ] Script de avaliação executável

## Status
Backlog
