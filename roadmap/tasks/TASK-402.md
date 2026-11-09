# TASK-402 — BUGFIX: registro pelo WhatsApp presume "hoje" quando a data não foi dita e não entende "hj" (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro de manutenção

## Prioridade
🟠 Alto — um toque em Confirmar grava manutenção numa data que não aconteceu.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-13**, **WA-07**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
- WA-13: "Quero atualizar a manutenção do alarme de incêndio" virou cartão com "08/11/2026 (não
  informada — usei hoje)".
- WA-07: "feita hj às 08:00" → "não informada — usei hoje".

## Causa (verificada no código)
- `AssistantRegistrationService.start`: `date != null ? date : today` com `performedAtAssumed=true` —
  comportamento intencional da TASK-306, agora revisto (data é obrigatória e não deve ser presumida).
- `RegistrationParser.parseDate` reconhece "hoje/ontem/anteontem", não as abreviações "hj", "onti",
  "ontem a noite" etc.

## Escopo da correção
- Data ausente → novo estágio `CHOOSE_DATE` antes do cartão: "Quando foi feita?" com botões
  **[Hoje] [Ontem] [Outra data]**; "Outra data" aceita texto ("17/10", "semana passada" → pede o dia).
  Texto livre com data nesse estágio também vale. Manter os demais campos do rascunho.
- Remover a marca "(não informada — usei hoje)" do cartão (deixa de existir).
- **Data explícita vence a relativa** (achado na manutenção 19: "ontem, dia 07/11/26" — hoje `parseDate`
  lê "ontem" antes de olhar a data escrita).
- `parseDate`: aceitar "hj", "hoje cedo", "hj de manhã", "ontem à noite", "onti".
- Ordem de estágios: item (TASK-400/401) → data → cartão.

## Decisão registrada
**Hora da execução fica fora** (Tiago, WA-03: "horário 09:00 ignorado"): `RegisterMaintenanceRequest.performedAt`
é `LocalDate` em todo o domínio (web, relatórios, índice). Guardar hora exige migration e mudança de
contrato — não cabe num bugfix. A hora dita continua indo no texto da descrição (ver [TASK-405](TASK-405.md)).

## Fora de escopo
- Desambiguação "atualizar = registrar feito ou remarcar?" (fluxo D/"alterar vencimento" da Parte B).
  Nesta task, "atualizar a manutenção de X" sem data apenas cai no `CHOOSE_DATE` — já impede gravar
  data falsa.

## Critérios de Aceite
- [ ] Registro sem data → pergunta com [Hoje] [Ontem] [Outra data]; nada de "usei hoje"
- [ ] "feita hj às 08:00" → data de hoje, sem pergunta
- [ ] "Outra data" → "17/10" → cartão com 17/10 do ano corrente (ou anterior, se futura — regra atual)
- [ ] Data futura digitada continua rejeitada pelo serviço de domínio (mensagem amigável)
- [ ] "cancelar" no `CHOOSE_DATE` descarta o rascunho
- [ ] Rascunho antigo serializado (sem o estágio novo) ainda é lido (compatibilidade do JSON pendente, TTL 30 min)
- [ ] `mvn test` sem regressão

## Riscos
Um passo a mais na conversa para quem não diz a data — aceitável (decisão do Tiago: "data é obrigatória").
