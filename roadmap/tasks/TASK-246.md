# TASK-246 — BACKEND: Índice de conformidade + endpoint `GET /dashboard/summary`

## Tipo
BACKEND

## Categoria
Dashboard / Compliance

## Prioridade
🔴 Crítico

## Épico
[EPIC-030](../epics/EPIC-030.md) — Compliance Dashboard

## QA obrigatório
Sim — casos de borda da fórmula (zero itens elegíveis, item nunca vencido, item vencido com
evidência, item em dia sem evidência, documento vinculado vencido) + confirmar isolamento
multi-tenant no escopo `PORTFOLIO`.

---

## Contexto

Renumerada de TASK-130 do documento original (protótipo "Painel de Conformidade", ver
[EPIC-030](../epics/EPIC-030.md)). **Não é greenfield**: já existe `GET /easy-maintenance/api/v1/dashboard`
(`DashboardController`/`DashboardService`/`DashboardResponse`), consumido hoje por `src/app/page.tsx`
no frontend, com um `complianceScore` **simplificado** (`Kpis.complianceScore` =
`okCount / itemsTotal` — não é a fórmula proposta abaixo, não considera evidência nem documento).

## Escopo

- `ComplianceIndexService` implementando a fórmula:
  ```
  eligible  = itens ativos com periodicidade definida
  compliant = eligible AND status != OVERDUE
                       AND (nunca venceu OR última manutenção tem >=1 evidência)
                       AND todo documento obrigatório vinculado está válido
  index     = round(compliant / eligible * 100), 0 quando eligible == 0
  ```
- Novo `GET /easy-maintenance/api/v1/dashboard/summary` — params `companyCode` (opcional, omitir =
  todas as organizações que o usuário acessa; renomeado de `companyId` do documento original, ver
  Decisões tomadas durante a implementação), `from`, `to` (ISO, default últimos 12 meses),
  `category` (opcional — não implementado nesta task, entra junto da TASK-247/taxonomia de
  categoria).
- Campo `state` (`ONBOARDING`/`OPERATING`/`PORTFOLIO`) calculado no backend — frontend nunca
  re-deriva.
- `previousComplianceIndex` — ver Viabilidade Técnica, depende da decisão #6 do épico.
- Sparklines de KPI — últimos 6 meses, mesmo bloqueio de histórico.

## Critérios de Aceite

- [x] Isolamento multi-tenant garantido em nível de repositório; um usuário nunca lê número de
      outro tenant
- [x] `state` calculado no backend conforme a tabela do §2 do documento original
- [x] Sparklines sempre com exatamente 6 entradas (zero-fill), mais antigo primeiro
- [x] Agregados calculados em SQL, não carregando entidades em memória
- [x] Testes unitários cobrindo: zero itens elegíveis, item nunca vencido, vencido com evidência,
      em dia sem evidência, documento vinculado vencido
- [x] Decisão registrada (não silenciosa) sobre snapshot histórico antes de implementar
      `previousComplianceIndex`/sparklines reais

## Viabilidade Técnica

**Reaproveitável direto:**
- `MaintenanceAttachment` (`assets/domain/MaintenanceAttachment.java` +
  `MaintenanceAttachmentRepository`) já cobre a parte (b) da fórmula (evidência de manutenção) —
  não precisa de entidade nova.
- `DashboardService` já usa Caffeine (`com.github.benmanes.caffeine.cache.Cache`) — padrão pronto
  pra reaproveitar se o cache virar necessidade aqui também (a TASK-247 é quem pede cache
  explicitamente).
- Padrão de agregação SQL sem carregar entidades já existe em outros módulos (ex.
  `BillingAccountRepository.findPayersSummary`) — não é um requisito novo pro projeto.

**Não existe e precisa ser criado (achado, não estava no documento original):**
- **Entidade de documento/laudo com validade.** Não existe `Document`/`Laudo` em lugar nenhum do
  schema (`grep -ri document` só encontra `DocumentValidator`, um validador de CPF/CNPJ, sem
  relação). A parte (c) da fórmula ("todo documento obrigatório vinculado ao item está válido")
  não tem onde buscar dado — precisa de uma sub-task própria (migration + entidade + repositório)
  **antes** desta task poder implementar a fórmula completa. Proposta: `ItemDocument` (itemId,
  type, issuedAt, validUntil, fileUrl opcional), sem isso a fórmula fica só com (a)+(b).
- **"Elegível" (periodicidade definida) vem de duas fontes diferentes**: itens `OPERACIONAL` usam
  `MaintenanceItem.customPeriodUnit/customPeriodQty` (colunas do próprio item); itens `REGULATORY`
  herdam de `Norm.periodUnit/periodQty` via `MaintenanceItem.normId` →
  `catalog_norms.domain.Norm`. A query real precisa de `LEFT JOIN` + `COALESCE`, não é um filtro
  de coluna única.
