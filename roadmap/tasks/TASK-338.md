# TASK-338 — Medir mensagens de WhatsApp por organização e por plano

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 0**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
IA já tem teto por créditos; mensagem de WhatsApp não tem. Antes de limitar, precisamos medir o custo por prédio.
Base: `staging` · branch `feature/TASK-338-<descricao-curta>`.

## Escopo
- Contador de mensagens enviadas por organização/mês, separado por categoria (utilidade, marketing, resposta na janela).
- Exposição no admin.
- Sem bloqueio nesta task.

## Critérios de aceite
- [ ] Contagem por organização e categoria disponível no admin
- [ ] Sem impacto no envio
- [ ] Isolamento por tenant preservado

## Status
Backlog
