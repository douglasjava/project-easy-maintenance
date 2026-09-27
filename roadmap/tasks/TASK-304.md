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

## Execução (27/09/2026)
Branches `feature/TASK-304-item-local-e-origem` (api e web) — V117 (`location_label`, `source`), campo 'Identificação / local' no formulário, rótulo 'Caixa d'água · Bloco B' na lista e no detalhe, selo 'Registrado via WhatsApp' no modal da manutenção.
Plano: `docs/superpowers/plans/2026-09-26-epic-031-onda-1-assistente-whatsapp.md` · testes: API 1.209 verdes; web 214 verdes (3 falhas pré-existentes em `middleware.test.ts`) · validação local ponta a ponta com a conta demo. Revisão final independente feita (6 pontos importantes corrigidos com teste). PR para `staging`: [api#122](https://github.com/douglasjava/easy-maintenance-api/pull/122) + [web#103](https://github.com/douglasjava/easy-maintenance-web/pull/103).

## Status
🟡 Em validação — PR aberta
