# TASK-310 — PDF da prestação de contas no servidor

## Tipo
FULL_STACK

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 3**

## Depende de
TASK-309

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-310-<descricao-curta>`.

**Escopo**: rota no Next.js que renderiza o **mesmo** `PrestacaoContasPdfDocument` no servidor
(autenticada serviço a serviço, com escopo de organização e período); o assistente pede o PDF e
envia como documento. A tela continua gerando no navegador (ou passa a usar a rota).

**Critérios de aceite**
- [ ] PDF do WhatsApp idêntico ao baixado na tela.
- [ ] Rota inacessível sem a credencial de serviço; nunca devolve outra organização.

**Prompt**: `execute a TASK-310 (EPIC-031): gerar o PDF da prestação de contas no servidor
reaproveitando o componente react-pdf e enviar pelo assistente.`

## Status
Backlog
