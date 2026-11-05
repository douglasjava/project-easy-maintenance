# FLOW-012 — Pessoas e Papéis (Governança do Condomínio)

## Criticidade
🟠 HIGH

## Launch Relevance
Primeiro módulo de cadastro de governança do condomínio (síndico/conselho/moradores/fornecedores/
unidades). Não é launch-blocker em si (puramente informativo, decisão 3 da spec — nenhuma
automação existente consome ainda), mas é a base de dados de EPIC-040 (esteira de aprovação de
identidade do morador via WhatsApp) — um bug de isolamento ou de validação aqui propaga para lá.

## Tasks Relacionadas
- TASK-380 — Backend: `Unit` — entidade, migration V131 e repositório
- TASK-381 — Backend: `CondoPerson` — entidade, migration V132, enum `CondoRole` e repositório
- TASK-382 — Backend: `Unit` — DTOs, serviço CRUD e API
- TASK-383 — Backend: `CondoPerson` — DTOs, serviço CRUD e API
- TASK-384 — Frontend: tela `/pessoas` — abas e formulário "Adicionar pessoa"
- TASK-385 — Frontend: aba Unidades (listar, criar, editar)
- TASK-386 — Frontend: entrada "Pessoas e Papéis" no menu do usuário

## Descrição do Fluxo

Duas entidades novas por organização (`Unit`, `CondoPerson`), expostas via `GET`/`POST`/`PUT`
`/organizations/units` e `GET`/`POST`/`PUT`/`DELETE` `/organizations/condo-people`, e consumidas
pela tela `/pessoas` (abas Gestão/Conselho/Moradores/Fornecedores/Unidades). `CondoPerson.role`
determina um `role_detail` válido (matriz fixa por papel, validada no backend, nunca em
`@Valid`/Bean Validation — combinação inválida deve retornar `400`, não 422/500). Papel
`FORNECEDOR` referencia um `Supplier` já existente por FK (não duplica cadastro); demais papéis
rejeitam `supplier_id` preenchido. `DELETE` é soft (`status` → `INATIVO`, nunca `deleted_at`).
Permissão `ADMIN`/`SYNDIC`; `TECH`/`READER` devem receber `403`.

## Camadas Impactadas
- **Backend:** módulo novo `condo_people` (`domain`/`application`/`infrastructure`), migrations
  V131/V132, `UnitService`, `CondoPersonService`, FK para `Supplier` (EPIC-028) e `User`
  (`org_users`)
- **Frontend:** rota nova `/pessoas`, 5 abas, formulário condicional ao papel, item novo no menu do
  usuário
- **Segurança:** multi-tenant (`X-Org-Id`), permissão `ADMIN`/`SYNDIC` vs. `403` para `TECH`/`READER`
- **Integração:** nenhuma automação existente consome `CondoPerson`/`Unit` nesta entrega (decisão 3
  da spec) — base de dados para o EPIC-040 (identidade de morador via WhatsApp)

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|-----------------|
| Criar pessoa de cada papel com `role_detail` válido | Happy path | Manual (MTD-009) |
| Combinação `role`/`role_detail` inválida → 400 (não 422/500) | Regra de negócio | Manual (MTD-009) |
| `role=FORNECEDOR` sem `supplier_id`, ou de outra organização → 400 | Regra de negócio | Manual (MTD-009) |
| `role≠FORNECEDOR` com `supplier_id` preenchido → 400 | Regra de negócio | Manual (MTD-009) |
| `DELETE` muda `status` para `INATIVO`, registro continua existindo | Soft state | Manual (MTD-009) |
| Número de unidade duplicado na mesma organização → 400 | Constraint única | Manual (MTD-009) |
| Isolamento multi-tenant: `GET` só retorna dados da organização autenticada | Segurança / IDOR | Manual (MTD-009) |
| `TECH`/`READER` → 403 em todos os endpoints de `Unit`/`CondoPerson` | Autorização | Manual (MTD-009) |
| Campo Detalhe (frontend) muda conforme Papel selecionado | UI | Manual (MTD-009) |
| Unidade com `CondoPerson` vinculado exibe nome+papel; sem vínculo exibe "vaga" | UI | Manual (MTD-009) |

## Validação Recomendada
- **Manual:** [MTD-009](../MTD/MTD-009.md)
- **Automatizada:** [TASK-QA-AUTO-009](../tasks/TASK-QA-AUTO-009.md)

## Gaps
- Nenhum teste automatizado de integração ainda para a matriz `role`/`role_detail` (combinações
  válidas/inválidas) nem para o isolamento multi-tenant dos endpoints novos.
- Sem teste automatizado de regressão da constraint única `(organization_id, number)` em `units`.
- `CondoPerson.user_id` ficar `NULL` quando o `User` é removido da organização é regra de
  sincronização descrita na spec, mas não implementada nesta entrega (fora do escopo de TASK-383) —
  não há o que testar ainda; registrar como gap de produto, não de QA.

## Status de Validação
- [ ] Criar pessoa de cada papel (incluindo Fornecedor vinculado e Síndico com `user_id`)
- [ ] Combinação `role`/`role_detail` inválida rejeitada com 400
- [ ] `FORNECEDOR` sem/`supplier_id` de outra organização rejeitado
- [ ] Soft delete (`INATIVO`) confirmado
- [ ] Unidade duplicada rejeitada
- [ ] Isolamento multi-tenant confirmado
- [ ] `403` para `TECH`/`READER` confirmado
- [ ] Frontend: abas, campo Detalhe condicional, mobile
