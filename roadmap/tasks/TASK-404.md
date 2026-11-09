# TASK-404 — BUGFIX: "Vencimentos da semana" diz "✅ nada vence" com itens vencidos, e datas sem ano (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Consultas

## Prioridade
🟠 Alto — o check verde passa a ideia de que está tudo em dia com 8 itens vencidos.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-19**, **WA-15**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Causa (verificada no código)
- `AssistantQueryService.upcoming` consulta só `[hoje, hoje+N]`; vazio → `NOTHING_DUE` ("✅ Nada vence
  nos próximos 7 dias"), sem olhar vencidos.
- `overdue` e `upcoming` formatam com `DAY_MONTH` (dd/MM): "venceu em 08/11 (há 730 dias)" parece hoje.

## Escopo
- `upcoming`: contar vencidos; se houver, acrescentar "⚠️ Mas há N itens vencidos" (ou listar os
  vencidos antes, limitado) e nunca usar ✅ quando houver vencido. Mensagem nova em `AssistantMessages`.
- Datas em `overdue`/`upcoming`: mostrar o ano quando diferente do ano corrente (`dd/MM/yyyy`).
- "(há 730 dias)": para mais de 60 dias, exibir em meses/anos ("há 2 anos").

## Fora de escopo
- Ações por item na lista de vencidos (WA-16 — é a [TASK-340](TASK-340.md) do EPIC-033).
- Pergunta "você sabe quando foi feito pela última vez?" para vencidos há mais de 1 ano (Parte B, fluxo C).

## Critérios de Aceite
- [ ] Sem vencimentos na semana e com vencidos → resposta sem ✅ e com o aviso de N vencidos
- [ ] Sem vencimentos e sem vencidos → "✅ Nada vence" (como hoje)
- [ ] Vencido de ano anterior aparece com ano ("08/11/2024"); do ano corrente, sem ano
- [ ] Testes unitários de `AssistantQueryService` para os três casos
- [ ] `mvn test` sem regressão