- **`previousComplianceIndex`/sparklines de 6 meses não têm de onde vir.** Nada no sistema grava
  snapshot periódico do estado de conformidade — `MaintenanceItem`/`Maintenance` são mutáveis sem
  histórico versionado. "Recalcular como estava há 30 dias" não é possível reconstruindo do estado
  atual. **Decisão #6 (respondida 09/09/2026): começar a gravar snapshot diário já**, a partir
  desta task — histórico nasce vazio/achatado, fica útil depois de algumas semanas/meses. Escopo
  desta task passa a incluir: job diário simples gravando `(organizationId, date, eligible,
  compliant, index)`.
- **Meta de conformidade (`targetIndex`)**: **decisão #5 (respondida): 95% fixo em código na v1,
  sem configuração por tenant** — não existe hoje tela de configurações de organização que peça
  esse ajuste; criar coluna/tabela pra uma config sem UI real é over-engineering agora. Simplifica
  esta task (constante, não campo de banco).

**Requer cuidado extra (não é "achado que falta", é "existe mas precisa atenção"):**
- Escopo `PORTFOLIO` (agregação cross-organização) exige `TenantContext.runCrossOrg(...)`
  explicitamente em cada query nova — o filtro Hibernate `tenantFilter`
  (`TenantFilterAspect`) só cobre `MaintenanceItemRepository`, escopado a uma única organização
  por requisição. Esquecer isso numa query nova é o mesmo tipo de bug já documentado no comentário
  de `TenantContext.runCrossOrg` (pool totals colapsando pra uma organização só). Tratar como
  revisão de segurança dedicada antes do merge, não só teste funcional.
- O endpoint `GET /dashboard` existente continua no ar e é consumido pelo `src/app/page.tsx`
  atual — este endpoint novo (`/dashboard/summary`) coexiste até a TASK-249 migrar o frontend;
  decidir explicitamente quando `/dashboard` (antigo) é removido, pra não manter dois caminhos de
  verdade divergentes por muito tempo.

## Dependências
Nenhuma — decisões #1/#5/#6/#7 do EPIC-030 já respondidas (09/09/2026). Entidade de documento
(achado técnico, não uma das 7 decisões) segue como sub-escopo próprio desta task antes da fórmula
completa poder rodar com a parte (c).

## Riscos
Alto — não pelo código em si (a agregação SQL é rotina), mas porque duas das três partes da fórmula
(evidência ✅, documento ❌, elegibilidade por periodicidade ⚠️ dupla fonte) e o próprio
`previousComplianceIndex` dependem de peças que não existem ainda. Risco de sub-estimar o esforço
real se a entidade de documento e o job de snapshot não forem tratados como sub-escopos próprios.

## Esforço
Grande — reclassificado a partir da estimativa implícita do documento original (que assumia
`ComplianceIndexService` como o único trabalho). Estimativa real inclui: entidade de documento
(migration+CRUD mínimo), decisão + implementação do snapshot, dicionário de categoria, e só então
a fórmula/endpoint em si.

## Implementação

### Arquivos criados

