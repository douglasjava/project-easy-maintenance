# TASK-431 — Samu: entrada sem portão + painel do condomínio por papel

## Tipo
BACKEND

## Categoria
Assistente WhatsApp (Samu) / Conversa

## Prioridade
🟠 Alto — WA-04/WA-05 e seção 5.3 do Tiago.

## Épico
[EPIC-043](../epics/EPIC-043.md) — Samu conversacional (Parte B)

## QA obrigatório
Sim.

---

## Contexto
Seção 5.3 da [Parte B](../QA/registro-usabilidade-producao.md) e D18 da [spec](../../docs/superpowers/specs/2026-11-06-assistant-role-matrix-design.md). Hoje o Samu é um "menu com portão": só funciona depois de
"menu".

## Escopo
- Qualquer primeira mensagem do dia (ou depois de 30 min parado) recebe o painel: vencidos, vencem esta semana,
  chamados abertos e fora do SLA, com 3 atalhos.
- Os números do painel seguem a política (zelador não vê custo; morador vê os próprios chamados).
- Intenção clara na primeira mensagem pula o painel e vai direto ao fluxo.
- "Mais opções" abre o menu por papel da TASK-415.

## Critérios de Aceite
- [ ] "oi" ou texto sem fluxo ativo → painel, sem pedir "menu"
- [ ] "troquei a lâmpada da garagem hoje" → vai direto ao registro
- [ ] Painel diferente por papel (teste)

## Dependências
[TASK-415](TASK-415.md), [TASK-417](TASK-417.md).

## Riscos
Mensagem de painel em todo primeiro contato: sem IA, sem custo extra de template (é resposta).

## Status
⬜ Backlog
