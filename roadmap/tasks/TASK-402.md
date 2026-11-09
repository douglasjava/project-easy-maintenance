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
- [x] Registro sem data → pergunta com [Hoje] [Ontem] [Outra data]; nada de "usei hoje"
- [x] "feita hj às 08:00" → data de hoje, sem pergunta
- [x] "Outra data" → "17/10" → cartão com 17/10 do ano corrente (ou anterior, se futura — regra atual)
- [x] Data futura digitada continua rejeitada pelo serviço de domínio (mensagem amigável)
- [x] "cancelar" no `CHOOSE_DATE` descarta o rascunho
- [x] Rascunho antigo serializado (sem o estágio novo) ainda é lido (compatibilidade do JSON pendente, TTL 30 min)
- [x] `mvn test` sem regressão — 1758/1758 (14 testes novos de registro + 2 do parser)

## Riscos
Um passo a mais na conversa para quem não diz a data — aceitável (decisão do Tiago: "data é obrigatória").

## Implementação (09/11/2026)
- Novo estágio `CHOOSE_DATE`. Sem data dita, `performedAt` fica vazio; **todo caminho até o cartão**
  passa por `savePendingAndShowSummary`, que pergunta "📅 Quando foi feita a manutenção de *X*?" com
  [Hoje] [Ontem] [Outra data]. Ordem: item (lista/parecidos/catálogo/periodicidade) → data → cartão.
- Data futura ou ilegível → pergunta de novo (a futura com mensagem própria). Foto que chega antes da
  data fica guardada no rascunho.
- `parseDate`: **data escrita vence a relativa** ("ontem, dia 07/11/26" → 07/11/26, achado da manutenção
  19); "hj" e "onti" reconhecidos (como palavra inteira).
- **Campo `data` da IA só vale se o texto fala de quando foi** (`mentionsWhen`: "semana passada",
  "sexta"…) — mesma lição do campo `item` da TASK-401; sem isso a IA podia "presumir" a data por nós.
- Defesa: confirmar sem data não grava, volta para a pergunta. Rascunho antigo (data presumida,
  gravado antes do deploy) continua lido e confirmado.
- Cartão: a marca "(não informada — usei hoje)" deixa de existir.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `e30967b`.

## Status
🟡 Em Validação — implementado e testado (1758/1758); falta QA manual
[TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) (C4, C5).
