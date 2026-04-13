# TASK-QA-AUTO-005 — Testes de Integração: Soft Delete e Filtro Automático de Listagens

## Tipo
QA Automatizada — Integração (API + Banco)

## Categoria
Banco de Dados / Compliance / Backend

## Prioridade
🟡 Médio

## Épico
EPIC-004 / EPIC-008 — Banco de Dados + Qualidade e Testes

## Flow relacionado
[FLOW-009](../Flow/FLOW-009.md)

## Descrição
Criar testes de integração com TestContainers (MySQL) verificando que:
1. A deleção de entidades críticas preenche `deleted_at` (não remove o registro físico)
2. Registros com `deleted_at IS NOT NULL` não aparecem nas listagens da API
3. O filtro automático `@Where` do Hibernate está ativo para todas as entidades com soft delete

## Justificativa para Automatização
- Soft delete é requisito de compliance regulatório — regressão causaria perda de dados de clientes sem alerta
- `@Where` do Hibernate pode ser removido acidentalmente em merge/rebase sem aviso de compilação
- Filtro automático é transparente ao código — só detectável em teste de integração com banco real

## Tecnologias
- JUnit 5
- MockMvc
- TestContainers (MySQL)
- `@SpringBootTest(webEnvironment = RANDOM_PORT)`
- JdbcTemplate para verificação direta no banco

## Cobertura Esperada

### Soft delete correto (não remove fisicamente)
- [ ] DELETE /items/{id} → HTTP 200/204 + registro existe no banco com `deleted_at IS NOT NULL`
- [ ] DELETE /maintenances/{id} → mesmo comportamento
- [ ] DELETE /users/{id} → mesmo comportamento

### Filtro automático de listagem
- [ ] GET /items após deleção de 1 item → item deletado não aparece na lista
- [ ] GET /maintenances após deleção → manutenção deletada não aparece
- [ ] Contagem da API = contagem SQL com `WHERE deleted_at IS NULL`

### Integridade histórica
- [ ] Deletar item que tem manutenções associadas → manutenções permanecem no banco (`deleted_at IS NULL`)
- [ ] Deletar usuário → manutenções criadas por ele permanecem no banco

### Fail-fast sem TenantContext (TASK-017)
- [ ] Chamada direta a repositório JPA sem TenantContext populado → lança exceção esperada (verificar tipo de exceção)

## Subtasks
- [ ] Criar classe `SoftDeleteIT`
- [ ] Criar fixture com entidades inter-relacionadas (item → manutenções)
- [ ] Implementar helper para consulta direta no banco via JdbcTemplate (contornar filtro Hibernate para verificação)
- [ ] Integrar na suite de CI como parte do módulo de testes de banco

## Esforço Estimado
Médio (5-8h)

## Dependências
- TestContainers configurado (coordenar com TASK-026)
- Migrations Flyway rodando no contexto de teste

## Status
Pendente — implementar durante SPRINT-03 (junto com TASK-026)
