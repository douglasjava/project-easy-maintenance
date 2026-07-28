# TASK-147 — Backend: evoluir export cross-org de CSV para Excel (.xlsx) real

## Tipo
BACKEND

## Categoria
Relatórios

## Prioridade
🟡 Médio

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — validar que o arquivo abre corretamente no Excel, com formatação nativa (moeda, data).

---

## Contexto

O Relatório Analítico existente (`GET /me/reports/maintenances/export`,
`MaintenanceExportService.exportCsvCrossOrg`) gera um CSV puro. Para uso analítico de verdade
(cálculo, tabela dinâmica), um `.xlsx` real com tipos de dado nativos (moeda, data) é mais adequado
que texto separado por vírgula.

**Decisão de escopo (Douglas, 27/07/2026)**: entregar só dado cru, uma linha por manutenção — sem
aba de totais agregados nem fórmulas prontas.

---

## Objetivo

Trocar a geração de CSV por `.xlsx` real (Apache POI), mantendo as colunas atuais e adicionando duas
novas: **Status do item** e **Qtd. de evidências anexadas**.

---

## Escopo

### 1. Nova dependência
- Adicionar Apache POI (ou equivalente) ao `pom.xml`.

### 2. Colunas
- Manter: `ID, Empresa, Item, Data da Manutenção, Tipo, Responsável, Custo (R$), Próxima Data, Norma
  Aplicável, Categoria, Registrado por`.
- Adicionar **Status do item** — reaproveita `StatusCalculator` (já usado em
  `MaintenanceService`), calculado a partir do `nextDueAt` do item no momento da exportação.
- Adicionar **Qtd. de evidências anexadas** — reaproveita
  `MaintenanceAttachmentRepository.findByMaintenanceIdIn` (batch já construído na TASK-142). **Não
  reintroduzir N+1** — uma exportação pode ter até 5000 linhas.

### 3. Formatação nativa
- Coluna de custo como número/moeda (não string formatada), coluna de data como data real (não
  string) — para permitir cálculo direto no Excel sem conversão manual do usuário.
- Cabeçalho congelado (freeze pane) na primeira linha.

### 4. Endpoint
- Mesmo endpoint (`GET /me/reports/maintenances/export`), mudando `Content-Type` para
  `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` e extensão do arquivo pra
  `.xlsx`.

### 5. Testes
- Testes novos cobrindo: colunas novas presentes e corretas, sem N+1 na resolução de anexos (mesmo
  padrão de verificação usado em `MaintenanceAttachmentAuthorTest`, TASK-142), regressão das colunas
  existentes.

---

## Critérios de Aceite

- [x] Arquivo gerado é `.xlsx` válido, abre corretamente no Excel
- [x] Todas as colunas atuais preservadas, mais "Status do item" e "Qtd. de evidências anexadas"
- [x] Custo e datas como tipos nativos, não texto formatado
- [x] Sem N+1 na resolução de anexos/status em lote de 5000 linhas
- [x] Testes automatizados cobrindo o cenário acima

## Dependências
Nenhuma — pode começar em paralelo com TASK-145/146.

## Riscos
Apache POI em memória para até 5000 linhas — verificar uso de `SXSSFWorkbook` (streaming) em vez de
`XSSFWorkbook` se o volume se mostrar pesado o suficiente para gerar pressão de memória perceptível.
Não trocado nesta task (5000 linhas em `XSSFWorkbook` não é volume alto o bastante pra justificar a
complexidade extra do streaming agora) — fica como otimização futura se o QA manual apontar lentidão.

## Esforço
Médio (nova dependência + reescrita da geração do arquivo + 2 colunas novas com reaproveitamento de
lógica existente)

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(`easy-maintenance-api`). 719/719 testes backend green. QA manual aprovado. Commitado, com PR
aberto para `staging`.

## Implementação

- **Apache POI** (`poi-ooxml` 5.3.0) — só o suficiente pra `.xlsx` (SpreadsheetML); a variante `poi`
  pura só cobre o formato binário antigo `.xls`.
- **Rename deliberado**: `exportCsvCrossOrg`/`buildCsvCrossOrg` → `exportExcelCrossOrg`/
  `buildExcelCrossOrg` — um método chamado "Csv" que na verdade devolve bytes de `.xlsx` seria
  enganoso pra quem ler o código depois. Só o nome do método mudou; o endpoint HTTP
  (`GET /me/reports/maintenances/export`) continua o mesmo, só o `Content-Type`/extensão mudaram.
  Escopo isolado: o export **single-org** (`MaintenanceExportService.exportCsv`/`buildCsv`, usado
  por `MaintenancesController`) não foi tocado — continua CSV, fora do escopo desta task.
  **Reescrevi os testes existentes** (`MaintenanceExportServiceCrossOrgTest`) porque as asserções
  antigas comparavam string CSV crua — não fazem mais sentido pra um arquivo binário `.xlsx`. Novas
  asserções leem o workbook de volta via POI (`XSSFWorkbook`), célula por célula.
- **"Status do item"** reaproveita `StatusCalculator.calculate(nextDueAt)` (mesma lógica usada em
  `MaintenanceService`/frontend) — rótulos em português (Em dia/Próximo do vencimento/Vencido),
  mesmo texto usado no frontend (TASK-146), pra consistência entre os dois relatórios do épico.
- **"Qtd. de evidências anexadas"** reaproveita `findByMaintenanceIdIn` (TASK-142) — uma única query
  em lote pra todas as linhas do export, não uma por manutenção. Teste dedicado
  (`exportExcelCrossOrg_multipleRows_fetchesAttachmentsInSingleBatchQuery`) verifica isso
  explicitamente com `verify(attachmentRepository, times(1))`.
- **Tipos nativos**: `Cell.setCellValue(LocalDate)` pras datas (suportado nativamente pela API do
  POI 5.x) e valor numérico (reais, não centavos) com formato de célula `"R$ #,##0.00"` pro custo —
  nenhum dos dois é texto formatado, permitindo cálculo direto no Excel.
- Cabeçalho congelado (`createFreezePane(0, 1)`) e colunas auto-ajustadas (`autoSizeColumn`).
