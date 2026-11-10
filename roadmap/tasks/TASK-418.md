# TASK-418 — Convite por código para Zelador e Conselheiro + aceite do termo + revogação

## Tipo
FULL_STACK

## Categoria
Assistente WhatsApp (Samu) / Identidade

## Prioridade
🔴 Crítico — sem isto nenhuma persona sem login entra com segurança (D19).

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D19 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md) e seção "Ativação e revogação das personas sem login". O WhatsApp prova o número; o convite
prova que é a pessoa certa (um número digitado errado não ativa ninguém).

## Escopo
- `/pessoas`: botão **[Convidar para o WhatsApp]** no Zelador e no Conselheiro → link `wa.me` com código (uso único,
  7 dias, um ativo por pessoa; gerar outro invalida o anterior). Status do convite visível na tela.
- Bot: mensagem "ATIVAR <código>" → confere código + telefone do cadastro → pede aceite do termo (versão registrada)
  → persona ativa.
- Limite de tentativas erradas por número (anti força bruta).
- Revogação automática: telefone do cadastro mudou, pessoa removida, mandato encerrado, "SAIR".
- Auditoria de ativação e revogação.

## Critérios de Aceite
- [ ] Código certo + telefone certo ativa; código certo + outro telefone não ativa
- [ ] Código expirado, usado ou substituído é recusado
- [ ] Trocar o telefone no cadastro revoga a persona
- [ ] Aceite do termo registrado com versão e data
- [ ] Nenhum custo de template (a conversa parte da pessoa)

## Dependências
[TASK-417](TASK-417.md).

## Riscos
LGPD: o aceite precisa ser explícito e guardado; não ativar antes dele.

## Status
⬜ Backlog
