# TASK-372 — INFRA/CONFIG: Templates WhatsApp (confirmação de código + protocolo criado/concluído)

## Tipo
INFRA / CONFIG

## Categoria
Chamados de Moradores

## Prioridade
🔴 Crítico (bloqueia TASK-368 e TASK-371 em produção — submissão à Meta tem prazo de aprovação fora
do nosso controle, mesmo risco já visto no EPIC-023/`vencimento_manutencao_v3`; deve começar o mais
rápido possível, em paralelo com TASK-367)

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — confirmar os 2 templates aprovados pela Meta recebem e renderizam corretamente as variáveis
reais (nome, protocolo, categoria, organização, código), antes de qualquer flag ser ligada em
produção.

---

## Contexto

Pedido de Douglas (28/10/2026): separar a definição/submissão dos templates WhatsApp em task própria,
fora de TASK-368/371 — são artefatos de configuração externa (Meta Business), não código, e têm
prazo de aprovação independente do desenvolvimento. Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

Definir e submeter à aprovação da Meta **2 templates (HSM)** novos. Os nomes, variáveis e ordem
abaixo já são os **nomes e contrato reais implementados em TASK-368/371**
(`ResidentTicketWhatsAppNotificationService`) — não são apenas sugestão, são o que o código já
chama; qualquer mudança de nome/ordem na submissão exige atualizar os `@Value` default em
`application.properties` (`notification.whatsapp.resident-ticket-optin-code-template-name` /
`...-protocol-template-name`) pra combinar.

### Template 1 — confirmação de código (`chamado_morador_confirmacao_codigo_v1`)

Usado por TASK-371 (`ResidentTicketWhatsAppOptInService.generateAndSendCode`), dispara quando o
morador marca o opt-in. Mesmo padrão de nome em snake_case versionado já usado em
`vencimento_manutencao_v2`/`v3` e `assistente_boas_vindas_v1` (TASK-332).

- **Nome**: `chamado_morador_confirmacao_codigo_v1`
- **Categoria**: `AUTHENTICATION` — **não `UTILITY`**. A Meta reclassificou automaticamente (29/10/2026):
  qualquer corpo reconhecido como código de verificação cai em Authentication, com texto de corpo
  fixo (não editável) e botão obrigatório. Ver nota abaixo.
- **Idioma**: Português (BR) — `pt_BR`
- **Corpo (Body)**: texto fixo definido pela própria Meta para a categoria Authentication (não é
  mais o texto livre que eu tinha desenhado) — só dá pra escolher os complementos oferecidos no
  formulário (ex. aviso de segurança "não compartilhe este código", tempo de expiração). `{{1}}` =
  código continua sendo a única variável.
- **Botão**: **"Copiar código"** (Copy Code) — **não** "Preenchimento automático" (One-tap
  autofill). One-tap exige nome de pacote + hash de assinatura de um app Android nativo, que o
  Easy Maintenance não tem (fluxo é só web, via QR code); "Copiar código" não exige esses campos e
  o morador cola o código manualmente no campo já existente em "Confirme seu WhatsApp".
- **Variáveis**: `{{1}}` = código de 6 dígitos, usado tanto no corpo quanto no parâmetro do botão

**Ajuste de código já feito (29/10/2026)**: `WhatsAppClient` já tinha suporte a um componente de
botão `type: button, sub_type: url` com 1 parâmetro de texto (usado pro botão de URL dinâmica do
`vencimento_manutencao_v2`) — é o mesmo formato documentado pela Meta pro botão "Copiar código" de
templates Authentication, só muda o valor (código em vez de URL). `ResidentTicketWhatsAppNotificationService.sendOptInCode`
agora manda o código também como parâmetro de botão (`send(..., code, "sendOptInCode")`), além do
corpo. `notifyCreated`/`notifyResolved` (template 2, que continua Utility) não mudaram — continuam
sem botão. Testes atualizados (`ResidentTicketWhatsAppNotificationServiceTest`), suíte completa do
módulo `resident_tickets` verde (45/45). **Ainda não testado contra a Graph API real** — só dá pra
confirmar de fato depois que o template for aprovado (sandbox ou produção controlada), é o primeiro
uso desse botão num template de Authentication neste projeto.

### Template 2 — protocolo criado/concluído (`chamado_morador_protocolo_v1`)

Usado por TASK-368 (`notifyCreated`/`notifyResolved`), um **único template genérico** com variável
de status — essa decisão (1 template em vez de 2) já foi tomada na implementação, não é mais aberta
na submissão. Chamado com os mesmos 3 parâmetros nas duas situações (criação e conclusão), só muda
o `{{3}}`.

