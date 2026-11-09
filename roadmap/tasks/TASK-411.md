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
- [ ] ≥ 60 casos versionados, sem dado pessoal real
- [ ] Runner isolado do `mvn test` padrão (não chama a OpenAI no CI)
- [ ] Relatório com acerto por intenção, por campo, taxa de campo inventado e tokens médios
- [ ] Linha de base do prompt atual registrada nesta task

## Dependências
Nenhuma. Bloqueia a [TASK-410](TASK-410.md).

## Riscos
Custo de crédito a cada execução (estimar antes: casos × tokens médios). Casos muito parecidos com os
exemplos do prompt inflam o acerto — manter um subconjunto "cego" que nunca vira exemplo.
