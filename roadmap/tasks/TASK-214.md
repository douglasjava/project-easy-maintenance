# TASK-214 — FULL_STACK: seleção múltipla + remoção em massa na tela de itens

## Tipo
FULL_STACK

## Categoria
Backend + Frontend / Itens

## Prioridade
🟡 Médio

## Épico
Sem épico — pedido por Douglas depois de validar a TASK-212/213, 30/08/2026.

## QA obrigatório
Sim — QA manual: selecionar vários itens (com e sem manutenção registrada) e confirmar que a remoção
em massa apaga os elegíveis e **não** apaga os que têm manutenção, com feedback claro de quais foram
pulados e por quê.

---

## Contexto

Douglas pediu um jeito de selecionar todos ou vários itens na tela `/items` pra remoção em massa,
respeitando a regra "não pode apagar item com manutenção registrada".

## Achado durante a análise (antes de implementar)

Essa regra **não existe hoje pro caminho de remoção**. Ela só existe em `update()`
(`MaintenanceItemService.java:307`, bloqueia edição com `ConflictException` se
`maintenanceRepository.existsByItemId(itemId)`). `remove()` (`MaintenanceItemService.java:288-296`)
não checa nada — qualquer item pode ser removido hoje, mesmo com manutenções registradas (é
soft-delete via `@SQLDelete`, o dado não se perde fisicamente, mas o item some da listagem mesmo
tendo histórico vinculado).

Como isso afeta diretamente o comportamento esperado da remoção em massa (e multiplicaria o risco de
apagar em lote itens com histórico), esta task fecha os dois lados juntos: adiciona a checagem no
`remove()` individual **e** no batch novo.

## Objetivo

1. `remove()` passa a bloquear (mesma `ConflictException` de `update()`) remoção de item com
   manutenção registrada — fecha a lacuna, consistente com a regra que já existe pra edição.
2. Novo endpoint de remoção em lote, que aplica a mesma regra por item e devolve um resultado
   parcial (removidos vs. pulados com motivo) — não é tudo-ou-nada.
3. Frontend: checkbox por linha + "selecionar todos nesta página" + seleção persistente entre
   páginas (a listagem é cursor-paginada) + barra de ação "Remover N selecionados" com resumo do
   resultado (X removidos, Y pulados por ter manutenção).

## Escopo (proposto, a confirmar no `/execute-task`)

### Backend
- `MaintenanceItemService.remove()`: adicionar a mesma checagem de `update()`
  (`maintenanceRepository.existsByItemId`) antes do soft-delete.
- `MaintenanceItemService.removeBatch(orgId, List<Long> ids)`: itera, aplica a mesma regra por item,
  captura sucesso/pulo (mesmo padrão de `created`/`failed`/`skipped` já usado em
  `AiBootstrapApplyResponse`, não lança no primeiro erro).
- `ItemsController`: novo `DELETE /items/batch` (corpo com lista de ids), simétrico ao
  `POST /items/batch` (`createBatch`) que já existe.

### Frontend (`items/page.tsx`)
- Checkbox por linha da tabela + checkbox "selecionar todos" no cabeçalho (escopo: itens
  carregados na página atual, dado que a listagem é cursor-paginada — "selecionar tudo que bate o
  filtro" exigiria um endpoint de bulk-by-filter, fora de escopo por ora).
- Set de ids selecionados sobrevive à navegação entre páginas (união, não reseta ao trocar página).
- Barra de ação flutuante/fixa quando há seleção: "Remover N selecionados", confirma via modal
  (reaproveitar `ConfirmModal` já usado no delete individual).
- Feedback pós-ação: toast ou resumo com quantos foram removidos e quantos pulados (com motivo).

## Critérios de Aceite

- [x] `remove()` bloqueia item com manutenção registrada (mesma mensagem de `update()`)
- [x] Endpoint de remoção em lote (`DELETE /items/batch`) existe, aplica a regra por item, não é
      tudo-ou-nada
- [x] Teste cobrindo: lote misto (alguns com manutenção, outros sem) remove só os elegíveis; id
      desconhecido/de outra org é pulado sem abortar o resto do lote
- [x] Frontend: seleção múltipla funcional, sobrevive à paginação, feedback claro do resultado
      (toast com quantos removidos/pulados, motivo legível)
- [x] `mvn clean test` (859/859, 0 falhas) e typecheck/lint do frontend sem regressão
- [ ] QA manual em produção pós-deploy — **não testado num browser real nesta sessão**: boot local
      completo da API exige credenciais Firebase/AWS não configuradas neste ambiente (infra não
      relacionada a esta task — `PushNotificationProvider` exige um bean `FirebaseMessaging` real).
      Douglas já roda local rotineiramente; recomendado validar visualmente lá antes do merge.

## Dependências
Nenhuma (independente da TASK-212/213, achada durante a mesma sessão de validação).

## Riscos
Baixo-Médio — ação destrutiva em lote; mitigado pela checagem por item (nunca tudo-ou-nada) e por
já ser soft-delete (reversível via banco, não é perda física de dado).

## Esforço
Médio

## Status
✅ Implementado, PRs abertas contra `staging`:
[api#61](https://github.com/douglasjava/easy-maintenance-api/pull/61) e
[web#61](https://github.com/douglasjava/easy-maintenance-web/pull/61). Branch
`feature/TASK-214-bulk-select-remove-items` nos dois repos. Suíte completa da API: 859/859, 0
falhas. Typecheck/lint do frontend sem regressão. QA manual pendente — não validado num browser real
nesta sessão (ver critério de aceite acima).

**30/08, dois ajustes pedidos por Douglas (commit `71cd0c0`, web):**
1. Tooltip do botão Editar desabilitado mostrava o código bruto do backend em inglês
   (`ITEM_ALREADY_USED_IN_MAINTENANCE`) em vez de uma mensagem legível.
2. O botão Remover não era bloqueado no cliente pra item com manutenção — ficava clicável, o
   usuário só descobria pelo erro 409 depois do clique (a validação em si já estava correta desde
   a implementação inicial).

**30/08, mesma correção espelhada em `/items/[id]` (commit `0c0d890`, web):** o botão Remover da
tela de detalhe do item tinha a mesma lacuna (Editar já checava `data?.canUpdate`, Remover não).

## Débito técnico registrado (não corrigido, guardado a pedido de Douglas)

Ao mexer em `/items/[id]/page.tsx` (commit `0c0d890`), achei **dois modais de confirmação de
exclusão sobrepostos** nessa página, ambos controlados pelo mesmo estado `showDeleteModal`: o
componente `<ConfirmModal>` padrão (linha ~131) e um modal Bootstrap "cru" duplicado mais abaixo no
arquivo (linha ~492). Os dois renderizam juntos quando o usuário clica em Remover — pré-existente,
não introduzido por esta task, não relacionado ao pedido original. Douglas já mergeou TASK-214 em
`staging` e pediu pra guardar isso como débito técnico pra remover o duplicado depois, sem abrir
task nova por ora.

Fix: `itemBlockedReasonMessage()` mapeia os códigos conhecidos pra PT-BR; Remover passou a reusar
o mesmo `it.canUpdate`/`it.reason` que a API já calcula pra Editar (mesma regra —
`existsByItemId`) — os dois botões agora ficam desabilitados de antemão, com tooltip legível, em
vez de só falhar depois do clique.
