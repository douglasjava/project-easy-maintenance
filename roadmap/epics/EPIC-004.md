# EPIC-004 — Banco de Dados e Persistência

## Status
Parcial — 3/4 tasks entregues (TASK-035 — retenção audit_logs — pendente)

## Objetivo
Garantir que o banco de dados suporte o crescimento do SaaS sem degradação de performance, com integridade histórica e esquema evoluível.

## Descrição
O banco está bem modelado para o domínio, mas existem lacunas que vão se tornar problemas com o crescimento: deleção hard sem histórico (perda de registros regulatórios), ausência de índices em queries frequentes de tenant, features de billing armazenadas como JSON sem schema, e crescimento ilimitado de tabelas de audit e webhook.

## Impacto no Produto
- **Sem este épico:** Dados de manutenção deletados são irrecuperáveis (problema regulatório). Performance degrada com volume. Mudança de estrutura de planos pode quebrar silenciosamente.
- **Com este épico:** Banco preparado para os primeiros 12-18 meses de crescimento.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-018 | Soft delete nas entidades críticas | 🟡 Médio | 2 |
| TASK-019 | Índices ausentes no banco de dados | 🟡 Médio | 2 |
| TASK-020 | Schema formal para features JSON em billing_plans | 🟡 Médio | 2 |
| TASK-035 | Política de retenção para audit_logs | 🔵 Baixo | 2 |

## Critério de Conclusão do Épico
- [ ] Entidades críticas (items, maintenances, users, orgs) têm soft delete com campo `deleted_at`
- [ ] EXPLAIN das queries do dashboard e listagens sem full scan em tabelas > 1k rows
- [ ] Features de billing_plans têm validação formal no código ao deserializar
- [ ] Política de retenção de audit_logs implementada (ex: purge após 2 anos)
