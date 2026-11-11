# TASK-QA-MAN-032 — QA Manual: Financeiro v2 (EPIC-044)

## Tipo
QA Manual, executado pelo Douglas (de preferência com o Tiago), em `staging`

## Categoria
Financeiro (web) e Samu (previstos)

## Prioridade
🟠 Alto: cobre o critério de QA manual da [TASK-454](../../tasks/TASK-454.md)

## Pré-requisitos
- Deploy da `staging` com as migrations **V153 a V158** aplicadas. Elas nunca rodaram num MySQL antes: conferir primeiro o log do Flyway.
- Um condomínio com: lançamentos antigos (anteriores a 11/11), pelo menos 1 manutenção com custo, 1 fornecedor vinculado e 1 unidade.
- Usuários: síndico, leitor e conselheiro (para o Samu).
- Storage S3 da staging funcionando (comprovantes).

## Tasks cobertas
TASK-443 a TASK-453 (ver o [EPIC-044](../../epics/EPIC-044.md)).

---

## Cenários

### 0. Migrações e dados antigos
| # | Ação | Esperado |
|---|---|---|
| 0.1 | Abrir `/finance` com o período de lançamentos antigos | Todos aparecem, na Ordinária, sem selo "Previsto"; a competência é o mês da data |
| 0.2 | Comparar o "Resumo por mês" com a soma manual dos lançamentos de um mês | Bate (receitas, despesas, manutenções) |
| 0.3 | Prestação de contas do mesmo período | Mesmos totais de antes do deploy |

### A. Editar, clonar, lançar e continuar, filtros (TASK-443/445)
| # | Ação | Esperado |
|---|---|---|
| A1 | Editar o valor e a categoria de um lançamento | Salva; a auditoria tem antes e depois |
| A2 | Editar uma despesa vinda de manutenção | Valor travado ("altere na manutenção"); categoria e data editáveis |
| A3 | Clonar | Formulário preenchido com a data de hoje; o original não muda |
| A4 | Nova despesa → "Salvar e lançar outro" 3 vezes | Modal continua aberto, mantendo tipo, categoria e data |
| A5 | Filtrar por categoria, buscar "luz" e filtrar por fornecedor | Combinam entre si e com o período |

### B. Visão mensal e competência (TASK-444/447)
| # | Ação | Esperado |
|---|---|---|
| B1 | Período de 3 meses | Um mês por linha, inclusive os sem movimento; o acumulado parte do "saldo antes do período" |
| B2 | Lançar a conta de outubro paga em novembro (competência outubro) | Lista mostra "ref. out/2026"; "Agrupar por: Competência" coloca em outubro |
| B3 | Período de 37 meses | Mensagem de limite no cartão; a lista continua |

### C. Fundos (TASK-448)
| # | Ação | Esperado |
|---|---|---|
| C1 | Definir o saldo inicial da Reserva (R$ 10.000 em 01/01) | O cartão mostra; o total do condomínio sobe |
| C2 | Transferir R$ 1.000 da Ordinária para a Reserva | Ordinária −1.000, Reserva +1.000, total igual; receitas e despesas do resumo **não** mudam |
| C3 | Cancelar um lado da transferência | Os dois lados somem; os saldos voltam |
| C4 | Nova despesa | "Fundo de reserva" não aparece como categoria; "Conta / fundo" aparece |

### D. Fornecedor, unidade, documento e comprovante (TASK-449/450)
| # | Ação | Esperado |
|---|---|---|
| D1 | Despesa com fornecedor e receita com unidade | Lista mostra "Fornecedor: X" / "Unidade 101" |
| D2 | Despesa com nº "NF 123" e sem anexo | "Doc. NF 123" e botão "Sem comprovante" |
| D3 | Anexar um PDF de 2 MB e uma foto | Botão vira "📎 2"; download funciona |
| D4 | Tentar anexar um .exe, um arquivo de 11 MB e o 6º arquivo | Recusados com mensagem |
| D5 | Leitor abre os comprovantes | Baixa, mas não anexa nem remove |
| D6 | Prestação de contas (tela e PDF) | Coluna "Documento" com "Nº NF 123 · com comprovante" |

### E. Parcelas e previstos (TASK-451)
| # | Ação | Esperado |
|---|---|---|
| E1 | Parcelado: despesa de R$ 1.000 em 3x a partir de hoje | 3 lançamentos "Previsto 1/3..3/3" (333,34 / 333,33 / 333,33); para ver os futuros, aumentar a data final |
| E2 | Resumo e fundos depois do E1 | Saldo **não** muda; a coluna "Previsto" mostra −1.000 distribuído nos meses |
| E3 | Confirmar a parcela 1 com R$ 340 | Passa a contar no saldo; a auditoria registra CONFIRM |
| E4 | Prestação de contas | Só os confirmados aparecem |
| E5 | Cancelar a parcela 3 | Some; as outras continuam |

### F. Recorrentes (TASK-452)
| # | Ação | Esperado |
|---|---|---|
| F1 | Despesa "Administradora" de hoje com "Repetir todo mês" | Lançamento de hoje salvo; "Recorrentes" lista a conta a partir do mês seguinte |
| F2 | Recorrente criada com mês inicial = atual (API) | O previsto do mês aparece na hora, com o selo "Recorrente" |
| F3 | Descartar o previsto do mês e rodar o job de novo (ou esperar o dia seguinte) | Não volta a ser gerado |
| F4 | Encerrar a recorrente | Some da lista; os lançamentos gerados continuam |
| F5 | Conferir o log das 03:15 (`FinancialRecurrenceJob`) | "Execução concluída: N previsto(s)" e métrica `financial_recurrence` |

### G. Samu (TASK-453)
| # | Ação | Esperado |
|---|---|---|
| G1 | Síndico manda "oi" com previstos até hoje | Painel com "💰 N conta(s) prevista(s) para confirmar" e opção [Confirmar contas] (lista de 4 opções) |
| G2 | Tocar [Confirmar contas] e escolher uma | "✅ Confirmado: R$ X …"; no web, o lançamento deixou de ser previsto |
| G3 | Conselheiro ou leitor manda "oi" | Sem a linha de previstos |
| G4 | Lançar despesa de manutenção pelo Samu | "Despesa lançada: R$ X" (sem "R$ R$") |

## Critério de aceite
Todos os cenários passam; os totais da prestação de contas batem com os do resumo mensal.
