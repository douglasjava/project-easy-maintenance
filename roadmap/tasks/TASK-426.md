# TASK-426 — Persona Fornecedor no bot: serviços que vencem, itens dele, enviar execução, cobranças

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Fornecedor

## Prioridade
🟠 Alto.

## Épico
[EPIC-042](../epics/EPIC-042.md) — Matriz de papéis no assistente

## QA obrigatório
Sim.

---

## Contexto
Linhas do Fornecedor na matriz ([spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md)), com o modelo de conta global de 10/11/2026: um contato vê os
serviços de **todos** os condomínios a que o fornecedor está vinculado, agrupados por condomínio.

## Escopo
- "Serviços que vencem para mim": itens em que ele é o habitual (TASK-346), todos os condomínios.
- Histórico dos itens dele (manutenções em que é o responsável, TASK-423).
- Enviar execução escolhendo o condomínio (TASK-424); só o condomínio dono do item valida.
- Minhas cobranças e pagamentos (EPIC-028).
- IA só para registrar execução (D11).

## Critérios de Aceite
- [x] Vê só itens e manutenções ligados a ele, nunca custos de outros nem outros fornecedores (teste negativo)
- [x] Execução enviada para o condomínio certo
- [x] Condomínio desligado some da lista

## Dependências
[TASK-422](TASK-422.md), [TASK-423](TASK-423.md), [TASK-424](TASK-424.md), [TASK-346](TASK-346.md).

## Riscos
Multi-tenant entre condomínios do mesmo fornecedor: teste com 2 condomínios.

## Implementação (10/11/2026)
[api#203](https://github.com/douglasjava/easy-maintenance-api/pull/203), mergeada em `staging`.
- Menu do fornecedor: serviços que vencem (60 dias, todos os condomínios vinculados), histórico, enviar execução (vira o responsável ao validar) e assinatura.
- "Itens dele" vêm das execuções em que ele foi o responsável (D8). O habitual entra com a TASK-346.
- Texto livre vira execução, sem IA (D11). Nunca mostra custo nem outros fornecedores.
- `mvn test` 1959, 0 falhas.

## Status
🔵 Em `staging` (10/11/2026) — atrás de `ASSISTANT_PERSONAS_ENABLED`; aguarda a validação de Douglas.
