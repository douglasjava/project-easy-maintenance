# TASK-332 — Assistente WhatsApp: mensagem automática de apresentação para todo novo cadastro

## Tipo
BACKEND / INFRA (integração Meta Cloud API) — depende de TASK-331

## Prioridade
🟠 Alto — ativação de novos usuários via WhatsApp (EPIC-031)

## Contexto
Decorre da mesma decisão de produto da TASK-331: ao capturar celular + opt-in no onboarding, o
assistente (EPIC-031) deve enviar automaticamente uma mensagem se apresentando, para todo novo
cadastro que der opt-in — não mais restrito ao piloto do Douglas.

Diferença importante em relação às mensagens que o assistente já envia hoje: aquelas são
**respostas** dentro de uma conversa iniciada pelo usuário (dentro da janela de 24h). Esta é uma
mensagem **iniciada pela empresa** (outbound frio, sem conversa aberta), o que na Meta Cloud API
exige um **template de mensagem pré-aprovado** (categoria Utility ou Marketing, a definir), e não
pode reaproveitar os templates/textos livres usados nas conversas em andamento.

## Proposta (a detalhar em brainstorming/spec antes de implementar)
- Criar e submeter um template novo para aprovação na Meta (categoria a definir — Utility tende a
  aprovar mais rápido que Marketing, mas precisa avaliar enquadramento).
- Gatilho: evento de conclusão de onboarding com opt-in = true → dispara a mensagem via
  `WhatsAppClient` (TASK-300) usando o template aprovado.
- Tratar falha de envio sem travar o onboarding (fire-and-forget com log/alerta, não bloqueante).
- Idempotência: nunca enviar a mensagem de apresentação duas vezes para o mesmo
  usuário/organização.

## Riscos / pontos de atenção
- Aprovação de template pela Meta não é instantânea e pode ser rejeitada — planejar tempo de
  antecedência e um texto alinhado às políticas (sem tom comercial agressivo se for categoria
  Utility).
- Custo por mensagem (~650 créditos/áudio nas interações atuais, mas esta é mensagem de texto —
  confirmar custo real do template outbound) em um fluxo que passa a ser **para todo cadastro**,
  não mais só o piloto — volume pode crescer sem controle de qualidade de lead.
- Hoje o piloto do EPIC-031 é restrito ao Douglas (ver TASK-299) — isso expande a exposição do
  assistente para qualquer novo usuário; vale confirmar se o restante do assistente (não só esta
  mensagem) já está pronto para esse público antes de ativar em produção.

## Critérios de Aceite
- [ ] Template de apresentação aprovado na Meta Cloud API
- [ ] Mensagem é disparada automaticamente só quando TASK-331 registrar opt-in = true
- [ ] Falha no envio não impede a conclusão do onboarding
- [ ] Mensagem nunca é enviada duplicada para o mesmo usuário
- [ ] QA manual cobrindo opt-in=false (não envia) e opt-in=true (envia)
