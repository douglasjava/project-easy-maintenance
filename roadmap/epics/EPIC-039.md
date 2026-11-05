# EPIC-039 — Pessoas e Papéis (Registro de Governança do Condomínio)

## Status
🟢 QA manual concluído (01/11/2026) — 7 tasks (TASK-380 a TASK-386) mergeadas em `staging`
(api#171, web#120). [TASK-393](../tasks/TASK-393.md) (bugfix crítico, `TenantFilter` não validava
X-Org-Id em `condo-people`/`units`, módulo inutilizável) encontrada e corrigida na mesma data,
mergeada direto em `staging` sem PR intermediária, suíte completa 1613/1613 verde. Plano de QA
([FLOW-012](../QA/Flow/FLOW-012.md), [MTD-009](../QA/MTD/MTD-009.md),
[TASK-QA-MAN-027](../QA/tasks/TASK-QA-MAN-027.md)) executado contra API/web local a partir da
`staging` atualizada — todos os 8 cenários + negativo aprovados (ver TASK-QA-MAN-027 pro detalhe).
Pronto para promover `staging` → `main`. Spec em
`docs/superpowers/specs/2026-10-29-pessoas-papeis-governanca-design.md` (fechada por Douglas,
decisões 1/3/4/5/6 tomadas sem validação externa do sócio Tiago — ver seção "Decisões" da spec).

## Objetivo
Dar ao condomínio um registro formal de governança — síndico, conselho, moradores, fornecedores e
unidades — que hoje não existe no sistema. O produto só modela `User`/`Role` (perfil de login) e
`Supplier` (fornecedor como empresa); não existe nenhuma entidade de "quem é síndico", "quem mora em
qual unidade" ou "quem está no conselho e até quando".

## Descrição

Duas entidades novas por organização, módulo `condo_people` (`domain`/`application`/
`infrastructure`, mesmo padrão de `resident_tickets`/`settings`):

- **`Unit`**: número, andar, tipo (apartamento/cobertura/etc.), status derivado de ter ou não pessoa
  vinculada. Sem fração ideal nem geração em lote nesta v1 (decisão 6).
- **`CondoPerson`**: documento (CPF/CNPJ), tipo PF/PJ, nome, contato, papel (`CondoRole` —
  `SINDICO, SUBSINDICO, CONSELHEIRO, MORADOR, FORNECEDOR, ZELADOR, ADMINISTRADORA, CONSTRUTORA`),
  detalhe condicional ao papel, unidade opcional, mandato (início/fim opcional), remunerado, aprova
  orçamentos (metadado, decisão 4). Papel `FORNECEDOR` referencia `Supplier` existente por FK, sem
  duplicar cadastro (decisão 1). FK opcional `user_id` para quando a pessoa também loga no sistema
  (síndico/conselheiro tipicamente; morador tipicamente não).

Tela nova `/pessoas`, abas Gestão/Conselho/Moradores/Fornecedores/Unidades, todas lendo da mesma
listagem filtrada por papel, com formulário único "Adicionar pessoa" (campo Detalhe condicional ao
Papel selecionado).

**Decisão importante**: `CondoPerson` é cadastro puramente informativo nesta entrega — nenhuma
automação existente passa a consumi-lo (`ResidentTicket` continua com nome/telefone em texto livre,
decisão 3; "Aprova orçamentos" não bloqueia nada, decisão 4). Serve de base para o EPIC-040
(esteira de identidade do morador via WhatsApp), que cria `CondoPerson`/`Unit` programaticamente a
partir da aprovação do síndico.

---

## Contexto Técnico

- `role_detail` varia por `role` (ex. Síndico: Profissional/Morador/Morador remunerado; Morador:
  Proprietário/Inquilino; Fornecedor: Prestador recorrente/avulso; Subsíndico/Zelador/Administradora/
  Construtora: sem detalhe, decisão 5). Validação no backend (enum Java por papel ou mapa
  `role → Set<detalhe válido>`), nunca em `@Valid`/Bean Validation — mesmo motivo já documentado em
  `organization-settings-module-design.md`: o `GlobalExceptionHandler` devolve 422 para erro de Bean
  Validation, e aqui a intenção é 400 (erro de regra).
