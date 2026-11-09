# TASK-380 — BACKEND: `Unit` — entidade, migration e repositório

## Tipo
BACKEND

## Categoria
Pessoas e Papéis

## Prioridade
🟠 Alto

## Épico
[EPIC-039](../epics/EPIC-039.md) — Pessoas e Papéis

## QA obrigatório
Não — coberto por teste de persistência (`@DataJpaTest`), sem fluxo de UI nesta task.

---

## Contexto
Base para o cadastro de unidades (apto/bloco) do condomínio. Detalhe completo em
`docs/superpowers/specs/2026-10-29-pessoas-papeis-governanca-design.md`, seção "Modelo de dados
proposto" (decisão 6: sem fração ideal nesta v1).

## Escopo
- Migration nova `units` (confirmar número exato — checar o que já foi mergeado desde `V129`):
  `id`, `organization_id` (BIGINT NOT NULL), `number` (VARCHAR(10) NOT NULL), `floor` (INTEGER
  NULL), `type` (VARCHAR(30) NULL), `created_at`/`updated_at`. `UNIQUE (organization_id, number)`.
- Entidade `Unit` (módulo `condo_people`, pacote `domain`), mesmo padrão Lombok/JPA de
  `ResidentTicket`.
- `UnitRepository extends JpaRepository<Unit, Long>` com `List<Unit> findByOrganizationId(Long
  organizationId)`.

## Critérios de Aceite
- [ ] Migration cria a tabela com a constraint única `(organization_id, number)`
- [ ] `UnitRepository` persiste e recupera por `organization_id`
- [ ] Duas unidades com o mesmo número na mesma organização são rejeitadas pela constraint
- [ ] Duas unidades com o mesmo número em organizações diferentes coexistem sem erro
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica. Desbloqueia TASK-382.

## Riscos
Baixo — entidade nova e isolada, sem alterar schema existente.

## Esforço
Pequeno

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (api), testes verdes, aguardando push/PR e QA.
