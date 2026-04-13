# SPRINT-01 — Bloqueadores de Lançamento

> **Período:** Semana 1–2 (estimado)
> **Objetivo:** Resolver todos os bloqueadores críticos e altos que impedem um lançamento seguro em produção
> **Capacidade estimada:** 11 tasks (9 para execução + 2 em análise paralela)
> **Critério de saída:** Zero bloqueadores críticos abertos, zero bloqueadores altos de segurança abertos

---

## Meta da Sprint

> "Ao final desta sprint, o sistema pode ser colocado em produção sem risco de deslogar usuários em deploy, sem risco de cobrança duplicada, e sem as maiores vulnerabilidades de segurança expostas."

---

## Tasks da Sprint

---

### 🔴 TASK-001 — Persistir chaves RSA JWT
**Arquivo:** [TASK-001.md](../tasks/TASK-001.md)

**Objetivo nesta sprint:** Eliminar o logout forçado de todos os usuários a cada deploy.

**Por que está na Sprint 1:**
É o bloqueador mais crítico para operação em produção. Qualquer deploy desloga todos os usuários. Impede testes reais com usuários piloto.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Subir a aplicação, fazer login, reiniciar o servidor
- [ ] Verificar que a sessão ainda está válida após o restart
- [ ] Verificar nos logs que a chave foi carregada do environment, não gerada

**Área impactada:** Backend (AuthorizationServerConfig.java)

**Esforço:** 2-4h

---

### 🔴 TASK-003 — Implementar ShedLock nos jobs agendados
**Arquivo:** [TASK-003.md](../tasks/TASK-003.md)

**Objetivo nesta sprint:** Garantir que jobs de billing não executem em múltiplas instâncias simultaneamente.

**Por que está na Sprint 1:**
Sem ShedLock, qualquer escalonamento horizontal (incluindo blue-green deploys no Railway) gera cobranças duplicadas. Isso é um risco financeiro e legal imediato.

**Dependências:** Nenhuma. ShedLock com JDBC não requer infraestrutura adicional.

**Como validar:**
- [ ] Subir 2 instâncias localmente com Docker Compose
- [ ] Verificar que o job de billing executa apenas uma vez entre as duas instâncias
- [ ] Verificar que a tabela `shedlock` está sendo populada com os locks

**Área impactada:** Backend (jobs: SubscriptionBlockingJob, DailyTrialJob, BillingCycleJob, BillingCancellationJob, NotificationEventDetectionJob)

**Esforço:** 3-5h

---

### 🟠 TASK-005 — Desabilitar Swagger/OpenAPI em produção
**Arquivo:** [TASK-005.md](../tasks/TASK-005.md)

**Objetivo nesta sprint:** Remover a exposição do schema completo da API em ambiente de produção.

**Por que está na Sprint 1:**
Quick win de 30 minutos com impacto de segurança alto. Sem isso, qualquer pessoa pode mapear toda a API antes do lançamento.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Acessar `/swagger-ui.html` em produção → deve retornar 404
- [ ] Acessar `/v3/api-docs` em produção → deve retornar 404
- [ ] Confirmar que Swagger ainda funciona em ambiente local/hml

**Área impactada:** Backend (application-prod.properties, OpenApiConfig.java)

**Esforço:** 30min

---

### 🟠 TASK-006 — Rate limiting em auth, reset e IA
**Arquivo:** [TASK-006.md](../tasks/TASK-006.md)

**Objetivo nesta sprint:** Proteger endpoints críticos contra brute force e abuso de custo.

**Por que está na Sprint 1:**
Sem rate limiting, o endpoint de login está exposto a ataques automatizados de força bruta. O endpoint de IA pode gerar custo inesperado se abusado.

**Dependências:** Nenhuma (usar Caffeine como backend, já configurado)

**Como validar:**
- [ ] Executar 11 chamadas consecutivas para `/auth/login` → 11ª deve retornar 429
- [ ] Header `Retry-After` presente na resposta 429
- [ ] Executar 4 requests de reset com o mesmo e-mail em < 15 min → 4ª deve retornar 429

