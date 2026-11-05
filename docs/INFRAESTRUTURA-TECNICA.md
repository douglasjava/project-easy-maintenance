# 🧱 Infraestrutura Técnica e Provedores — Easy Maintenance

> ⚠️ **Documento interno.** Contém contas de e-mail, custos e status de MFA de provedores de
> infraestrutura/pagamento. **Não usar como base para material de marketing, pitch ou qualquer
> conteúdo que possa ser compartilhado externamente** — para isso, ver
> `docs/produto/context-brief.md` (seção 7, versão só com tecnologias, sem custo/conta).

**Última atualização:** 2026-07-25

---

## 1. Objetivo

Inventariar, em um único lugar, todos os componentes técnicos e provedores externos usados pelo
Easy Maintenance — o que é, para que serve, quanto custa e em qual conta está — para que qualquer
pessoa do time consiga entender a infraestrutura completa sem precisar caçar informação espalhada
em `application.properties`, `pom.xml`, `package.json` e memória de quem configurou.

Este documento **não** descreve fluxos de arquitetura (para isso, ver os design docs em
`docs/superpowers/specs/` e os runbooks em `docs/runbooks/`) — é um inventário de componentes.

---

## 2. Stack Tecnológico

### 2.1 Backend (`easy-maintenance-api`)

| Componente | Tecnologia | Propósito |
|---|---|---|
| Linguagem | Java 21 | |
| Framework | Spring Boot 3.5.7 | |
| Persistência | Spring Data JPA / Hibernate | ORM |
| Banco de dados | MySQL 8 | |
| Migrações | Flyway (`flyway-core` + `flyway-mysql`) | Versionamento de schema |
| Segurança | Spring Security + OAuth2 Authorization Server + JWT (`jjwt`) | Login, tokens, refresh |
| 2FA | `totp` (TOTP/Google Authenticator) | Segundo fator de usuários admin |
| Documentação de API | SpringDoc OpenAPI (Swagger UI) | `/swagger-ui.html` |
| Mapeamento de DTO | MapStruct | |
| Boilerplate | Lombok | |
| Resiliência | Resilience4j (retry, circuit breaker) | Integrações externas (Asaas, WhatsApp, IA, e-mail) |
| Rate limiting | Bucket4j | Endpoints de autenticação |
| Cache | Caffeine | |
| Jobs distribuídos | ShedLock (JDBC) | Evita execução duplicada de `@Scheduled` em múltiplas instâncias |
| Cliente HTTP reativo | Spring WebFlux `WebClient` | Chamadas a Asaas, WhatsApp Cloud API, Resend, MailerSend |
| IA | Spring AI (`spring-ai-openai-spring-boot-starter`) | Provider OpenAI + DeepSeek (compatível via base-url) |
| Storage de arquivos | AWS SDK S3 (`software.amazon.awssdk:s3`) | Comprovantes/certificados de manutenção |
| Push notifications | `firebase-admin` | Firebase Cloud Messaging |
| Métricas | Micrometer + Micrometer Prometheus Registry | `/actuator/prometheus` |
| Observabilidade de erros | Sentry (`sentry-spring-boot-starter-jakarta`) | |
| Testes | JUnit 5, Mockito, AssertJ, Testcontainers | |
| Build | Maven (`mvnw`) | |

### 2.2 Frontend (`easy-maintenance-web`)

| Componente | Tecnologia | Propósito |
|---|---|---|
| Framework | Next.js 16 (React 19) | App Router |
| Linguagem | TypeScript | |
| UI | Bootstrap 5 + Bootstrap Icons + `lucide-react` | |
| Estado/dados servidor | TanStack React Query v5 | |
| HTTP | Axios | |
| Auth client-side | `js-cookie` | Armazenamento de token |
| Push/Firebase client | `firebase` (JS SDK) | |
| Notificações UI | `react-hot-toast` | |
| Observabilidade | `@sentry/nextjs` | |
| Telemetria | OpenTelemetry (`@opentelemetry/*`) | |
| Testes | Jest + `ts-jest` | |
| Lint | ESLint (`eslint-config-next`) | |

