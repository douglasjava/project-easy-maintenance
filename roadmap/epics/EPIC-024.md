# EPIC-024 — Agendamento de Demonstração (Cal.com)

## Status
Desenhado via brainstorm com Douglas (19/08/2026), pronto para implementar. Spec em
`docs/superpowers/specs/2026-08-19-agendamento-demo-design.md`.

## Objetivo
Dar ao prospect a opção de marcar um horário específico de demonstração na hora, sem esperar
follow-up manual — inspirado no `/agendar` do concorrente Easy Alert. Reduz o trabalho manual de
Douglas/time comercial de marcar call por call.

## Descrição

Nova página `/agendar` com o widget do **Cal.com** embutido (plano gratuito, calendário único —
só Douglas atende por enquanto) — sem construir calendário/disponibilidade/reserva do zero. Um
webhook do Cal.com (`BOOKING_CREATED`) cria um `landing_lead` (mesma tabela e mesmo `LeadService`
já usados pelo formulário de e-mail), preservando UTM/afiliado/consentimento LGPD já capturados
hoje — o painel de leads continua sendo a fonte única de verdade do funil, independente de qual
caminho o prospect escolheu.

**Decisão importante confirmada com Douglas**: isso **não substitui nem altera** o formulário de
e-mail e o botão "Solicitar Demonstração" já existentes na landing — nem toda pessoa quer marcar
horário específico na hora, algumas preferem só deixar contato pra alguém entrar em contato
depois. Os dois caminhos coexistem como opções paralelas e independentes. A única mudança na
landing existente é um botão novo, "Agendar demonstração", na navbar (mesmo lugar em que o Easy
Alert coloca o deles).

---

## Contexto Técnico

- `landing/page.tsx` (navbar): novo item `<Link href="/agendar">`, sem tocar em nenhum outro
  elemento da página.
- Nova rota `/agendar`, mesmo padrão de `/blog`/`/termos` (App Router, navbar simples com Logo).
- UTM (cookie `em_utm`) e `affiliateCode` (cookie `em_ref`), já capturados hoje por `UtmCapture`,
  são passados como parâmetros de URL pro embed do Cal.com, que os devolve no payload do webhook.
- `LeadService.createLead` (já existente, usado pelo formulário de e-mail) é reaproveitado pelo
  webhook — sem tabela nova, sem serviço de lead novo.
- Consentimento LGPD vira uma pergunta obrigatória (checkbox) configurada diretamente no
  formulário do Cal.com — sem isso, `LeadService` rejeitaria o lead (regra já existente: e-mail
  presente exige `consentAccepted=true`, mesma regra endurecida na TASK-171 pro clique do
  WhatsApp).

---

## Tasks

| ID | Título | Tipo | Prioridade |
|---|---|---|---|
| [TASK-175](../tasks/TASK-175.md) | Frontend: página `/agendar` (embed Cal.com) + botão na navbar da landing | FRONTEND | 🟠 Alto |
| [TASK-176](../tasks/TASK-176.md) | Backend: webhook do Cal.com cria lead via `LeadService` | BACKEND | 🟠 Alto |

Ordem: as duas podem andar em paralelo do ponto de vista de código (não há dependência direta
entre o embed do frontend e o endpoint de webhook), mas o webhook precisa estar configurado no
painel do Cal.com apontando pro endpoint antes do rollout completo fazer sentido.

---

## Critério de Conclusão do Épico

- [ ] `/agendar` acessível publicamente, com o embed do Cal.com funcional
- [ ] Botão "Agendar demonstração" na navbar da landing, sem alterar nenhum outro elemento da
      página
- [ ] Webhook `POST /landing/leads/calcom-webhook` valida assinatura, extrai UTM/afiliado/
      consentimento, cria `landing_lead` via `LeadService.createLead`
- [ ] Agendamento aparece no painel de leads (`/private/admin/leads`) igual a qualquer outro lead
- [ ] Formulário de e-mail + botão "Solicitar Demonstração" existentes continuam funcionando sem
      nenhuma mudança
- [ ] Testes cobrindo assinatura válida/inválida e payload sem consentimento
- [ ] `npm run build` (frontend) e `mvn test` (backend) sem regressão

---

## Fora de Escopo

- Qualquer alteração no formulário de e-mail ou no botão "Solicitar Demonstração" existentes.
- Distribuição de agendamento entre múltiplas pessoas (round-robin) — só Douglas por enquanto.
- Perguntas de qualificação de lead extras no formulário do Cal.com (tipo as que o Easy Alert usa).
- Confirmação por WhatsApp do agendamento (Cal.com já manda confirmação por e-mail nativamente).
- Self-hosting do Cal.com — usa o plano gratuito hospedado deles por enquanto.

## Riscos
Baixo — aditivo, não toca em nada do fluxo comercial existente. Único ponto de atenção real é a
validação de assinatura do webhook (superfície pública nova, precisa ser robusta contra payload
forjado).
