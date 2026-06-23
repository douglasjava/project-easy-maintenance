#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# migrate-to-github-projects.sh
# Migra as tasks abertas do kanban markdown para GitHub Projects V2
#
# Uso: bash scripts/migrate-to-github-projects.sh
# Pré-requisito: gh auth login já executado
# ─────────────────────────────────────────────────────────────────────────────

set -e

OWNER="douglasjava"
REPO="project-easy-maintenance"
FULL_REPO="$OWNER/$REPO"
PROJECT_TITLE="Easy Maintenance — Kanban"

echo "═══════════════════════════════════════════════════════"
echo " Easy Maintenance — Migração para GitHub Projects"
echo " Repositório: $FULL_REPO"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────

create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" \
    --color "$color" \
    --description "$desc" \
    --repo "$FULL_REPO" \
    --force 2>/dev/null && echo "  label: $name" || echo "  (já existe) $name"
}

create_issue() {
  local title="$1" body="$2" labels="$3"
  local url
  url=$(gh issue create \
    --repo "$FULL_REPO" \
    --title "$title" \
    --body "$body" \
    --label "$labels" \
    --json url \
    --jq '.url')
  echo "  ✓ $title"
  echo "    $url"
  echo "$url"
}

# ─────────────────────────────────────────
# STEP 1 — LABELS
# ─────────────────────────────────────────
echo "📌 [1/4] Criando labels..."
echo ""

# Prioridade
create_label "prioridade: crítico"  "B60205" "🔴 Crítico"
create_label "prioridade: alto"     "E4480A" "🟠 Alto"
create_label "prioridade: médio"    "FBCA04" "🟡 Médio"
create_label "prioridade: baixo"    "0075CA" "🔵 Baixo"

# Tipo
create_label "tipo: bug"            "D73A4A" "Bug reportado"
create_label "tipo: backend"        "0E8A16" "Backend"
create_label "tipo: frontend"       "1D76DB" "Frontend"
create_label "tipo: full-stack"     "5319E7" "Full-Stack"
create_label "tipo: qa-manual"      "9B59B6" "QA Manual"
create_label "tipo: e2e"            "6C3483" "Teste E2E Playwright"
create_label "tipo: infra"          "84929E" "Infra / Config"

# Épicos
create_label "epic: EPIC-001"       "C0392B" "Segurança Crítica"
create_label "epic: EPIC-003"       "E67E22" "Multi-tenancy e Autorização"
create_label "epic: EPIC-004"       "F39C12" "Banco de Dados e Persistência"
create_label "epic: EPIC-005"       "27AE60" "Observabilidade e Operação"
create_label "epic: EPIC-006"       "2980B9" "Produto SaaS"
create_label "epic: EPIC-007"       "8E44AD" "Performance e Escalabilidade"
create_label "epic: EPIC-008"       "17A589" "Qualidade e Testes"
create_label "epic: EPIC-009"       "1A5276" "Performance Frontend"
create_label "epic: EPIC-010"       "7D6608" "PIX Recorrente"

# Status kanban (facilita filtro visual)
create_label "status: bug-ativo"    "B60205" "Bug ativo, não resolvido"
create_label "status: em-validação" "FEF2C0" "Implementado — aguarda validação"
create_label "status: pronto"       "C2E0C6" "Pronto para implementar"
create_label "status: backlog"      "E1E4E8" "Backlog — ainda não priorizado"

echo ""
echo "✅ Labels prontos!"
echo ""

# ─────────────────────────────────────────
# STEP 2 — ISSUES
# Guarda as URLs para adicionar ao projeto
# ─────────────────────────────────────────
echo "📝 [2/4] Criando issues..."
echo ""

ISSUE_URLS=()

# ── 🐛 BUGS ────────────────────────────────────────────────────────────────

echo "── Bugs ──"

