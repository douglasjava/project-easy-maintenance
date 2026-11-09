# TASK-334 — Remover jargão de sistema da interface

## Tipo
FRONTEND

## Prioridade
🟡 Médio

## Épico
[EPIC-033](../epics/EPIC-033.md) — Prova de manutenção (reposicionamento: evidência, relatório e North Star) · **Fase 0**

## Depende de
—

## QA obrigatório
Sim.

## Contexto
Códigos como `EXTINTOR_CO2`, "Itens (conta) 0/500", "organização" e "tipo de empresa" não são a língua do síndico.
Base: `staging` · branch `feature/TASK-334-<descricao-curta>`.

## Escopo
- Varredura das telas: sempre nome amigável do tipo de item (já existe mapeamento, TASK-294).
- Quando o tipo da conta for condomínio, usar "condomínio" no lugar de "organização/empresa".
- Contador de limite só perto do teto.

## Critérios de aceite
- [ ] Nenhum código em MAIÚSCULAS_COM_SUBLINHADO visível ao usuário
- [ ] Termos ajustados no fluxo de condomínio
- [ ] Build e testes do web verdes

## Status
Backlog
