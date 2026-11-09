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
| [TASK-400](../../tasks/TASK-400.md) | "Corrigir" troca o item; fim do ciclo "confirme antes" | Backlog |
| [TASK-401](../../tasks/TASK-401.md) | Busca aproximada de item; fim do falso positivo de norma | Backlog |
| [TASK-402](../../tasks/TASK-402.md) | Data nunca presumida; "hj" | Backlog |
| [TASK-403](../../tasks/TASK-403.md) | Próxima data e regra no cartão | Backlog |
| [TASK-404](../../tasks/TASK-404.md) | Vencimentos da semana avisam vencidos; datas com ano | Backlog |
| [TASK-405](../../tasks/TASK-405.md) | Descrição limpa; responsável validado | Backlog |
| [TASK-406](../../tasks/TASK-406.md) | Histórico usa a última data do item | Backlog |
| [TASK-407](../../tasks/TASK-407.md) | Mensagem depois do botão "Registrar" abre o rascunho | Backlog |
| [TASK-408](../../tasks/TASK-408.md) | Negrito do nome; limpeza do Gerador; WA-17 | Backlog |
| [TASK-409](../../tasks/TASK-409.md) | Modal de lançamento sem visual destrutivo | Backlog |

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
