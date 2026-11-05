# TASK-309 — Relatórios fase 1

## Tipo
BACKEND

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-305, TASK-307

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-309-<descricao-curta>`.

**Escopo**
- **Regra documento × link**:
  - **documento fechado** (uma organização, período definido, para imprimir/enviar) → arquivo;
  - **exploratório** (filtros, vários condomínios, comparação de períodos, dashboard) → link.
- Excel de manutenções (export existente) enviado como documento.
- Prestação de contas: link da tela com o período preenchido.

**Caso ambíguo**: "relatório de conformidade" → documento só se o usuário disser PDF/assembleia/
prestação; senão, link do dashboard. Calendário `.ics` (export existente): opcional.

**Critérios de aceite**
- [ ] Excel recebido no WhatsApp igual ao baixado no web para o mesmo filtro.
- [ ] Pedido exploratório sempre responde com link.

**Prompt**: `execute a TASK-309 (EPIC-031): relatórios pelo WhatsApp: Excel como documento e
prestação de contas por link.`

## Status
Backlog
