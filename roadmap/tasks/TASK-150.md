# TASK-150 — Frontend: ocultar menu "Relatórios" quando o plano não inclui relatórios

## Tipo
FRONTEND

## Categoria
Relatórios

## Prioridade
🟡 Médio

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — validar que o menu some/aparece corretamente ao trocar de organização com planos diferentes.

---

## Contexto

Achado no QA manual (Douglas, 28/07/2026, cenário C3 da TASK-QA-MAN-012): o gate `reportsEnabled`
até então só bloqueava as ações dentro da tela `/reports` (botão "Baixar PDF"/"Exportar Excel"
desabilitado com mensagem). Decisão: mais coerente **nem exibir o item de menu "Relatórios"**
quando o plano da organização ativa não inclui a funcionalidade — não dar margem ao usuário de
entrar numa área que ele não pode de fato usar.

---

## Objetivo

Ocultar o item "Relatórios" do menu (Sidebar e dropdown do `UserTopBar`) quando
`features.reportsEnabled` da organização ativa for `false`.

---

## Escopo

- `Sidebar.tsx`: `features` já era obtido de `useCurrentOrganizationAccess()` mas não usado pra
  filtrar itens — o item `/reports` agora só entra no array `items` quando
  `features?.reportsEnabled` é verdadeiro.
- `UserTopBar.tsx`: mesmo critério, mesmo padrão já usado ali pra `canManageBilling` (`{condição &&
  (<li>...)}`) — trocado `useAccessContext()` (só tinha `accessContext`) para também expor
  `currentOrganizationCode`, usado pra encontrar a organização ativa em
  `accessContext.organizationsAccess` e ler `features.reportsEnabled`.
- **Fora do escopo, deliberadamente**: não adicionado guard de rota (redirecionamento se o usuário
  acessar `/reports` direto pela URL). O pedido foi especificamente sobre o menu; um guard de rota
  bloquearia também as abas "Visão Geral"/"Manutenções", que hoje funcionam pra qualquer plano (só
  as ações de exportar/baixar são gated) — mudança de comportamento maior que o que foi pedido.

---

## Critérios de Aceite

- [x] Menu "Relatórios" (Sidebar e dropdown do TopBar) não aparece quando a organização ativa não
      tem `reportsEnabled`
- [x] Menu volta a aparecer ao trocar para uma organização com `reportsEnabled`
- [x] `npm run build` limpo

## Dependências
Nenhuma.

## Riscos
Nenhum risco técnico relevante — mudança aditiva de filtro de exibição, sem alterar nenhuma rota ou
endpoint.

## Esforço
Baixo

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes, não
relacionadas). QA manual aprovado (C3). Commitado, com PR aberto para `staging`.

## Implementação

- `Sidebar.tsx`: item `/reports` incluído condicionalmente no array `items` via spread
  (`...(features?.reportsEnabled ? [...] : [])`) — `features` já vinha de
  `useCurrentOrganizationAccess()`, só não era usado pra esse fim ainda.
- `UserTopBar.tsx`: `reportsEnabled` derivado de `accessContext.organizationsAccess.find(...)` pela
  organização correspondente a `currentOrganizationCode` (agora também exposto por
  `useAccessContext()`) — mesmo padrão exato já usado ali pra `canManageBilling`.
- Nenhum novo lint introduzido — os erros pré-existentes no `Sidebar.tsx` (componentes internos
  criados durante o render, `setState` em `useEffect`) estão em código não tocado por esta mudança.
