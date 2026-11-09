# TASK-405 — BUGFIX: descrição do registro é o texto cru/intenção e "responsável" recebe palavras soltas (EPIC-031)

## Tipo
BUGFIX — BACKEND

## Categoria
Assistente WhatsApp (Samu) / Registro de manutenção

## Prioridade
🟡 Médio — dado de baixa qualidade no histórico e na prestação de contas.

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · Onda 1 da triagem de usabilidade
([triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), itens **WA-03**, **WA-14**)

## QA obrigatório
Sim — coberto pelo [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md).

---

## Contexto
- WA-03: responsável = "emergencial"; descrição = texto cru e cortado.
- WA-14: descrição = "quer atualizar a manutenção do alarme de incendio" (frase de intenção), mantida
  depois da correção.

## Causa (verificada no código)
- `start`: `description = text` (mensagem inteira, até 1000 caracteres); o cartão corta em 120.
- `who = fields.get("responsavel")` (campo extraído pela IA) sem validação; "emergencial" é tipo de
  manutenção, não pessoa/empresa.

## Escopo
- **Descrição:** usar o campo de descrição extraído pela IA quando vier (ajustar o prompt do
  `AiIntentClassifier` para extrair "o que foi feito" sem a intenção — "quero registrar/atualizar…").
  Sem campo, limpar a mensagem: remover frases de intenção conhecidas, data/valor/responsável já
  extraídos. Resultado vazio → usar o nome do item + tipo ("Limpeza caixa de gordura — emergencial").
- Correção em texto livre que não seja campo conhecido pode ser "o que foi feito" — aceitar
  "descrição: …" / "o que foi feito: …" para trocar a descrição.
- **Responsável:** confirmado em produção que `performed_by = "emergencial"` veio do campo `responsavel`
  da IA (o texto não tem "feito por…"). Aplicar a mesma checagem da TASK-401 (`groundedInText`: o valor
  precisa aparecer no texto) e descartar valores que são tipo de manutenção, data, valor ou palavra solta de
  1 token genérico; aceitar nome de empresa/pessoa.
- A hora dita ("às 09:00") permanece na descrição (decisão da [TASK-402](TASK-402.md)).

## Fora de escopo
- Vincular responsável a um `Supplier` cadastrado — pela spec da matriz de papéis (D8) o fornecedor
  responsável fica **na manutenção** e vem com a task "vínculo manutenção ↔ fornecedor"; não antecipar aqui.

## Critérios de Aceite
- [x] Texto do teste 1 → responsável vazio (não "emergencial"), descrição sem a frase de intenção
- [x] "quero atualizar a manutenção do alarme de incêndio" → descrição não é a frase de intenção
- [x] "feito pela Fire Safe" continua preenchendo o responsável
- [x] "descrição: troca de detectores do 3º andar" no cartão → descrição trocada
- [x] `mvn test` sem regressão — 1796/1796 (6 testes de registro + 3 do parser)

## Riscos
Mudança de prompt da IA: rodar o conjunto de frases dos testes existentes do classificador; custo de
crédito por mensagem não deve subir (mesma chamada, só campos).

## Implementação (09/11/2026)
- **Responsável:** `RegistrationParser.validResponsible` recusa tipo de manutenção, data, valor e palavras
  genéricas ("emergencial", "hoje", "eu"…), venha da IA, do texto ou da correção. O campo `responsavel` da IA
  ainda passa por `groundedInText` (TASK-401): precisa aparecer no texto.
- **Descrição:** `RegistrationParser.cleanDescription` tira a frase de intenção ("quero atualizar a manutenção
  do…"), o valor e o "feito por…"; data e hora ditas ficam (hora sem campo próprio, TASK-402). Se sobrar
  nada ou só o nome do item, o cartão **e o registro** usam "Preventiva — Alarme de incêndio".
- **Correção:** "descrição: …" (ou "o que foi feito: …") no cartão troca só a descrição — datas/valores dentro
  dela não viram correção. O Corrigir ganhou o campo "Descrição".

## Desvio do escopo original (decisão)
**Não** mexi no prompt da IA para extrair a descrição. Motivos: (1) em produção a IA inventou `item` e
`responsavel` na mesma mensagem — mais um campo dela é mais um ponto de alucinação; (2) desde a TASK-407 a
resposta ao "me conte o que foi feito" nem passa pela IA. A limpeza determinística cobre os dois caminhos e
não muda o custo de crédito.

## Branch
`bugfix/onda1-usabilidade-samu` (`easy-maintenance-api`), commit `3fd949b`.

## Status
✅ Concluído — validado em `staging` no QA manual [TASK-QA-MAN-030](../QA/tasks/TASK-QA-MAN-030.md) pelo Douglas e promovida para `main` em 09/11/2026 — api [#184](https://github.com/douglasjava/easy-maintenance-api/pull/184)→[#185](https://github.com/douglasjava/easy-maintenance-api/pull/185), web [#136](https://github.com/douglasjava/easy-maintenance-web/pull/136)→[#137](https://github.com/douglasjava/easy-maintenance-web/pull/137).
