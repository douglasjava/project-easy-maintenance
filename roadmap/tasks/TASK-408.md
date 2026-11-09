# TASK-408 — BUGFIX: negrito quebrado no nome do condomínio + limpeza dos dados do teste (Gerador) (EPIC-031)

## Tipo
BUGFIX — BACKEND + DADOS

## Categoria
Assistente WhatsApp (Samu) / Acabamento e higiene de dados

## Prioridade
🔵 Baixo (negrito) · 🟡 Médio (dados errados em produção afetam o índice do Edifício Veneza)

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-12**, **WA-17**, **WA-18**)

## QA obrigatório
Sim — limpeza de dado em produção: Douglas executa/aprova.

---

## Parte 1 — WA-12: "*Condomínio Edifício Veneza *"
**Causa:** o nome da organização tem espaço no final; `*%s*` com espaço antes do `*` não vira negrito no WhatsApp.
- `trim()` do nome no envio do assistente (todas as mensagens com `*%s*`) — correção imediata.
- `trim()` na criação/edição de organização (web e WhatsApp) + migration `UPDATE organizations SET name = TRIM(name)`.

## Parte 2 — WA-18: item "Gerador" criado por engano (maintenanceId=19)
- Confirmar que o "Gerador" da lista de vencidos é o criado no teste 1 (origem `WHATSAPP`, criado em 08/11).
- Com aprovação do Douglas/Tiago: mover a manutenção 19 para "Limpeza caixa de gordura · Garragem
  subsolo" (ou excluí-la e o Tiago registra de novo) e excluir o item Gerador. Registrar no audit.
- Feito **depois** do deploy das [TASK-400](TASK-400.md)/[TASK-401](TASK-401.md) para não recriar.

## Parte 3 — WA-17: "Nenhum item vencido" no teste 1 × 8 vencidos no teste 2
- Verificar no audit/`created_at` se os 8 itens foram cadastrados entre os testes (hipótese provável).
- Se não foram: abrir bug próprio de cálculo de vencidos. Registrar a conclusão nesta task.

## Critérios de Aceite
- [ ] Saudação e "Itens vencidos" exibem o nome em negrito sem asteriscos visíveis
- [ ] Migration de trim aplicada; criação/edição não aceitam espaços nas pontas
- [ ] Item Gerador do teste removido/corrigido com aprovação, manutenção 19 no item certo ou removida
- [ ] Conclusão do WA-17 registrada (dados vs. cálculo)
