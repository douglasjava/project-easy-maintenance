# EPIC-033 — Prova de manutenção (reposicionamento: evidência, relatório e North Star)

## Status
📝 Backlog — criado em 15/10/2026. Fase 0 (ajustes rápidos) pode começar já; Fase 1 depende das decisões abaixo.

Origem: avaliação de produto feita por um dos sócios (10 e 11/10/2026: PRD de reposicionamento, diretrizes do agente de onboarding via WhatsApp e comparação com a Facilitat), consolidada com leitura do código em 14/10/2026 (documento interno, fora do repositório).

## Objetivo
Mudar a promessa do produto de **"lembrar da manutenção"** para **"provar que a manutenção foi feita"**.
O alerta passa a ser o meio; o valor entregue é o registro com evidência, no prazo, pronto para
assembleia, seguradora e construtora.

**North Star proposta:** manutenções **críticas** concluídas **com evidência** **dentro do prazo**, por mês.

Fase 0 remove atritos baratos que já confirmamos no código (painel travado em 5 itens, jargão,
preço por condomínio invertido, trial menor que o ciclo de manutenção). Fase 1 fecha o ciclo
fazer → provar: evidência obrigatória para item crítico, baixa respondendo ao alerta, status
"sem evidência", relatório mensal automático e eventos para medir a North Star.

## Achados do código
- `OnboardingPanel.tsx:20` só libera o painel com `itemsTotal >= 5`.
- Preço por condomínio (V69/V103): Starter R$ 149/3, Business R$ 299/20 (R$ 14,95), Enterprise
  R$ 899/50 (R$ 17,98) — desconto por volume invertido.
- IA já tem teto por plano (`AiCreditService`); **mensagem de WhatsApp não tem**.
- `MaintenanceItem.criticality` já existe; evidência hoje é opcional e fica numa etapa separada.
- Registro pelo WhatsApp com confirmação + foto já existe (TASK-306) — reaproveitar na baixa pelo alerta.
- TASK-309 (relatórios pelo WhatsApp) e TASK-311 (métricas do assistente) **não** cobrem o relatório
  mensal de prova nem os eventos da North Star — por isso viram tasks novas aqui.

## Fora do escopo
- Remover o módulo financeiro (EPIC-032): só não expandir.
- Decisões de nome/marca (INPI, nome do assistente) — são de negócio, registradas abaixo.

## Decisões em aberto
- [ ] Sócios aceitam a North Star e a lista de sistemas críticos (sugestão: elevador, SPDA, extintores e hidrantes, reservatórios, bombas, gás, portão automático, piscina)?
- [ ] Novo desenho de preço (TASK-335).
- [ ] Fornecedor pago na notificação: sinalizar "patrocinado" ou pausar cobrança nova (TASK-337)?
- [ ] Marca: consulta ao INPI sobre "Easy Maintenance" × "Easy Alert" e nome do assistente.

## Tasks

| ID | Título | Prioridade | Fase | Tipo |
|----|--------|------------|------|------|
| [TASK-333](../tasks/TASK-333.md) | Painel de conformidade liberado desde o 1º item | 🟠 Alto | Fase 0 | FRONTEND |
| [TASK-334](../tasks/TASK-334.md) | Remover jargão de sistema da interface | 🟡 Médio | Fase 0 | FRONTEND |
| [TASK-335](../tasks/TASK-335.md) | Corrigir preço por condomínio invertido entre planos | 🟠 Alto | Fase 0 | INFRA / CONFIG |
| [TASK-336](../tasks/TASK-336.md) | Piloto acompanhado de 30 dias (extensão de trial pelo admin) | 🟡 Médio | Fase 0 | FULL_STACK |
| [TASK-337](../tasks/TASK-337.md) | Fornecedor patrocinado sinalizado na notificação | 🟡 Médio | Fase 0 | FULL_STACK |
| [TASK-338](../tasks/TASK-338.md) | Medir mensagens de WhatsApp por organização e por plano | 🟠 Alto | Fase 0 | BACKEND |
| [TASK-339](../tasks/TASK-339.md) | Evidência obrigatória para itens críticos + registro em etapa única | 🔴 Crítico | Fase 1 | FULL_STACK |
| [TASK-340](../tasks/TASK-340.md) | Baixa pelo alerta no WhatsApp: "Já foi feita" → foto → confirmar | 🟠 Alto | Fase 1 | BACKEND |
| [TASK-341](../tasks/TASK-341.md) | Status "concluída sem evidência" e % de críticas com evidência | 🟡 Médio | Fase 1 | FULL_STACK |
| [TASK-342](../tasks/TASK-342.md) | Relatório mensal de prova enviado automaticamente | 🟠 Alto | Fase 1 | FULL_STACK |
| [TASK-343](../tasks/TASK-343.md) | Eventos de produto para a North Star e o funil de ativação | 🟠 Alto | Fase 1 | BACKEND |