**Área impactada:** Backend (filtros de autenticação, controllers de auth e AI)

**Esforço:** 4-8h

---

### 🟠 TASK-007 — Validação robusta de webhook Asaas
**Arquivo:** [TASK-007.md](../tasks/TASK-007.md)

**Objetivo nesta sprint:** Garantir idempotência nos eventos de pagamento e que o token de webhook está em variável de ambiente.

**Por que está na Sprint 1:**
Webhook de pagamento sem deduplicação atômica pode processar eventos duplicados, gerando inconsistência de assinatura.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Enviar o mesmo evento de webhook duas vezes com o mesmo `providerEventId`
- [ ] Verificar que o evento é processado apenas uma vez
- [ ] Verificar que token de webhook está sendo lido de variável de ambiente
- [ ] Enviar webhook com token inválido → deve retornar 401 e logar o IP

**Área impactada:** Backend (AsaasWebhookController, WebhookEventLog)

**Esforço:** 3-5h

---

### 🟠 TASK-009 — Validar X-Org-Id contra claims do JWT
**Arquivo:** [TASK-009.md](../tasks/TASK-009.md)

**Objetivo nesta sprint:** Fechar a brecha de IDOR entre tenants.

**Por que está na Sprint 1:**
Um usuário autenticado trocando o header `X-Org-Id` pode potencialmente acessar dados de outro tenant. É o risco de segurança mais direto para um multi-tenant SaaS.

**Dependências:** Nenhuma (verificação lógica no filtro de autenticação existente)

**Como validar:**
- [ ] Criar dois usuários em organizações diferentes
- [ ] Autenticar como usuário A, trocar `X-Org-Id` para código da org B
- [ ] Requisição deve retornar 403

**Área impactada:** Backend (filtro de tenant/autenticação)

**Esforço:** 2-4h

---

### 🟠 TASK-010 — Auditar e rotacionar secrets no repositório
**Arquivo:** [TASK-010.md](../tasks/TASK-010.md)

**Objetivo nesta sprint:** Garantir que nenhuma chave de API de produção está exposta no histórico do git.

**Por que está na Sprint 1:**
Se chaves de produção estão no git history, elas precisam ser rotacionadas antes de qualquer lançamento. Quem tem acesso ao repositório tem acesso ao sistema de produção.

**Dependências:** Acesso às plataformas para rotacionar chaves (OpenAI, Asaas, MailerSend, AWS, Firebase)

**Como validar:**
- [ ] `truffleHog` ou `git-secrets` executado sem findings críticos
- [ ] Chaves rotacionadas nas plataformas
- [ ] `application-local.properties` no `.gitignore`
- [ ] `application-prod.properties` usa apenas placeholders `${VAR}`

**Área impactada:** DevOps / Configuração

**Esforço:** 2-4h

---

### 🟠 TASK-011 — Restringir endpoints do Actuator em produção
**Arquivo:** [TASK-011.md](../tasks/TASK-011.md)

**Objetivo nesta sprint:** Remover exposição de informações internas via Actuator.

**Por que está na Sprint 1:**
Quick win de 1-2h com impacto de segurança. `/actuator/health` com `show-details=always` expõe informações de infraestrutura interna.

**Dependências:** Nenhuma

**Como validar:**
- [ ] `GET /actuator/health` em produção retorna apenas `{"status":"UP"}` sem detalhes
- [ ] `/actuator/env` e `/actuator/beans` não acessíveis publicamente
- [ ] Prometheus ainda consegue fazer scrape em `/actuator/prometheus`

**Área impactada:** Backend (application-prod.properties)

**Esforço:** 1-2h

---

### 🟠 TASK-012 — Verificar e corrigir profile de e-mail em produção
**Arquivo:** [TASK-012.md](../tasks/TASK-012.md)

**Objetivo nesta sprint:** Confirmar que e-mails estão sendo enviados em produção.

