# TASK-423 — Manutenção ↔ fornecedor responsável (D8)

## Tipo
FULL_STACK

## Categoria
Manutenção / Fornecedores

## Prioridade
🟠 Alto — sem isto o fornecedor não tem "itens dele" nem "serviços que vencem para mim".

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
D8 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md): o fornecedor **responsável** fica na manutenção, registro de quem fez. O fornecedor
**habitual** fica no item (D15) e é a [TASK-346](TASK-346.md) (EPIC-034). Hoje `assets` não referencia fornecedor.

## Escopo
- Campo opcional "fornecedor responsável" na manutenção (migration + DTO + validação por organização vinculada).
- Web: registro e histórico mostram o fornecedor.
- Samu: o "quem fez" do cartão sugere o fornecedor habitual do item quando houver; texto livre continua valendo.

## Critérios de Aceite
- [ ] Manutenção grava o fornecedor só se ele estiver vinculado à organização (`X-Org-Id`)
- [ ] Trocar o habitual do item não altera o responsável das manutenções antigas
- [ ] Contrato da API compatível (campo novo opcional)

## Dependências
Nenhuma para o campo; a sugestão pelo habitual depende da [TASK-346](TASK-346.md).

## Riscos
Duplicidade com o texto livre "feito por": manter os dois, com o campo estruturado tendo prioridade.

## Status
⬜ Backlog
