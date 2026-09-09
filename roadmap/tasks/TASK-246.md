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
- Novo `GET /easy-maintenance/api/v1/dashboard/summary` — params `companyId` (opcional, omitir =
  todas as organizações que o usuário acessa), `from`, `to` (ISO, default últimos 12 meses),
  `category` (opcional).
- Campo `state` (`ONBOARDING`/`OPERATING`/`PORTFOLIO`) calculado no backend — frontend nunca
  re-deriva.
- `previousComplianceIndex` — ver Viabilidade Técnica, depende da decisão #6 do épico.
- Sparklines de KPI — últimos 6 meses, mesmo bloqueio de histórico.

## Critérios de Aceite

- [ ] Isolamento multi-tenant garantido em nível de repositório; um usuário nunca lê número de
      outro tenant
- [ ] `state` calculado no backend conforme a tabela do §2 do documento original
- [ ] Sparklines sempre com exatamente 6 entradas (zero-fill), mais antigo primeiro
- [ ] Agregados calculados em SQL, não carregando entidades em memória
- [ ] Testes unitários cobrindo: zero itens elegíveis, item nunca vencido, vencido com evidência,
      em dia sem evidência, documento vinculado vencido
- [ ] Decisão registrada (não silenciosa) sobre snapshot histórico antes de implementar
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

## Status
🔴 Não iniciada — decisões resolvidas, pronta pra abrir branch.
