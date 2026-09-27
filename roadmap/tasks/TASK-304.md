# TASK-304 — "Identificação/local" no item + `source`

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 1**

## Depende de
—

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-304-<descricao-curta>`.

**Escopo**
- Coluna opcional `location_label` (ex.: "Bloco B") em `maintenance_items`: API (criar/editar/
  listar) e web (formulário, lista, detalhe, exibição junto ao tipo).
- Coluna `source` (`WEB` padrão, `WHATSAPP`) em `maintenance_items` e `maintenances`.
- Detalhe da manutenção mostra "Registrado via WhatsApp" quando for o caso.

**Critérios de aceite**
- [ ] Itens existentes continuam funcionando sem o campo.
- [ ] Dois itens do mesmo tipo aparecem distinguíveis na lista.
- [ ] Contrato da API compatível (campos novos opcionais).

**Prompt**: `execute a TASK-304 (EPIC-031): campo opcional de identificação/local no item e coluna
source em item e manutenção.`

## Status
Backlog
