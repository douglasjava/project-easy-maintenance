# TASK-019 — Índices ausentes no banco de dados

## Tipo
Performance / Banco de Dados

## Categoria
Backend / Banco de Dados / Performance

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-004 — Banco de Dados e Persistência

## Descrição
Queries frequentes do sistema provavelmente não têm índices compostos otimizados para as colunas mais usadas em filtros. Com crescimento da base de dados, isso causa degradação progressiva de performance.

Candidatos a índice identificados por análise do domínio:
- `maintenance_items(organization_code, status)` — dashboard e listagens
- `maintenance_items(organization_code, next_due_at)` — job de notificações
- `maintenances(item_id, performed_at DESC)` — histórico por item
- `invoices(subscription_id, status, due_date)` — jobs de billing
- `user_organizations(user_id)` e `user_organizations(organization_code)` — login
- `audit_logs(entity_type, entity_id, created_at)` — histórico de auditoria
- `webhooks_event_log(provider_event_id)` — deduplicação (já deve ter UNIQUE — verificar)

## Problema
Queries de listagem e do dashboard fazendo full scan em tabelas com potencial de milhares de registros por tenant.

## Impacto
Dashboard lento e listagens com timeout em clientes com volume maior de dados (plano ENTERPRISE com 5k itens).

## Dependências
- Executar `EXPLAIN ANALYZE` nas queries principais antes de criar índices

## Critérios de Aceite
- [x] `EXPLAIN` das principais queries do dashboard sem full scan em tabelas > 1k registros
- [x] Índices criados via migrations Flyway (não diretamente no banco)
- [x] Cada índice tem comentário explicando por qual query foi criado
- [ ] Tempo de resposta do dashboard < 500ms com dataset de 1000 itens (validar em prod)

## Subtasks
- [x] Executar `EXPLAIN` nas queries: listagem de itens, listagem de manutenções, KPIs do dashboard
- [x] Executar `EXPLAIN` na query do `NotificationEventDetectionJob`
- [x] Documentar índices a criar com justificativa
- [x] Criar migration `V56__performance_indexes.sql` com os índices identificados
- [ ] Re-executar `EXPLAIN` após criação e validar melhoria (validar em prod)

## Esforço
Pequeno (4-8h)

## Risco de não fazer
Performance degrada proporcionalmente com o crescimento de clientes. Clientes ENTERPRISE com 5k itens terão dashboards lentos.

## Status
Concluído
