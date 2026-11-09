# TASK-347 — Assistente: foto → rascunho → Confirmar/Corrigir → item + evidência

## Tipo
BACKEND

## Prioridade
🔴 Crítico

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
TASK-345, TASK-346

## QA obrigatório
Sim.

## Contexto
Integra a leitura ao pipeline do assistente, no mesmo padrão de rascunho pendente da TASK-306/330.
Base: `staging` · branch `feature/TASK-347-<descricao-curta>`.

## Escopo
- Nova intenção para imagem sem registro pendente.
- Casar o tipo com o catálogo de normas/curado; divergência entre a data da etiqueta e a periodicidade da norma vira pergunta.
- Uma pergunta por mensagem; "não sei" marca pendente.
- Ao confirmar: cria/atualiza item, registra manutenção, anexa a foto como evidência e faz upsert do fornecedor por CNPJ.
- Evita item duplicado (busca existente).

## Critérios de aceite
- [ ] Placa do elevador gera rascunho com validade correta e aviso de prazo
- [ ] Etiqueta do extintor sugere fornecedor e próxima data
- [ ] Adesivo sem data gera pergunta
- [ ] Nada é gravado sem confirmação

## Status
Backlog