### 2.3 Testes E2E (`easy-maintenance-e2e`)

| Componente | Tecnologia | Propósito |
|---|---|---|
| Framework E2E | Playwright | Testes de UI e API ponta a ponta |
| Seed de banco | `ts-node` + `mysql2` | Scripts de setup de dados de teste |
| Auth de teste | `bcryptjs` | Gerar hashes de senha nos fixtures |

### 2.4 CI/CD

| Componente | Ferramenta | Propósito |
|---|---|---|
| Pipeline | GitHub Actions (`.github/workflows/ci-backend.yml`, `easy-maintenance-api/.github/workflows/ci.yml`) | Build + `mvn verify` a cada push/PR para `main` |
| Cobertura | JaCoCo | Upload do relatório como artifact do workflow |
| Banco de teste (CI) | H2 in-memory | Substitui MySQL só no pipeline, via `SPRING_DATASOURCE_URL=jdbc:h2:mem:testdb` |

### 2.5 Observabilidade local (dev)

Definido em `easy-maintenance-api/docker-compose.yml` — sobe local, não é o ambiente de produção:

| Serviço | Imagem | Porta local |
|---|---|---|
| MySQL | `mysql:8.0` | 3306 |
| Prometheus | `prom/prometheus` | 9090 |
| Alertmanager | `prom/alertmanager` | 9093 |
| Grafana | `grafana/grafana` | 3001 |
| MailHog (SMTP fake) | `mailhog/mailhog` | 1025 (SMTP) / 8025 (UI) |

Em produção, métricas são raspadas por **Grafana Cloud** (ver `docs/OBSERVABILITY.md`), não pelo
Prometheus/Grafana local do compose.

---

## 3. Arquitetura de Módulos (Backend)

Pacotes de domínio em `com.brainbyte.easy_maintenance` (DDD modular, sem camada de arquitetura
compartilhada única — cada pacote é dono do seu fluxo):

| Pacote | Responsabilidade |
|---|---|
| `admin` | Bootstrap do sistema (criação da primeira org/usuário) |
| `affiliates` | Programa de afiliados (cadastro, comissão, link de indicação) |
| `ai` | Assistente de IA, resumo executivo, sugestão de itens (OpenAI + DeepSeek) |
| `assets` | Itens de manutenção e registros de manutenção |
| `billing` | Planos, assinaturas, ciclo de cobrança, limites por plano |
| `catalog_norms` | Catálogo técnico de normas regulatórias |
| `dashboard` | KPIs e agregações para a tela inicial |
| `infrastructure` | Integrações técnicas transversais: `mail` (Resend/MailerSend), `notification` (e-mail/push/WhatsApp), `observability` (métricas), `access`, `audit`, `saas`, `storage` (S3) |
| `jobs` | Jobs agendados (`@Scheduled` + ShedLock): billing, notificações, trial, deferred-send |
| `leads` | Captura de leads da landing page |
| `onboarding` | Fluxo de criação de conta/organização no primeiro acesso |
| `org_users` | Organizações (tenants) e usuários |
| `payment` | Domínio de pagamento (complementar ao billing) |
| `push` | Notificações push (Firebase Cloud Messaging) |
| `reports` | Relatórios cross-org (`/me/reports`) |
| `supplier` | Busca de fornecedores via geolocalização (Google Maps) |
| `webhooks` | Recebimento de eventos externos: `asaas` (pagamento), `whatsapp` (status de entrega/leitura) |
| `commons` / `config` / `kernel` / `shared` | Exceções, properties, `TenantContext`, filtros, tratamento de erro (`ProblemDetail`) |

---

## 4. Provedores Externos (Infra & SaaS)

