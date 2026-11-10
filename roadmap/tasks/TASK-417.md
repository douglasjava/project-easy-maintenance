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
- [x] Fluxo atual de usuário com login sem nenhuma regressão (teste de regressão antes de qualquer persona nova)
- [x] Persona sem login ativa é reconhecida pelo telefone; inativa não
- [x] Login + papel de governança soma capacidades (teste)
- [x] Multi-tenant: persona só age na organização a que pertence (`TenantContext`)

## Dependências
[TASK-414](TASK-414.md).

## Riscos
Mexe no ponto de entrada de todo turno: regressão derruba o assistente inteiro. Fazer atrás de flag.

## Implementação (10/11/2026)
Branch `feature/TASK-417-assistant-persona-identity` · [api#193](https://github.com/douglasjava/easy-maintenance-api/pull/193), mergeada em `staging`.
- `AssistantIdentity` passa a representar login **ou** persona (`Persona`), com `roles()` e `capabilities()` pela política. A soma da D12 vem de `condo_people.user_id`; mandato encerrado não conta.
- `assistant_persona_links` (V139): vínculo da persona com o WhatsApp, a base para as TASK-418, 419 e 422. `assistant_conversations` ganha `persona_link_id` e `user_id` passa a aceitar nulo.
- Resolução: o login vence a persona. A persona exige vínculo ativo, termo atual, cadastro ativo com o mesmo telefone (tolera o 9º dígito) e mandato vigente.
- Atrás de `assistant.personas-enabled` (padrão `false`). Até ter fluxo próprio, a persona recebe uma mensagem fixa. O "SAIR" revoga o vínculo.
- `mvn test` 1904, 0 falhas. A migration não roda nos testes (H2 sem Flyway).

## Status
🔵 Em `staging` (10/11/2026) — atrás da flag `ASSISTANT_PERSONAS_ENABLED` (desligada); aguarda a validação de Douglas.
