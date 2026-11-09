# TASK-340 — Baixa pelo alerta no WhatsApp: "Já foi feita" → foto → confirmar

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 1**

## Depende de
TASK-339; template de utilidade aprovado na Meta

## QA obrigatório
Sim.

## Contexto
O alerta de vencimento vira o início da baixa: o usuário responde com um botão e uma foto, sem abrir o web.
Base: `staging` · branch `feature/TASK-340-<descricao-curta>`.

## Escopo
- Botão no template de alerta (categoria utilidade).
- Resposta abre o fluxo de registro da TASK-306 já com o item preenchido.
- Concluir em até 2 mensagens.
- Origem `WHATSAPP` auditada.

## Critérios de aceite
- [ ] Responder ao alerta registra a manutenção com foto
- [ ] Template aprovado como utilidade
- [ ] Usuário sem vínculo ativo não consegue registrar

## Status
Backlog
