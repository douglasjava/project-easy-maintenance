# FLOW-009 — Soft Delete e Histórico Regulatório

## Criticidade
🟡 MEDIUM

## Launch Relevance
Compliance regulatório — clientes do nicho de manutenção podem ser auditados e precisam provar histórico de execuções.

## Tasks Relacionadas
- TASK-018 — Soft delete nas entidades críticas

## Descrição do Fluxo

Quando um usuário deleta um item de manutenção, um registro de manutenção ou um usuário, o sistema NÃO remove o registro do banco. Em vez disso, preenche o campo `deleted_at` com o timestamp atual. O Hibernate `@Where(clause = "deleted_at IS NULL")` aplicado nas entidades JPA garante que registros deletados não apareçam nas listagens normais da aplicação.

## Entidades com Soft Delete
- `MaintenanceItem` (itens de manutenção)
- `Maintenance` (registros de execução)
- `User` (usuários)
- `Organization` (organizações)

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| DELETE item → `deleted_at` preenchido no banco | Backend | Manual (TASK-018) |
| GET /items após delete → item não aparece | Filtro | Manual |
| Manutenções do item deletado → preservadas no banco | Compliance | Manual |
| Histórico de compliance de usuário deletado → preservado | LGPD/Compliance | Manual |
| Filtro `@Where` automático em todos os repositórios JPA | Arquitetura | Integração (gap) |
| Admin pode ver/restaurar deletados (fase futura) | Produto | Não implementado |

## Validação Recomendada
- **Manual:** [MTD-007](../MTD/MTD-007.md)
- **Automatizada:** [TASK-QA-AUTO-005](../tasks/TASK-QA-AUTO-005.md)

## Gaps
- Sem teste automatizado de filtro `@Where`
- Restauração de registros deletados não implementada (fase 3)
- Admin tool para visualizar registros deletados não existe

## Status de Validação
- [ ] Soft delete validado manualmente para todas as entidades críticas
- [ ] Histórico de manutenções preservado após delete de item
- [ ] TASK-QA-AUTO-005 criada para cobrir com integração
