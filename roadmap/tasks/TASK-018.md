# TASK-018 — Soft delete nas entidades críticas

## Tipo
Débito técnico / Produto

## Categoria
Backend / Banco de Dados

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-004 — Banco de Dados e Persistência

## Descrição
A deleção de entidades críticas (itens de manutenção, registros de manutenção, usuários) parece ser hard delete — os registros são permanentemente removidos do banco. Para um produto de compliance regulatório, isso é problemático: um cliente pode precisar provar que realizou manutenções de um item que depois foi removido, ou um administrador pode deletar um usuário acidentalmente.

Soft delete adiciona um campo `deleted_at` à entidade e apenas marca o registro como deletado, sem removê-lo do banco.

## Problema
Hard delete:
- Impossibilita recuperação de dados deletados acidentalmente
- Quebra histórico de audit trail (manutenção de item deletado some)
- Pode violar requisitos regulatórios (LGPD, normas de compliance)
- Foreign Key violations em cascade delete podem causar perda de dados relacionados

## Impacto
- Risco de perda de histórico regulatório de compliance
- Impossibilidade de "desfazer" deleções acidentais

## Dependências
- Deve ser feito antes de crescimento significativo de dados (mais difícil de migrar depois)

## Critérios de Aceite
- [ ] Entidades com soft delete: `MaintenanceItem`, `Maintenance`, `User`, `Organization`
- [ ] Campo `deleted_at TIMESTAMP NULL` adicionado às tabelas via migration Flyway
- [ ] Hibernate `@Where(clause = "deleted_at IS NULL")` nas entidades para filtro automático
- [ ] Endpoint de delete muda de DELETE físico para `UPDATE ... SET deleted_at = NOW()`
- [ ] API de listagem NÃO retorna registros deletados (filtro automático)
- [ ] Admin consegue ver registros deletados via endpoint específico (opcional, fase 3)

## Subtasks
- [ ] Criar migration `V55__soft_delete_columns.sql` com `ALTER TABLE` nas entidades listadas
- [ ] Adicionar `@Where(clause = "deleted_at IS NULL")` nas entidades JPA
- [ ] Modificar métodos de deleção nos services para soft delete
- [ ] Testar que registros deletados não aparecem em listagens normais
- [ ] Testar que deleção é reversível (manual via banco — admin tool, fase 3)

## Esforço
Médio (1 dia)

## Risco de não fazer
Cliente deleta item de manutenção acidentalmente e perde todo o histórico de compliance — potencial problema legal em segmentos regulados.

## Status
Concluído
