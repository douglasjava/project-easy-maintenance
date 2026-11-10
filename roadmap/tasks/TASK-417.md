# TASK-417 — Assistente: identidade por persona (User, CondoPerson, contato de fornecedor)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Identidade

## Prioridade
🔴 Crítico — a maior mudança técnica do ciclo; tudo de persona e de contexto depende dela.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Item 2 da "Proposta técnica" da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md). Hoje `AssistantIdentity` é "um `User`" e a conversa e o
consentimento são chaveados por `userId`. As personas sem login (Morador, Zelador, Conselheiro, contato de Fornecedor)
precisam de identidade própria, e quem tem login e papel de governança soma as capacidades (D12). O contexto curto da
Parte B ([TASK-432](TASK-432.md)) só pode vir depois disto (D18).

## Escopo
- `AssistantIdentity` passa a representar uma persona (`User` | `CondoPerson` | contato de fornecedor), com
  organização(ões) e capacidades resolvidas pela política (TASK-414).
- `IdentityStep` resolve a persona pelo telefone, só entre personas **ativas** (convite aceito ou morador aprovado).
- Conversa (`AssistantConversation`) e consentimento chaveados por persona.
- Regra: a mesma pessoa nunca tem duas identidades; login + `CondoPerson.user_id` soma capacidades.
- Gate de assinatura do EPIC-041 continua valendo por organização.

## Critérios de Aceite
- [ ] Fluxo atual de usuário com login sem nenhuma regressão (teste de regressão antes de qualquer persona nova)
- [ ] Persona sem login ativa é reconhecida pelo telefone; inativa não
- [ ] Login + papel de governança soma capacidades (teste)
- [ ] Multi-tenant: persona só age na organização a que pertence (`TenantContext`)

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Mexe no ponto de entrada de todo turno: regressão derruba o assistente inteiro. Fazer atrás de flag.

## Status
⬜ Backlog
