# TASK-149 — Frontend: seletor de organização na aba Prestação de Contas

## Tipo
FRONTEND

## Categoria
Relatórios

## Prioridade
🟡 Médio

## Épico
[EPIC-017](../epics/EPIC-017.md) — Relatórios: Prestação de Contas (PDF) e Analítico (Excel)

## QA obrigatório
Sim — validar que o relatório gerado reflete de fato a organização selecionada, não a ativa
globalmente.

---

## Contexto

Achado pós-TASK-146 (Douglas, 28/07/2026): um usuário dono de várias organizações precisa trocar de
organização no seletor global, sair da tela de relatórios, entrar de novo, pra gerar a Prestação de
Contas de outra empresa. Pedido: um seletor de organização **dentro da própria aba**, sem precisar
sair da tela.

Isso esbarra na decisão tomada na TASK-146 (relatório sempre da organização ativa via `X-Org-Id`
global) — mas o motivo daquela decisão era evitar que um seletor **paralelo e desincronizado** do
seletor global gerasse dados da organização errada. A solução não é abrir mão do seletor, é fazer
esse seletor **controlar explicitamente** o `X-Org-Id` só das chamadas deste relatório, sem tocar no
contexto global (que continua intocado pro resto do app).

---

## Objetivo

Seletor de organização na aba "Prestação de Contas", disponível quando o usuário tem acesso a mais
de uma organização — gera o relatório da organização escolhida ali, sem mexer no seletor global nem
navegar pra outra tela.

---

## Escopo

### 1. `apiClient.ts` — respeitar override explícito de `X-Org-Id`
- O interceptor sobrescrevia incondicionalmente `X-Org-Id` com a organização ativa globalmente.
  Ajustado para só aplicar esse valor quando a chamada **não** já especificou o header — mudança
  retrocompatível (nenhum outro call site do app define esse header manualmente hoje).

### 2. Seletor na `PrestacaoContasSection`
- Lista as organizações do `accessContext.organizationsAccess` (já carregado globalmente, sem
  chamada nova) — `organizationCode`/`organizationName`.
- Só aparece quando o usuário tem mais de uma organização (evita poluição visual pra quem só tem
  uma, maioria dos casos).
- Default: organização ativa no momento (mesmo comportamento de antes, só que agora trocável ali
  mesmo).
- As 3 chamadas de dados do relatório (`/items/maintenances`, `/items/maintenances/cancelled`,
  `/items`) passam `headers: { "X-Org-Id": selectedOrgCode }` explícito.
- Nome da organização e gate `reportsEnabled` no PDF/preview usam a organização **selecionada**, não
  a ativa globalmente (busca no próprio `organizationsAccess`, não em `useCurrentOrganizationAccess()`
  que só expõe a org corrente).

### 3. Testes
- Sem infraestrutura de teste de componente React neste projeto (mesma limitação já registrada) —
  validar via build/lint/revisão manual + QA manual.

---

## Critérios de Aceite

- [x] Seletor aparece só quando o usuário tem mais de uma organização
- [x] Trocar a organização no seletor gera o relatório da organização escolhida, sem navegar pra
      outra tela nem afetar o contexto global (outras telas do app continuam na organização que
      estava ativa antes)
- [x] Nome da organização e gate `reportsEnabled` refletem a organização selecionada no seletor
- [x] `npm run build` limpo

## Dependências
- **TASK-146** — seção/fluxo já existe, esta task ajusta o comportamento de seleção de organização.

## Riscos
Nenhum risco técnico relevante — a mudança no `apiClient` é estritamente aditiva (só ativa quando o
chamador especifica o header, o que nenhum outro código do app faz hoje).

## Esforço
Baixo/Médio (ajuste pontual no interceptor + seletor + troca de fonte de dados de org corrente pra
org selecionada)

## Status
**Concluída** — implementado na branch `feature/EPIC-017-reports-accountability-analytics`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes, não
relacionadas). QA manual aprovado. Commitado, com PR aberto para `staging`.

## Implementação

- **`apiClient.ts`**: interceptor ajustado para só aplicar `X-Org-Id` da organização ativa
  globalmente quando a chamada **não** já especifica esse header (`if (!config.headers["X-Org-Id"])`)
  — mudança estritamente aditiva, retrocompatível com todo o resto do app (nenhum outro call site
  define esse header manualmente hoje).
- **Fonte de organizações**: trocado `useCurrentOrganizationAccess()` (só expõe a org ativa) por
  `useAccessContext()` direto (`organizationsAccess`, já carregado globalmente, sem chamada nova) —
  necessário pra ter a lista completa de organizações do usuário, não só a corrente.
- Seletor só renderiza quando `organizationsAccess.length > 1` — evita poluição visual pra quem só
  tem uma organização (a maioria dos casos).
- Default do seletor: `currentOrganizationCode` (organização ativa no momento) — comportamento
  inicial idêntico ao de antes da TASK-149, só que agora trocável sem sair da tela.
- Trocar a organização no seletor limpa o preview (`setData(null)`) — evita mostrar dados da
  organização anterior rotulados como se fossem da nova selecionada.
- Nome da organização e gate `reportsEnabled` no preview/PDF agora vêm de `selectedOrg` (encontrado
  em `organizationsAccess` pelo código selecionado), não mais da organização ativa globalmente.
