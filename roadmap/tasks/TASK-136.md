# TASK-136 — Backend: Provedor de e-mail Resend + endpoint de teste manual

## Tipo
INFRA / CONFIG

## Categoria
Infraestrutura / Custo / Integração Externa

## Prioridade
🟡 Médio

## Épico
N/A — melhoria de infraestrutura/custo, não vinculada a um épico de produto. Nasceu de uma conversa
sobre reduzir custo operacional (MailerSend $7/mês fixo) enquanto a base de clientes ainda é zero.

## QA obrigatório
Sim — troca o provedor que carrega todo e-mail transacional (cobrança, notificações, convites).

---

## Contexto

MailerSend cobrava $7/mês fixo (3.000 e-mails/mês) mesmo sem clientes pagantes ainda. Resend oferece
plano grátis equivalente (3.000/mês, 100/dia) — suficiente para o estágio atual do produto. Decisão
de Douglas: usar Resend como provedor **ativo por padrão**, manter o MailerSend **intacto no
código** (não remover), só desativado, pra religar sem precisar de deploy de código novo quando/se o
plano pago voltar a ser necessário.

---

## Objetivo

Trocar o provedor de e-mail ativo para o Resend (grátis), preservando a capacidade de voltar pro
MailerSend só mudando uma variável de ambiente, e dar um jeito de testar qualquer um dos dois
provedores sob demanda sem depender de um evento de negócio real.

---

## Escopo

### 1. Novo provedor Resend

- `ResendServiceImpl implements MailService` — mesmo padrão de retry (Resilience4j, 3 tentativas,
  backoff exponencial) e métricas (`email.sent`/`email.failed`) do `MailerSendServiceImpl`. Loga um
  aviso específico ao detectar `daily_quota_exceeded`/`monthly_quota_exceeded` na resposta da API.
- `ResendProperties`/`ResendConfig` (WebClient com `Authorization: Bearer`), `ResendEmailRequest`
  (formato da API do Resend: `from` é uma única string `"Nome <email>"`, `to` é lista de e-mails
  simples — diferente do formato estruturado por pessoa do MailerSend).

### 2. Seleção de provedor via configuração (sem editar MailerSend)

- Nova property `mail.provider` (`resend` por padrão, `mailersend` pra reverter) via
  `MAIL_PROVIDER`.
- `MailProviderConfig` — `@Bean @Primary` que escolhe qual `MailService` concreto é o ativo de fato
  (usado por `EmailNotificationProvider`/`CriticalEmailDispatchService`/`EmailRetryJob`), lido da
  property. As duas implementações concretas (`ResendServiceImpl`/`MailerSendServiceImpl`) ficam
  **sempre** registradas como bean — necessário pro endpoint de teste (item 3) conseguir usar
  qualquer um dos dois, independente de qual está ativo pro tráfego real.

### 3. Endpoint de teste manual (QA/ops)

- `GET /run-jobs/test-email?to=...&provider=resend|mailersend` em `JobController` — dispara um
  e-mail de teste (template fixo simples) via o provedor escolhido, sem depender de um evento de
  negócio real. Provedor inválido → `400` via `RuleException`.
- **Bug encontrado e corrigido durante a implementação**: `ResendServiceImpl`/`MailerSendServiceImpl`
  são `@Profile("!local")` — no perfil `local` (MailHog) nenhum dos dois existe como bean, e o
  `JobController` inicialmente exigia os dois no construtor, quebrando o boot local
  (`BeanCreationException`). Corrigido trocando pra `Optional<ResendServiceImpl>`/
  `Optional<MailerSendServiceImpl>` — o app sobe normalmente em qualquer perfil, e só falha (com
  erro claro) se o endpoint for de fato chamado pedindo um provedor indisponível naquele ambiente.

### 4. Testes

- TDD em cada mudança (RED confirmado antes do GREEN), incluindo uma reprodução do bug do item 3
  antes de corrigi-lo.
- `ResendServiceImplTest` — payload correto + métrica de sucesso, erro HTTP lança
  `InternalErrorException`, fallback incrementa métrica de falha.
- `JobControllerTest` — resolução de provedor por parâmetro (case-insensitive), provedor inválido
  rejeitado, e os dois cenários de provedor indisponível (`Optional.empty()`) sem quebrar o boot.

---

## Arquivos impactados

### Backend
- `infrastructure/mail/ResendServiceImpl.java` — **novo**
- `infrastructure/mail/dto/ResendEmailRequest.java`, `ResendEmailResponse.java` — **novos**
- `commons/properties/ResendProperties.java` — **novo**
- `config/ResendConfig.java` — **novo**
- `config/MailProviderConfig.java` — **novo**
- `infrastructure/mail/MailerSendServiceImpl.java` — sem mudança funcional, só documentação de que
  não é mais o padrão
- `jobs/infrastucture/web/JobController.java` — novo endpoint `GET /test-email`,
  `Optional<ResendServiceImpl>`/`Optional<MailerSendServiceImpl>`
- `application.properties` — `mail.provider`, `resend.*`, retry `resend` no Resilience4j

---

## Critérios de Aceite

- [x] Resend é o provedor ativo por padrão (`mail.provider=resend`)
- [x] MailerSend continua funcional, religável só via `MAIL_PROVIDER=mailersend`, sem mudança de
      código
- [x] Endpoint de teste dispara e-mail via qualquer um dos dois provedores, por parâmetro
- [x] App sobe normalmente no perfil `local` (MailHog), mesmo sem `ResendServiceImpl`/
      `MailerSendServiceImpl` disponíveis nesse perfil
- [x] Testes cobrindo os dois provedores + o cenário de provedor indisponível

## Dependências
Nenhuma.

## Riscos
- Nenhum teste no repositório sobe o contexto Spring real (`@SpringBootTest`) — o wiring de múltiplos
  beans `MailService` + `@Primary` não foi validado por um boot automatizado, só manualmente (boot
  local real, que inclusive pegou o bug do item 3). Recomendado validar em staging antes de confiar
  100% em produção.
- Plano grátis do Resend tem teto rígido (100/dia, 3.000/mês) sem fallback automático caso estoure —
  decisão consciente de Douglas (não implementar fallback automático agora, só religar manual via
  property se precisar).

## Esforço
Médio (provedor novo + reestruturação da seleção de bean + endpoint de teste + bugfix de boot)

## Status
Concluído — implementado, testado (684/684 testes backend green) e validado com boot local real
(MySQL + perfil `local`) após o bugfix do item 3. Commit direto em `staging` (`d9672b1`, sem branch
de feature dedicada), incluído no PR
[easy-maintenance-api#25](https://github.com/douglasjava/easy-maintenance-api/pull/25)
(`staging` → `main`).

## Implementação

- Sem branch de feature — commitado direto em `staging` (fora do padrão usual do projeto, registrado
  aqui só pra manter o histórico honesto).
- Pendências que ficaram para o Douglas resolver fora do código (não são deste repositório):
  1. Configurar o domínio `notify.easymaintenance.com.br` no painel do Resend + registros DNS
     (SPF/DKIM) no provedor de DNS — sem isso, envio real de produção fica restrito ao domínio
     sandbox do Resend.
  2. Configurar `RESEND_API_KEY` no ambiente de staging/produção.
  3. Avaliar cancelar o plano pago do MailerSend agora que o tráfego real está no Resend (ver
     `docs/INFRAESTRUTURA-TECNICA.md`, seção de provedores).
