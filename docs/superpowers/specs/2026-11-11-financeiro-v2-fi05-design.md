# Financeiro v2: competência, fundo, fornecedor, documento, anexo e recorrência (FI-05)

> **Status:** 🟡 RASCUNHO, aguarda a aprovação de Douglas. Origem: [TASK-446](../../../roadmap/tasks/TASK-446.md), [EPIC-044](../../../roadmap/epics/EPIC-044.md), achado FI-05 do [registro de usabilidade](../../../roadmap/QA/registro-usabilidade-producao.md).
> **Data:** 11/11/2026

## 1. Problema

O formulário de lançamento tem só categoria, valor, data e descrição. Para prestar contas, o síndico também precisa de:

- **competência**: o mês a que a conta se refere, que pode ser diferente do mês em que foi paga;
- **conta ou fundo**: ordinária, reserva ou obras;
- **fornecedor**;
- **número do documento** e **anexo**: nota, boleto ou recibo;
- **recorrência e parcelas**: a administradora, o elevador e a limpeza são redigitados todo mês.

O Tiago apontou isso na triagem de 08/11/2026.

## 2. O que já existe (ponto de partida)

| Peça | Estado |
| --- | --- |
| `financial_entries` | categoria fixa (TASK-441), `entry_date`, `maintenance_id` (TASK-442), edição auditada (TASK-443) |
| Resumo | `/summary` e `/summary/monthly` (TASK-444), pela `entry_date` |
| Fornecedor | `Supplier` + `SupplierOrganizationLink` (EPIC-028 / TASK-422): conta global vinculada à organização |
| Unidade | `condo_people.Unit` (EPIC-039) |
| Anexo | `MaintenanceAttachment` (url, nome, tipo, tamanho): mesmo storage, outra tabela |
| Categoria `FUNDO_RESERVA` | hoje é uma **categoria de despesa** (transferência para o fundo) |
| Clonar | TASK-443: já resolve parte da dor das contas mensais |

## 3. Proposta

### 3.1 Competência × data de pagamento
- Novo campo `competence` (`YYYY-MM`), obrigatório na criação. O padrão é o mês da `entry_date`.
- A `entry_date` continua sendo a **data do pagamento ou recebimento** e entra no fluxo de caixa.
- A visão mensal (TASK-444) ganha a escolha **"Agrupar por: pagamento | competência"**. O padrão é pagamento, que é o comportamento de hoje.
- **Migração:** `competence = YYYY-MM(entry_date)` para todos os lançamentos existentes.

### 3.2 Conta ou fundo
- Novo campo `fund`, um enum fixo: `ORDINARIA` (padrão), `RESERVA` e `OBRAS`. O enum segue a mesma decisão da TASK-441: lista fixa e curada, sem configuração por condomínio.
- Cada fundo tem seu saldo no resumo. O total do condomínio é a soma dos fundos.
- **Transferência entre fundos:** um par de lançamentos ligados, saída num fundo e entrada no outro, que não altera o total. Isso substitui o uso da categoria `FUNDO_RESERVA` como despesa.
- **Migração:** a despesa `FUNDO_RESERVA` existente continua como está, no fundo `ORDINARIA`. A categoria deixa de aparecer para novos lançamentos.

### 3.3 Fornecedor e unidade
- `supplier_id`, opcional, só em **despesa**. Lista os fornecedores vinculados à organização, os mesmos do cadastro e do Samu (TASK-437).
- `unit_id`, opcional, só em **receita**: taxa, multa ou aluguel de uma unidade. Isso prepara a inadimplência, que fica fora deste escopo.
- O filtro da lista (TASK-445) ganha **fornecedor**.

### 3.4 Documento e anexo
- `document_number`, opcional, até 60 caracteres: nº da NF, do boleto ou do recibo.
- Anexos: uma nova tabela `financial_entry_attachments`, no mesmo formato e storage de `maintenance_attachments`.
  - PDF ou imagem, até 10 MB, no máximo 5 por lançamento.
