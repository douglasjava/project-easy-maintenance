# EPIC-036 — Conselho e aprovação de orçamentos

## Status
📝 Backlog — criado em 15/10/2026. **Só iniciar com demanda comprovada em piloto.**

Origem: avaliação de produto feita por um dos sócios (10 e 11/10/2026: PRD de reposicionamento, diretrizes do agente de onboarding via WhatsApp e comparação com a Facilitat), consolidada com leitura do código em 14/10/2026 (documento interno, fora do repositório).

## Objetivo
O conselho vira um papel do sistema, com mandato. O síndico envia até 3 orçamentos; os
conselheiros aprovam ou recusam (com comentário) e cada voto fica auditado. Regras configuráveis
por condomínio: quando exige conselho (valor/categoria), quórum e prazo. Sem promessa de validade
jurídica.

## Achados do código
- Não existe nenhum conceito de conselho/conselheiro no código.
- `SupplierBudgetRequest` cobre pedido de orçamento para **1** fornecedor; precisa evoluir para cotação múltipla.
- Hoje o assistente sempre fala **em nome de um usuário autenticado** (ativação por código).
  Conselheiro/zelador votando pelo WhatsApp exige um **modelo de identidade por telefone com escopo
  restrito** — spec de segurança própria antes de qualquer código (TASK-355).

## Fora do escopo
- Assembleia virtual, votação de moradores, assinatura digital com validade jurídica.

## Decisões em aberto
- [ ] Padrão inicial (sugestão: maioria simples, 72 h, limite de valor configurável).
- [ ] Segmento-alvo confirma a dor? (o ICP inicial — síndico profissional — tende a querer menos etapas de aprovação).

## Tasks

| ID | Título | Prioridade | Fase | Tipo |
|----|--------|------------|------|------|
| [TASK-355](../tasks/TASK-355.md) | Spec de segurança: identidade por telefone com escopo restrito | 🔴 Crítico | Fase 4 | ANÁLISE / SEGURANÇA |
| [TASK-356](../tasks/TASK-356.md) | Cadastro de conselheiros com mandato | 🟡 Médio | Fase 4 | FULL_STACK |
| [TASK-357](../tasks/TASK-357.md) | Pedido de aprovação com até 3 orçamentos + regras por condomínio | 🟡 Médio | Fase 4 | BACKEND |
| [TASK-358](../tasks/TASK-358.md) | Voto do conselheiro (WhatsApp ou link) com auditoria | 🟡 Médio | Fase 4 | FULL_STACK |
| [TASK-359](../tasks/TASK-359.md) | QA: conselho e aprovação ponta a ponta | 🟠 Alto | Fase 4 | QA |