**Por que está na Sprint 1:**
Se `@Profile("local")` não está ativo em produção, **nenhum e-mail está sendo enviado** — trial, cobrança, reset de senha. Isso é um bug crítico de produto que pode estar passando despercebido.

**Dependências:** Acesso ao ambiente de produção (Railway)

**Como validar:**
- [ ] Verificar `SPRING_PROFILES_ACTIVE` no Railway
- [ ] Enviar e-mail de teste via endpoint de reset de senha com e-mail real
- [ ] Confirmar recebimento do e-mail
- [ ] Verificar dashboard do MailerSend para confirmar entrega

**Área impactada:** Backend (MailerSendServiceImpl, application.properties, Railway config)

**Esforço:** 1-3h

---

### 🟠 TASK-013 — Adicionar security headers HTTP
**Arquivo:** [TASK-013.md](../tasks/TASK-013.md)

**Objetivo nesta sprint:** Adicionar camada básica de proteção contra ataques de browser.

**Por que está na Sprint 1:**
Headers de segurança são configuração, não implementação — 2-3h de trabalho que fecha múltiplos vetores (clickjacking, MIME sniffing, downgrade HTTP).

**Dependências:** Nenhuma

**Como validar:**
- [ ] Verificar headers em resposta HTTP via DevTools → Network → Headers
- [ ] `X-Frame-Options: DENY` presente
- [ ] `X-Content-Type-Options: nosniff` presente
- [ ] `Strict-Transport-Security` presente
- [ ] Validar em `securityheaders.com`

**Área impactada:** Backend (Spring Security config) + Frontend (next.config.ts)

**Esforço:** 2-3h

---

### 🟠 TASK-014 — Restrição CORS para domínio de produção
**Arquivo:** [TASK-014.md](../tasks/TASK-014.md)

**Objetivo nesta sprint:** Restringir origens permitidas ao domínio do frontend de produção.

**Por que está na Sprint 1:**
CORS permissivo + cookies (TASK-002) seria um risco sério. Mesmo sem cookies, é boa prática fechar antes do lançamento.

**Dependências:** Domínio de produção do frontend definido

**Como validar:**
- [ ] Request de origem `https://dominio-malicioso.com` com `Origin` header → bloqueado (sem `Access-Control-Allow-Origin` na resposta)
- [ ] Request de origem correta do frontend → aceito normalmente

**Área impactada:** Backend (CORS configuration)

**Esforço:** 1-2h

---

## Tasks em Análise Paralela (não bloqueiam execução das tasks acima)

### 🔴 TASK-002 — Migrar JWT para cookie HttpOnly
> Em análise técnica — requer decisão de arquitetura sobre cookies vs tokens
> **Decisão necessária:** Implementar agora (mais seguro, maior esforço) ou adicionar CSP restrito como mitigação temporária?

### 🔴 TASK-004 — Testes mínimos para billing e tenant isolation
> Em análise de escopo — definir quais testes são "mínimo viável" para o lançamento
> **Decisão necessária:** Qual é o escopo mínimo de testes para dar confiança suficiente?

---

## Backlog da Sprint (para Sprint 02)

Tasks que ficam para a próxima sprint após concluir S01:
- TASK-008 — Circuit breaker para serviços externos
- TASK-015 — Banner de trial expirando
- TASK-016 — Tratamento de erro no onboarding
- TASK-017 — Enforcement automático de tenant no repository

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída nesta sprint:
- [ ] Código implementado e revisado
- [ ] Validação manual executada conforme critérios da task
- [ ] Sem regressão visível nos fluxos de login, onboarding e dashboard
- [ ] Variáveis de ambiente de produção atualizadas no Railway se necessário
- [ ] Task movida para "Concluído" no kanban

---

## Retrospectiva (a preencher ao final)

**O que funcionou bem:**
_[preencher após sprint]_

**O que poderia melhorar:**
_[preencher após sprint]_

**Próximos passos:**
_[preencher após sprint]_
