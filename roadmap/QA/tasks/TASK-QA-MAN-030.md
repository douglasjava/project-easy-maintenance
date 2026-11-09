# TASK-QA-MAN-030 — QA Manual: Onda 1 da triagem de usabilidade do Samu (EPIC-031, staging → produção)

## Tipo
QA Manual: executado pelo Douglas, com reteste do Tiago no Edifício Veneza depois do deploy

## Categoria
Assistente WhatsApp (Samu) + Financeiro (modal)

## Prioridade
🔴 Crítico: valida as correções que impedem o registro de dado errado

## Tasks cobertas

| Task | O que entrega | Status |
|---|---|---|
| [TASK-400](../../tasks/TASK-400.md) | "Corrigir" troca o item; fim do ciclo "confirme antes" | Em Validação |
| [TASK-401](../../tasks/TASK-401.md) | Busca aproximada de item; fim do falso positivo de norma | Em Validação |
| [TASK-402](../../tasks/TASK-402.md) | Data nunca presumida; "hj" | Em Validação |
| [TASK-403](../../tasks/TASK-403.md) | Próxima data e regra no cartão | Em Validação |
| [TASK-404](../../tasks/TASK-404.md) | Vencimentos da semana avisam vencidos; datas com ano | Em Validação |
| [TASK-405](../../tasks/TASK-405.md) | Descrição limpa; responsável validado | Em Validação |
| [TASK-406](../../tasks/TASK-406.md) | Histórico usa a última data do item | Em Validação |
| [TASK-407](../../tasks/TASK-407.md) | Mensagem depois do botão "Registrar" abre o rascunho | Em Validação |
| [TASK-408](../../tasks/TASK-408.md) | Negrito do nome; limpeza do Gerador; WA-17 | Em Validação |
| [TASK-409](../../tasks/TASK-409.md) | Modal de lançamento sem visual destrutivo | Em Validação |

Origem: [registro do Tiago](../registro-usabilidade-producao.md) e [triagem](../triagem-usabilidade-producao-2026-11-09.md).

---

## Cenários (texto dos testes reais de 08/11)

| # | Entrada | Esperado | Task |
|---|---|---|---|
| C1 | "manutenção da caixa de gorduro ontem, emergencial, R$ 300" | Sugere "Limpeza caixa de gordura · …"; não cria Gerador | 401 |
| C2 | Cartão aberto → "o item é caixa de gordura" | Troca o item e reapresenta o cartão | 400 |
| C3 | Cartão → botão Corrigir → Item | Lista de itens; escolha volta ao cartão com os demais campos | 400 |
| C4 | "quero atualizar a manutenção do alarme de incêndio" | Pergunta a data [Hoje][Ontem][Outra]; não presume | 402 |
| C5 | "poda do jardim feita hj às 08:00, R$ 180" | Data de hoje, sem "não informada" | 402 |
| C6 | Qualquer cartão de item com periodicidade | Mostra "⏭️ Próxima: … (regra)"; após confirmar, a mesma data | 403 |
| C7 | "Vencimentos da semana" com vencidos | Sem ✅; avisa N vencidos | 404 |
| C8 | "Itens vencidos" | Datas de anos anteriores com ano | 404 |
| C9 | C4 confirmado | Descrição sem frase de intenção; responsável não é "emergencial" | 405 |
| C10 | "última manutenção dos extintores" (item só com data no cadastro) | Mostra a data informada no cadastro | 406 |
| C11 | Botão "Registrar manutenção" → "poda de jardim" | Abre o rascunho, sem resposta genérica | 407 |
| C12 | Foto sem legenda → texto | Rascunho com a foto anexada | 407 |
| C13 | "menu" / saudação | Nome do condomínio em negrito, sem asteriscos | 408 |
| C14 | Financeiro → Nova receita / Nova despesa | Modal sem triângulo vermelho; mobile ok | 409 |
| C15 | Regressão: correção "feita no dia 17/10/2026 e custou 80,00" | Aplicada como no teste 2 | 400 |

## Critério de conclusão
C1 a C15 aprovados em staging pelo Douglas e reteste do Tiago em produção depois do deploy.

## Notas para a execução (09/11/2026)
- Branches: `bugfix/onda1-usabilidade-samu` na api e no web (a partir de `staging`).
- **C1** (caixa de gorduro): espere "Achei estes itens parecidos… É algum deles?" com *Nenhum destes* — não o cartão direto.
- **C4/C5**: sem data dita, o bot pergunta [Hoje] [Ontem] [Outra data].
- **C6**: a linha "⏭️ Próxima: …" deve bater com o vencimento gravado depois de confirmar.
- **C11**: confirma também que o bean novo `AwaitingInputHandler` sobe no ambiente real (nenhum teste sobe o contexto Spring).
- Extra (TASK-403): registrar com data **anterior** à última do item mostra o aviso "Já existe manutenção mais recente".
- Extra (revisão pré-merge): "manutenção do alarme hoje" **sem valor** não pode mostrar 💰 no cartão; "paguei
  trezentos reais" pode (o valor vem da IA porque o texto fala de dinheiro).
- Depois do deploy: limpeza do Gerador pela tela (roteiro na TASK-408) e o Tiago refaz o C1 em produção.
