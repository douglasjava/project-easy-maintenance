# TASK-433 — Samu: chamados pela equipe — abrir com SLA, lista por SLA e ações

## Tipo
FULL_STACK

## Categoria
Assistente WhatsApp (Samu) / Chamados

## Prioridade
🟠 Alto.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Fluxo F da [Parte B](../QA/registro-usabilidade-producao.md) e D14 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): ADMIN, SYNDIC e Zelador também abrem chamado.

## Escopo
- Abrir chamado: descrição e foto, sugestão de local/item, urgência ([Urgente] [Normal] [Baixa]), SLA resultante.
  Chamado sai com origem "equipe" (web mostra a origem).
- "Chamados por SLA": fora do SLA, vence hoje, no prazo.
- Ações por chamado: [Atualizar status] [Acionar fornecedor] [Responder morador].
- Ao concluir, oferece registrar a manutenção com item e foto preenchidos.

## Critérios de Aceite
- [ ] Equipe abre chamado pelo bot e ele aparece no kanban com origem "equipe"
- [ ] Lista por SLA ordenada (fora do prazo primeiro)
- [ ] Concluir chamado oferece o registro já preenchido

## Dependências
[TASK-414](TASK-414.md), [TASK-415](TASK-415.md). "Acionar fornecedor" usa o habitual da [TASK-346](TASK-346.md).

## Riscos
Zelador só atende e abre; não reprova nem apaga (matriz).

## Implementação (10/11/2026)
[api#209](https://github.com/douglasjava/easy-maintenance-api/pull/209) e [web#147](https://github.com/douglasjava/easy-maintenance-web/pull/147), mergeadas em `staging`.
- ADMIN, SYNDIC e zelador abrem chamado pelo bot: descrição e foto → urgência (Urgente/Normal/Baixa = HIGH/MEDIUM/LOW) → protocolo e prazo pelo SLA da organização.
- `resident_tickets.origin` (V147) MORADOR/EQUIPE; selo **Equipe** no kanban do web.
- A lista de chamados (por SLA) ganha ➕ Abrir chamado; ao concluir, o botão [Registrar] abre o registro com a descrição do chamado.
- **Pendente:** acionar o fornecedor depende do fornecedor habitual (TASK-346 e TASK-437); responder ao morador precisa de um template novo da Meta.
- `mvn test` 1979, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026), com pendências: acionar o fornecedor (TASK-437) e responder ao morador (template Meta).
