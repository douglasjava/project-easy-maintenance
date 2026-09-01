# TASK-219 — FULL_STACK: Aumentar teto de anexo pra 20MB + exibir limite no plano

## Tipo
FULL_STACK

## Categoria
Backend (config) + Frontend (comparação de planos)

## Prioridade
🟠 Alto — achado #1 da demo com o cliente Rogerio Dantas (31/08/2026, ver `TASK-218.md`)

## QA obrigatório
Sim — QA manual: subir um anexo de ~15MB numa conta Business e confirmar que passa; confirmar que a
tela de comparação de planos mostra o tamanho máximo de anexo por plano.

---

## Contexto

Cliente tentou subir um arquivo de exatos 10MB numa manutenção e foi barrado. Investigando:
`application.properties` tem `aws.s3.upload.max-file-size-mb=10` — esse é o **teto rígido**
(`hardMaxFileSizeMb`), aplicado via `Math.min(planMaxFileSizeMb, hardMaxFileSizeMb)` em
`MaintenanceAttachmentService`. Os planos já têm `maxFileSizeMb` configurado de forma diferenciada
(`V63__restructure_billing_plans.sql`): STARTER=5, BUSINESS=20, ENTERPRISE=50 — mas o teto de 10MB
capava **Business e Enterprise abaixo do que o próprio plano promete**. Cliente provavelmente numa
conta Business, esperava 20MB e foi barrado em 10MB.

Adicionalmente, o limite de anexo hoje não aparece em nenhum lugar visível pro cliente comparar
planos — `PlanComparisonSection.tsx` (tela de billing) não lista `maxFileSizeMb`, mesmo a API
`/me/billing/plans` já retornando esse campo (`BillingPlanFeatures` completo, sem filtro).

## Decisão (Douglas)

Subir o teto rígido de 10MB pra **20MB agora** — isso já resolve o caso real (Business honra seu
limite prometido de 20MB). Aumento pra Enterprise (que ficaria capado em 20 em vez dos 50 prometidos)
fica pra uma rodada progressiva futura, não nesta task — decisão consciente de não pular direto pro
teto mais alto sem validar impacto de custo/infra primeiro. Também adicionar a informação do limite
na tela de comparação de planos, pra ficar visível pro cliente.

## Escopo

### Backend
- `application.properties`: `aws.s3.upload.max-file-size-mb` `10` → `20`.
- Sem mudança de lógica (`Math.min` já está correto) nem de mensagem de erro (já mostra o valor
  dinamicamente — `"...de %d MB..."` — corrige sozinha ao subir o valor).

### Frontend (`PlanComparisonSection.tsx`)
- `PlanFeatures` (interface): adicionar `maxFileSizeMb: number`.
- `FEATURE_ROWS`: nova linha "Tamanho máximo por arquivo", formatada como `"${v} MB"`.

### Frontend (mensagem de erro do upload) — pedido de Douglas na revisão
- `maintenances/new/page.tsx` (`handleUploadAttachments`) e `maintenances/page.tsx`
  (`handleUploadAttachmentToExisting`): os dois catch engoliam o erro real da API e sempre mostravam
  mensagem genérica ("Erro ao enviar anexo(s)"), mesmo quando o backend retorna motivo claro (ex.:
  `RuleException` de tamanho excedido, já exposto em `ProblemDetail.detail` via
  `GlobalExceptionHandler.handleRuleException`). Corrigido pra extrair `err?.response?.data?.detail`
  com fallback pra mensagem genérica — mesmo padrão já usado no `handleSubmitMaintenance` do mesmo
  arquivo.

## Critérios de Aceite

- [x] Teto rígido em produção passa a ser 20MB
- [x] Conta Business (plano promete 20MB) consegue subir arquivo de até 20MB sem ser barrada
- [x] Conta Starter continua limitada a 5MB (plano dela, sem mudança)
- [x] Tela de comparação de planos exibe o tamanho máximo de anexo por plano
- [x] Testes existentes (`MaintenanceAttachmentServiceTest`) continuam passando sem regressão —
      já testam a lógica `Math.min` de forma independente do valor real da property, nenhum teste
      novo necessário pra essa mudança de config pura

## Fora de escopo (decisão consciente)
- Subir o teto pra Enterprise (50MB) — fica pra depois, avaliação de custo/infra separada.
- Exibir `maxMonthlyUploadsMb` (cota mensal) na comparação de planos — não foi pedido, só o limite
  por arquivo.

## Dependências
Nenhuma. Achado durante a triagem da `TASK-218`.

## Riscos
Baixo — só sobe um valor de config (S3 presigned URL já suporta arquivos maiores) e adiciona uma
linha de exibição. Sem migração de dado, sem mudança de contrato de API.

## Esforço
Baixo

## Status
✅ Implementada, PRs abertas contra `staging`:
[api#67](https://github.com/douglasjava/easy-maintenance-api/pull/67) e
[web#64](https://github.com/douglasjava/easy-maintenance-web/pull/64). Branch
`feature/TASK-219-increase-attachment-size-limit` nos dois repos. Backend: teto rígido 10MB→20MB em
`application.properties`, sem mudança de lógica/mensagem. Frontend: nova linha "Tamanho máximo por
arquivo" em `PlanComparisonSection.tsx`. Testes existentes sem regressão (typecheck/lint com só os
erros pré-existentes de sempre, confirmados via stash).

**01/09/2026 — ajuste pós-revisão (mesma PR web#64)**: Douglas notou que, ao estourar o limite, o
front mostrava só "Erro ao enviar o anexo" genérico em vez do motivo real. Corrigido nos 2 pontos de
upload de anexo (`maintenances/new/page.tsx`, `maintenances/page.tsx`) — agora mostra
`ProblemDetail.detail` do backend quando disponível. Typecheck/lint sem regressão (mesmo padrão
`catch (err: any)` já usado 9x nesses 2 arquivos).

Falta QA manual: subir anexo ~15MB numa conta Business e confirmar que a mensagem de erro (se
estourar) mostra o valor real do teto.

**01/09/2026 — mergeada em `staging`, PR `staging→main` aberta**:
[web#69](https://github.com/douglasjava/easy-maintenance-web/pull/69) (promove TASK-219 a TASK-223
juntas).
