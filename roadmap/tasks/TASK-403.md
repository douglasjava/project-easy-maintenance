# TASK-403 — MELHORIA: cartão de confirmação do registro mostra a próxima data e a regra usada (EPIC-031)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro de manutenção

## Prioridade
🟠 Alto — usuário confirma às cegas o efeito no vencimento (poda: próximo em 21 dias sem aviso).

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-06**, **WA-23**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
O cartão "Confere o registro?" não mostra o próximo vencimento; ele só aparece na mensagem de
"✅ Registrado!" (`commit`, depois de gravar). Tiago: o padrão deve ser **calcular e mostrar**; o usuário
só altera por exceção.

## Escopo
- No `summary()` do cartão, linha `⏭️ Próxima: dd/MM/yyyy (regra)`, onde a regra é:
  - item regulatório: periodicidade da norma (ex.: "anual, ABNT NBR 12962");
  - item operacional: periodicidade do item (ex.: "a cada 6 meses, do item");
  - item novo operacional: periodicidade escolhida no `CHOOSE_PERIOD`.
- **Fonte única do cálculo:** extrair/reaproveitar o cálculo de próximo vencimento usado por
  `MaintenanceService.register` (sem duplicar regra no assistente). Se não houver método puro, criar um
  no domínio (`assets`) que receba item + data de execução e devolva data + descrição da regra, e
  fazer o `register` usar o mesmo.
- Remover do `REGISTER_FIX_PROMPT` o exemplo "a cada 6 meses" quando o item já tem periodicidade
  (WA-23) — só faz sentido para item novo operacional.
- Se a data do registro for **anterior** à última manutenção do item, avisar no cartão que o
  vencimento não muda (comportamento atual do domínio, a confirmar na implementação).

## Fora de escopo
- Corrigir a "próxima data" pelo cartão e o fluxo "Alterar vencimento" (Parte B).
- Decisão "corretiva/emergencial reinicia o ciclo?" — pendente de produto; nesta task o cartão
  mostra **o que o domínio faz hoje**, seja qual for.
- Execução 📝 de zelador/fornecedor (spec da matriz de papéis, D9) — quando vier, o cartão dirá
  "calculada após validação do síndico".

## Critérios de Aceite
- [x] Cartão mostra a próxima data e a regra para item regulatório, operacional e item novo
- [x] A data mostrada no cartão é **igual** à gravada após Confirmar (teste comparando os dois caminhos)
- [x] Item sem periodicidade (se existir) → cartão não quebra; mostra "sem periodicidade definida"
- [x] Mensagem de "✅ Registrado!" continua com o próximo vencimento
- [x] `mvn test` sem regressão — 1770/1770 (5 testes de domínio + 7 do cartão)

## Riscos
Refatorar o cálculo do `MaintenanceService.register` toca o fluxo web de registro — cobrir com os
testes existentes do serviço antes de mexer.

## Implementação (09/11/2026)
- **Fonte única do cálculo:** `MaintenanceService.nextDueAfter` (período → data da execução + período;
  sem período → vencimento atual) é usado pelo `register()` **e** pela prévia
  (`previewNextDue(orgId, itemId, data)` e `previewNextDueForNewItem(normId, meses, data)`). Teste prova que a
  data da prévia é igual à gravada. `ServiceBase.resolveNormPeriod` virou a única tradução norma → período.
- Prévia usa `findEntityForOrg` (valida o condomínio); item de outra organização → `TenantException`.
- Cartão: `⏭️ Próxima: 07/05/2027 (a cada 6 meses, periodicidade do item)` ou
  `(uma vez por ano, pela norma — Corpo de Bombeiros / ABNT)`; item novo usa a norma do tipo do catálogo ou
  a periodicidade escolhida; sem periodicidade: "o vencimento continua dd/MM/yyyy". Falha na prévia não
  impede o cartão (só omite a linha).
- O exemplo "a cada 6 meses" do Corrigir só aparece para item novo operacional (feito na TASK-400).

## ⚠️ Achado de domínio (não corrigido — decisão de produto)
Registrar uma manutenção com data **anterior** à última do item faz o `register()` recalcular o vencimento a
partir dessa data antiga (puxa o vencimento para trás e sobrescreve `lastPerformedAt`). O cartão agora
**avisa** ("Já existe manutenção mais recente…"), mas a regra em si vale para web e WhatsApp e merece decisão:
manter, ou só recalcular quando a data for a mais recente. Mesma família da decisão pendente "corretiva
reinicia o ciclo?".

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `eda46e6`.

## Status
✅ Concluído — validado em `staging` no QA manual [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) pelo Douglas e promovida para `main` em 09/11/2026 — api [#184](https://github.com/douglasjava/easy-maintenance-api/pull/184)→[#185](https://github.com/douglasjava/easy-maintenance-api/pull/185), web [#136](https://github.com/douglasjava/easy-maintenance-web/pull/136)→[#137](https://github.com/douglasjava/easy-maintenance-web/pull/137).
