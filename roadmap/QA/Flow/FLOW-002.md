# FLOW-002 — Isolamento Multi-Tenant

## Criticidade
🔴 CRITICAL

## Launch Relevance
Vazamento de dados entre tenants é o risco jurídico e reputacional mais severo de um SaaS B2B multi-tenant.

## Tasks Relacionadas
- TASK-009 — Validar X-Org-Id contra claims do JWT
- TASK-017 — Enforcement automático de tenant no repository

## Descrição do Fluxo

Cada request autenticado carrega o header `X-Org-Id`. O filtro de autenticação valida que o `orgCode` no header pertence às organizações do usuário autenticado (JWT claims). Se não pertencer, retorna 403. No nível de banco de dados, o Hibernate `@Filter` ativo via `TenantContext` garante que queries só retornem dados do tenant correto, mesmo sem filtro explícito no código.

## Camadas Impactadas
- **Backend:** Filtro de tenant/autenticação, `TenantContext`, `TenantFilterInterceptor`, entidades JPA com `@Filter`
- **Segurança:** IDOR (Insecure Direct Object Reference) entre tenants

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| X-Org-Id válido do próprio usuário → 200 | Happy path | Implícito nos fluxos de produto |
| X-Org-Id de outra organização → 403 | Segurança | Manual (TASK-009 critérios) |
| Query em repositório sem TenantContext → exceção | Fail-fast | Manual (TASK-017) |
| Listagem retorna apenas registros do tenant ativo | Isolamento | Manual |
| Usuário admin de plataforma (se existir) → escopo especial | Autorização | A validar |

## Validação Recomendada
- **Manual:** [MTD-002](../MTD/MTD-002.md)
- **Automatizada:** [TASK-QA-AUTO-001](../tasks/TASK-QA-AUTO-001.md) — prioritário para TASK-026

## Gaps
- Nenhum teste automatizado de regressão de IDOR atualmente
- Endpoints futuros criados sem `@Filter` passariam despercebidos sem suite de integração

## Status de Validação
- [ ] X-Org-Id cross-tenant → 403 testado manualmente
- [ ] Filtro Hibernate validado no banco
- [ ] Fail-fast sem TenantContext validado
- [ ] Testes de integração criados (TASK-QA-AUTO-001)
