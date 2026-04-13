# EPIC-003 — Multi-tenancy e Autorização

## Status
Parcial — 3/4 tasks entregues (TASK-038 — LGPD — pendente, Fase 3)

## Objetivo
Garantir que o isolamento entre tenants seja robusto, automático e auditável, eliminando riscos de data leak entre organizações.

## Descrição
O sistema usa ThreadLocal (`TenantContext`) para isolar tenants por requisição, com annotations `@TenantRequired` nos serviços. Esse modelo funciona, mas depende de disciplina do desenvolvedor — um endpoint novo sem a annotation correta fica sem proteção. Além disso, o header `X-Org-Id` é enviado pelo frontend e pode ser manipulado se o backend não validar que o usuário autenticado pertence àquela organização. CORS e LGPD também fazem parte deste épico.

## Impacto no Produto
- **Sem este épico:** Risco de data leak entre tenants. Um cliente malicioso pode tentar acessar dados de outro cliente via manipulação de header.
- **Com este épico:** Isolamento garantido por arquitetura, não apenas por convenção.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-009 | Validar X-Org-Id contra claims do JWT | 🟠 Alto | 1 |
| TASK-014 | Restricão CORS para domínio de produção | 🟠 Alto | 1 |
| TASK-017 | Enforcement automático de tenant no repository | 🟡 Médio | 1 |
| TASK-038 | LGPD: exportação e exclusão de dados pessoais | 🔵 Baixo | 3 |

## Critério de Conclusão do Épico
- [ ] X-Org-Id é validado contra lista de organizações do JWT em cada request
- [ ] CORS configurado explicitamente para domínio(s) de produção
- [ ] Toda query JPA de entidade com tenant automaticamente filtra por orgCode
- [ ] Teste de integração valida que usuário A não acessa dados da org B
