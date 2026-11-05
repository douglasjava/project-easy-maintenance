# TASK-QA-MAN-029 — Executar JORNADA-PRD-001 (Jornada Completa do Produto em PRD)

## Tipo
QA Manual — execução em produção (PRD), por blocos independentes, dono: Tiago

## Categoria
Full-Stack / QA ponta a ponta

## Prioridade
🟠 Alto — validação completa do produto rodando de verdade (WhatsApp/e-mail reais), antes de
expandir vendas

## Documento
[JORNADA-PRD-001](../JORNADA-PRD-001.md) — 8 blocos independentes + bloco de preparação

## Descrição
Executar a jornada de ponta a ponta do produto diretamente em produção: onboarding, pessoas
(morador via esteira de aprovação de identidade do EPIC-040, conselheiro, fornecedor), itens e
manutenções, chamados, financeiro, notificações automáticas, assistente via WhatsApp (ativo) e
fornecedor self-service. Pode ser feito aos poucos, um bloco por vez, marcando os checkboxes
dentro do próprio documento.

## Pré-requisitos antes de começar
- Organização de teste dedicada em PRD (nunca reaproveitar conta/número de cliente real) — ver
  seção "Isolamento" do documento.
- Para o Bloco 4 (chamados/esteira): confirmar estado da env var
  `WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED`.
- Para o Bloco 7 (assistente): `userId` de teste precisa estar em `ASSISTANT_PILOT_USER_IDS`.

## Critérios de Aceite
- [ ] Bloco 0 — Preparação concluído
- [ ] Bloco 1 — Onboarding validado
- [ ] Bloco 2 — Pessoas e Papéis (cadastro manual) validado
- [ ] Bloco 3 — Itens e Manutenções validado
- [ ] Bloco 4 — Chamados e Esteira de Aprovação de Identidade validado
- [ ] Bloco 5 — Financeiro e Prestação de Contas validado
- [ ] Bloco 6 — Notificações Automáticas validado
- [ ] Bloco 7 — Assistente via WhatsApp (ativo) validado
- [ ] Bloco 8 — Fornecedor Self-Service validado

## Status
🔵 A fazer — documento publicado em 05/11/2026, execução ainda não iniciada.
