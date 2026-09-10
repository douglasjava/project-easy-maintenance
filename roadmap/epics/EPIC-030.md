# EPIC-030 — Compliance Dashboard (redesenho do dashboard principal)

## Status
🟢 Decisões respondidas (09/09/2026) — pronto pra iniciar TASK-246. Protótipo/tasks recebidos
prontos de uma sessão do Claude Code rodada por Douglas com um artifact visual ("Painel de
Conformidade", 3 estados de conta), que **não tinha acesso ao código** (só aos prints/artifact). As
9 tasks foram replicadas (renumeradas TASK-130-138 → TASK-246-254, conforme a nota do próprio
documento original), cada uma ganhou uma seção **Viabilidade Técnica**, e as 7 decisões em aberto
foram respondidas (ver seção própria abaixo) — nenhuma implementação começou ainda, mas o escopo
real de cada task já está fechado o suficiente pra abrir a TASK-246.

## Objetivo
Substituir o dashboard atual (4 contadores igualmente pesados, estado vazio "Tudo em dia ✅", duas
barras de distribuição) por um painel de conformidade com 3 estados de conta (`ONBOARDING`,
`OPERATING`, `PORTFOLIO`), um índice de conformidade proprietário, horizonte de 90 dias, fila de
ações priorizada e (em `PORTFOLIO`) ranking de unidades.

## Descrição

Documento original (traduzido/resumido): o dashboard hoje não comunica o produto (a palavra
"conformidade" não aparece em lugar nenhum, apesar de ser o posicionamento central via ABNT NBR
5674), não tem dimensão de tempo (sem filtro de período, sem comparação com período anterior, sem
horizonte pra frente), e mostra o mesmo layout de conta madura pra conta recém-criada (tela vazia).

**Já existe um módulo `dashboard` completo e em produção** (`GET /easy-maintenance/api/v1/dashboard`
— ver `dashboard/`). Este épico não é greenfield: é uma reescrita profunda de um endpoint e uma tela
que já funcionam, usados hoje pelo dashboard principal (`src/app/page.tsx`). Qualquer plano de
execução precisa decidir explicitamente como migrar sem quebrar consumidores atuais do endpoint
existente, não só "adicionar campos novos".

---

## ⚠️ Resumo executivo da viabilidade (leia antes de sequenciar)

O protótipo foi desenhado só a partir de prints — os 5 pontos abaixo são lacunas reais entre o que
ele assume e o que existe hoje no código. Nenhum é bloqueador definitivo, mas cada um muda esforço
ou exige uma decisão de produto antes de codar:

1. **Não existe entidade de "Laudo/Documento"** — a parte (c) da fórmula do índice
   ("todo documento obrigatório vinculado ao item está válido") e o painel "Laudos e documentos"
   (TASK-251) pressupõem uma entidade com data de validade vinculada ao item que **não existe em
   lugar nenhum do schema atual**. Isso não é um detalhe da TASK-246 — é uma sub-feature inteira
   (migration + entidade + repositório + serviço + endpoints de cadastro/upload) que o documento
   original trata como se já existisse. Ver decisão sugerida na TASK-246.
2. **`previousComplianceIndex` e os sparklines de 6 meses pressupõem histórico que não é
   guardado hoje.** O sistema não versiona o estado de conformidade no tempo — `MaintenanceItem`,
   `Maintenance` e (quando existir) documentos são todos mutáveis, sem snapshot. "Recalcular a
   fórmula como estava há 30 dias" não é possível reconstruindo do estado atual; exige um job que
   comece a gravar snapshots periódicos **a partir de agora** (histórico vai nascer vazio/achatado
   e só fica útil depois de ~1-6 meses rodando). Decisão #6 (respondida 09/09/2026): começar a
   gravar já — reforçando aqui porque é o item de maior risco de todo o épico.
3. **Todo o resto do sistema opera com isolamento single-tenant por requisição** (header
   `X-Org-Id`, filtro Hibernate `tenantFilter` aplicado via AOP só em `MaintenanceItemRepository` —
   ver `TenantFilterAspect`). Agregação `PORTFOLIO` (somar métricas de várias organizações numa
   chamada só) precisa usar deliberadamente `TenantContext.runCrossOrg(...)` (padrão já usado em
   `OrganizationsService.getOrganizationSubscription` pro billing) em toda query nova que
   atravessa organizações — se alguma consulta esquecer isso, ou vaza dado cross-tenant ou o
   filtro do Hibernate quebra a query silenciosamente. Tratar isso como revisão de segurança, não
   como "adicionar um parâmetro `companyId` opcional".
4. **A categoria de custo do protótipo ("Incêndio", "Elétrica"...) não existe como campo — só
   `itemType` (string livre) e `ItemCategory` (só `REGULATORY`/`OPERACIONAL`, 2 valores).**
   `costByCategory` como o protótipo mostra exige um dicionário `itemType → categoria de exibição`
   novo (mesmo espírito de `SupplierCategoryKeywords`, que existe pra fornecedores mas não pra
   isso).
5. **"Elegibilidade" (item com periodicidade definida) está espalhada em duas fontes**: itens
   `OPERACIONAL` usam `MaintenanceItem.customPeriodUnit/customPeriodQty` (do próprio item);
   itens `REGULATORY` herdam de `Norm.periodUnit/periodQty` via `normId`. A fórmula do protótipo
   trata isso como um campo único — a query real precisa de `COALESCE`/join dos dois.

### O que já existe e reduz esforço real (não é tudo do zero)
- `MaintenanceAttachment` — evidência de manutenção já é uma entidade própria, cobre a parte (b)
  da fórmula do índice sem precisar de nada novo.
- `AuditLog`/`AuditService` — infraestrutura de auditoria já existe, cobre o requisito de
  "adiar gera registro de auditoria" da TASK-248 direto.
- `AiBootstrapService` (`preview`/`apply`) — é o "SAMU" que o protótipo assume: sugestão de itens
  obrigatórios por tipo de estabelecimento já existe e já está exposto (`AiBootstrapController`).
  A TASK-253 pode reaproveitar de verdade, não é suposição.
- Cache Caffeine já em uso no próprio `DashboardService` (bloco de IA, TTL 15min) — mesmo padrão
  serve pro cache de 5min pedido na TASK-247, sem introduzir dependência nova.
- `Maintenance.costCents` já existe por registro de manutenção — `monthlyCost`/`costByCategory`
  não precisam de tabela nova, só agregação SQL correta (ver ponto 4 sobre categoria de exibição).
- Frontend já tem `OnboardingChecklist.tsx` e `GuidedTour.tsx` — o estado `ONBOARDING` da TASK-253
  não é 100% greenfield; precisa decidir se substitui ou se integra com o que já existe (trial
  banner, past-due banner, blocked banner do `src/app/page.tsx` também precisam sobreviver à
  reescrita da TASK-249).

---

## Definição do Índice de Conformidade (v1) — conforme documento original, §3

```
eligible      = itens ativos com periodicidade definida
compliant     = itens elegíveis onde TUDO:
                  a) status != OVERDUE
                  b) a última manutenção concluída tem >= 1 anexo de evidência
                     (itens que nunca venceram ficam isentos dessa regra)
                  c) todo documento obrigatório vinculado ao item está válido (não vencido)
index         = round(compliant / eligible * 100)      // 0 quando eligible == 0
```

- Calculado por organização; índice de portfólio é `sum(compliant) / sum(eligible)` entre
  organizações — **não** é a média dos índices por organização.
- Timezone `America/Sao_Paulo` em todo limite de data.
- `previousIndex` = mesma fórmula recalculada contra o estado em `hoje - 1 mês` (ver ponto 2 da
  viabilidade acima — depende de snapshot).
- Meta é configuração por tenant, default `95`.
- v2 (fora de escopo, deixar nota no código): pesar itens `REGULATORIO` mais que `OPERACIONAL`.

---

## Tasks

| ID | Título | Camada | Prioridade | Depende de |
|---|---|---|---|---|
| [TASK-246](../tasks/TASK-246.md) | Índice de conformidade + endpoint `/dashboard/summary` | Backend | 🔴 Crítico | — |
| [TASK-247](../tasks/TASK-247.md) | Endpoint `/dashboard/series` (séries pros gráficos) | Backend | 🟠 Alto | TASK-246 |
| [TASK-248](../tasks/TASK-248.md) | Fila de ações + ações inline (adiar) | Backend | 🟠 Alto | TASK-246 |
| [TASK-249](../tasks/TASK-249.md) | Shell do dashboard: layout, filtros, máquina de estado | Frontend | 🔴 Crítico | TASK-246 |
| [TASK-250](../tasks/TASK-250.md) | Hero de conformidade + tiles de KPI | Frontend | 🟠 Alto | TASK-249 |
| [TASK-251](../tasks/TASK-251.md) | Fila de ações + painel de documentos (UI) | Frontend | 🟠 Alto | TASK-248, TASK-249 |
| [TASK-252](../tasks/TASK-252.md) | Gráficos (90 dias, planejado×realizado, custo, ranking) | Frontend | 🟡 Médio | TASK-247, TASK-249 |
| [TASK-253](../tasks/TASK-253.md) | Estado `ONBOARDING` | Frontend | 🟡 Médio | TASK-249 |
| [TASK-254](../tasks/TASK-254.md) | E2E e regressão | QA/Infra | 🟡 Médio | TASK-250, TASK-251, TASK-252, TASK-253 |

## Decisões — respondidas em 09/09/2026

Todas as 7 decisões abaixo foram respondidas (proposta minha, sujeita a revisão do Douglas — nenhuma
é irreversível, mas destrava início de implementação das tasks bloqueadas por elas).

| # | Decisão | Resposta | Justificativa |
|---|---|---|---|
| 1 | Fórmula do índice — §3 está correta? | ✅ **Sim, aceitar como v1.** Peso REGULATORIO > OPERACIONAL fica pra v2 | (a)/(b) têm dado real hoje; (c) fica faseada pela decisão #6/#7 abaixo — motivo pra sequenciar, não pra rejeitar a fórmula |
| 2 | Quais itens contam como *obrigatórios* por tipo de estabelecimento | ✅ **Resolvida pela #3** — usar `AiBootstrapService` direto | Não precisa de seed table; o serviço já responde isso |
| 3 | SAMU já sugere itens por tipo de estabelecimento? | ✅ **Sim, confirmado** — `AiBootstrapController`/`AiBootstrapService.preview` já faz isso, recebe `CompanyType` | Achado técnico, não suposição |
| 4 | "Exportar PDF" está no escopo deste épico? | ❌ **Não.** Removido da barra de filtro antes do merge pra staging (TASK-257) — um botão desabilitado com tooltip ainda convida clique; volta junto com o endpoint real, em épico separado | Evita escopo crescer no meio de um redesenho já grande, e evita confundir o usuário com um botão morto |
| 5 | Meta de conformidade default | **95% fixo em código na v1, sem configuração por tenant ainda** | Não existe hoje nenhuma tela de configurações de organização que peça esse ajuste — criar coluna/tabela pra uma config sem UI real é over-engineering agora; configurabilidade entra quando houver demanda real |
| 6 | Snapshot histórico começa a ser gravado quando? | **Agora, assim que a TASK-246 for implementada** (job diário simples) | Sparklines/`previousComplianceIndex` nascem vazios/achatados, ficam úteis depois de algumas semanas — sem isso não existe dado real, e não dá pra inventar retroativamente sem violar a regra do próprio protótipo |
| 7 | Taxonomia de categoria de custo/exibição (ex. "Incêndio") | **Criar dicionário `itemType → categoria` agora**, ver mapeamento inicial abaixo | Pequeno, contido, necessário pra TASK-247/252 |

### Taxonomia inicial da decisão #7 (`itemType → categoria de exibição`)

Ponto de partida mapeando os `itemType` que já existem no sistema (mesmos usados em
`SupplierCategoryKeywords`, EPIC-023) — qualquer `itemType` fora da lista cai em **"Outros"**, pra
nunca travar cadastro de item novo:

| Categoria de exibição | `itemType` |
|---|---|
| Incêndio | `EXTINTOR`, `HIDRANTE` |
| Proteção contra descargas | `SPDA` |
| Hidráulica | `CAIXA_DAGUA` |
| Emergência | `ILUMINACAO_EMERGENCIA` |
| Climatização | `AR_COND` |
| Outros | qualquer outro `itemType` |

## Sequenciamento sugerido

```
Onda 1 (backend, paralelizável entre si depois de decidir #1/#6/#7)
  TASK-246 → TASK-247 → TASK-248

Onda 2 (frontend, TASK-249 bloqueia o resto)
  TASK-249 → { TASK-250, TASK-251, TASK-252, TASK-253 }

Onda 3 (verificação)
  TASK-254
```

## Riscos
- **Maior risco do épico**: histórico/snapshot (decisão #6) — se não for resolvido antes da
  TASK-246, o índice "anterior" e os sparklings ficam com dado fake/zero, contradizendo
  explicitamente a regra do próprio documento original ("nunca renderizar dado placeholder ou
  aleatório").
- Migração do endpoint `/dashboard` existente sem quebrar o frontend atual durante o período de
  transição (duas telas coexistindo, ou big-bang na TASK-249).
- Cross-org aggregation (`PORTFOLIO`) é uma classe de bug que já mordeu este projeto antes (comentário
  em `TenantContext.runCrossOrg` referencia exatamente esse tipo de bug em pool totals). Exige
  revisão de segurança dedicada, não só teste funcional.
- Entidade de documento nova (achado #1) muda a estimativa de esforço da TASK-246 pra cima — sem
  ela, ~1/3 da fórmula do índice não pode ser implementada.
