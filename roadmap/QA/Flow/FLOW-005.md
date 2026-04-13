# FLOW-005 — Trial Lifecycle e Conversão

## Criticidade
🟠 HIGH

## Launch Relevance
Conversão trial→pago é a principal métrica de negócio pré-escala. Banner e indicadores de uso são os principais gatilhos de upgrade.

## Tasks Relacionadas
- TASK-015 — Banner de trial expirando no dashboard
- TASK-023 — Indicador de uso vs limite de plano no frontend
- TASK-030 — Tela de comparação de planos (upgrade page)

## Descrição do Fluxo

1. Usuário em trial vê banner no dashboard com dias restantes
2. Banner muda de cor conforme urgência (> 7 dias → neutro, 3–7 → amarelo, < 3 → vermelho)
3. Em telas de recursos limitados, indicador "X de Y usados" aparece próximo ao botão de criar
4. Quando limite atingido (ex: 30/30 itens), botão desabilita com tooltip de upgrade
5. Usuário acessa tela de comparação de planos via banner ou botão de upgrade
6. Usuário seleciona plano e é direcionado para checkout

## Camadas Impactadas
- **Backend:** Endpoint de subscription status / access context com `daysRemainingInTrial`, `currentUsage`, `maxAllowed`
- **Frontend:** `TrialBanner`, `UsageMeter`, tela de upgrade/comparação de planos

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Banner visível com dias corretos (trial ativo) | Happy path | Manual (TASK-015) |
| Banner oculto para usuário ACTIVE pago | Regressão | Manual |
| Cores de urgência corretas por faixa de dias | UX | Manual |
| CTA do banner → /billing ou /upgrade | Navegação | Manual |
| Banner reaparece após dispensar e re-logar | UX | Manual |
| Indicador de uso em 80%+ muda de cor | Conversão | Manual (TASK-023) |
| Botão de criar bloqueado no limite → tooltip de upgrade | UX | Manual |
| Tela de comparação de planos exibe plano atual destacado | Produto | Manual (TASK-030) |

## Validação Recomendada
- **Manual:** [MTD-005](../MTD/MTD-005.md)

## Gaps
- Sem teste automatizado para lógica de cores do banner por faixa de dias
- Endpoint de subscription status sem cobertura de integração para `daysRemainingInTrial`

## Status de Validação
- [ ] Banner com cores corretas validado manualmente
- [ ] Indicador de uso validado nas telas de itens e usuários
- [ ] Tela de comparação de planos validada
- [ ] Fluxo de upgrade funcional end-to-end
