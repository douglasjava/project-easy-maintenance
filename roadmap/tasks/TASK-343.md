# TASK-343 — Eventos de produto para a North Star e o funil de ativação

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 1**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Sem eventos não dá para calcular a North Star — boa parte do uso acontece no WhatsApp. Complementa a TASK-311 (métricas do assistente).
Base: `staging` · branch `feature/TASK-343-<descricao-curta>`.

## Escopo
- Eventos: `building_created`, `plan_activated`, `maintenance_completed{has_photo, on_time, actor_role, channel}`, `report_generated/opened`, `wa_template_billed{category}`.
- Consulta/painel admin: North Star semanal e funil cadastrado → plano ativo → 1ª baixa → 1º relatório.

## Critérios de aceite
- [ ] Eventos gravados com organização, canal e papel
- [ ] North Star calculável por semana e por conta
- [ ] Sem dado pessoal desnecessário nos eventos

## Status
Backlog