| Arquivo | Descrição |
|---|---|
| `db/migration/V110__create_item_documents_and_compliance_snapshots.sql` | tabelas `item_documents` (laudo/documento vinculado ao item, com `valid_until`) e `compliance_snapshots` (snapshot diário por organização, unique `(organization_code, snapshot_date)`) |
| `assets/domain/ItemDocument.java` + `assets/infrastructure/persistence/ItemDocumentRepository.java` | entidade + repositório mínimo (sem CRUD/endpoint ainda — fica pra quando a TASK-251 precisar de verdade) |
| `dashboard/domain/ComplianceSnapshot.java` + `dashboard/infrastructure/persistence/ComplianceSnapshotRepository.java` | snapshot diário — busca exata por data, por intervalo, e "mais próximo anterior ou igual" (usado pra `previousComplianceIndex`) |
| `dashboard/infrastructure/persistence/ComplianceMetricsRepository.java` + `ComplianceCountsProjection.java` | a fórmula em si — query nativa com CTE + `ROW_NUMBER()` pra achar a última manutenção de cada item, sem carregar entidade nenhuma em memória |
| `dashboard/application/ComplianceIndexService.java` | `computeCounts` (uma organização) / `computePortfolioCounts` (soma eligible/compliant entre organizações, nunca média — EPIC-030 §3). Meta fixa em `DEFAULT_TARGET_INDEX = 95` (decisão #5) |
| `dashboard/application/DashboardSummaryService.java` | orquestra tudo: resolve organizações do usuário autenticado, decide `scope`/`state`, monta a resposta com KPIs + sparklines |
| `dashboard/infrastructure/web/dto/DashboardSummaryResponse.java` | DTO da resposta |
| `jobs/service/ComplianceSnapshotService.java` + `jobs/ComplianceSnapshotJob.java` | job diário (decisão #6), mesmo padrão dos outros jobs (`@SchedulerLock`, isolamento de falha por organização, `JobHealthReporter`) |
| `test/.../ComplianceMetricsRepositoryTest.java` | 6 testes com H2 real cobrindo os 5 casos de borda exigidos + 1 caso positivo (documento válido) |
| `test/.../DashboardSummaryServiceTest.java` | 7 testes: sem organização, ONBOARDING por poucos itens, OPERATING, PORTFOLIO (soma não é média), `companyCode` restringe mesmo com múltiplas orgs, `companyCode` de organização alheia lança `NotFoundException`, `previousComplianceIndex` null sem snapshot |
| `test/.../ComplianceSnapshotServiceTest.java` | 3 testes: cria snapshot novo, atualiza snapshot existente do mesmo dia (idempotência), isolamento de falha entre organizações |

### Arquivos modificados
| Arquivo | Operação |
|---|---|
| `assets/infrastructure/persistence/MaintenanceRepository.java` | novos métodos `countByOrgsInAndPerformedBetween`/`sumCostCentsByOrgsInAndPerformedBetween` (variantes cross-org dos já existentes, pro escopo `PORTFOLIO`) |
| `org_users/infrastructure/persistence/OrganizationRepository.java` | novo método `findAllCodes()` (usado pelo job, que roda em contexto de sistema, não de um usuário específico) |
| `dashboard/infrastructure/web/DashboardController.java` | novo `GET /dashboard/summary`, endpoint antigo (`GET /dashboard`) intocado |

### Decisões tomadas durante a implementação
- **`companyId` do documento original virou `companyCode`** — o resto do sistema identifica
  organização por `code` (UUID), não por `id` numérico (é o que `X-Org-Id`/`TenantContext` já usam
  em todo o resto da API, e o que o frontend já guarda em `localStorage`). Usar `companyId`
  introduziria um segundo identificador só pra este endpoint, exigindo tradução id↔code sem
  necessidade real.
- **`/dashboard/summary` não usa `X-Org-Id`/`@RequireTenant`** — resolve as organizações do
  usuário autenticado direto via `OrganizationRepository.findAllByUserId`, porque o escopo
  `PORTFOLIO` precisa olhar mais de uma organização na mesma chamada, o que o header de tenant
  único por requisição não suporta. `companyCode` (quando informado) é validado contra as
  organizações do usuário antes de qualquer query — 404 genérico se não pertencer a ele, nunca
  revela se o código existe.
- **`TenantContext.runCrossOrg` em toda chamada a `MaintenanceItemRepository`** (a única
  interceptada por `TenantFilterAspect`) — seguro porque a validação de posse já aconteceu antes.
  `ComplianceMetricsRepository`/`MaintenanceRepository` não precisam disso: filtram
  `organization_code` explicitamente na própria query (nativa ou JPQL), mesmo padrão já usado
  nas outras queries nativas do projeto.
- **`monthlyCost` não depende do snapshot** — `Maintenance.costCents`/`performedAt` já são
  histórico real e imutável, diferente de `overdue`/`dueIn30Days` (estado mutável do item). Só os
  dois últimos ficam com `spark`/`previous` zero-fill/null enquanto o `ComplianceSnapshotJob` não
  tiver acumulado histórico de verdade.
- **Sem endpoint de CRUD pra `ItemDocument` nesta task** — só entidade + repositório mínimo (uma
  busca por item). Cadastro/upload de documento é decisão de UI que pertence à TASK-251; aqui só
  o necessário pra fórmula funcionar.
- **`from`/`to`/`category` do documento original não foram implementados como parâmetro nesta
  task** — `complianceIndex`/KPIs são sempre calculados relativos a "hoje" (índice atual, mês
  corrente, sparkline dos últimos 6 meses); um filtro de período arbitrário não se encaixa nesse
  desenho sem redefinir o que "índice atual" significa quando `to` é uma data passada. `category`
  depende da taxonomia da decisão #7 (só usada de fato pela TASK-247/`costByCategory`). Corte de
  escopo deliberado, não esquecimento — sinalizar se o Douglas quiser esses filtros nesta v1 antes
  do merge.
- **Query nativa da fórmula validada duas vezes**: `ComplianceMetricsRepositoryTest` (H2,
  `ddl-auto=create-drop`) e diretamente contra o MySQL real do docker local (CTE + `ROW_NUMBER()`
  aplicados/revertidos manualmente, mesmo cuidado da TASK-230/241 — sintaxe confirmada compatível
  com MySQL 8.0.33, resultado cruzado com uma contagem de overdue independente pra sanity check).

### Verificação
- `mvn clean test` → **965/965, 0 falhas** (949 de staging + 16 testes novos desta task).
- Migration `V110` aplicada e testada diretamente contra o MySQL real do docker local (mesmo
  cuidado da TASK-230/241), depois revertida (`DROP TABLE`) pra não conflitar com o Flyway quando
  a app rodar de verdade nesta branch.

Branch `feature/TASK-246-compliance-index-summary` (a partir de `staging`).

## Status
🟢 Implementado e testado (`mvn test` 965/965) — pronto pra QA manual/PR. Não deu pra validar o
endpoint `/dashboard/summary` num navegador/HTTP real nesta sessão (mesmo bloqueio de credencial
Firebase já documentado no EPIC-030/TASK-243 — a API local completa não sobe sem
`FIREBASE_SERVICE_ACCOUNT_JSON`).
