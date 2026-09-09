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

- [x] Cadastrar CNPJ novo cria `Supplier` + vínculo, `registrationCount = 1`
- [x] Cadastrar CNPJ já existente (organização diferente) só cria vínculo, `registrationCount`
      incrementa, dado do fornecedor não muda
- [x] Cadastrar o mesmo CNPJ pela mesma organização duas vezes não soma pontuação de novo
      (idempotente)
- [x] Busca por `city`/`state`/`category` retorna resultado correto, ordenado por pontuação
- [x] Endpoints exigem autenticação (JWT + `X-Org-Id`), mesma regra do resto do sistema
- [x] Testes cobrindo dedup, idempotência e busca
- [x] `mvn test` sem regressão

## Dependências
TASK-241 (entidades/migration) precisa estar pronta.

## Riscos
Baixo — endpoints autenticados, mesmo padrão de segurança já usado em todo o resto do sistema.
Ponto de atenção real é a lógica de dedup/idempotência (testar bem os casos de concorrência —
mesmo CNPJ cadastrado quase ao mesmo tempo por duas organizações).

**Decisão de escopo sobre concorrência real** (dois `POST` simultâneos com o mesmo CNPJ, por
organizações diferentes, colidindo no mesmo instante): o serviço faz `findByCnpj` seguido de
`save()` numa única transação, sem lock otimista/retry — se as duas transações colidirem de
verdade no banco, a constraint `uk_suppliers_cnpj` (TASK-241) protege contra duplicidade de dado,
mas a segunda transação recebe uma exceção (500) em vez de silenciosamente virar um vínculo. Aceito
conscientemente para v1 (mesmo espírito do "risco aceito" já documentado no EPIC-028 pra qualidade
de dado) — a garantia de integridade vem do banco, não da aplicação; adicionar retry/lock otimista
fica pra se isso se provar um problema real em uso (volume de cadastro simultâneo do mesmo CNPJ é
baixo por natureza).

## Esforço
Médio

## Implementação

### Arquivos criados

| Arquivo | Descrição |
|---|---|
| `supplier/application/dto/RegisterSupplierRequest.java` | `cnpj` (`@NotBlank @CNPJ` — reaproveita `org.hibernate.validator.constraints.br.CNPJ`, já usado em `OrganizationDTO`/`BillingAccountDTO`), `name`, `phone`, `category`, `city`, `state` |
| `supplier/application/dto/SupplierRegistryResponse.java` | dado público do fornecedor + `registrationCount` — nunca expõe quem cadastrou |
| `supplier/application/service/SupplierRegistryService.java` | `register()` (dedup por cnpj, idempotência por `(supplierId, organizationId)`, nunca sobrescreve dado do primeiro cadastro) + `search()` (filtros opcionais, `city`/`state` default pra da organização logada) |
| `supplier/infrastructure/web/SupplierRegistryController.java` | `POST /suppliers` (201), `GET /suppliers?city=&state=&category=` — autenticados por padrão (`anyRequest().authenticated()` do `SecurityConfig`, nenhuma regra nova precisou ser adicionada) |
| `test/.../supplier/application/service/SupplierRegistryServiceTest.java` | 6 testes: cnpj novo cria supplier+vínculo com `registrationCount=1`; cnpj existente de outra org só vincula e não sobrescreve nome/telefone; mesma org cadastrando 2x é idempotente; sem `X-Org-Id` lança `TenantException`; busca usa `city`/`state` da organização quando filtro omitido; busca usa filtro explícito quando informado |

### Arquivos modificados
`supplier/infrastructure/persistence/SupplierRepository.java` — novo método `findByRegion` (`@Query`
JPQL, `category` opcional via `(:category IS NULL OR ...)`, ordenado por `registrationCount DESC,
name ASC` — segundo critério garante ordem determinística quando a pontuação empata).

### Decisões tomadas durante a implementação
- `resolveCurrentOrganization()` replica exatamente o padrão já usado em
  `ResidentTicketAdminService` (`TenantContext.get()` → `OrganizationRepository.findByCode` →
  `TenantException`/`NotFoundException`) — nenhum helper novo compartilhado, mesmo trade-off já
  aceito no resto do código (duplicação pequena, 2 ocorrências, não justifica extração ainda).
- `city`/`state` no `GET /suppliers` default pra da organização autenticada quando omitidos (usa
  `StringUtils.hasText`) — corresponde à leitura da spec ("mesmo `city`/`state` da organização do
  token, ou informado explicitamente").
- Concorrência real (dois cadastros do mesmo CNPJ ao mesmo tempo) não tem retry — ver nota em
  Riscos acima.

### Verificação
`mvn clean test` → **948/948, 0 falhas** (942 da TASK-241 + 6 novos testes desta task, sem
regressão).

Branch `feature/EPIC-028-supplier-registry` (mesma da TASK-241, decisão do Douglas de consolidar o
épico numa branch/PR só).

## Status
🟢 Implementado e testado (`mvn test` 948/948). QA obrigatório desta task (dedup + pontuação + não
sobrescrita) coberto por `SupplierRegistryServiceTest`; validação end-to-end contra a app rodando de
verdade fica pra a rodada de QA manual única no final do épico (junto com TASK-243), não nesta
sessão — não consegui subir a app local completa (faltam credenciais Asaas/Google Places no
ambiente desta sessão pra o boot do Spring Context).
