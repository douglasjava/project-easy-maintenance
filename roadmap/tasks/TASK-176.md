# TASK-176 — Backend: webhook do Cal.com cria lead via `LeadService`

## Tipo
BACKEND

## Categoria
Marketing / Funil Comercial

## Prioridade
🟠 Alto

## Épico
[EPIC-024](../epics/EPIC-024.md) — Agendamento de Demonstração (Cal.com)

## QA obrigatório
Sim — testes automatizados (assinatura válida/inválida, payload com/sem consentimento) + QA
manual disparando um agendamento real e conferindo o lead aparecer no painel.

---

## Contexto

Todo agendamento feito em `/agendar` (TASK-175) deve virar um `landing_lead`, igual ao formulário
de e-mail já faz — sem isso, o agendamento fica invisível pro painel de leads e pras métricas de
funil já existentes. Detalhe completo em
`docs/superpowers/specs/2026-08-19-agendamento-demo-design.md`.

## Objetivo

Endpoint público que recebe o webhook `BOOKING_CREATED` do Cal.com, valida a assinatura, e cria um
lead reaproveitando o `LeadService` já existente — sem tabela nova, sem serviço de lead novo.

## Escopo

- Novo endpoint `POST /easy-maintenance/api/v1/landing/leads/calcom-webhook`.
- Valida a assinatura do webhook (segredo compartilhado, configurado como variável de ambiente) —
  rejeita (400/401) payload sem assinatura válida, sem criar lead.
- Extrai do payload do evento `BOOKING_CREATED`: nome, e-mail, telefone (se informado), UTM e
  `affiliateCode` (dos parâmetros de URL repassados pela TASK-175), e o campo de consentimento
  LGPD (pergunta obrigatória configurada no formulário do Cal.com).
- Chama `LeadService.createLead` (mesmo usado pelo formulário de e-mail) com esses dados — `source`
  marcado como `"agendamento"` (ou equivalente) pra diferenciar de `"landing"` no painel.
- Segue a mesma regra já existente: e-mail presente exige `consentAccepted=true` (endurecida na
  TASK-171/PR do WhatsApp) — payload sem consentimento marcado é rejeitado do mesmo jeito que o
  formulário de e-mail já rejeitaria.

## Critérios de Aceite

- [ ] Webhook com assinatura válida e payload completo cria `landing_lead` corretamente, com UTM/
      afiliado propagados
- [ ] Webhook com assinatura inválida é rejeitado, não cria lead
- [ ] Payload sem consentimento marcado é rejeitado (mesma regra do `LeadService`)
- [ ] Lead criado aparece no painel `/private/admin/leads` com `source` identificando que veio do
      agendamento
- [ ] Testes cobrindo os 3 cenários acima
- [ ] `mvn test` sem regressão

## Dependências
Nenhuma (independente da TASK-175 do ponto de vista de código, mas precisa da URL de produção da
TASK-175 configurada no painel do Cal.com pro webhook fazer sentido de ponta a ponta).

## Riscos
Baixo-Médio — superfície pública nova (endpoint de webhook), precisa de validação de assinatura
robusta contra payload forjado.

## Esforço
Baixo-Médio

## Status
Pronto para implementar.
