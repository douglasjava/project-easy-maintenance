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
- [x] Sem vencimentos na semana e com vencidos → resposta sem ✅ e com o aviso de N vencidos
- [x] Sem vencimentos e sem vencidos → "✅ Nada vence" (como hoje)
- [x] Vencido de ano anterior aparece com ano ("08/11/2024"); do ano corrente, sem ano
- [x] Testes unitários de `AssistantQueryService` para os três casos (+ datas/atraso: 5 testes novos)
- [x] `mvn test` sem regressão — 1775/1775

## Implementação (09/11/2026)
- `upcoming` consulta também a janela de vencidos (mesma consulta do `overdue`, no contexto do condomínio):
  - nada na semana + vencidos → "📅 Nada vence nos próximos 7 dias em *X*, mas há ⚠️ *8 itens vencidos*. Ver: …&status=OVERDUE" (sem ✅);
  - itens na semana + vencidos → lista + "⚠️ Além disso, há *N itens vencidos*. Ver: …";
  - nada e nenhum vencido → "✅ Nada vence…" (como antes).
- Datas: `dd/MM` no ano corrente, `dd/MM/yyyy` em outro ano (vencidos e próximos).
- Atraso: até 60 dias em dias; depois em meses; a partir de 12 meses "mais de N anos".
- Um teste antigo (limite de 10 linhas) passou a declarar explicitamente "sem vencidos" no cenário.
- Fora: ações por item na lista de vencidos (TASK-340) e a pergunta da última data real (Parte B).

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `c21b6b1`.

## Status
🟡 Em Validação — implementado e testado (1775/1775); falta QA manual
[TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) (C7, C8).
