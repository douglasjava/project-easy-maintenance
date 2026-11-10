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

## Template proposto para submissão na Meta (19/10/2026)
Segue o mesmo padrão de nome em snake_case versionado já usado em `vencimento_manutencao_v2`/`v3`
(ambos Utility aprovados).

- **Nome**: `assistente_boas_vindas_v1`
- **Categoria**: `UTILITY` (não Marketing)
- **Idioma**: Português (BR)
- **Corpo (Body)**:
  ```
  Olá, {{1}}! 👋

  Sou o assistente virtual do Easy Maintenance da *{{2}}*. A partir de agora você pode me
  chamar aqui no WhatsApp pra registrar manutenções, consultar pendências e receber avisos de
  vencimento.

  Você está recebendo esta mensagem porque ativou as notificações por WhatsApp no seu cadastro.
  ```
- **Rodapé (Footer)**: `Easy Maintenance — responda SAIR para desativar`
- **Botão**: Quick Reply — `Começar`
- **Variáveis**: `{{1}}` = primeiro nome do usuário · `{{2}}` = nome da organização/condomínio

**Por que Utility e não Marketing**: dispara só por opt-in explícito do próprio usuário
(TASK-331), é sobre funcionalidade da conta já contratada, sem oferta/desconto/CTA comercial —
enquadra em "account update/onboarding" da política da Meta. Risco residual: a Meta pode
reclassificar como Marketing na revisão — submeter com folga de prazo antes de depender da
aprovação para liberar a task.

Optei por Quick Reply em vez de botão de URL pra simplificar a aprovação e porque
`WhatsAppClient.sendTemplateMessage` já suporta esse padrão sem precisar de botão dinâmico. Se
preferir linkar pro dashboard, dá pra trocar por um botão de URL com `{{1}}`/slug da org como
sufixo dinâmico — não submetido ainda, aguardando decisão final antes do cadastro na Meta.

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
- [x] Template de apresentação aprovado na Meta Cloud API
- [x] Mensagem é disparada automaticamente só quando TASK-331 registrar opt-in = true
- [x] Falha no envio não impede a conclusão do onboarding
- [x] Mensagem nunca é enviada duplicada para o mesmo usuário
- [x] QA manual cobrindo opt-in=false (não envia) e opt-in=true (envia) — validado em produção

## Execução
Implementado em `WhatsAppWelcomeMessageService`, disparado a partir de `OnboardingService.createOrganization`
(PR [api#159](https://github.com/douglasjava/easy-maintenance-api/pull/159) contra `staging`).
Idempotência via `users.whatsapp_welcome_sent_at` (migration V124).

Template `assistente_boas_vindas_v1` aprovado pela Meta. A flag
`notification.whatsapp.welcome-message-enabled` foi ligada em produção (commit direto em `main`
pelo Douglas). Primeiro envio real em produção (20/10/2026) revelou um bug: `WhatsAppClient`
montava sempre um componente de botão `url`, mesmo quando o template usa botão Quick Reply (sem
parâmetro dinâmico) — a Graph API rejeitava com HTTP 400 `(#100) Invalid parameter: button:
Parameter 'text' is mandatory ... cannot be empty`. Corrigido tornando o componente de botão
condicional a `buttonUrlParam` não vazio, com teste de regressão novo
(`sendTemplateMessage_withNullButtonParam_omitsButtonComponent`). Mergeado em `staging`
([api#163](https://github.com/douglasjava/easy-maintenance-api/pull/163)) e em `main`
([api#164](https://github.com/douglasjava/easy-maintenance-api/pull/164)). `mvn test` 1458/1458,
sem regressão.

Publicado e testado funcionando em produção em 21/10/2026.

## Status
Done — publicado e validado em produção (21/10/2026).
