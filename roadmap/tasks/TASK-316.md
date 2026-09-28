# TASK-316 — Catálogo de tipos de item: global curado × tipos próprios da organização

## Tipo
FULL_STACK

## Prioridade
🟡 Médio (não bloqueia; o risco cresce com o número de clientes)

## Épico
Qualidade de dados / multi-tenant (achado durante a TASK-315, EPIC-031)

## Depende de
—

## QA obrigatório
Sim (multi-tenant).

## Contexto
`item_types` é **um catálogo global único**, compartilhado por todas as organizações, sem autor e sem escopo. Hoje ele é gravado por dois caminhos:
- **Web** `/items/new` → `POST /item-types` com o texto digitado (qualquer usuário autenticado).
- **IA Onboarding** (`AiBootstrapService`) → cria os tipos sugeridos pela IA.

Levantamento em produção (28/09/2026): as seeds vão até o id 186. Os ids 187–231 foram criados em uso real: 187 e 219–227
pelo web, e 188–218 e 228–231 pela IA (em lotes no mesmo segundo). A qualidade está boa, mas já apareceram:
- **Dado de cliente vazando para os outros:** 225 "RELATORIO PREVENCAO ACIDENTES PISCINA SEGURA VILA VELHA".
- **Erro de digitação da IA virando padrão para todos:** 230 "SISTEMA_DE_INCEDIO".

Com dezenas de clientes, o catálogo global vira uma lista poluída e deixa de ser padrão.

## Proposta (recomendada)
Tipos **próprios da organização** + catálogo **global curado**:
- `item_types` ganha `organization_code` (NULL = global), `origin` (SEED · USER · AI · ADMIN) e `created_by`.
- **Listagem** para a organização X = global ATIVO + tipos próprios de X. Outra organização nunca vê os tipos de X.
- **`POST /item-types`** (web) e **IA Onboarding** criam o tipo **na organização** (`X-Org-Id`). Se já existe um global com
  o mesmo `normalized_name`, reaproveita o global (não duplica).
- **Promoção (admin):** endpoint privado para promover um tipo próprio a global, com correção do nome. Essa é a curadoria.
  Pode ficar para uma fase 2, junto com uma tela no admin.
- `maintenance_items.item_type` é texto (não é FK): mudar o escopo do tipo **não mexe em item existente**.
- **Índice único:** hoje `normalized_name` é único globalmente. Passa a ser único por
  (escopo, normalized_name), com coluna gerada `COALESCE(organization_code, 'GLOBAL')`, porque no MySQL NULL não conta na unicidade.

## Migração dos existentes
- ids ≤ 186 (seeds) e todos com `norm_id` → global, `origin = SEED`.
- 187–231: **revisão caso a caso com o Douglas** antes da migration. Sugestão:
  - se é usado por uma única organização → vira tipo próprio dela;
  - se é bom e genérico → global (com o nome corrigido, ex.: "SISTEMA_DE_INCEDIO" → "SISTEMA DE INCENDIO");
  - o 225 → próprio da organização dona.
  - Consulta de apoio (quais organizações usam cada tipo):
    `SELECT it.id, it.name, COUNT(DISTINCT mi.organization_code) orgs FROM item_types it LEFT JOIN maintenance_items mi ON mi.item_type = it.normalized_name WHERE it.id > 186 GROUP BY it.id, it.name;`

## Riscos
- **Cache:** o snapshot em memória da TASK-315 precisa respeitar o escopo (global + da organização). O bot continua
  oferecendo só tipos globais curados.
- **Front:** o autocomplete de `/items/new` passa a mandar `X-Org-Id` na listagem e no POST.
- **Segurança:** ninguém lê nem grava tipo de outra organização (teste de isolamento).

## Critérios de aceite
- [ ] Tipo criado no web ou pela IA Onboarding fica visível só na organização que o criou.
- [ ] A listagem da organização = global + próprios; outra organização não vê.
- [ ] Nome igual a um global reaproveita o global (sem duplicar).
- [ ] Os itens existentes continuam funcionando (nenhum item muda).
- [ ] O índice único respeita o escopo (duas organizações podem ter o mesmo tipo próprio).
- [ ] Migração dos ids 187–231 aprovada pelo Douglas.

**Prompt**: `execute a TASK-316: separar catálogo global curado de tipos próprios por organização (item_types com escopo, origem e autor).`

## Status
Backlog
