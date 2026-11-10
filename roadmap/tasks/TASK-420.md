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
- [x] Morador abre chamado sem passar pelo QR Code e recebe o protocolo
- [x] Morador só vê os próprios chamados (teste negativo)
- [x] Nunca aparece custo, financeiro ou dado de outro morador

## Dependências
[TASK-419](TASK-419.md). Liberar para todos só depois da [TASK-429](TASK-429.md) (limite de IA).

## Riscos
Morador é o público mais numeroso: custo de IA e de WhatsApp.

## Implementação (10/11/2026)
[api#196](https://github.com/douglasjava/easy-maintenance-api/pull/196), mergeada em `staging`.
- `AssistantResidentService`: menu do morador (Abrir chamado, Meus chamados, Áreas comuns).
- Abrir chamado: o texto livre vira a descrição sem IA (D11), o áudio chega transcrito e a foto vai para o S3 do chamado. A categoria é escolhida em botões e o chamado é criado pelo serviço do QR Code (protocolo, SLA, aviso ao síndico).
- Meus chamados: pelo CPF do próprio morador. Áreas comuns: só leitura.
- Liberar para todos depende da TASK-429. Por ora o morador não usa IA, só a transcrição do áudio.
- `mvn test` 1929, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
