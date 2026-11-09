# TASK-345 — Backend: leitura estruturada de imagem com confiança e validação

## Tipo
BACKEND

## Prioridade
🔴 Crítico

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
TASK-344

## QA obrigatório
Sim.

## Contexto
Chamada de visão que devolve só JSON: tipo de documento e campos com confiança (alta/média/baixa). Nada é gravado.
Base: `staging` · branch `feature/TASK-345-<descricao-curta>`.

## Escopo
- Redimensionar a imagem antes de enviar; não reprocessar a mesma foto (hash).
- Validações no backend: dígito do CNPJ, validade > inspeção, ano com 2 dígitos, nome do condomínio × conta.
- Consome créditos de IA; circuit breaker existente.
- Texto da imagem nunca vira instrução.

## Critérios de aceite
- [ ] Os 4 casos iniciais extraem os campos esperados
- [ ] CNPJ inválido é marcado como baixa confiança
- [ ] Falha da IA não perde a mensagem
- [ ] Testes com modelo mockado no CI

## Status
Backlog
