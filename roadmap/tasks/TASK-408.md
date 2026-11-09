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
- [x] Saudação e "Itens vencidos" exibem o nome em negrito sem asteriscos visíveis (teste; confirmar no QA C13)
- [x] Migration de trim (V136) criada; criação/edição normalizam o nome (`@PrePersist/@PreUpdate`) — aplicar no deploy
- [ ] Item Gerador do teste removido/corrigido com aprovação, manutenção 19 no item certo ou removida
- [ ] Conclusão do WA-17 registrada (dados vs. cálculo)

## Implementação da Parte 1 (09/11/2026)
- `AssistantOrg` faz `trim` no construtor: todo nome que o bot exibe sai limpo (cobre dados antigos mesmo
  antes da migration rodar).
- `Organization.normalizeName()` em `@PrePersist/@PreUpdate`: web, IA Onboarding, WhatsApp e afiliados — sem
  depender de cada serviço lembrar.
- `V136__trim_organization_names.sql`: `UPDATE organizations SET name = TRIM(name) WHERE name <> TRIM(name)`.
- 4 testes novos; `mvn test` 1802/1802. Commit `a1a3987` em `bugfix/onda1-usabilidade-samu`.

## Partes 2 e 3 — roteiro para o Douglas (produção, **depois do deploy** da Onda 1)

**Recomendação: corrigir pela tela, não por SQL** — o domínio já tem o caminho auditado (cancelamento com motivo,
TASK-137, e exclusão de item), e o cancelamento recalcula o vencimento do item (RN-016).

1. Web → Edifício Veneza → item **Gerador (140)** → histórico → manutenção **19** → **Cancelar**, motivo:
   "Registrada no item errado pelo assistente (IA inventou o item — TASK-401)".
2. Excluir o item **Gerador (140)** (criado em 08/11 pelo WhatsApp, sem outra manutenção).
3. Tiago registra de novo pelo WhatsApp: "manutenção da caixa de gorduro ontem, emergencial, R$ 300" — é o
   cenário **C1** do [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) (deve sugerir a caixa de gordura).

Conferência antes do passo 2 (só leitura):
```sql
SELECT id, item_id, performed_at, cancelled_at FROM maintenances WHERE item_id = 140;  -- só a 19
```

**WA-17** ("nenhum vencido" no teste 1 × 8 vencidos no teste 2) — consulta de leitura:
```sql
SELECT id, item_type, next_due_at, source, created_at
FROM maintenance_items
WHERE organization_code = (SELECT organization_code FROM maintenance_items WHERE id = 140)
  AND deleted_at IS NULL AND next_due_at < '2026-11-08'
ORDER BY created_at;
```
Se os itens vencidos tiverem `created_at` entre o teste 1 e o teste 2 de 08/11, a diferença vem dos cadastros
(hipótese provável). Senão, abrir bug próprio de cálculo de vencidos.

## Status
🟡 Em Validação — Parte 1 implementada (1802/1802); Partes 2 e 3 aguardam deploy + execução/aprovação do Douglas.