- **Nome**: `chamado_morador_protocolo_v1`
- **Categoria**: `UTILITY` (atualização de status de uma solicitação que o próprio morador abriu)
- **Idioma**: Português (BR) — `pt_BR`
- **Corpo (Body)**:
  ```
  Olá, {{1}}! Seu chamado nº {{2}} foi {{3}}.

  Você pode acompanhar pelo link que usou para abrir o chamado.
  ```
- **Rodapé (Footer)**: `Easy Maintenance`
- **Botão**: nenhum
- **Variáveis** (nesta ordem exata — é a ordem que o código envia):
  - `{{1}}` = nome do morador (ex. `"Maria Souza"`)
  - `{{2}}` = número do protocolo (ex. `"12"`)
  - `{{3}}` = `"aberto"` (na criação) ou `"concluído"` (na conclusão) — enviar exemplo com
    `"aberto"` na submissão; a Meta aprova o texto com placeholder, o valor real varia em runtime

**Nota de implementação importante**: o desenho original (ver spec) previa uma 4ª variável — nome
da organização — e um texto diferente para criação vs. conclusão. Na implementação real
(TASK-368), isso foi simplificado pra 1 template com 3 variáveis (sem nome da organização, só
nome/protocolo/status) — os textos acima refletem exatamente isso. Se preferir reintroduzir o nome
da organização antes de submeter, precisa também ajustar
`ResidentTicketWhatsAppNotificationService.notifyCreated`/`notifyResolved` pra passar esse 4º
parâmetro.

### Depois de aprovar

1. Documentar aqui (atualizar esta seção) o nome final e variáveis **se algo mudar** na aprovação
   da Meta em relação ao que está acima.
2. Confirmar a categoria de aprovação de cada template — Template 1 (`AUTHENTICATION`, confirmado
   29/10/2026) e Template 2 (`UTILITY`, esperado — confirmar na submissão). Categoria errada
   pode exigir opt-in de marketing (como aconteceu no template `v3` do EPIC-023, TASK-229) ou ser
   rejeitada pela Meta.
3. Testar o envio real do Template 1 com o botão "Copiar código" (sandbox ou produção controlada)
   — é o primeiro template Authentication do projeto, o ajuste de código (ver nota acima) ainda não
   foi validado contra a Graph API real.
4. Ligar as flags em produção (`notification.whatsapp.resident-ticket-enabled=true`), hoje `false`
   por padrão — sem os templates aprovados, o envio real fica sempre desligado (comportamento
   validado em QA manual de 29/10/2026, ver TASK-371).

## Critérios de Aceite

- [x] Nomes finais, variáveis e texto de corpo documentados (seção "Escopo" acima, 29/10/2026) —
      refletem exatamente o que `ResidentTicketWhatsAppNotificationService` já envia, prontos pra
      colar no cadastro de template da Meta
- [x] Código ajustado pro botão "Copiar código" do Template 1 (categoria Authentication) — código
      enviado como parâmetro de corpo e de botão, suíte do módulo `resident_tickets` verde (45/45,
      29/10/2026)
- [x] Template de confirmação de código submetido e aprovado pela Meta — confirmado por Douglas em 10/11/2026
- [x] Template(s) de protocolo criado/concluído submetido(s) e aprovado(s) pela Meta — confirmado por Douglas em 10/11/2026
- [x] Teste de envio real (sandbox ou produção controlada) confirma renderização correta das
      variáveis e do botão "Copiar código" em cada template

## Dependências
Nenhuma técnica — pode começar em paralelo com TASK-367, já que é trabalho de configuração externa,
não depende do código. **Bloqueia** TASK-368 e TASK-371 em produção (o código pode ser escrito e
testado contra mock antes da aprovação, mas o envio real só funciona depois).

## Riscos
Prazo de aprovação da Meta é incerto e fora do controle do time (precedente: EPIC-023). Categoria de
aprovação (`Utility` x `Marketing`) pode vir diferente do esperado e exigir ajuste de opt-in —
mesmo problema já visto no `v3` do EPIC-023 (TASK-229).

## Esforço
Pequeno (trabalho de configuração, não de código) — mas com tempo de espera externo imprevisível.

## Status
✅ Done — `chamado_morador_confirmacao_codigo_v1` (Authentication) e `chamado_morador_protocolo_v1` (Utility)
aprovados pela Meta, online e produtivos (confirmado por Douglas em 10/11/2026).
