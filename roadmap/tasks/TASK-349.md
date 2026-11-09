# TASK-349 — Onboarding guiado: assistente pede fotos na ordem certa

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-034](../epics/EPIC-034.md) — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item · **Fase 2**

## Depende de
TASK-347

## QA obrigatório
Sim.

## Contexto
Após o cadastro, o assistente conduz: primeiro equipamentos regulatórios (elevador, extintores, hidrantes, caixa d'água), depois laudos e notas.
Base: `staging` · branch `feature/TASK-349-<descricao-curta>`.

## Escopo
- Roteiro por tipo de condomínio usando o catálogo.
- Estado salvo para retomar no dia seguinte.
- Meta: 10 itens com vencimento em 30 min de conversa.

## Critérios de aceite
- [ ] Conversa pode ser retomada sem recomeçar
- [ ] Itens já cadastrados não são pedidos de novo

## Status
Backlog