- `Supplier` (`supplier/domain/Supplier.java`, EPIC-028) é reaproveitado por FK quando `role=
  FORNECEDOR` — nome/documento/contato vêm do `Supplier`, não duplicados em `CondoPerson`.
- `DELETE` é soft: muda `status` para `INATIVO`, nunca `deleted_at` — mesmo padrão de
  `Supplier.marketplaceEnabled` como flag de estado.
- Multi-tenant (`X-Org-Id`), permissão `ADMIN`/`SYNDIC` — mesmo padrão do módulo de configurações
  (EPIC-038).
- Migrations novas: confirmar o número exato no momento da implementação (checar o que já foi
  mergeado desde `V129`, usada por `CommonArea` no EPIC-038).

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-380](../tasks/TASK-380.md) | Backend: `Unit` — entidade, migration e repositório | BACKEND | 🟠 Alto |
| [TASK-381](../tasks/TASK-381.md) | Backend: `CondoPerson` — entidade, migration e repositório | BACKEND | 🟠 Alto |
| [TASK-382](../tasks/TASK-382.md) | Backend: `Unit` — DTOs, serviço CRUD e API | BACKEND | 🟠 Alto |
| [TASK-383](../tasks/TASK-383.md) | Backend: `CondoPerson` — DTOs, serviço CRUD e API (validação de `role_detail`, FK `Supplier`/`User`) | BACKEND | 🟠 Alto |
| [TASK-384](../tasks/TASK-384.md) | Frontend: tela `/pessoas` — abas Gestão/Conselho/Moradores/Fornecedores + formulário "Adicionar pessoa" | FRONTEND | 🟠 Alto |
| [TASK-385](../tasks/TASK-385.md) | Frontend: aba Unidades (listar, criar, editar) | FRONTEND | 🟠 Alto |
| [TASK-386](../tasks/TASK-386.md) | Frontend: entrada "Pessoas e Papéis" no menu do usuário | FRONTEND | 🟡 Médio |

Ordem: TASK-380 e TASK-381 em paralelo (independentes) → TASK-382 (depende da 380) e TASK-383
(depende da 381 e, se `role=FORNECEDOR`, do cadastro de `Supplier` já existente), também em
paralelo entre si → TASK-384 (depende da 383) → TASK-385 (depende da 382 e da 384, que cria a
página) → TASK-386 (depende da 384 existir).

---

## Critério de Conclusão do Épico

- [ ] `units`/`condo_people` persistem e isolam por `organization_id` corretamente
- [ ] `ADMIN`/`SYNDIC` conseguem criar/editar/inativar; `TECH`/`READER` recebem `403`
- [ ] Combinação inválida de `role`/`role_detail` é rejeitada com `400`, não 500/422
- [ ] Papel `FORNECEDOR` só aceita `supplier_id` de fornecedor já existente na organização
- [ ] Tela `/pessoas` reflete as 5 abas do protótipo, com formulário condicional ao papel
- [ ] `mvn test`/`npm run build`/`tsc --noEmit` sem regressão
- [ ] QA manual: cadastrar pessoa de cada papel (incluindo Fornecedor vinculado e Síndico com
      `user_id`), cadastrar/editar unidade, vincular pessoa a unidade

## Fora de Escopo
- Qualquer automação consumindo `CondoPerson`/`Unit` (ex. `ResidentTicket` com protocolo nominal,
  enforcement de "Aprova orçamentos", alerta de fim de mandato).
- Fração ideal e geração em lote de unidades.
- Mudança no enum `Role` (perfil de login) para cobrir `CONSELHEIRO` — decisão de permissão de app
  fica fora desta spec, revisitar quando alguma feature precisar.

## Riscos
Baixo — módulo novo, isolado, sem alterar fluxo/entidade existente. Risco de produto: as 6 decisões
da spec foram tomadas direto por Douglas, sem validar com o sócio Tiago (que desenhou o protótipo
original) — a mais arbitrária (Subsíndico sem detalhe, decisão 5) é a mais sujeita a mudar se ele
revisar depois; reversível sem redesenho grande.
