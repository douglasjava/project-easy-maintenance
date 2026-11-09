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
- [ ] Cartão mostra a próxima data e a regra para item regulatório, operacional e item novo
- [ ] A data mostrada no cartão é **igual** à gravada após Confirmar (teste comparando os dois caminhos)
- [ ] Item sem periodicidade (se existir) → cartão não quebra; mostra "sem periodicidade definida"
- [ ] Mensagem de "✅ Registrado!" continua com o próximo vencimento
- [ ] `mvn test` sem regressão

## Riscos
Refatorar o cálculo do `MaintenanceService.register` toca o fluxo web de registro — cobrir com os
testes existentes do serviço antes de mexer.
