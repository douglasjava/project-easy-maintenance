# EPIC-043 — Samu conversacional (Parte B do Tiago)

## Status
⬜ Backlog — criado em 10/11/2026.

## Objetivo
Inverter o Samu de "menu com portão" para conversa: qualquer mensagem abre, o bot mostra o que precisa antes de pedir, calcula o que já sabe e só pergunta o que falta.

## Descrição
Fonte: [Parte B do registro de usabilidade](../QA/registro-usabilidade-producao.md) e [triagem](../QA/triagem-usabilidade-producao-2026-11-09.md), seção 4 (os 7 conflitos com a matriz
fechados em 10/11/2026). Os passos de correção de dado (Corrigir, item obrigatório, data nunca presumida, cartão com a
próxima data) já foram entregues na Onda 1 (TASK-400 a 409). **Começa depois** das TASK-414, 415 e 417 do EPIC-042.

Tasks que já existem e entram neste fluxo: [TASK-410](../tasks/TASK-410.md) (prompt do classificador, retomada aqui),
[TASK-339](../tasks/TASK-339.md) (evidência), [TASK-340](../tasks/TASK-340.md) (vencidos com ação "Já foi feita"),
[TASK-345](../tasks/TASK-345.md)/[TASK-347](../tasks/TASK-347.md)/[TASK-349](../tasks/TASK-349.md) (leitura de documento e
foto da etiqueta), [TASK-346](../tasks/TASK-346.md) (fornecedor habitual), [TASK-311](../tasks/TASK-311.md) e
[TASK-343](../tasks/TASK-343.md) (métricas 5.7).

## Tasks
| ID | Título | Tipo | Prioridade | Depende de |
|---|---|---|---|---|
| [TASK-431](../tasks/TASK-431.md) | Entrada sem portão + painel por papel | BACKEND | 🟠 | 415, 417 |
| [TASK-432](../tasks/TASK-432.md) | Contexto curto 30 min + comandos globais | BACKEND | 🟠 | 417 |
| [TASK-410](../tasks/TASK-410.md) | Prompt do classificador (retomada) | BACKEND | 🟡 | 432 |
| [TASK-433](../tasks/TASK-433.md) | Chamados pela equipe (abrir, SLA, ações) | FULL_STACK | 🟠 | 414, 415 |
| [TASK-434](../tasks/TASK-434.md) | Registro com modelo + anexo depois do registro | BACKEND | 🟡 | — |
| [TASK-435](../tasks/TASK-435.md) | Foi feita ou remarcar + alterar vencimento | FULL_STACK | 🟠 | 414 |
| [TASK-436](../tasks/TASK-436.md) | Item novo completo pelo chat | BACKEND | 🟡 | 414, 346 |
| [TASK-437](../tasks/TASK-437.md) | Fornecedor pelo chat + habitual | BACKEND | 🟡 | 346, 422 |
| [TASK-438](../tasks/TASK-438.md) | Anexo sem contexto | BACKEND | 🟡 | 432, 345 |
| [TASK-439](../tasks/TASK-439.md) | QA do EPIC-043 (casos 5.6) | QA | 🟠 | todas |

## Critério de Conclusão do Épico
- Todos os casos da seção 5.6 do Tiago passando (avaliação automática + QA manual).
- Taxa de resposta genérica abaixo de 5% das mensagens (métrica 5.7).

## Fora de Escopo
- Cadastro de Locais (épico próprio, a criar; pedir ao Tiago o documento de 04/11).
- Financeiro pelo chat além do que a TASK-442 cobre.

## Riscos
- Prompt maior aumenta o custo por mensagem: medir com o runner da TASK-411.
- Contexto curto aplicado à pergunta errada.
