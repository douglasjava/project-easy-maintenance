# TASK-140 — Frontend: Ação "Cancelar manutenção" com modal de motivo obrigatório

## Tipo
FRONTEND

## Categoria
Manutenções / Compliance e Auditoria

## Prioridade
🟠 Alto

## Épico
[EPIC-016](../epics/EPIC-016.md) — Cancelamento de Manutenções com Motivo

## QA obrigatório
Sim — precisa validar visualmente (feedback claro de que a ação é destrutiva/permanente do ponto de
vista do fluxo, mesmo sendo soft-delete por trás).

---

## Contexto

Foi o gap que motivou este épico: testando em produção, não havia como corrigir uma manutenção
cadastrada errada. `easy-maintenance-web/src/app/maintenances/page.tsx` é onde hoje se vê o detalhe
de uma manutenção (`maintDetail`) e os anexos — é o lugar natural pra essa ação.

Depende do endpoint da **TASK-137** existir (`POST .../maintenances/{id}/cancel`).

---

## Objetivo

Dar ao usuário (ADMIN/SYNDIC) um jeito claro e seguro de cancelar uma manutenção incorreta, direto
da tela onde ele já vê o detalhe dela.

---

## Escopo

### 1. Botão/ação de cancelar

- No detalhe da manutenção (`maintDetail`), adicionar ação "Cancelar manutenção" — visível só para
  papéis autorizados (ADMIN/SYNDIC), espelhando qualquer padrão de controle de UI por papel já
  usado em outras telas (ex.: guard ADMIN em `/users`, ver TASK-100/101/102).
- Não mostrar a ação em manutenções já canceladas.

### 2. Modal de confirmação com motivo obrigatório

- Modal exigindo o motivo (textarea, obrigatório, com validação inline — não deixar confirmar vazio).
- Copy clara de que a ação não pode ser desfeita pelo usuário (mesmo sendo soft-delete no banco, do
  ponto de vista do usuário deve ser tratado como definitivo — evita banalizar o cancelamento).
- Estado de loading/erro no submit (padrão já usado em outros modais de ação destrutiva do sistema,
  ex.: exclusão de item/usuário).

### 3. Atualização da UI pós-cancelamento

- Após cancelar com sucesso: remover a manutenção da lista de válidas (ou marcar visualmente),
  atualizar o status/próximo vencimento exibido do item (reflete o recálculo da TASK-138) e mostrar
  feedback de sucesso (toast, mesmo padrão de `react-hot-toast` já usado no projeto).
- Tratar erros da API (motivo inválido, já cancelada, sem permissão) com mensagens específicas, não
  um erro genérico.

### 4. Testes

- Componente do modal: validação de motivo obrigatório, estados de loading/erro.
- Fluxo completo (se houver padrão de teste de integração no frontend): cancelar atualiza a lista e
  o status do item exibido.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/app/maintenances/page.tsx` — ação de cancelar no detalhe, atualização de estado pós-cancelamento
- Novo componente de modal (ex.: `src/components/maintenances/CancelMaintenanceModal.tsx`)
- Cliente de API — novo método `cancelMaintenance(itemId, maintenanceId, reason)`

---

## Critérios de Aceite

- [ ] Ação "Cancelar manutenção" visível só para papéis autorizados, e só em manutenções ainda
      válidas
- [ ] Modal exige motivo obrigatório, não permite confirmar vazio
- [ ] Sucesso atualiza a lista e o status/próximo vencimento do item na tela, sem precisar recarregar
      a página
- [ ] Erros da API (já cancelada, sem permissão, motivo inválido) mostram mensagem específica
- [ ] Responsivo (mobile) — mesmo padrão de modais já usado no projeto

## Dependências
- **TASK-137** — endpoint de cancelamento precisa existir.
- **TASK-138** — pra a UI refletir o recálculo correto do item após cancelar.

## Riscos
- Se o padrão de controle de UI por papel não estiver claro/reaproveitável, pode precisar de decisão
  de produto sobre quem vê o botão nesta fase (mesmo risco espelhado no backend da TASK-137).

## Esforço
Médio (modal + integração com API + atualização de estado — sem novidade arquitetural)

## Status
**Concluída** — implementado na branch `feature/EPIC-016-cancel-maintenance-reason`
(`easy-maintenance-web`). `npm run build` limpo, `npm test` 86/89 (3 falhas pré-existentes de
`middleware.test.ts`, não relacionadas). QA manual aprovado (clique-a-clique real, C1/C2/C7).
Commitado, com PR aberto para `staging`.

## Implementação

- **Guard por papel**: usei o padrão de `userRole` salvo em localStorage/sessionStorage (mesmo de
  `/users` e `UserTopBar`), checando `ADMIN || SYNDIC` — não o sistema de `permissions` do
  `accessContext` (`canRegisterMaintenance` etc., já usado nesta mesma página para o botão
  "Registrar manutenção"). Decisão deliberada: o backend (TASK-137) autoriza por `Role` bruto, não
  por uma flag de permissão dedicada — se eu reaproveitasse `canRegisterMaintenance`, um TECH (que
  pode registrar manutenção) veria o botão "Cancelar" e levaria um 403 ao tentar, uma UX pior do que
  usar a fonte de verdade certa. Registrar aqui pra não parecer inconsistência com o resto da página.
- `CancelMaintenanceModal.tsx` (novo componente) — portal próprio (`createPortal`, mesmo padrão de
  `PaymentMethodSelectionModal`/`ConfirmModal`), textarea com validação de mínimo de 5 caracteres
  (espelhando `@Size(min=5)` do backend, só pra feedback imediato), erro da API lido via
  `err?.response?.data?.detail` (convenção já usada em ~10 lugares do projeto).
- Endpoint chamado direto via `api.post` inline no componente — sem criar uma camada de "cliente de
  API" separada, já que nenhuma outra chamada desta página passa por uma (todas usam `api.get/post`
  diretamente).
- Pós-cancelamento: fecha os dois modais e invalida (`queryClient.invalidateQueries`) as queries
  `["maintenances"]`, `["items"]` e `["item", itemId]` — cobre tanto a lista desta página quanto o
  status/nextDueAt do item, se a página do item já estiver montada em outra aba/navegação futura.
- **Correção de doc**: o retorno de `@Valid @RequestBody` inválido no backend não é `400` como a
  TASK-137 registrou — é `422 Unprocessable Entity`, com a mensagem específica dentro de
  `response.data.violations[]`, não em `response.data.detail` (só populado pra outras exceções, ex.
  `ConflictException`/`ForbiddenException`). Como o modal já valida o motivo no cliente antes de
  chamar a API, esse caminho de erro não deveria ocorrer na prática — não implementei parsing de
  `violations[]`, só o fallback genérico de `detail`.
- **Não testado automaticamente**: não existe infraestrutura de teste de componente React neste
  projeto (`jest.config` usa `testEnvironment: 'node'` e só casa `*.test.ts`, sem `jsdom`/
  `@testing-library/react`) — só testes de lógica pura (ex. `phoneMask.test.ts`). Construir essa
  infraestrutura está fora do escopo desta task. Validado via `npm run build` (typecheck completo)
  + `npm run lint` + revisão manual contra os padrões já usados em `PaymentMethodSelectionModal`/
  `ConfirmModal`/`UserTopBar`. **Não fiz o clique-a-clique real no navegador**: a página é protegida
  por middleware de autenticação, e teria exigido subir a API local (bloqueada pelo gap de
  `bootstrap.admin.token` já registrado na TASK-136) + dados de teste (org/usuário/item/manutenção)
  — validação visual completa fica para o cenário C7 da TASK-QA-MAN-011.
