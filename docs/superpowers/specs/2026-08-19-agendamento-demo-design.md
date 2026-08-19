# Agendamento de Demonstração (Cal.com) — Design

**Data**: 2026-08-19
**Status**: Aprovado por Douglas (via diálogo de brainstorm)

## Contexto

Douglas viu o concorrente Easy Alert (`easyalert.com.br/agendar/`) oferecer agendamento de
demonstração comercial com calendário próprio: mês → dia → horário de 45 min → formulário
(nome, e-mail ou WhatsApp, empresa, observações) → reserva em tempo real, sem double-booking. O
link de fallback deles aponta pro próprio subdomínio (`app.easyalert.com.br`), sugerindo algo
próprio ou auto-hospedado.

Hoje o funil comercial do Easy Maintenance (`landing/page.tsx`) só tem o formulário de e-mail —
captura o lead, mas marcar a call é 100% manual (Douglas ou o time comercial entra em contato
depois). A ideia é dar à pessoa a opção de já marcar um horário específico na hora, sem esperar
esse contato manual.

## Decisões de escopo (confirmadas com Douglas)

1. **Escopo**: é uma melhoria do funil comercial (agendar demo/call de vendas), não uma feature
   dentro do produto pros clientes finais.
2. **Build vs buy**: usa o **Cal.com** (plano gratuito, widget embutível) em vez de construir
   calendário/disponibilidade/reserva do zero. Reduz o trabalho a integração, não construção de
   infraestrutura de agenda.
3. **Quem atende**: só Douglas, por enquanto — calendário único no Cal.com, sem lógica de
   distribuição entre pessoas.
4. **Integração com leads**: todo agendamento também vira um registro em `landing_leads` (mesma
   tabela do formulário de e-mail), via webhook do Cal.com — preserva UTM/afiliado/consentimento
   LGPD já capturados, mantendo o painel de leads como fonte única de verdade do funil.
5. **⚠️ Não mexe no fluxo atual**: o formulário de e-mail + botão "Solicitar Demonstração" da
   landing continuam exatamente como estão, sem nenhuma alteração. Nem toda pessoa quer marcar
   horário específico na hora — algumas preferem só deixar contato pra alguém entrar em contato
   depois. Os dois caminhos coexistem como opções paralelas e independentes, nenhum substitui o
   outro.
6. **Botão novo**: "Agendar demonstração" na navbar da landing (mesmo lugar em que o Easy Alert
   coloca o deles), levando pra uma página nova `/agendar` — só isso muda na landing existente.

---

## Componentes técnicos

### Frontend

- Nova rota `/agendar` (App Router, mesmo padrão de `/blog` e `/termos`: navbar simples com Logo
  linkando pra `/landing`, sem rota dinâmica).
- Embed oficial do Cal.com (`@calcom/embed-react` ou script embed direto — decisão de
  implementação, não muda o design) na página.
- UTM (cookie `em_utm`, já capturado hoje por `UtmCapture`) e `affiliateCode` (cookie `em_ref`)
  são passados como parâmetros de URL pro embed do Cal.com, que os devolve no payload do webhook
  de agendamento — mesmo padrão de propagação que o formulário de e-mail já faz manualmente hoje
  em `landing/page.tsx` (`getStoredUtm()`, `Cookies.get('em_ref')`).
- `landing/page.tsx` (navbar): novo item "Agendar demonstração" (`<Link href="/agendar">`), ao
  lado de "Login Cliente" — sem tocar em nenhum outro elemento da página (nem o formulário de
  e-mail, nem o botão "Solicitar Demonstração" existente, nem o CTA final).

### Backend

- Novo endpoint público `POST /easy-maintenance/api/v1/landing/leads/calcom-webhook`.
- Valida a assinatura do webhook do Cal.com (segredo compartilhado configurado no painel do
  Cal.com e como variável de ambiente no backend) — rejeita payload sem assinatura válida.
- Extrai do payload do evento `BOOKING_CREATED`: nome, e-mail, telefone (se informado), UTM e
  `affiliateCode` (dos parâmetros de URL repassados), e o campo de consentimento LGPD (pergunta
  obrigatória configurada no formulário do Cal.com, ver abaixo).
- Chama o `LeadService.createLead` já existente (mesmo usado pelo formulário de e-mail) — **sem
  tabela nova, sem serviço de lead novo**, só mais uma porta de entrada pro mesmo fluxo. `source`
  do lead marcado como `"agendamento"` (ou equivalente) pra diferenciar de `"landing"` no painel.

### Configuração no Cal.com (não é código)

- Pergunta obrigatória de consentimento LGPD (checkbox) no formulário de agendamento, equivalente
  à checkbox que o formulário de e-mail já exige — sem isso, o `LeadService.createLead` rejeitaria
  o lead (regra já existente: e-mail presente exige `consentAccepted=true`).
- Duração do slot, disponibilidade e fuso horário configurados diretamente no Cal.com — fora do
  código do produto.

---

## Fluxo de dados

1. Prospect clica em "Agendar demonstração" na navbar da landing → vai pra `/agendar`.
2. Escolhe dia/horário no embed do Cal.com, preenche nome/e-mail/consentimento.
3. Cal.com confirma o agendamento (e-mail de confirmação nativo do Cal.com) e dispara webhook
   `BOOKING_CREATED` pro backend.
4. Backend valida assinatura, extrai dados, chama `LeadService.createLead` — cria o
   `landing_lead`, aparece no painel de leads (`/private/admin/leads`) igual a qualquer outro.

## Tratamento de erro

- Webhook com assinatura inválida: rejeitado (400/401), logado, não cria lead.
- Payload sem e-mail (não deveria acontecer — e-mail é campo obrigatório no Cal.com pra confirmar
  o agendamento) ou sem consentimento marcado: seguem a mesma validação que `LeadService` já
  aplica hoje pro formulário de e-mail (rejeita se `consentAccepted` não for `true` e houver
  e-mail).
- Falha ao criar o lead (erro de banco, etc.): o agendamento no Cal.com **já está confirmado**
  independente disso — o pior caso é o lead não aparecer no painel interno, mas a call continua
  marcada e Douglas é avisado pelo e-mail nativo do Cal.com de qualquer forma. Não é um ponto único
  de falha pro agendamento em si.

## Testes

- Teste do endpoint de webhook: assinatura válida cria lead corretamente; assinatura inválida
  rejeita; payload sem consentimento é rejeitado (mesma regra do `LeadService` já testada).
- Sem teste automatizado pro embed do Cal.com em si (widget de terceiro) — validação é manual,
  mesmo padrão já usado nas páginas de conteúdo estático deste projeto.

---

## Fora de Escopo

- Qualquer alteração no formulário de e-mail ou no botão "Solicitar Demonstração" existentes —
  ficam exatamente como estão.
- Distribuição de agendamento entre múltiplas pessoas (round-robin) — só Douglas por enquanto.
- Perguntas de qualificação de lead extras no formulário do Cal.com (tipo as 2 que o Easy Alert
  usa) — pode virar melhoria futura, não faz parte desta leva.
- Confirmação por WhatsApp do agendamento (Cal.com já manda confirmação por e-mail nativamente) —
  fica pra depois se fizer falta.
- Self-hosting do Cal.com — usa o plano gratuito hospedado deles por enquanto.

## Riscos

- Baixo — aditivo, não toca em nada do fluxo comercial existente. Único ponto de atenção real é a
  validação de assinatura do webhook (superfície pública nova, precisa ser robusta contra payload
  forjado).
