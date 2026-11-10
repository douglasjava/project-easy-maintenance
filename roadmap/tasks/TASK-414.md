# TASK-414 — Assistente: política única de permissões por papel (AssistantCapability)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Permissões

## Prioridade
🟠 Alto — base de todo o EPIC-042: menu, guard e personas leem desta tabela.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Hoje a permissão do bot está espalhada (guard, `if role == ADMIN` no `IntentStep`, checagens nos serviços), o menu
mostra o que o papel não pode fazer e bot e web divergem no financeiro (TECH). Ver [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md), "Problemas
encontrados" 1 a 4 e "Proposta técnica" item 1.

## Escopo
- Enum `AssistantCapability`, uma capacidade por linha da matriz (incluindo D14 abrir chamado pela equipe e D16
  alterar vencimento e cadastros).
- `AssistantRolePolicy`: papel ou persona → `Set<AssistantCapability>`, com soma de capacidades (D12).
- O `IntentStep` e os handlers barram **antes** de abrir rascunho, com mensagem do `AssistantMessages`.
- Os serviços de domínio mantêm a checagem própria (defesa em profundidade).
- Lançamento financeiro: só ADMIN/SYNDIC, igual ao `/financeiro`.

## Critérios de Aceite
- [x] Toda intenção do bot consulta a política antes de agir
- [x] READER tentando registrar recebe a recusa antes de qualquer rascunho
- [x] A matriz da spec vira teste parametrizado (papel × capacidade)
- [x] Nenhuma regressão nos fluxos atuais de ADMIN/SYNDIC (suíte do `assistant` verde)

## Dependências
Nenhuma.

## Riscos
Regressão em todo turno do bot: cobrir com teste da matriz inteira antes de trocar os pontos de checagem.

## Implementação (10/11/2026)
Branch `feature/TASK-414-assistant-capability-policy` (api, a partir de `staging`), commit `7aa4f28` · PR [api#191](https://github.com/douglasjava/easy-maintenance-api/pull/191).
- `AssistantCapability` (uma por linha da matriz), `AssistantRole` (login + personas; TECH e papel ausente = READER) e
  `AssistantRolePolicy` (matriz em código, soma D12, capacidade exigida por intenção).
- `IntentStep` barra antes de rascunho, espera ou consulta. Fecha o problema 1 (READER tocava "Registrar" e só depois
  era recusado) e o problema 2 da spec (TECH iniciava lançamento financeiro pelo bot).
- `AssistantRolePolicyTest`: matriz inteira linha a linha. `IntentStepTest`: recusas antes do rascunho.
  `mvn test` 1900, 0 falhas.

## Status
🔵 Em Validação — [api#191](https://github.com/douglasjava/easy-maintenance-api/pull/191) → `staging` (junto com a TASK-415).