- O PDF de prestação de contas (`PrestacaoContasPdfDocument`) lista o nº do documento e indica "📎 com comprovante".
- Despesa vinda de manutenção: mostra os anexos da manutenção, sem copiá-los.

### 3.5 Recorrência e parcelas
- **Recorrente**, para contas mensais: no lançamento, "Repetir todo mês" cria uma **regra** (`financial_recurrences`) com dia, valor, categoria, fundo e fornecedor.
  - Um job diário gera o lançamento do mês como **"previsto"**, com o status novo `PLANNED`. Previsto não entra no saldo.
  - Quem tem acesso **confirma** (vira `CONFIRMED`, podendo ajustar valor e data) ou **descarta**.
  - Encerrar a regra não apaga os lançamentos que já foram confirmados.
- **Parcelado** (ex.: uma obra em 6x): gera N lançamentos `PLANNED` de uma vez, com "1/6", "2/6"... e o mesmo `installment_group_id`. Cada parcela é confirmada quando for paga.
- O status `PLANNED` aparece na lista com um selo. O resumo mostra "Previsto no mês" à parte.

## 4. Decisões para Douglas

| # | Pergunta | Proposta |
| --- | --- | --- |
| D1 | A visão mensal agrupa por pagamento ou por competência por padrão? | Pagamento (caixa), com a opção de competência |
| D2 | Os fundos são fixos (ordinária, reserva, obras) ou configuráveis por condomínio? | Fixos, como a TASK-441 |
| D3 | Saldo inicial de cada fundo? Hoje o saldo começa do zero no período. | Um campo "saldo inicial" por fundo nas configurações da organização |
| D4 | Recorrente gera "previsto para confirmar" ou lança direto? | Previsto: evita lançar valor errado sem ninguém ver |
| D5 | O Samu avisa "3 contas previstas para confirmar" no resumo do dia? | Sim, só para ADMIN e SYNDIC (depende da matriz de papéis, EPIC-042) |
| D6 | Unidade na receita entra agora ou fica para a inadimplência? | Entra agora como campo opcional; a inadimplência fica para depois |
| D7 | Anexo obrigatório acima de um valor? | Não obrigatório; só o selo "sem comprovante" |

## 5. Quebra em tasks (depois da aprovação)

| Ordem | Task | Tipo | Depende de |
| --- | --- | --- | --- |
| 1 | Competência: campo, migração, visão mensal por competência | FULL_STACK | D1 |
| 2 | Fundos: campo, saldo por fundo, transferência, saldo inicial | FULL_STACK | D2, D3 |
| 3 | Fornecedor e unidade no lançamento + filtro por fornecedor | FULL_STACK | D6 |
| 4 | Nº do documento + anexos do lançamento + PDF de prestação de contas | FULL_STACK | D7 |
| 5 | Parcelas (`installment_group_id`, status `PLANNED`, confirmar) | FULL_STACK | 4 |
| 6 | Recorrência (regra, job diário, confirmar e descartar) | FULL_STACK | 5, D4 |
| 7 | Samu: aviso de previstos + confirmar pelo chat | BACKEND | 6, D5, EPIC-042 |
| 8 | QA do Financeiro v2 | QA | todas |

## 6. Riscos
- **Status `PLANNED`:** todas as somas precisam filtrar `CONFIRMED`: `/summary`, `/summary/monthly`, prestação de contas e o KPI do dashboard. É o maior risco de regressão. A proposta é cobrir cada uma com um teste antes de ligar a recorrência.
- **Fundos:** a transferência não pode inflar receita nem despesa no total do condomínio.
- **Anexos:** usar o mesmo controle de tenant e tamanho dos anexos de manutenção, e a URL não pode ser pública.
- **Retrocompatibilidade:** todos os campos novos são opcionais ou têm padrão. Os clientes atuais da API (web, Samu e PDF) continuam funcionando sem mudança.
