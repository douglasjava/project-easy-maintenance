# TASK-305 — Consultas só leitura

## Tipo
BACKEND

## Prioridade
🟠 Alto

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2**

## Depende de
TASK-302, TASK-303

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-305-<descricao-curta>`.

**Escopo**: vencimentos (semana/30 dias), vencidos, histórico de um item (últimas 5), índice de
conformidade; até 10 linhas por resposta + link "ver todos"; nomes legíveis (portar
`formatItemType` para o backend); comparação entre condomínios → link para Relatórios.

**Critérios de aceite**
- [ ] Respostas batem com o que o dashboard e as listas mostram para a mesma organização.
- [ ] Organização sem itens: resposta útil (como começar), não lista vazia.
- [ ] Nenhuma consulta atravessa organizações.

**Prompt**: `execute a TASK-305 (EPIC-031): consultas só leitura pelo assistente, reaproveitando
os serviços de dashboard, itens e manutenções.`

## Status
Backlog
