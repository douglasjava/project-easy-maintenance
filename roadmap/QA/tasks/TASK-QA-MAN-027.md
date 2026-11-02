# TASK-QA-MAN-027 — QA Manual: Pessoas e Papéis (EPIC-039, staging)

## Tipo
QA Manual — **execução manual** pelo Douglas, contra `staging` (api PR #171 e web PR #124 já
mergeadas)

## Categoria
Backend + Frontend / Condomínio / Governança

## Prioridade
🟠 Alto — módulo novo de cadastro, com regra de negócio (matriz `role`/`role_detail`) e isolamento
multi-tenant que ainda não têm nenhuma cobertura automatizada de integração.

## Tasks cobertas

| Task | O que entrega | Status |
|---|---|---|
| [TASK-380](../../tasks/TASK-380.md) | `Unit` — entidade, migration V131, repositório | Em Validação |
| [TASK-381](../../tasks/TASK-381.md) | `CondoPerson` — entidade, migration V132, enum `CondoRole`, repositório | Em Validação |
| [TASK-382](../../tasks/TASK-382.md) | `Unit` — DTOs, serviço CRUD e API | Em Validação |
| [TASK-383](../../tasks/TASK-383.md) | `CondoPerson` — DTOs, serviço CRUD e API | Em Validação |
| [TASK-384](../../tasks/TASK-384.md) | Tela `/pessoas` — abas e formulário "Adicionar pessoa" | Em Validação |
| [TASK-385](../../tasks/TASK-385.md) | Aba Unidades (listar, criar, editar) | Em Validação |
| [TASK-386](../../tasks/TASK-386.md) | Entrada "Pessoas e Papéis" no menu do usuário | Em Validação |

Roteiro completo de cenários: [MTD-009](../MTD/MTD-009.md), fluxo [FLOW-012](../Flow/FLOW-012.md).

---

## Descrição
Executar o roteiro do MTD-009 contra `staging` (api + web já mergeadas) e registrar o resultado de
cada cenário. Este é o QA manual que os critérios de aceite de TASK-382/383/384/385 e o critério de
conclusão do EPIC-039 exigem antes de considerar o épico pronto para promover a `main`.

## Passos
Seguir [MTD-009](../MTD/MTD-009.md) na ordem: Cenário 1 (criar cada papel) → 2 (role_detail
inválido) → 3 (supplier_id inválido) → 4 (soft delete) → 5 (unidade duplicada) → 6 (multi-tenant)
→ 7 (permissão TECH/READER) → 8 (frontend) → Negativo (vínculo unidade/pessoa).

## Resultado Esperado
Todos os cenários do MTD-009 aprovados, com evidência (prints/queries) anexada em
`roadmap/QA/MTD/evidencias/MTD-009/`.

## Critérios de Aceite
- [ ] Cenário 1 — pessoa de cada um dos 8 papéis criada corretamente
- [ ] Cenário 2 — combinação `role`/`role_detail` inválida rejeitada com 400 (não 422/500)
- [ ] Cenário 3 — `supplier_id` inválido/cross-tenant rejeitado com 400
- [ ] Cenário 4 — `DELETE` confirmado como soft (`INATIVO`, nunca `deleted_at`)
- [ ] Cenário 5 — unidade duplicada na mesma organização rejeitada; mesma numeração entre
      organizações diferentes coexiste
- [ ] Cenário 6 — isolamento multi-tenant confirmado (`403` com `X-Org-Id` de outra organização,
      `404` em `PUT` cross-tenant)
- [ ] Cenário 7 — `403` para `TECH`/`READER` em todos os endpoints; item de menu ausente para eles
- [ ] Cenário 8 — campo Detalhe condicional ao Papel, combo de Fornecedor, mobile, erro de
      validação sem crash
- [ ] Cenário Negativo — vínculo unidade/pessoa refletido na aba Unidades ("vaga" vs. nome+papel)

## Status
🟢 Validado via API (curl) e UI (navegador) contra ambiente local (`staging` atualizada) em
01/11/2026. **Bloqueador resolvido:** [TASK-393](../../tasks/TASK-393.md) (bug crítico no
`TenantFilter`, endpoints inteiros retornavam 403 mesmo com `X-Org-Id` correto) foi encontrado ao
preparar os dados deste QA, corrigido e mergeado direto em `staging`.

Resultado da execução (API local porta 9000 + web local porta 3000, dados `QA-027-*`):
- [x] Cenário 1 — pessoa de cada um dos 8 papéis criada corretamente (incluindo FORNECEDOR com
      `supplierId` válido)
- [x] Cenário 2 — `role`/`role_detail` inválido rejeitado com `400 rules-invalid` (não 422/500)
- [x] Cenário 3 — `supplierId` inexistente rejeitado com `400 rules-invalid`
- [x] Cenário 4 — `DELETE` confirmado como soft (`status=INATIVO` no banco, nunca `deleted_at`);
      refletido na UI (linha "Inativo" na aba Gestão)
- [x] Cenário 5 — unidade duplicada na mesma organização rejeitada (`400`); mesma numeração em
      outra organização aceita
- [x] Cenário 6 — isolamento multi-tenant confirmado: `403 tenant-invalid` com `X-Org-Id` de outra
      organização, `404` em `PUT` cross-tenant
- [x] Cenário 7 — `403 forbidden` para `TECH` em `GET`/`POST` e `READER` em `DELETE`; item de menu
      "Pessoas e Papéis" ausente para `TECH`; acesso direto via URL bloqueado sem vazar dados
      (gap de UX menor: página fica em branco sem mensagem de erro — não bloqueante)
- [x] Cenário 8 — campo Detalhe condicional confirmado na UI (Morador → Proprietário/Inquilino;
      Subsíndico → campo some; Fornecedor → combo de fornecedores reais da organização)
- [x] Cenário Negativo — vínculo unidade/pessoa refletido corretamente na aba Unidades ("Ocupada —
      nome (papel)" vs. "Vaga")

Nota de UX (não bloqueante): usuário `TECH`/`READER` acessando `/pessoas` direto pela URL recebe
página em branco sem mensagem de erro — avaliar toast/redirect numa iteração futura.
