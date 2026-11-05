# TASK-144 — Frontend: Histórico de manutenções (ativas e canceladas) na página de detalhe do item

## Tipo
FRONTEND

## Categoria
Manutenções / Compliance e Auditoria / UX

## Prioridade
🟡 Médio

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — validar visualmente que a nova seção não conflita com a exibição já existente em
`/maintenances` (TASK-141) e que a navegação entre abas fica clara.

---

## Contexto

Achado durante o QA manual da TASK-QA-MAN-011 (cenário C1/C2): a seção "Manutenções canceladas
deste item" (TASK-141) foi implementada em `/maintenances`, empilhada abaixo da tabela geral de
manutenções. Ao testar, Douglas apontou dois problemas de UX:

1. Ficar dentro do modal "Ver detalhes" não faria sentido — aquele modal é escopado a **uma única
   manutenção**, não ao histórico do item inteiro.
2. Ficar solta na página `/maintenances` (que lista manutenções de todos os itens, com filtros)
   também não é o lugar mais natural — item já tem sua própria página de detalhe
   (`/items/[id]/page.tsx`), que hoje só mostra metadados do item (tipo, status, vencimento,
   periodicidade), sem nenhum histórico de manutenções.

Decisão (Douglas, 27/07/2026): manter a visualização já existente em `/maintenances` (não remover —
já funciona, é só mais uma forma de ver) e **adicionar** uma segunda forma, mais natural, na própria
página de detalhe do item.

---

## Objetivo

Adicionar à página `/items/[id]` uma seção "Histórico de manutenções" com duas abas — **Ativas** e
**Canceladas** — reaproveitando os endpoints e componentes já existentes (`GET
/items/maintenances?itemId=X`, `GET /items/maintenances/cancelled?itemId=X`, `CancelledMaintenanceRow`
da TASK-141), sem duplicar lógica de negócio nem endpoints novos no backend.

---

## Escopo

### 1. Seção "Histórico de manutenções" em `/items/[id]/page.tsx`

- Novo card abaixo do card principal de dados do item.
- Duas abas: "Ativas" (padrão, selecionada ao entrar na página) e "Canceladas".
- Aba Ativas: lista simples das manutenções válidas do item (data, tipo, custo) — hoje essa
  informação só existe na tabela geral de `/maintenances`; aqui é uma versão enxuta, sem os filtros
  cross-item que não fazem sentido numa página já escopada a um único item.
- Aba Canceladas: reaproveita o mesmo padrão de card expansível (`CancelledMaintenanceRow` ou
  equivalente) já usado em `/maintenances` (TASK-141) — mesmo motivo/autor/data.

### 2. Não remover a visualização existente

- `/maintenances` continua com a seção da TASK-141 intacta — é uma segunda forma de acesso, não uma
  substituição. Nenhuma mudança de comportamento lá.

### 3. Testes

- Aba Ativas carrega e lista as manutenções do item (estado vazio tratado).
- Aba Canceladas carrega e lista as manutenções canceladas do item, com motivo/autor/data (estado
  vazio tratado).
- Troca de aba não perde o estado da outra (ou refaz fetch de forma aceitável — decisão de
  implementação, sem exigência de cache complexo).

---

## Arquivos impactados (estimativa)

### Frontend
- `src/app/items/[id]/page.tsx` — nova seção de histórico com abas
- Possível extração de `CancelledMaintenanceRow` de `src/app/maintenances/page.tsx` para um
  componente compartilhado, se a duplicação de JSX entre as duas páginas ficar grande demais para
  copiar-colar — decisão a tomar durante a implementação, não estimada previamente.

---

## Critérios de Aceite

- [ ] Página `/items/[id]` mostra seção "Histórico de manutenções" com abas Ativas/Canceladas
- [ ] Aba Ativas lista as manutenções válidas do item
- [ ] Aba Canceladas lista as manutenções canceladas, com motivo/autor/data visíveis
- [ ] Nenhuma mudança de comportamento em `/maintenances` (TASK-141 continua igual)
- [ ] Estados de loading/erro/vazio tratados nas duas abas

## Dependências
- **TASK-139** — endpoint de canceladas já existe.
- **TASK-141** — padrão visual de card de cancelada já existe, para reaproveitar.

## Riscos
Nenhum risco técnico relevante — reaproveita endpoints e padrões já validados; risco é só de
duplicação de UI se não for bem fatorado (mitigado por decisão de extrair componente compartilhado
se necessário, ver Arquivos impactados).

## Esforço
Baixo/Médio (sem endpoint novo — é composição de UI reaproveitando dados já existentes)

## Status
**Concluída** — implementado na branch `feature/EPIC-016-cancel-maintenance-reason`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (mesmas 3 falhas pré-existentes
da TASK-141, não relacionadas). QA manual aprovado, incluindo a remoção do card equivalente em
`/maintenances` (ver Implementação). Commitado, com PR aberto para `staging`.

## Implementação

- **Extração de componente compartilhado**: `TypeBadge`, `formatDate`, `formatDateTime`,
  `formatCost`, `CancelledMaintenanceRow` e a interface `Maintenance` saíram de
  `maintenances/page.tsx` (onde foram implementados na TASK-141) para
  `src/components/maintenances/maintenanceDisplay.tsx` — usados agora nas duas páginas, sem
  duplicar JSX/lógica. `maintenances/page.tsx` passou a importar do módulo novo; nenhuma mudança de
  comportamento lá.
- **Duas abas, não lista única mesclada**: "Ativas" (padrão) e "Canceladas" — decisão consistente
  com a TASK-141 (nunca misturar sem diferenciação clara), só que agora como abas em vez de
  card/toggle empilhado, já que aqui é o único histórico da página (menos poluição visual que
  motivou a task).
- **Aba Ativas é enxuta de propósito**: lista simples (data, tipo, responsável, custo), sem a
  tabela completa/paginação cursor de `/maintenances` — não faz sentido reimplementar filtros
  cross-item numa página já escopada a um único item. Link "Ver todas em Manutenções →" cobre quem
  precisar da visão completa (paginação, exportação, etc.).
- **Aba Canceladas reaproveita 100% o padrão da TASK-141** (`CancelledMaintenanceRow`, mesmo
  endpoint `GET /items/maintenances/cancelled?itemId=X`) — sem lógica nova, só uma segunda
  superfície de acesso, como pedido.
- **Lazy-load da aba Canceladas**: só busca (`enabled: historyTab === "cancelled"`) quando o
  usuário troca de aba, mesmo padrão de `showCancelled` da TASK-141 — evita uma requisição
  desnecessária pra quem nunca abre a aba.
- Sem endpoint novo, sem mudança de backend — reaproveita integralmente TASK-139/141.
- **Follow-up (Douglas, 27/07/2026)**: depois de validar visualmente esta task, decidiu remover o
  card "Manutenções canceladas deste item" de `/maintenances` (TASK-141) — com a aba equivalente
  aqui, ele ficava redundante. Removido: state `showCancelled`, query `["maintenances-cancelled"]`
  e o card/toggle inteiro em `maintenances/page.tsx`; `handleMaintenanceCancelled` (TASK-140) agora
  invalida `["item-maintenances-active", itemId]` e `["item-maintenances-cancelled", itemId]` (as
  novas query keys desta task) em vez de `["maintenances-cancelled"]`, pra manter esta página em
  sincronia depois de cancelar. Import não usado (`CancelledMaintenanceRow`) removido de
  `maintenances/page.tsx`. `npm run build` revalidado limpo.
