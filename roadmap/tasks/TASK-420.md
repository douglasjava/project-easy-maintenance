# TASK-420 — Persona Morador no bot: abrir chamado, status, áreas comuns

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Morador

## Prioridade
🟠 Alto.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Linhas "Abrir chamado", "Status dos meus chamados" e "Áreas comuns" da matriz ([spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md)). IA só para abrir
chamado (D11, D18).

## Escopo
- Abrir chamado por texto, foto ou áudio (EPIC-027: categoria e protocolo), já vinculado à unidade do morador.
- "Meus chamados": status de cada um.
- Regras e horários das áreas comuns (EPIC-038), só leitura.
- Menu do morador gerado pela política.

## Critérios de Aceite
- [ ] Morador abre chamado sem passar pelo QR Code e recebe o protocolo
- [ ] Morador só vê os próprios chamados (teste negativo)
- [ ] Nunca aparece custo, financeiro ou dado de outro morador

## Dependências
[TASK-419](TASK-419.md). Liberar para todos só depois da [TASK-429](TASK-429.md) (limite de IA).

## Riscos
Morador é o público mais numeroso: custo de IA e de WhatsApp.

## Status
⬜ Backlog