url=$(create_issue \
  "[TASK-055] Bug: Sessão do usuário sem organização é apagada após login" \
"## Problema
Usuário faz login pela primeira vez (sem org vinculada), é redirecionado para onboarding, mas ao montar a página \`initAuth()\` chama \`checkSubscription()\` → recebe 400 do TenantFilter (sem X-Org-Id) → interpreta como sessão inválida → apaga isLoggedIn/userId/userName.

## Root Cause
- **Backend:** \`GET /me/access-context\` não está no bypass do TenantFilter.
- **Frontend:** \`initAuth()\` trata UNKNOWN (oriundo do 400) como cookie expirado e limpa estado.

## Fix Proposto
1. Adicionar \`GET /me/access-context\` ao \`BYPASS_EXACT\` no \`TenantFilter.java\`
2. \`AuthContext.initAuth()\`: não limpar estado em UNKNOWN quando usuário não tem org

## Critérios de Aceite
- [ ] Usuário sem org acessa /onboarding com sessão preservada
- [ ] \`isLoggedIn\`, \`userId\`, \`userName\` permanecem no storage após redirect
- [ ] \`checkSubscription()\` retorna ACTIVE para trial válido mesmo sem org
- [ ] Cookie expirado ainda limpa a sessão (sem regressão no logout implícito)

---
📁 \`roadmap/tasks/TASK-055.md\`" \
"tipo: bug,tipo: full-stack,prioridade: crítico,epic: EPIC-006,status: bug-ativo")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-QA-BUG-001] Bug: Onboarding sem redirect após conclusão (JWT stale pós-onboarding)" \
"## Problema
Após concluir o onboarding, o frontend recebia 403 porque o JWT ainda tinha \`orgs: []\` — o TenantFilter rejeitava o \`GET /me/access-context\` com X-Org-Id recém-criado.

## Correção Aplicada (v2)
- **Backend:** \`OnboardingController.createOrganization()\` emite JWT renovado (com org incluída) e seta novo cookie \`accessToken\` na mesma response.
- **Frontend:** \`window.location.replace('/')\` garante remontagem limpa do \`AccessContextProvider\`.

## Status
🔄 Corrigido v2 — aguardando validação final

## Critérios de Aceite
- [ ] Após onboarding → redirect automático para o dashboard
- [ ] Dados da org disponíveis no contexto (sem necessidade de re-login)
- [ ] Nenhum erro exibido durante o redirect
- [ ] Fluxo funciona com e sem refresh de página

---
📁 \`roadmap/QA/tasks/TASK-QA-BUG-001.md\`" \
"tipo: bug,tipo: full-stack,prioridade: alto,epic: EPIC-006,status: em-validação")
ISSUE_URLS+=("$url")

# ── 🔄 EM VALIDAÇÃO — EPIC-010 PIX ─────────────────────────────────────────

echo ""
echo "── Em Validação — PIX (EPIC-010) ──"

url=$(create_issue \
  "[TASK-058] Refatorar job de expiração de TRIAL: PIX via cobrança avulsa (DETACHED)" \
"## Contexto
O Asaas \`/subscriptions\` só aceita CREDIT_CARD. Para PIX recorrente, cada ciclo é gerenciado internamente via cobrança avulsa (DETACHED).

## Escopo
Refatorar o job de expiração de TRIAL para criar cobrança PIX avulsa no Asaas quando o método escolhido for PIX.

## Critérios de Aceite
- [ ] Job cria cobrança DETACHED ao expirar trial com método PIX
- [ ] Webhook \`PAYMENT_CREATED\` recebido e vinculado à subscription
- [ ] Subscription local atualizada com \`payment_id\` da cobrança avulsa
- [ ] Trial com cartão de crédito não é impactado (sem regressão)

---
📁 \`roadmap/tasks/TASK-058.md\`" \
"tipo: backend,prioridade: crítico,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-059] Subscription PIX recorrente manual: ciclo gerenciado internamente" \
"## Contexto
Como o Asaas não suporta PIX em /subscriptions, o ciclo de cobrança PIX é gerenciado internamente — cada ciclo gera uma nova cobrança DETACHED.

## Escopo
Implementar a lógica de ciclo de cobrança PIX no backend: criação, tracking de estado e geração do próximo ciclo.

## Critérios de Aceite
- [ ] Ciclo de billing PIX criado e gerenciado internamente
- [ ] Próxima cobrança DETACHED gerada ao confirmar pagamento do ciclo atual
- [ ] Estado da subscription atualizado a cada transição de ciclo
- [ ] Idempotência garantida (não duplicar cobrança se webhook chegar duas vezes)

---
📁 \`roadmap/tasks/TASK-059.md\`" \
"tipo: backend,prioridade: crítico,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-060] Webhook PAYMENT_RECEIVED avança ciclo PIX manual" \
"## Escopo
Handler do webhook \`PAYMENT_RECEIVED\` deve: marcar o pagamento atual como PAID, avançar o estado da subscription e gerar nova cobrança DETACHED para o próximo ciclo.

## Critérios de Aceite
- [ ] \`PAYMENT_RECEIVED\` marca payment como PAID no banco
- [ ] Nova cobrança DETACHED criada para o próximo ciclo
- [ ] Subscription permanece ACTIVE após confirmação
- [ ] Idempotência: reenvio do webhook não gera duplicidade

---
📁 \`roadmap/tasks/TASK-060.md\`" \
"tipo: backend,prioridade: crítico,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-061] UX: seleção de método de pagamento antes da expiração do TRIAL" \
"## Escopo
Tela/modal de seleção de método de pagamento (PIX ou Cartão) exibida ao usuário antes do TRIAL expirar.

## Critérios de Aceite
- [ ] Seleção exibida com antecedência suficiente antes da expiração
- [ ] Escolha PIX: dispara criação de cobrança DETACHED (TASK-058/059)
- [ ] Escolha Cartão: segue fluxo existente via Asaas /subscriptions
- [ ] UX responsiva (mobile 375px)

---
📁 \`roadmap/tasks/TASK-061.md\`" \
"tipo: frontend,prioridade: alto,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-062] Classificador de motivos de recusa Asaas + roteamento por bucket" \
"## Escopo
Classificar os motivos de falha de pagamento retornados pelo Asaas em buckets semânticos (cartão recusado, sem limite, suspeita de fraude, etc.) e mapear para mensagens de notificação adequadas ao usuário.

## Critérios de Aceite
- [ ] Mapeamento de códigos Asaas → buckets definido
- [ ] E-mail/notificação ao usuário usa mensagem do bucket correto
- [ ] Bucket UNKNOWN tratado com mensagem genérica (sem vazamento de detalhe técnico)

---
📁 \`roadmap/tasks/TASK-062.md\`" \
"tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-063] Job de reconciliação noturna: Asaas vs estado local" \
"## Escopo
Job noturno que consulta o Asaas e compara com o estado local de subscriptions/payments, corrigindo divergências (ex: pagamento confirmado no Asaas mas ainda PENDING localmente).

## Critérios de Aceite
- [ ] Job executa nightly com ShedLock (não duplica em múltiplas instâncias)
- [ ] Divergências logadas e corrigidas automaticamente
- [ ] Alertas para divergências que não podem ser resolvidas automaticamente

---
📁 \`roadmap/tasks/TASK-063.md\`" \
"tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-064] Hardening de webhook Asaas: DLQ + replay manual" \
"## Escopo
Adicionar Dead Letter Queue para webhooks que falharam no processamento, com endpoint de replay manual para reprocessar eventos sem intervenção no banco.

## Critérios de Aceite
- [ ] Falha no processamento de webhook → evento vai para DLQ
- [ ] Endpoint \`POST /admin/webhooks/replay/{id}\` disponível para ops
- [ ] DLQ não perde eventos entre restarts da aplicação
- [ ] Retry automático (N tentativas) antes de ir para DLQ

---
📁 \`roadmap/tasks/TASK-064.md\`" \
"tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-065] Frontend: tela 'Atualizar método de pagamento' para subscriptions PAST_DUE" \
"## Escopo
Tela acessível ao usuário com subscription em PAST_DUE para atualizar o método de pagamento: trocar cartão de crédito ou gerar novo QR Code PIX.

## Critérios de Aceite
- [ ] Tela exibida automaticamente quando subscription está PAST_DUE
- [ ] Opção de trocar cartão (redirect para checkout Asaas)
- [ ] Opção de gerar novo PIX (nova cobrança DETACHED)
- [ ] Estado atualizado em tempo real após ação do usuário
- [ ] Responsiva (mobile 375px)

---
📁 \`roadmap/tasks/TASK-065.md\`" \
"tipo: frontend,prioridade: alto,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

# ── 🔄 EM VALIDAÇÃO — E2E ───────────────────────────────────────────────────

echo ""
echo "── Em Validação — E2E ──"

url=$(create_issue \
  "[TASK-E2E-001] Setup do projeto Playwright E2E (easy-maintenance-e2e)" \
"## Status
Projeto criado e funcional. TypeScript compila. Smoke test pronto. Aguarda execução contra API real e CI.

## Subtasks Pendentes
- [ ] Instalar browsers Playwright no CI (\`npx playwright install chromium\`)
- [ ] Criar seed SQL para TENANT_A e TENANT_B (pré-requisito para TASK-E2E-002)

## Estrutura
\`\`\`
easy-maintenance-e2e/
├── playwright.config.ts    (projetos api + ui)
├── docker-compose.e2e.yml  (MySQL:3307 + MailHog:1026)
├── fixtures/               (auth, tenant, api-client)
├── tests/                  (smoke, auth, billing, data, frontend)
└── helpers/db.ts
\`\`\`

---
📁 \`roadmap/QA/tasks/TASK-E2E-001.md\`" \
"tipo: e2e,tipo: infra,prioridade: alto,epic: EPIC-008,status: em-validação")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-E2E-003] Testes E2E: Webhook Asaas — Token e Idempotência" \
"## Status
9 testes implementados. TypeScript compila. Aguarda execução contra API + DB reais e integração no CI.

## Cobertura
- Validação de token (válido / inválido / ausente / branco)
- Idempotência via constraint UNIQUE no banco (\`webhook_event_log\`)
- Campos PIX populados via \`PAYMENT_CREATED\` (billingType PIX e CREDIT_CARD)

## Pendências
- [ ] Integrar na suite CI como job obrigatório em PRs que tocam segurança/billing/webhook

---
📁 \`roadmap/QA/tasks/TASK-E2E-003.md\`" \
"tipo: e2e,prioridade: alto,epic: EPIC-001,epic: EPIC-010,status: em-validação")
ISSUE_URLS+=("$url")

# ── ✅ PRONTO PARA IMPLEMENTAR ──────────────────────────────────────────────

echo ""
echo "── Pronto para Implementar ──"

url=$(create_issue \
  "[TASK-E2E-004] Testes E2E: Soft Delete e Filtro Automático de Listagens" \
"## Escopo
Testes E2E Playwright verificando que:
1. Deleção de entidade preenche \`deleted_at\` (não remove fisicamente)
2. Registros deletados não aparecem nas listagens da API
3. Filtro \`@Where\` do Hibernate está ativo (comparando contagem API vs SQL raw)

## Épico
EPIC-004 / EPIC-008 — substitui TASK-QA-AUTO-005

## Dependências
- TASK-E2E-001 concluído ✅
- Fixture de auth de TASK-E2E-002 disponível

---
📁 \`roadmap/QA/tasks/TASK-E2E-004.md\`" \
"tipo: e2e,prioridade: médio,epic: EPIC-004,epic: EPIC-008,status: pronto")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-E2E-005] Testes E2E: Performance React Query sem Requisições Redundantes" \
"## Escopo
Testes E2E com Playwright + interceptor de network validando:
- Segunda visita dentro do staleTime → ZERO re-fetch
- Window focus → ZERO re-fetch
- staleTime expirado → re-fetch correto
- Máximo 2 requests na carga inicial de /items (sem N+1)
- Sem flash de tela antes de redirect de auth

## Épico
EPIC-009 — Performance Frontend — substitui TASK-QA-AUTO-006

## Dependências
- TASK-E2E-001 concluído ✅
- Frontend Next.js no docker-compose.e2e.yml

---
📁 \`roadmap/QA/tasks/TASK-E2E-005.md\`" \
"tipo: e2e,prioridade: médio,epic: EPIC-009,status: pronto")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-021] Alertas no Prometheus/Grafana" \
"## Escopo
Configurar alertas no Prometheus/Grafana para métricas críticas: latência de endpoints, taxa de erro 5xx, uso de memória/CPU, job failures.

## Épico
EPIC-005 — Observabilidade e Operação

---
📁 \`roadmap/tasks/TASK-021.md\`" \
"tipo: infra,prioridade: médio,epic: EPIC-005,status: pronto")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-066] Implementar Pix Automático (mandato no banco do payer)" \
"## Escopo
Implementar suporte ao Pix Automático regulamentado pelo Bacen — mandato que permite débito automático na conta do pagador, eliminando a necessidade de gerar QR Code a cada ciclo.

## Dependência
**Bloqueia:** estabilização das TASK-058 a TASK-065 deve estar concluída antes de iniciar.

## Épico
EPIC-010 — PIX Recorrente (Fase 3)

---
📁 \`roadmap/tasks/TASK-066.md\`" \
"tipo: full-stack,prioridade: médio,epic: EPIC-010,status: pronto")
ISSUE_URLS+=("$url")

# ── QA MANUAL — PENDENTE ────────────────────────────────────────────────────

echo ""
echo "── QA Manual — Pendente ──"

url=$(create_issue \
  "[TASK-QA-MAN-003] QA Manual: Fluxo PIX completo com Sandbox Asaas" \
"## Escopo
Validação manual E2E do fluxo completo de pagamento PIX:
1. \`PAYMENT_CREATED\` → QR Code exibido na página /billing
2. \`PAYMENT_OVERDUE\` → e-mail de lembrete enviado + banner vermelho
3. \`PAYMENT_RECEIVED\` → card desaparece automaticamente (≤ 30s)
4. Regressão: cartão de crédito não exibe card PIX

## Pré-condições
- Ambiente sandbox Asaas configurado
- Acesso ao painel sandbox para disparar webhooks manualmente
- Variável \`ASAAS_WEBHOOK_TOKEN\` configurada

## Épico
EPIC-010 — PIX Recorrente

---
📁 \`roadmap/QA/tasks/TASK-QA-MAN-003.md\`" \
"tipo: qa-manual,prioridade: crítico,epic: EPIC-010,status: pronto")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-QA-MAN-004] QA Manual: Onboarding em cenários de erro" \
"## Escopo
Validação manual do onboarding com foco em cenários de erro:
1. Happy path completo (< 3 min)
2. CPF inválido → mensagem inline no campo (não toast)
3. E-mail duplicado → mensagem específica com orientação para login
4. Asaas indisponível (circuit breaker OPEN) → opção de trial sem pagamento
5. Timeout de rede → botão retry com dados preservados
6. Sentry: zero erros não tratados capturados

## Épico
EPIC-006 — Produto SaaS

---
📁 \`roadmap/QA/tasks/TASK-QA-MAN-004.md\`" \
"tipo: qa-manual,prioridade: alto,epic: EPIC-006,status: pronto")
ISSUE_URLS+=("$url")

# ── 📋 BACKLOG ───────────────────────────────────────────────────────────────

echo ""
echo "── Backlog ──"

url=$(create_issue \
  "[TASK-033] Status page básica" \
"## Escopo
Criar status page pública com indicadores de disponibilidade dos serviços (API, banco, Asaas, e-mail).

## Épico
EPIC-005 — Observabilidade e Operação

---
📁 \`roadmap/tasks/TASK-033.md\`" \
"tipo: infra,prioridade: baixo,epic: EPIC-005,status: backlog")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-035] Política de retenção para audit_logs" \
"## Escopo
Implementar job que remove registros de audit_logs mais antigos que N dias (configurável), evitando crescimento ilimitado da tabela.

## Épico
EPIC-004 — Banco de Dados e Persistência

---
📁 \`roadmap/tasks/TASK-035.md\`" \
"tipo: backend,prioridade: baixo,epic: EPIC-004,status: backlog")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-037] Jobs de billing assíncronos com fila" \
"## Escopo
Mover processamento pesado de billing para fila assíncrona (ex: RabbitMQ ou Redis Streams) para evitar bloqueio de thread em picos de cobrança.

## Épico
EPIC-007 — Performance e Escalabilidade

---
📁 \`roadmap/tasks/TASK-037.md\`" \
"tipo: backend,prioridade: baixo,epic: EPIC-007,status: backlog")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-038] LGPD: exportação e exclusão de dados pessoais" \
"## Escopo
Implementar endpoints para: (1) exportação de todos os dados pessoais de um usuário em JSON/CSV; (2) exclusão definitiva conforme direito ao esquecimento da LGPD.

## Épico
EPIC-003 — Multi-tenancy e Autorização

---
📁 \`roadmap/tasks/TASK-038.md\`" \
"tipo: backend,prioridade: baixo,epic: EPIC-003,status: backlog")
ISSUE_URLS+=("$url")

url=$(create_issue \
  "[TASK-040] Acessibilidade básica (WCAG AA)" \
"## Escopo
Garantir conformidade WCAG AA nas principais telas: contraste mínimo 4.5:1, navegação completa por teclado, ARIA labels em elementos interativos, skip-to-content link.

## Épico
EPIC-006 — Produto SaaS

---
📁 \`roadmap/tasks/TASK-040.md\`" \
"tipo: frontend,prioridade: baixo,epic: EPIC-006,status: backlog")
ISSUE_URLS+=("$url")

echo ""
echo "✅ [2/4] Todos os ${#ISSUE_URLS[@]} issues criados!"
echo ""

# ─────────────────────────────────────────
# STEP 3 — CRIAR PROJETO
# ─────────────────────────────────────────
echo "📋 [3/4] Criando GitHub Project..."

PROJECT_URL=$(gh project create \
  --owner "$OWNER" \
  --title "$PROJECT_TITLE" \
  --format json \
  --jq '.url')

# Extrai o número do projeto da URL (último segmento numérico)
PROJECT_NUMBER=$(basename "$PROJECT_URL")

echo "  ✓ Projeto criado: $PROJECT_URL"
echo "  ✓ Número do projeto: $PROJECT_NUMBER"
echo ""

# ─────────────────────────────────────────
# STEP 4 — ADICIONAR ISSUES AO PROJETO
# ─────────────────────────────────────────
echo "🔗 [4/4] Adicionando issues ao projeto..."

for url in "${ISSUE_URLS[@]}"; do
  # Extrai apenas a URL (remove linhas extras que o create_issue imprime)
  clean_url=$(echo "$url" | grep "https://github.com" | head -1)
  if [ -n "$clean_url" ]; then
    gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$clean_url" 2>/dev/null \
      && echo "  ✓ $clean_url" \
      || echo "  ⚠ Falha ao adicionar: $clean_url"
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo " ✅ Migração concluída!"
echo ""
echo " 🔗 Projeto: $PROJECT_URL"
echo " 📊 Issues criados: ${#ISSUE_URLS[@]}"
echo ""
echo " Próximos passos no GitHub Projects:"
echo ""
echo " 1. Abra o projeto e configure as colunas do 'Status' field:"
echo "    • 🐛 Bug Ativo"
echo "    • 🔄 Em Validação"
echo "    • ✅ Pronto para Implementar"
echo "    • 📋 Backlog"
echo "    • ✔ Concluído"
echo ""
echo " 2. Distribua as issues nas colunas:"
echo "    Bug Ativo     → TASK-055"
echo "    Em Validação  → TASK-QA-BUG-001, TASK-058~065, TASK-E2E-001, TASK-E2E-003"
echo "    Pronto        → TASK-E2E-004, E2E-005, TASK-021, TASK-066, QA-MAN-003, QA-MAN-004"
echo "    Backlog       → TASK-033, 035, 037, 038, 040"
echo "═══════════════════════════════════════════════════════"
