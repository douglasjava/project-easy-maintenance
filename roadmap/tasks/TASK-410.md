# TASK-410 — MELHORIA: endurecer o prompt do classificador de intenções do Samu (EPIC-031)

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / IA

## Prioridade
🟡 Médio — a Onda 1 já blindou o dado (campos da IA só valem com pista no texto); falta a classificação errar menos.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · registrado na revisão da Onda 1
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md))

## QA obrigatório
Sim — mudança de prompt muda o comportamento de todo texto livre. **Depende da [TASK-411](TASK-411.md)**: sem o
conjunto de avaliação não há como provar que o prompt novo é melhor que o atual.

---

## Contexto
`AiIntentClassifier.SYSTEM_PROMPT` (modelo `gpt-4o-mini`, via `openAiAiProvider`) só lista as intenções e os
campos permitidos. Não tem exemplos, não fixa `temperature` (fica o padrão do modelo) e não diz para **não
inventar** campos. Em produção (08/11/2026, manutenção 19) a IA devolveu `item = "gerador"` e
`responsavel = "emergencial"` para um texto sobre caixa de gordura que não tinha nenhuma das duas palavras.

O que a Onda 1 já fez (não refazer aqui): todo campo da IA — item, data, responsável, valor e tipo — só é usado
se o texto der pista dele (`groundedInText`, `mentionsWhen`, `mentionsMoney`, `mentionsKind`), e o texto sempre
vence o campo. A resposta ao "me conte o que foi feito" nem passa pela IA (TASK-407).

## Achado da TASK-411 (09/11/2026)
O classificador roda com **`temperature(1.0)`** — fixado em `AiConfig.customOpenAiChatModel`, o mesmo bean do
`openAiAiProvider` usado por outros fluxos de IA (onboarding etc.). Baixar a temperatura **só do classificador** exige
um `ChatModel`/opção própria para ele, sem mudar os demais. Comparar com `-DaiEval.temperature=0` no runner da 411
antes de decidir.

## Escopo
- `temperature = 0` (ou o mínimo suportado) na chamada do classificador — sem afetar os outros usos do
  `openAiAiProvider` (IA Onboarding etc.).
- Instrução explícita: "inclua em `fields` só o que está escrito na mensagem; nunca deduza item, valor,
  responsável ou data que não foram ditos".
- 6 a 10 exemplos curtos (few-shot) cobrindo os casos que erraram em produção: registro com erro de
  digitação, "quero atualizar a manutenção de X", "poda de jardim" sozinho, pergunta sobre anexar foto,
  "e para a caixa de gordura?", lançamento financeiro.
- Medir antes/depois com o conjunto da TASK-411 e manter só se melhorar sem subir o custo por mensagem
  de forma relevante (registrar tokens médios antes/depois).

## Fora de escopo
- Novas intenções (alterar vencimento, chamados, anexo) e contexto de conversa — Parte B
  ([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 4).
- Trocar de modelo/provedor.

## Critérios de Aceite
- [ ] Prompt novo com instrução de não inventar campos e exemplos
- [ ] `temperature` fixada só no classificador do assistente
- [ ] Conjunto da TASK-411 rodado antes e depois; acerto de intenção e de campos não piora em nenhuma categoria
- [ ] Custo médio de tokens por classificação registrado (antes/depois) na task
- [ ] `mvn test` sem regressão

## Dependências
[TASK-411](TASK-411.md).

## Riscos
Prompt maior = mais tokens por mensagem (crédito de IA do condomínio). Exemplos demais podem enviesar a
classificação para os casos de exemplo.
