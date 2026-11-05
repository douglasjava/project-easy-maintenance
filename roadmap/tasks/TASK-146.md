# TASK-146 — Frontend: Relatório de Prestação de Contas (PDF, uma organização, 4 seções)

## Tipo
FRONTEND

## Categoria
Relatórios / Compliance e Auditoria

## Prioridade
🟠 Alto

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — validar visualmente o PDF gerado (layout, dados corretos) e o gate de plano.

---

## Contexto

Hoje não existe nenhuma forma de gerar um documento apresentável a terceiros (assembleia de
condomínio, cliente, auditor) mostrando o que foi feito num condomínio/imóvel específico num
período. O `/me/reports` atual é cross-org e entrega tabela + CSV, não um documento de prestação de
contas.

---

## Objetivo

Fluxo novo: usuário escolhe **uma organização** + **período**, e gera um PDF com 4 seções, via
`@react-pdf/renderer` (geração client-side, RN-017-05).

---

## Escopo

### 1. Seleção de período
- Organização: sempre a **ativa no momento** (`X-Org-Id` global) — sem seletor próprio nesta tela
  (ver Implementação, achado sobre conflito com o seletor global de organização).
- Período: data início/fim, com atalhos ("Último mês", "Último trimestre", "Este ano").

### 2. Composição dos dados (reaproveitando endpoints existentes)
- KPIs do período: total de manutenções realizadas, custo total (agregado client-side a partir da
  listagem), itens em dia/vencidos/próximos do vencimento (via `GET /items?status=X`), taxa de
  conformidade (% em dia).
- Manutenções realizadas: `GET /items/maintenances?performedAtFrom&performedAtTo` (já existe).
- Manutenções canceladas/auditoria: endpoint novo da **TASK-145**.
- Itens pendentes/vencidos: `GET /items?status=OVERDUE` (e/ou `NEAR_DUE`, já existe).

### 3. Preview em tela + download
- Preview do conteúdo na própria tela antes de baixar (não só um botão "cego").
- Botão "Baixar PDF" — gera o arquivo via `@react-pdf/renderer` no navegador.

### 4. Gate de plano
- Respeitar `reportsEnabled` (mesmo padrão de guard já usado em outras features pagas — verificar
  `permissions`/`features` do `useCurrentOrganizationAccess()`).

### 5. Testes
- Sem infraestrutura de teste de componente React neste projeto (limitação já registrada em tasks
  anteriores do EPIC-016) — validar via build/lint/revisão manual + QA manual (TASK-QA-MAN-012).

---

## Critérios de Aceite

- [x] Usuário escolhe período e vê um preview com as 4 seções (organização é sempre a ativa — ver
      Implementação, achado sobre `X-Org-Id`)
- [x] PDF baixado contém as 4 seções com dados corretos do período escolhido
- [x] Canceladas aparecem só na seção de auditoria, nunca misturadas com as realizadas
- [x] Sem `reportsEnabled`, ação fica bloqueada com mensagem clara (mesmo padrão de outras features
      gated por plano)
- [x] `npm run build` limpo

## Dependências
- **TASK-145** — endpoint de canceladas por organização/período.

## Riscos
Volume de dados grande pode deixar a geração do PDF lenta no navegador (ver Riscos do épico) — se
aparecer no QA manual, considerar limitar o período (ex. máx. 12 meses) antes de escalar pra geração
server-side.

## Esforço
Alto (fluxo novo completo: seleção, composição de múltiplas fontes de dados, layout de PDF)

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes, não
relacionadas). QA manual aprovado (evoluída depois pela TASK-149, seletor de organização inline).
Commitado, com PR aberto para `staging`.

## Implementação

- **Achado que mudou o escopo original — sem seletor de organização**: todo endpoint org-scoped
  neste app (`/items`, `/items/maintenances`) depende do header `X-Org-Id`, montado globalmente pelo
  `apiClient` a partir da organização ativa (`organizationCode` salvo em localStorage/sessionStorage
  no seletor global de organização já existente) — não é passível de override por requisição.
  Adicionar um dropdown de organização SÓ nesta tela criaria duas noções conflitantes de "organização
  atual" (o seletor global vs. o dropdown local), com risco real de o usuário escolher uma
  organização no relatório e os dados virem de outra (a que estiver ativa globalmente). Solução: o
  relatório é sempre da organização **atualmente ativa** — pra gerar de outra, o usuário troca no
  seletor global, exatamente como em qualquer outra tela do sistema (`/items`, `/maintenances`).
  Critério de aceite ajustado para refletir essa decisão.
- **Sem endpoint agregador novo**: KPIs (total de manutenções, custo, contagem por status) são
  calculados no frontend a partir de 3 chamadas em paralelo já existentes (`GET
  /items/maintenances`, `GET /items/maintenances/cancelled` da TASK-145, `GET /items`) — evita
  inventar um endpoint de agregação só pra este relatório.
- **`size=1000` sem paginação**: pragmático pra v1 dado o volume esperado (dezenas de itens/manutenções
  por prédio, não milhares) — ver Riscos do épico sobre volume grande.
- **Dois componentes separados**: `PrestacaoContasSection.tsx` (preview em tela, HTML/CSS normal) e
  `PrestacaoContasPdfDocument.tsx` (documento `@react-pdf/renderer`, que não usa DOM normal — não dá
  pra reaproveitar o mesmo JSX pro preview e pro PDF). Os dados são computados uma vez só
  (`PrestacaoContasData`) e passados pros dois.
- Nova aba "Prestação de Contas" em `/reports`, ao lado de "Visão Geral" e "Manutenções" — mesma UI
  de segmented control já existente.
- Gate `reportsEnabled` via `GuardedButton` (mesmo componente já usado em outras features pagas),
  checando `features?.reportsEnabled` de `useCurrentOrganizationAccess()`.
- **Mesma limitação de teste das tasks de frontend anteriores** (TASK-140/143/144): sem
  infraestrutura de teste de componente React neste projeto — validado via build/lint/revisão
  manual, sem clique-a-clique real (login bloqueado pelo mesmo motivo de sempre). Fica para
  TASK-QA-MAN-012.