| Item | Provedor | MFA | Valor | Plano | Recorrente | Conta |
|---|---|---|---|---|---|---|
| Storage (S3) | AWS | Google Authenticator | Free tier — 20GB × $0,023 = **$0,46** | — | — | easymaintenancecompany@gmail.com |
| IA | DeepSeek | — | $30,00 | Crédito manual | Sem recarga automática | easymaintenancecompany@gmail.com |
| IA | ChatGPT (OpenAI) | — | $30,00 | Crédito manual | Sem recarga automática | douglasmarquesdias@gmail.com |
| Maps | Google Cloud | — | On demand | On demand | Sem recarga automática | brainbyteconsultoria@gmail.com |
| Push (Firebase) | Google Cloud / Firebase | — | Free tier | Grátis | — | brainbyteconsultoria@gmail.com |
| Envio de e-mail | MailerSend | — | $7,00/mês | 3.000 e-mails/mês | Sem recarga automática | easymaintenancecompany@gmail.com |
| Envio de e-mail | Resend | — | Grátis | 3.000/mês, 100/dia | — | douglasmarquesdias@gmail.com |
| Hospedagem | Railway | Google Authenticator | $5,00/mês base | Até 48 vCPU / 48GB RAM por serviço, até 6 réplicas (8 vCPU/8GB cada); acima disso cobra por uso: Memória $0,000231/GB/min · CPU $0,000463/vCPU/min · Volume $0,000003/GB/min · Egress $0,05/GB | Se passar do incluso, cobrado por consumo | GitHub (login) |
| Domínio | GoDaddy | — | $99,00/ano | — | — | douglasmarquesdias@gmail.com |
| Monitoramento | Sentry | — | Grátis | Free tier | — | GitHub (login) |
| Gateway de pagamento | Asaas | — | Por transação | — | — | easymaintenancecompany@gmail.com |
| DNS | Cloudflare | — | Grátis | Free tier | — | douglasmarquesdias@gmail.com |

### Notas sobre a tabela

- **E-mail (MailerSend → Resend):** desde 24/07/2026, Resend é o provedor **ativo por padrão**
  (`mail.provider=resend`); MailerSend continua integrado no código, só desativado, pra religar via
  variável de ambiente sem precisar de deploy de código novo (ver `MailProviderConfig` e
  `roadmap/kanban.md`). Ainda cobrando $7/mês enquanto o plano MailerSend não for cancelado — vale
  reavaliar o cancelamento agora que o tráfego real está no Resend.
- **Railway:** único provedor com custo variável relevante por consumo — acompanhar conforme a base
  de organizações crescer, é o item com maior risco de virar custo surpresa.
- **Asaas:** cobrança é por transação processada (PIX/cartão/boleto), não tem mensalidade fixa
  documentada aqui — conferir taxa vigente direto no painel Asaas antes de qualquer projeção
  financeira (taxas de gateway mudam com frequência).

---

## 5. Observações de Segurança

- Só **AWS (S3)** e **Railway** têm MFA confirmado (Google Authenticator) nesta tabela. Contas de
  **pagamento** (Asaas) e **domínio** (GoDaddy) sem MFA registrado são o maior risco — um
  comprometimento de e-mail levaria a controle de cobrança/domínio. Recomendado habilitar MFA
  nessas contas prioritariamente.
- Credenciais reais (API keys, tokens) **nunca** ficam neste documento nem no repositório — só como
  variável de ambiente (ver `application.properties` de cada serviço para o nome da env var
  esperada, ex. `RESEND_API_KEY`, `WHATSAPP_APP_SECRET`, `ASAAS_API_KEY`).
- Contas usadas se dividem em 3 e-mails diferentes (`easymaintenancecompany@gmail.com`,
  `douglasmarquesdias@gmail.com`, `brainbyteconsultoria@gmail.com`) — sem um cofre de senhas
  compartilhado documentado aqui; considerar consolidar em um gerenciador de senhas de equipe se o
  time crescer além do fundador.

---

## 6. Como manter este documento atualizado

Atualizar quando:
- Um novo provedor externo for contratado (adicionar linha na seção 4).
- Um provedor for trocado ou desativado (ex.: troca MailerSend → Resend já refletida acima).
- Uma dependência de peso for adicionada ao backend/frontend (`pom.xml`/`package.json`).
- O custo, plano ou conta de um provedor existente mudar.
