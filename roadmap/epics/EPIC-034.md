# EPIC-034 — Leitura de documentos por IA no WhatsApp + fornecedor e contrato por item

## Status
📝 Backlog — criado em 15/10/2026. Começa por spec + conjunto de avaliação (TASK-344).

Origem: avaliação de produto feita por um dos sócios (10 e 11/10/2026: PRD de reposicionamento, diretrizes do agente de onboarding via WhatsApp e comparação com a Facilitat), consolidada com leitura do código em 14/10/2026 (documento interno, fora do repositório).

## Objetivo
O síndico manda **foto de etiqueta, placa ou adesivo** (extintor, elevador, hidrante) e o
assistente devolve um **rascunho** de item com fornecedor, última execução e próximo vencimento.
Nada entra no cadastro sem **confirmação explícita** (mesmo padrão Confirmar/Corrigir da TASK-306).

Ataca o maior atrito de ativação (cadastro) e cria a base que falta para várias regras de produto:
**fornecedor de referência por item** e **tipo de contrato** (recorrente, avulso, interno).

Princípio: o modelo só **lê e devolve JSON** com confiança por campo; validação, permissão e
gravação ficam no backend. Texto dentro da imagem é dado, nunca instrução.

## Achados do código
- Imagem recebida pelo assistente (`InboundKind.IMAGE`) hoje **só vira anexo** — não há leitura.
- Spring AI + `gpt-4o-mini` já em uso, com créditos por plano e circuit breaker `ai`.
- Fornecedor está ligado à **organização** (`SupplierOrganizationLink`), não ao item;
  `Maintenance.performedBy` é texto livre. Dedup de fornecedor por CNPJ já existe (EPIC-028).
- Catálogo de normas revisado (EPIC-025) + catálogo curado `item_types` (V121) para casar o tipo.

## Fora do escopo
- Contrato completo em PDF de várias páginas, conciliação bancária, laudo automático.
- Leitura de demonstrativo de despesas fica como task de baixa prioridade (TASK-351): formato varia
  por administradora e só faz sentido com vários meses.

## Decisões em aberto
- [ ] Autorização para usar as fotos e o demonstrativo do condomínio piloto no conjunto de testes.
- [ ] Prazo de retenção de fotos (podem conter rostos, placas, documentos).
- [ ] Custo aceitável por foto lida (em créditos de IA).

## Tasks

| ID | Título | Prioridade | Fase | Tipo |
|----|--------|------------|------|------|
| [TASK-344](../tasks/TASK-344.md) | Spec + conjunto de avaliação para leitura de documentos | 🟠 Alto | Fase 2 | QA / ANÁLISE |
| [TASK-345](../tasks/TASK-345.md) | Backend: leitura estruturada de imagem com confiança e validação | 🔴 Crítico | Fase 2 | BACKEND |
| [TASK-346](../tasks/TASK-346.md) | Vínculo item ↔ fornecedor + tipo de contrato | 🟠 Alto | Fase 2 | FULL_STACK |
| [TASK-347](../tasks/TASK-347.md) | Assistente: foto → rascunho → Confirmar/Corrigir → item + evidência | 🔴 Crítico | Fase 2 | BACKEND |
| [TASK-348](../tasks/TASK-348.md) | Indicação de fornecedor respeita contrato + lista de bloqueio | 🟡 Médio | Fase 2 | FULL_STACK |
| [TASK-349](../tasks/TASK-349.md) | Onboarding guiado: assistente pede fotos na ordem certa | 🟡 Médio | Fase 2 | BACKEND |
| [TASK-350](../tasks/TASK-350.md) | QA: leitura de documentos ponta a ponta | 🟠 Alto | Fase 2 | QA |
| [TASK-351](../tasks/TASK-351.md) | Leitura de demonstrativo de despesas (classificar lançamentos) | 🔵 Baixo | Fase 2+ | BACKEND |
