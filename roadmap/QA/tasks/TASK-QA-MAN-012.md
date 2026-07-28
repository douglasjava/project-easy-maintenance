# TASK-QA-MAN-012 — QA Manual: E2E dos dois relatórios (EPIC-017)

## Tipo
QA Manual

## Categoria
Backend + Frontend / Relatórios

## Prioridade
🟠 Alto

## Épico
[EPIC-017](../../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## Tasks cobertas
[TASK-145](../../tasks/TASK-145.md) (canceladas por organização/período)
· [TASK-146](../../tasks/TASK-146.md) (PDF de prestação de contas)
· [TASK-147](../../tasks/TASK-147.md) (Excel analítico)
· [TASK-148](../../tasks/TASK-148.md) (UI do Excel)

---

## Descrição

Validação end-to-end dos dois relatórios novos: o PDF de prestação de contas (uma organização, 4
seções) e a evolução do Excel analítico (cross-org, dado cru). O ponto crítico do PDF é que ele
**conta a história certa do período** — números batendo com o que realmente aconteceu, canceladas
isoladas numa seção própria. O ponto crítico do Excel é que os dados batem e o arquivo é um `.xlsx`
de verdade, não um CSV disfarçado.

---

## Pré-condições

- Ambiente: staging (`{BASE_URL}`)
- Uma organização de teste (`{ORG_CODE}`) com: pelo menos 2 manutenções realizadas no período, pelo
  menos 1 cancelada no período, pelo menos 1 item vencido/próximo do vencimento
- Plano da organização com `reportsEnabled = true`
- Uma segunda organização (ou plano) com `reportsEnabled = false`, para validar o gate

---

## Cenários de Teste

### C1 — Gerar PDF de prestação de contas com dados completos

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Escolher a organização de teste e um período que cubra os dados de pré-condição | Preview mostra as 4 seções |
| 2 | Conferir o resumo do período (Seção 1) | Totais batem com os dados reais do período |
| 3 | Conferir a lista de manutenções realizadas (Seção 2) | Todas as manutenções válidas do período aparecem, nenhuma cancelada misturada |
| 4 | Conferir a seção de canceladas/auditoria (Seção 3) | A manutenção cancelada aparece, com motivo/autor/data |
| 5 | Conferir itens pendentes/vencidos (Seção 4) | Item vencido/próximo do vencimento aparece |
| 6 | Baixar o PDF | Arquivo `.pdf` válido, abre normalmente, conteúdo bate com o preview |

---

### C2 — Período sem nenhum dado

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Escolher um período sem nenhuma manutenção/cancelamento/pendência | Preview mostra estados vazios claros em cada seção, sem erro |

---

### C3 — Gate de plano (`reportsEnabled`)

**Correção (Douglas, 28/07/2026)**: passo 1 original bloqueava a ação dentro da tela; decisão foi
mais coerente esconder o menu inteiro (TASK-150), não dar margem ao usuário de entrar numa área que
ele não pode usar.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Estar numa organização sem `reportsEnabled` | Menu "Relatórios" (Sidebar e dropdown do usuário) não aparece |
| 2 | Trocar para uma organização com `reportsEnabled` | Menu "Relatórios" volta a aparecer |

---

### C4 — Isolamento multi-tenant

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Gerar o PDF da organização de teste | Nenhum dado de outra organização do usuário aparece |

---

### C5 — Excel analítico: colunas novas e formatação

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Exportar o Relatório Analítico (cross-org) | Arquivo `.xlsx` válido, abre no Excel |
| 2 | Conferir colunas novas | "Status do item" e "Qtd. de evidências anexadas" presentes e corretas |
| 3 | Conferir tipos de dado | Custo e datas como números/datas nativos, não texto |
| 4 | Conferir que não há canceladas no arquivo | Nenhuma manutenção cancelada aparece |

---

## Critérios de Aceite da Suite

- [x] C1: PDF completo gerado com dados corretos nas 4 seções
- [x] C2: período vazio tratado sem erro
- [x] C3: menu "Relatórios" não aparece sem `reportsEnabled`, volta a aparecer quando o plano permite
- [x] C4: isolamento multi-tenant confirmado
- [x] C5: Excel com colunas novas, tipos nativos, sem canceladas

---

## Status
**Aprovado — 28/07/2026.** Todos os 5 cenários (C1-C5) validados por Douglas na branch
`feature/EPIC-017-reports-accountability-analytics`, incluindo 2 achados incorporados no processo
(TASK-149: seletor de organização inline; TASK-150: ocultar o menu "Relatórios" por completo em vez
de só bloquear o botão, C3 corrigido pra refletir isso). Fecha o EPIC-017.
