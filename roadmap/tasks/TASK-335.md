# TASK-335 — Corrigir preço por condomínio invertido entre planos

## Tipo
INFRA / CONFIG

## Prioridade
🟠 Alto

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 0**

## Depende de
Decisão de preço dos sócios

## QA obrigatório
Sim.

## Contexto
Business sai a R$ 14,95/condomínio e Enterprise a R$ 17,98 — o desconto por volume está invertido. **Aguarda decisão de valores.**
Base: `staging` · branch `feature/TASK-335-<descricao-curta>`.

## Escopo
- Migration em `plans` com os novos limites/preços.
- Landing e tela de planos coerentes.
- Assinaturas existentes: avaliar impacto (hoje sem clientes pagantes).

## Critérios de aceite
- [ ] Preço por condomínio cai conforme o plano cresce
- [ ] Landing, /billing e Asaas exibem os mesmos valores
- [ ] Testes de billing verdes

## Status
Backlog
