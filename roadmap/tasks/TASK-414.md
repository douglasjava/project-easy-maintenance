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
- [ ] Toda intenção do bot consulta a política antes de agir
- [ ] READER tentando registrar recebe a recusa antes de qualquer rascunho
- [ ] A matriz da spec vira teste parametrizado (papel × capacidade)
- [ ] Nenhuma regressão nos fluxos atuais de ADMIN/SYNDIC (suíte do `assistant` verde)

## Dependências
Nenhuma.

## Riscos
Regressão em todo turno do bot: cobrir com teste da matriz inteira antes de trocar os pontos de checagem.

## Status
⬜ Backlog
