# TASK-QA-MAN-007 — Validação de Soft Delete e Integridade de Histórico

## Tipo
QA Manual

## Categoria
Banco de Dados / Compliance / Backend

## Prioridade
🟡 Médio

## Épico
EPIC-004 — Banco de Dados e Persistência

## Flow relacionado
[FLOW-009](../Flow/FLOW-009.md)

## Documento de Teste
[MTD-007](../MTD/MTD-007.md)

## Descrição
Validação manual do comportamento de soft delete nas entidades críticas. Verificar que deleção de itens, manutenções e usuários não remove fisicamente os registros do banco, que o histórico de compliance é preservado, e que registros deletados não aparecem nas listagens normais da aplicação.

Cobre a task TASK-018.

## Pré-condições
- Acesso ao banco de dados de staging via cliente MySQL (DBeaver, TablePlus ou linha de comando)
- Usuário com permissão para criar e deletar entidades
- Pelo menos 1 item com 3 manutenções criadas previamente

## Passos

### Passo 1 — Soft delete de item de manutenção
1. Anotar o `id` de um item com manutenções associadas
2. Deletar o item pela UI ou API (`DELETE /items/{id}`)
3. Verificar na UI: item não aparece em `/items`
4. Verificar no banco:
   ```sql
   SELECT id, name, deleted_at FROM maintenance_items WHERE id = {id};
   ```
5. Confirmar que `deleted_at IS NOT NULL`

### Passo 2 — Histórico de manutenções preservado
1. Com o item deletado do Passo 1, verificar no banco:
   ```sql
   SELECT id, item_id, performed_at, deleted_at 
   FROM maintenances 
   WHERE item_id = {id_do_item};
   ```
2. Confirmar que as manutenções existem e que `deleted_at IS NULL` nelas

### Passo 3 — Soft delete de usuário
1. Criar um usuário de teste com pelo menos 2 manutenções em seu nome
2. Deletar o usuário via UI (como admin) ou API
3. Verificar no banco: `SELECT id, name, email, deleted_at FROM users WHERE id = {id_usuario}`
4. Verificar que manutenções criadas pelo usuário permanecem:
   ```sql
   SELECT id, created_by, performed_at FROM maintenances WHERE created_by = {id_usuario};
   ```

### Passo 4 — Coluna deleted_at em todas as entidades críticas
Executar as queries de verificação:
```sql
SHOW COLUMNS FROM maintenance_items LIKE 'deleted_at';
SHOW COLUMNS FROM maintenances LIKE 'deleted_at';
SHOW COLUMNS FROM users LIKE 'deleted_at';
SHOW COLUMNS FROM organizations LIKE 'deleted_at';
```
Confirmar que todas as 4 tabelas possuem a coluna.

### Passo 5 — Filtro automático nas listagens
1. Criar 3 itens e anotar IDs
2. Deletar o 1º item
3. Fazer `GET /items` e contar os itens retornados (deve ser 2)
4. Verificar no banco que há 3 registros mas 1 com `deleted_at IS NOT NULL`

## Resultado Esperado
- Item deletado com `deleted_at` preenchido no banco (não removido fisicamente)
- Item não aparece na listagem da UI
- Manutenções associadas ao item deletado permanecem no banco
- Histórico de usuário deletado preservado
- Coluna `deleted_at` presente em todas as 4 tabelas críticas
- Listagem retorna apenas registros com `deleted_at IS NULL`

## Evidências Necessárias
- [ ] Screenshot da query SQL mostrando `deleted_at` preenchido
- [ ] Screenshot da UI sem o item deletado
- [ ] Screenshot das manutenções preservadas no banco
- [ ] Resultado das 4 queries SHOW COLUMNS

## Status
Pendente — executar na próxima sprint (não bloqueador de launch)
