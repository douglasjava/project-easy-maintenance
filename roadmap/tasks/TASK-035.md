# TASK-035 — Política de retenção para audit_logs

## Tipo
Banco de Dados / Operação

## Categoria
Backend / Banco de Dados

## Prioridade
🔵 Baixo

## Fase
2 — Pós-lançamento

## Épico
EPIC-004 — Banco de Dados e Persistência

## Descrição
A tabela `audit_logs` cresce indefinidamente. Cada operação de CREATE, UPDATE, DELETE em qualquer entidade gera um registro. Com múltiplos clientes e uso intensivo, essa tabela pode ter milhões de registros em 12-18 meses, impactando performance e custo de armazenamento.

## Critérios de Aceite
- [ ] Política de retenção definida (ex: 24 meses para logs de compliance, 6 meses para logs operacionais)
- [ ] Job semanal de purge que remove registros além da janela de retenção
- [ ] Estratégia de archiving para logs antigos (ex: exportar para S3 antes de deletar)
- [ ] Índice em `audit_logs(created_at)` para o job de purge ser eficiente

## Esforço
Pequeno (4-8h)

## Status
Backlog
