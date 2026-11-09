# TASK-383 — BACKEND: `CondoPerson` — DTOs, serviço CRUD e API

## Tipo
BACKEND

## Categoria
Pessoas e Papéis

## Prioridade
🟠 Alto

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Sim — cadastrar pessoa de cada papel (incluindo Fornecedor vinculado a `Supplier` existente e
Síndico com `user_id`), confirmar rejeição de `role_detail` inválido para o papel, confirmar
isolamento por organização.

---

## Contexto
Expõe `CondoPerson` (TASK-381) via API autenticada — o CRUD central da tela `/pessoas`. Detalhe
completo na spec de Pessoas e Papéis, seções "Modelo de dados proposto" e "API (rascunho)".

## Escopo
- `GET /organizations/condo-people?role=` — lista, filtro opcional por papel (cobre as abas
  Gestão/Conselho/Moradores/Fornecedores sem endpoint por aba).
- `POST /organizations/condo-people` — cria.
- `PUT /organizations/condo-people/{id}` — atualiza.
- `DELETE /organizations/condo-people/{id}` — soft (muda `status` para `INATIVO`, nunca
  `deleted_at`).
- Validação de `role_detail` por `role` no backend (mapa `role → Set<detalhe válido>`, decisão 5 da
  spec: `SUBSINDICO`/`ZELADOR`/`ADMINISTRADORA`/`CONSTRUTORA` não aceitam nenhum `role_detail`,
  `SINDICO` aceita `PROFISSIONAL`/`MORADOR`/`MORADOR_REMUNERADO`, `CONSELHEIRO` aceita
  `FISCAL`/`CONSULTIVO`, `MORADOR` aceita `PROPRIETARIO`/`INQUILINO`, `FORNECEDOR` aceita
  `RECORRENTE`/`AVULSO`) — combinação inválida lança `RuleException` → `400`.
- `role=FORNECEDOR` exige `supplier_id` de um `Supplier` já existente na organização (decisão 1);
  qualquer outro papel rejeita `supplier_id` preenchido.
- `user_id`, quando preenchido, deve referenciar um `User` da mesma organização; ao remover o
  `User` da organização, `user_id` em `CondoPerson` deve virar `NULL` (regra de sincronização da
  spec, decisão 2 — já fechada antes desta entrega) — fora do escopo desta task implementar o
  gatilho de remoção de `User` em si; só garantir que `CondoPerson.user_id` aceita `NULL`.
- Permissão `ADMIN`/`SYNDIC`, mesmo padrão de TASK-382. Tenant scoping explícito.

## Critérios de Aceite
- [ ] `POST` com `role`/`role_detail` válidos persiste corretamente
- [ ] `POST` com combinação `role`/`role_detail` inválida retorna `400`, não 500/422
- [ ] `POST` com `role=FORNECEDOR` sem `supplier_id`, ou com `supplier_id` de outra organização,
      retorna `400`
- [ ] `POST` com `role≠FORNECEDOR` e `supplier_id` preenchido retorna `400`
- [ ] `DELETE` muda `status` para `INATIVO`, registro continua existindo e consultável
- [ ] `GET ?role=MORADOR` retorna só pessoas desse papel, isoladas por organização
- [ ] `TECH`/`READER` recebem `403` nos quatro endpoints
- [ ] `mvn test` sem regressão

## Dependências
TASK-381 (entidade/repositório). Depende também do cadastro de `Supplier` (EPIC-028, já existente)
para validar `supplier_id`. Desbloqueia TASK-384 (frontend).

## Riscos
Validação de `role_detail` por papel é a parte com mais lógica de regra desta task — cobrir todas
as combinações válidas/inválidas em teste, não só um caso feliz por papel.

## Esforço
Médio

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (api), testes verdes (incluindo matriz de role/role_detail), aguardando push/PR e QA manual.
