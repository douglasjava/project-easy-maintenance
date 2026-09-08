# TASK-242 — BACKEND: Endpoints `POST`/`GET /suppliers` (cadastro com dedup + busca por região)

## Tipo
BACKEND

## Categoria
Fornecedores / Cadastro

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Cadastro de Fornecedores pelos Usuários + Pontuação

## QA obrigatório
Sim — cadastrar o mesmo CNPJ por duas organizações diferentes e confirmar que não duplica, soma
pontuação corretamente, e que a segunda organização não sobrescreve os dados da primeira.

---

## Contexto

Camada de serviço/endpoints sobre as entidades da TASK-241. Detalhe completo em
`docs/superpowers/specs/2026-09-08-supplier-registry-design.md`.

## Escopo

- `application/service/SupplierRegistryService.java` (nome distinto de
  `SupplierLookupService`/`SupplierSearchService`, que continuam intocados):
  - Cadastro: recebe `cnpj`, `name`, `phone`, `category`, `city`, `state`. Se `Supplier` com esse
    CNPJ já existe: cria só o `SupplierOrganizationLink` pra organização atual (idempotente — se o
    vínculo já existir, não soma pontuação de novo), **não sobrescreve** dado existente. Se não
    existe: cria `Supplier` + `SupplierOrganizationLink`, `registrationCount = 1`.
  - Busca: lista `Supplier` por `city`/`state`/`category` (filtros opcionais), ordenado por
    `registrationCount` desc.
- `application/dto/`: `RegisterSupplierRequest`, `SupplierRegistryResponse`.
- `infrastructure/web/SupplierRegistryController.java` — `POST /suppliers`, `GET /suppliers`, ambos
  autenticados (JWT + `X-Org-Id`), mesmo padrão do resto do sistema.

## Critérios de Aceite

- [ ] Cadastrar CNPJ novo cria `Supplier` + vínculo, `registrationCount = 1`
- [ ] Cadastrar CNPJ já existente (organização diferente) só cria vínculo, `registrationCount`
      incrementa, dado do fornecedor não muda
- [ ] Cadastrar o mesmo CNPJ pela mesma organização duas vezes não soma pontuação de novo
      (idempotente)
- [ ] Busca por `city`/`state`/`category` retorna resultado correto, ordenado por pontuação
- [ ] Endpoints exigem autenticação (JWT + `X-Org-Id`), mesma regra do resto do sistema
- [ ] Testes cobrindo dedup, idempotência e busca
- [ ] `mvn test` sem regressão

## Dependências
TASK-241 (entidades/migration) precisa estar pronta.

## Riscos
Baixo — endpoints autenticados, mesmo padrão de segurança já usado em todo o resto do sistema.
Ponto de atenção real é a lógica de dedup/idempotência (testar bem os casos de concorrência —
mesmo CNPJ cadastrado quase ao mesmo tempo por duas organizações).

## Esforço
Médio

## Status
🔴 Não iniciada
