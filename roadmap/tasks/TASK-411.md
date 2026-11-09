# TASK-411 — QA/IA: conjunto de avaliação do classificador de intenções do Samu (EPIC-031)

## Tipo
BACKEND — QA de IA

## Categoria
Assistente WhatsApp (Samu) / IA

## Prioridade
🟡 Médio — pré-requisito para qualquer mudança de prompt ou de modelo ([TASK-410](TASK-410.md)).

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · registrado na revisão da Onda 1
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md))

## QA obrigatório
Sim — o próprio entregável é uma ferramenta de QA.

---

## Contexto
Os testes do `AiIntentClassifier` cobrem só a **leitura** do JSON (intenção fora da lista, campos não
permitidos, resposta inválida). Nenhum mede se o modelo acerta. Uma mudança de prompt ou de modelo hoje não tem
como ser avaliada — só no WhatsApp real, com o Tiago. A [TASK-344](TASK-344.md) (EPIC-034) prevê o mesmo para a
leitura de documentos; este é o equivalente para o texto livre.

## Escopo
- Arquivo versionado de casos (ex.: `src/test/resources/assistant/intent-eval.jsonl`): mensagem → intenção
  esperada → campos esperados (e campos que **não** podem vir).
- Fonte dos casos: transcrições dos testes do Tiago (08/11/2026,
  [registro](../QA/registro-usabilidade-producao.md)), a mensagem real da manutenção 19 e variações
  (erro de digitação, áudio transcrito, mensagens curtas, perguntas fora do escopo, tentativas de prompt
  injection). Mínimo de 60 casos, separados por intenção.
- **Sem dado pessoal**: nomes de pessoas, telefones e endereços reais trocados por fictícios.
- Runner **fora da suíte padrão** (chama a OpenAI de verdade e gasta crédito): teste marcado/perfil próprio,
  executado manualmente ou sob demanda, nunca no `mvn test` do CI.
- Relatório: acerto de intenção (total e por intenção), acerto por campo, **taxa de campo inventado**
  (campo devolvido sem estar no texto), tokens médios por caso.
- Registrar a linha de base com o prompt atual.

## Critérios de Aceite
- [x] ≥ 60 casos versionados, sem dado pessoal real — 69 casos, 28 cegos, todas as 11 intenções
- [x] Runner isolado do `mvn test` padrão (não chama a OpenAI no CI) — `@EnabledIfSystemProperty(aiEval=true)`; aparece como *skipped*
- [x] Relatório com acerto por intenção, por campo, taxa de campo inventado e tokens médios (+ subconjunto cego, campo proibido e instabilidade entre execuções)
- [ ] Linha de base do prompt atual registrada nesta task — **pendente: precisa da `OPENAI_API_KEY`** (não está no ambiente do Claude)

## Dependências
Nenhuma. Bloqueia a [TASK-410](TASK-410.md).

## Riscos
Custo de crédito a cada execução (estimar antes: casos × tokens médios). Casos muito parecidos com os
exemplos do prompt inflam o acerto — manter um subconjunto "cego" que nunca vira exemplo.

## Implementação (09/11/2026)
Branch `chore/TASK-411-classifier-eval` (`easy-maintenance-api`, a partir de `staging`), commit `0be9f31`.

- `src/test/resources/assistant/intent-eval.jsonl` — 69 casos: mensagem, intenções aceitas, campos esperados
  (`"*"` = só presença), campos **proibidos** (não podem vir) e `blind` (nunca usar como exemplo de prompt).
  Fontes: transcrições do Tiago (08/11), a manutenção 19, typos, áudio transcrito, fora do escopo e 3 tentativas de
  prompt injection. Nomes de empresas fictícios.
- `IntentClassifierEvalTest` — chama a OpenAI **igual à produção**: `OpenAiChatModel` com `gpt-4o-mini` e
  `temperature 1.0` (cópia de `AiConfig.customOpenAiChatModel`), `OpenAiAiProvider` e `AiIntentClassifier` reais
  (mesmo prompt, mesmo parse). Crédito dos condomínios **mockado** — o custo cai só na chave usada.
- `IntentEvalRunner` — pontuação: acerto de intenção (total, por categoria, subconjunto cego), acerto por campo,
  **campo inventado** pela MESMA régua que a produção usa para descartar (`groundedInText`, `mentionsWhen`,
  `mentionsMoney`, `mentionsKind`), campo proibido, tokens (total/média/máximo) e casos instáveis entre execuções.
  Relatório em `target/ai-eval/intent-eval-AAAAMMDD-HHMM.md`.
- `IntentEvalRunnerTest` (roda no CI, sem rede): valida o arquivo de casos e a pontuação com provedor falso,
  incluindo a resposta real da manutenção 19 (`item=gerador`, `responsavel=emergencial` → inventados).
- Produção: só `AssistantRegistrationService.groundedInText` virou `public`. `mvn test` 1813/1813 (1 skipped = a avaliação).

## Como rodar a linha de base
```bash
export OPENAI_API_KEY=...        # PowerShell: $env:OPENAI_API_KEY="..."
mvn test -Dtest=IntentClassifierEvalTest -DaiEval=true -DaiEval.runs=3
```
`runs=3` mede a instabilidade (com temperature 1.0 a mesma frase pode mudar de intenção). Custo estimado: 69 casos ×
~400 tokens × 3 ≈ 85 mil tokens — centavos de dólar no gpt-4o-mini. Colar aqui o resumo do relatório.

## Achado
O classificador de produção roda com **`temperature 1.0`** (`AiConfig.customOpenAiChatModel`, bean usado também por
outros fluxos via `openAiAiProvider`). Registrado na [TASK-410](TASK-410.md); a avaliação aceita `-DaiEval.temperature=0`
para comparar.

## Status
🟡 Em Execução — código pronto; falta rodar a linha de base com a chave e abrir a PR.
