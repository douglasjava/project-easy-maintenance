# TASK-381 — BACKEND: `CondoPerson` — entidade, migration e repositório

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
Entidade central da spec: registro de governança do condomínio, independente de login. Detalhe
completo em `docs/superpowers/specs/2026-10-29-pessoas-papeis-governanca-design.md`, seção "Modelo
de dados proposto".

## Escopo
- Migration nova `condo_people` (número a confirmar, sequencial à de TASK-380):
  `id`, `organization_id` (BIGINT NOT NULL), `document` (VARCHAR(20) NULL), `person_type`
  (VARCHAR(2)), `name` (VARCHAR(200) NOT NULL), `email` (VARCHAR(160) NULL), `phone` (VARCHAR(20)
  NULL), `whatsapp_opt_in` (BOOLEAN NOT NULL DEFAULT FALSE), `role` (VARCHAR(20) NOT NULL),
  `role_detail` (VARCHAR(40) NULL), `unit_id` (BIGINT NULL, FK `units`), `supplier_id` (BIGINT
  NULL, FK `suppliers`), `user_id` (BIGINT NULL, FK `users`), `term_start`/`term_end` (DATE NULL),
  `paid` (BOOLEAN NOT NULL DEFAULT FALSE), `approves_budgets` (BOOLEAN NOT NULL DEFAULT FALSE),
  `status` (VARCHAR(10) NOT NULL DEFAULT 'ATIVO'), `created_at`/`updated_at`.
- Enum Java `CondoRole`: `SINDICO, SUBSINDICO, CONSELHEIRO, MORADOR, FORNECEDOR, ZELADOR,
  ADMINISTRADORA, CONSTRUTORA`.
- Entidade `CondoPerson` (módulo `condo_people`, pacote `domain`), FKs mapeadas como `Long` simples
  (sem `@ManyToOne` obrigatório, mesmo padrão de referência por id já usado em `ResidentTicket`) —
  decisão de implementação na task, consistente com o resto do módulo.
- `CondoPersonRepository extends JpaRepository<CondoPerson, Long>` com `List<CondoPerson>
  findByOrganizationIdAndRole(Long organizationId, String role)` e `Optional<CondoPerson>
  findByOrganizationIdAndPhoneAndRole(Long organizationId, String phone, String role)` (usado depois
  por TASK-388, EPIC-040, para checar se um telefone já é `MORADOR` reconhecido).

## Critérios de Aceite
- [ ] Migration cria a tabela `condo_people` com todas as colunas listadas
- [ ] `CondoPersonRepository` persiste e recupera por organização e por papel
- [ ] `findByOrganizationIdAndPhoneAndRole` encontra corretamente um `CondoPerson` existente e
      retorna vazio quando não existe
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma técnica própria, mas a FK `unit_id` referencia a tabela criada em TASK-380 — rodar depois
dela (mesma branch, migrations sequenciais). Desbloqueia TASK-383.

## Riscos
Baixo — entidade nova e isolada, sem alterar schema existente. Única atenção: a FK `supplier_id`
deve referenciar `suppliers` já existente (EPIC-028) sem exigir alteração nessa tabela.

## Esforço
Médio

## Status
Em Validação — implementado em `feature/EPIC-039-pessoas-papeis` (api), testes verdes, aguardando push/PR e QA.
