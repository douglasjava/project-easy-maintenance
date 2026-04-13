# EPIC-008 — Qualidade e Testes

## Status
Parcial — 1/2 tasks entregues (TASK-026 — testes de integração — pendente)

## Objetivo
Estabelecer uma base de testes automatizados que permita mudanças com confiança — especialmente em fluxos críticos de billing, autenticação e isolamento multi-tenant.

## Descrição
O projeto não possui testes automatizados identificados. Isso é o maior risco técnico do sistema: qualquer bug fix ou melhoria pode silenciosamente quebrar cobrança, autenticação ou isolamento de tenant. O mínimo antes do lançamento é ter cobertura nos fluxos onde um bug causa impacto financeiro ou de segurança.

## Impacto no Produto
- **Sem este épico:** Cada deploy é um salto às cegas. Bugs críticos de cobrança só aparecem em produção. Refatoração é impossível com segurança.
- **Com este épico:** Confiança para evoluir o produto. Billing e security com cobertura suficiente para detectar regressões.

## Tasks Relacionadas

| ID | Título | Prioridade | Fase |
|----|--------|-----------|------|
| TASK-004 | Testes mínimos para billing e tenant isolation | 🔴 Crítico | 1 |
| TASK-026 | Testes de integração — billing e auth completos | 🟡 Médio | 2 |

## Critério de Conclusão do Épico
- [ ] Testes unitários cobrindo: ProrataCalculator, BillingCycleJobService, SubscriptionBlockingService
- [ ] Teste de integração validando que tenant A não acessa dados do tenant B
- [ ] Teste de integração validando fluxo trial → invoice → pagamento → ativo
- [ ] Pipeline CI rodando testes a cada push (GitHub Actions ou similar)
- [ ] Coverage mínimo de 60% nos módulos billing e auth
