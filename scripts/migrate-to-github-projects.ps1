# ─────────────────────────────────────────────────────────────────────────────
# migrate-to-github-projects.ps1
# Migra as tasks abertas do kanban markdown para GitHub Projects V2
#
# Uso: .\scripts\migrate-to-github-projects.ps1
# Pre-requisito: gh auth login ja executado
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$OWNER          = "douglasjava"
$REPO           = "project-easy-maintenance"
$FULL_REPO      = "$OWNER/$REPO"
$PROJECT_TITLE  = "Easy Maintenance — Kanban"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Easy Maintenance — Migracao para GitHub Projects"      -ForegroundColor Cyan
Write-Host " Repositorio: $FULL_REPO"                               -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────

function New-Label($name, $color, $desc) {
    gh label create $name --color $color --description $desc --repo $FULL_REPO --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  label: $name" -ForegroundColor Green
    } else {
        Write-Host "  (ja existe) $name" -ForegroundColor DarkGray
    }
}

function New-Issue($title, $body, $labels) {
    $url = gh issue create `
        --repo $FULL_REPO `
        --title $title `
        --body $body `
        --label $labels `
        --json url `
        --jq '.url'

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO ao criar: $title" -ForegroundColor Red
        return $null
    }

    Write-Host "  ok  $title" -ForegroundColor Green
    Write-Host "      $url"   -ForegroundColor DarkGray
    return $url
}

$issueUrls = [System.Collections.Generic.List[string]]::new()

# ─────────────────────────────────────────
# STEP 1 — LABELS
# ─────────────────────────────────────────
Write-Host "📌 [1/4] Criando labels..." -ForegroundColor Yellow
Write-Host ""

# Prioridade
New-Label "prioridade: critico"   "B60205" "Critico"
New-Label "prioridade: alto"      "E4480A" "Alto"
New-Label "prioridade: medio"     "FBCA04" "Medio"
New-Label "prioridade: baixo"     "0075CA" "Baixo"

# Tipo
New-Label "tipo: bug"             "D73A4A" "Bug reportado"
New-Label "tipo: backend"         "0E8A16" "Backend"
New-Label "tipo: frontend"        "1D76DB" "Frontend"
New-Label "tipo: full-stack"      "5319E7" "Full-Stack"
New-Label "tipo: qa-manual"       "9B59B6" "QA Manual"
New-Label "tipo: e2e"             "6C3483" "Teste E2E Playwright"
New-Label "tipo: infra"           "84929E" "Infra / Config"

# Epicos
New-Label "epic: EPIC-001"        "C0392B" "Seguranca Critica"
New-Label "epic: EPIC-003"        "E67E22" "Multi-tenancy e Autorizacao"
New-Label "epic: EPIC-004"        "F39C12" "Banco de Dados e Persistencia"
New-Label "epic: EPIC-005"        "27AE60" "Observabilidade e Operacao"
New-Label "epic: EPIC-006"        "2980B9" "Produto SaaS"
New-Label "epic: EPIC-007"        "8E44AD" "Performance e Escalabilidade"
New-Label "epic: EPIC-008"        "17A589" "Qualidade e Testes"
New-Label "epic: EPIC-009"        "1A5276" "Performance Frontend"
New-Label "epic: EPIC-010"        "7D6608" "PIX Recorrente"

# Status kanban
New-Label "status: bug-ativo"     "B60205" "Bug ativo, nao resolvido"
New-Label "status: em-validacao"  "FEF2C0" "Implementado - aguarda validacao"
New-Label "status: pronto"        "C2E0C6" "Pronto para implementar"
New-Label "status: backlog"       "E1E4E8" "Backlog - nao priorizado"

Write-Host ""
Write-Host "Labels prontos!" -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────
# STEP 2 — ISSUES
# ─────────────────────────────────────────
Write-Host "📝 [2/4] Criando issues..." -ForegroundColor Yellow
Write-Host ""

# ── BUGS ─────────────────────────────────────────────────────────────────────

Write-Host "── Bugs ──" -ForegroundColor Magenta

$body1 = @'
## Problema
Usuario faz login pela primeira vez (sem org vinculada), e redirecionado para o onboarding, mas ao montar a pagina ``initAuth()`` chama ``checkSubscription()`` que recebe 400 do TenantFilter (sem X-Org-Id) e interpreta como sessao invalida, apagando isLoggedIn/userId/userName.

## Root Cause
- **Backend:** ``GET /me/access-context`` nao esta no bypass do TenantFilter.
- **Frontend:** ``initAuth()`` trata UNKNOWN (oriundo do 400) como cookie expirado e limpa estado.

## Fix Proposto
1. Adicionar ``GET /me/access-context`` ao ``BYPASS_EXACT`` no ``TenantFilter.java``
2. ``AuthContext.initAuth()``: nao limpar estado em UNKNOWN quando usuario nao tem org

## Criterios de Aceite
- [ ] Usuario sem org acessa /onboarding com sessao preservada
- [ ] ``isLoggedIn``, ``userId``, ``userName`` permanecem no storage apos redirect
- [ ] ``checkSubscription()`` retorna ACTIVE para trial valido mesmo sem org
- [ ] Cookie expirado ainda limpa a sessao (sem regressao)

---
Roadmap: ``roadmap/tasks/TASK-055.md``
'@
$url = New-Issue `
    "[TASK-055] Bug: Sessao do usuario sem organizacao e apagada apos login" `
    $body1 `
    "tipo: bug,tipo: full-stack,prioridade: critico,epic: EPIC-006,status: bug-ativo"
if ($url) { $issueUrls.Add($url) }

$body2 = @'
## Problema
Apos concluir o onboarding, o frontend recebia 403 porque o JWT ainda tinha ``orgs: []`` — o TenantFilter rejeitava o ``GET /me/access-context`` com X-Org-Id recem-criado.

## Correcao Aplicada (v2)
- **Backend:** ``OnboardingController.createOrganization()`` emite JWT renovado (com org) e seta novo cookie ``accessToken`` na mesma response.
- **Frontend:** ``window.location.replace('/')`` garante remontagem limpa do ``AccessContextProvider``.

## Status
Corrigido v2 — aguardando validacao final

## Criterios de Aceite
- [ ] Apos onboarding, redirect automatico para o dashboard
- [ ] Dados da org disponiveis no contexto (sem re-login)
- [ ] Nenhum erro exibido durante o redirect

---
Roadmap: ``roadmap/QA/tasks/TASK-QA-BUG-001.md``
'@
$url = New-Issue `
    "[TASK-QA-BUG-001] Bug: Onboarding sem redirect apos conclusao (JWT stale)" `
    $body2 `
    "tipo: bug,tipo: full-stack,prioridade: alto,epic: EPIC-006,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

# ── EM VALIDACAO — EPIC-010 PIX ──────────────────────────────────────────────

Write-Host ""
Write-Host "── Em Validacao — PIX (EPIC-010) ──" -ForegroundColor Magenta

$body3 = @'
## Contexto
O Asaas ``/subscriptions`` so aceita CREDIT_CARD. Para PIX recorrente, cada ciclo e gerenciado internamente via cobranca avulsa (DETACHED).

## Criterios de Aceite
- [ ] Job cria cobranca DETACHED ao expirar trial com metodo PIX
- [ ] Webhook ``PAYMENT_CREATED`` recebido e vinculado a subscription
- [ ] Subscription local atualizada com ``payment_id`` da cobranca avulsa
- [ ] Trial com cartao de credito nao e impactado (sem regressao)

---
Roadmap: ``roadmap/tasks/TASK-058.md``
'@
$url = New-Issue `
    "[TASK-058] PIX: refatorar job de expiracao de TRIAL via cobranca avulsa (DETACHED)" `
    $body3 `
    "tipo: backend,prioridade: critico,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body4 = @'
## Contexto
Como o Asaas nao suporta PIX em /subscriptions, o ciclo de cobranca PIX e gerenciado internamente — cada ciclo gera uma nova cobranca DETACHED.

## Criterios de Aceite
- [ ] Ciclo de billing PIX criado e gerenciado internamente
- [ ] Proxima cobranca DETACHED gerada ao confirmar pagamento do ciclo atual
- [ ] Estado da subscription atualizado a cada transicao de ciclo
- [ ] Idempotencia garantida (nao duplicar cobranca se webhook chegar duas vezes)

---
Roadmap: ``roadmap/tasks/TASK-059.md``
'@
$url = New-Issue `
    "[TASK-059] PIX: subscription recorrente manual com ciclo gerenciado internamente" `
    $body4 `
    "tipo: backend,prioridade: critico,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body5 = @'
## Criterios de Aceite
- [ ] ``PAYMENT_RECEIVED`` marca payment como PAID no banco
- [ ] Nova cobranca DETACHED criada para o proximo ciclo
- [ ] Subscription permanece ACTIVE apos confirmacao
- [ ] Idempotencia: reenvio do webhook nao gera duplicidade

---
Roadmap: ``roadmap/tasks/TASK-060.md``
'@
$url = New-Issue `
    "[TASK-060] PIX: webhook PAYMENT_RECEIVED avanca ciclo da subscription manual" `
    $body5 `
    "tipo: backend,prioridade: critico,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body6 = @'
## Criterios de Aceite
- [ ] Selecao exibida com antecedencia antes da expiracao do trial
- [ ] Escolha PIX: dispara criacao de cobranca DETACHED
- [ ] Escolha Cartao: segue fluxo existente via Asaas /subscriptions
- [ ] UX responsiva (mobile 375px)

---
Roadmap: ``roadmap/tasks/TASK-061.md``
'@
$url = New-Issue `
    "[TASK-061] UX: selecao de metodo de pagamento antes da expiracao do TRIAL" `
    $body6 `
    "tipo: frontend,prioridade: alto,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body7 = @'
## Criterios de Aceite
- [ ] Mapeamento de codigos Asaas para buckets semanticos definido
- [ ] E-mail/notificacao ao usuario usa mensagem do bucket correto
- [ ] Bucket UNKNOWN tratado com mensagem generica (sem detalhe tecnico)

---
Roadmap: ``roadmap/tasks/TASK-062.md``
'@
$url = New-Issue `
    "[TASK-062] Classificador de motivos de recusa Asaas + roteamento por bucket" `
    $body7 `
    "tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body8 = @'
## Criterios de Aceite
- [ ] Job executa nightly com ShedLock (nao duplica em multiplas instancias)
- [ ] Divergencias logadas e corrigidas automaticamente
- [ ] Alertas para divergencias que nao podem ser resolvidas automaticamente

---
Roadmap: ``roadmap/tasks/TASK-063.md``
'@
$url = New-Issue `
    "[TASK-063] Job de reconciliacao noturna: Asaas vs estado local" `
    $body8 `
    "tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body9 = @'
## Criterios de Aceite
- [ ] Falha no processamento de webhook: evento vai para DLQ
- [ ] Endpoint ``POST /admin/webhooks/replay/{id}`` disponivel para ops
- [ ] DLQ nao perde eventos entre restarts da aplicacao
- [ ] Retry automatico (N tentativas) antes de ir para DLQ

---
Roadmap: ``roadmap/tasks/TASK-064.md``
'@
$url = New-Issue `
    "[TASK-064] Hardening de webhook Asaas: DLQ + replay manual" `
    $body9 `
    "tipo: backend,prioridade: alto,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body10 = @'
## Criterios de Aceite
- [ ] Tela exibida automaticamente quando subscription esta PAST_DUE
- [ ] Opcao de trocar cartao (redirect para checkout Asaas)
- [ ] Opcao de gerar novo PIX (nova cobranca DETACHED)
- [ ] Estado atualizado em tempo real apos acao do usuario
- [ ] Responsiva (mobile 375px)

---
Roadmap: ``roadmap/tasks/TASK-065.md``
'@
$url = New-Issue `
    "[TASK-065] Frontend: tela 'Atualizar metodo de pagamento' para subscriptions PAST_DUE" `
    $body10 `
    "tipo: frontend,prioridade: alto,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

# ── EM VALIDACAO — E2E ────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Em Validacao — E2E ──" -ForegroundColor Magenta

$body11 = @'
## Status
Projeto criado. TypeScript compila. Smoke test pronto. Aguarda execucao contra API real e CI.

## Pendencias
- [ ] Instalar browsers Playwright no CI (``npx playwright install chromium``)
- [ ] Criar seed SQL para TENANT_A e TENANT_B (pre-requisito para TASK-E2E-002)

## Estrutura
```
easy-maintenance-e2e/
├── playwright.config.ts
├── docker-compose.e2e.yml
├── fixtures/  (auth, tenant, api-client)
├── tests/
└── helpers/db.ts
```

---
Roadmap: ``roadmap/QA/tasks/TASK-E2E-001.md``
'@
$url = New-Issue `
    "[TASK-E2E-001] Setup do projeto Playwright E2E (easy-maintenance-e2e)" `
    $body11 `
    "tipo: e2e,tipo: infra,prioridade: alto,epic: EPIC-008,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

$body12 = @'
## Status
9 testes implementados. TypeScript compila. Aguarda execucao contra API + DB reais e CI.

## Cobertura
- Validacao de token (valido / invalido / ausente / branco)
- Idempotencia via constraint UNIQUE no banco (``webhook_event_log``)
- Campos PIX populados via ``PAYMENT_CREATED``

## Pendencias
- [ ] Integrar na suite CI como job obrigatorio em PRs que tocam seguranca/billing/webhook

---
Roadmap: ``roadmap/QA/tasks/TASK-E2E-003.md``
'@
$url = New-Issue `
    "[TASK-E2E-003] Testes E2E: Webhook Asaas — Token e Idempotencia" `
    $body12 `
    "tipo: e2e,prioridade: alto,epic: EPIC-001,epic: EPIC-010,status: em-validacao"
if ($url) { $issueUrls.Add($url) }

# ── PRONTO PARA IMPLEMENTAR ───────────────────────────────────────────────────

Write-Host ""
Write-Host "── Pronto para Implementar ──" -ForegroundColor Magenta

$body13 = @'
## Escopo
Testes E2E Playwright verificando:
1. Delecao preenche ``deleted_at`` (nao remove fisicamente)
2. Registros deletados nao aparecem nas listagens da API
3. Filtro ``@Where`` do Hibernate esta ativo (contagem API vs SQL raw)

Substitui TASK-QA-AUTO-005.

## Dependencias
- TASK-E2E-001 concluido
- Fixture de auth de TASK-E2E-002 disponivel

---
Roadmap: ``roadmap/QA/tasks/TASK-E2E-004.md``
'@
$url = New-Issue `
    "[TASK-E2E-004] Testes E2E: Soft Delete e Filtro Automatico de Listagens" `
    $body13 `
    "tipo: e2e,prioridade: medio,epic: EPIC-004,epic: EPIC-008,status: pronto"
if ($url) { $issueUrls.Add($url) }

$body14 = @'
## Escopo
Testes E2E com Playwright + interceptor de network validando:
- Segunda visita dentro do staleTime: ZERO re-fetch
- Window focus: ZERO re-fetch
- staleTime expirado: re-fetch correto
- Maximo 2 requests na carga inicial de /items (sem N+1)

Substitui TASK-QA-AUTO-006.

---
Roadmap: ``roadmap/QA/tasks/TASK-E2E-005.md``
'@
$url = New-Issue `
    "[TASK-E2E-005] Testes E2E: Performance React Query sem Requisicoes Redundantes" `
    $body14 `
    "tipo: e2e,prioridade: medio,epic: EPIC-009,status: pronto"
if ($url) { $issueUrls.Add($url) }

$body15 = @'
## Escopo
Configurar alertas para metricas criticas: latencia de endpoints, taxa de erro 5xx, uso de memoria/CPU, job failures.

---
Roadmap: ``roadmap/tasks/TASK-021.md``
'@
$url = New-Issue `
    "[TASK-021] Alertas no Prometheus/Grafana" `
    $body15 `
    "tipo: infra,prioridade: medio,epic: EPIC-005,status: pronto"
if ($url) { $issueUrls.Add($url) }

$body16 = @'
## Escopo
Implementar suporte ao Pix Automatico regulamentado pelo Bacen — mandato que permite debito automatico na conta do pagador.

## Dependencia
Estabilizacao das TASK-058 a TASK-065 deve estar concluida antes de iniciar.

---
Roadmap: ``roadmap/tasks/TASK-066.md``
'@
$url = New-Issue `
    "[TASK-066] Implementar Pix Automatico (mandato no banco do payer)" `
    $body16 `
    "tipo: full-stack,prioridade: medio,epic: EPIC-010,status: pronto"
if ($url) { $issueUrls.Add($url) }

# ── QA MANUAL — PENDENTE ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "── QA Manual — Pendente ──" -ForegroundColor Magenta

$body17 = @'
## Escopo
Validacao manual E2E do fluxo completo PIX:
1. ``PAYMENT_CREATED`` → QR Code exibido em /billing
2. ``PAYMENT_OVERDUE`` → e-mail enviado + banner vermelho
3. ``PAYMENT_RECEIVED`` → card desaparece automaticamente (max 30s)
4. Regressao: cartao de credito nao exibe card PIX

## Pre-condicoes
- Ambiente sandbox Asaas configurado
- Acesso ao painel sandbox para disparar webhooks

---
Roadmap: ``roadmap/QA/tasks/TASK-QA-MAN-003.md``
'@
$url = New-Issue `
    "[TASK-QA-MAN-003] QA Manual: Fluxo PIX completo com Sandbox Asaas" `
    $body17 `
    "tipo: qa-manual,prioridade: critico,epic: EPIC-010,status: pronto"
if ($url) { $issueUrls.Add($url) }

$body18 = @'
## Escopo
1. Happy path completo (< 3 min)
2. CPF invalido: mensagem inline no campo (nao toast)
3. E-mail duplicado: mensagem especifica com orientacao para login
4. Asaas indisponivel (circuit breaker): opcao de trial sem pagamento
5. Timeout de rede: botao retry com dados preservados
6. Sentry: zero erros nao tratados capturados

---
Roadmap: ``roadmap/QA/tasks/TASK-QA-MAN-004.md``
'@
$url = New-Issue `
    "[TASK-QA-MAN-004] QA Manual: Onboarding em cenarios de erro" `
    $body18 `
    "tipo: qa-manual,prioridade: alto,epic: EPIC-006,status: pronto"
if ($url) { $issueUrls.Add($url) }

# ── BACKLOG ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Backlog ──" -ForegroundColor Magenta

$body19 = @'
## Escopo
Status page publica com indicadores de disponibilidade dos servicos (API, banco, Asaas, e-mail).

---
Roadmap: ``roadmap/tasks/TASK-033.md``
'@
$url = New-Issue `
    "[TASK-033] Status page basica" `
    $body19 `
    "tipo: infra,prioridade: baixo,epic: EPIC-005,status: backlog"
if ($url) { $issueUrls.Add($url) }

$body20 = @'
## Escopo
Job que remove registros de audit_logs mais antigos que N dias (configuravel), evitando crescimento ilimitado da tabela.

---
Roadmap: ``roadmap/tasks/TASK-035.md``
'@
$url = New-Issue `
    "[TASK-035] Politica de retencao para audit_logs" `
    $body20 `
    "tipo: backend,prioridade: baixo,epic: EPIC-004,status: backlog"
if ($url) { $issueUrls.Add($url) }

$body21 = @'
## Escopo
Mover processamento pesado de billing para fila assincrona para evitar bloqueio de thread em picos de cobranca.

---
Roadmap: ``roadmap/tasks/TASK-037.md``
'@
$url = New-Issue `
    "[TASK-037] Jobs de billing assincronos com fila" `
    $body21 `
    "tipo: backend,prioridade: baixo,epic: EPIC-007,status: backlog"
if ($url) { $issueUrls.Add($url) }

$body22 = @'
## Escopo
Endpoints para: (1) exportacao de dados pessoais em JSON/CSV; (2) exclusao definitiva conforme direito ao esquecimento da LGPD.

---
Roadmap: ``roadmap/tasks/TASK-038.md``
'@
$url = New-Issue `
    "[TASK-038] LGPD: exportacao e exclusao de dados pessoais" `
    $body22 `
    "tipo: backend,prioridade: baixo,epic: EPIC-003,status: backlog"
if ($url) { $issueUrls.Add($url) }

$body23 = @'
## Escopo
Conformidade WCAG AA nas principais telas: contraste minimo 4.5:1, navegacao por teclado, ARIA labels, skip-to-content.

---
Roadmap: ``roadmap/tasks/TASK-040.md``
'@
$url = New-Issue `
    "[TASK-040] Acessibilidade basica (WCAG AA)" `
    $body23 `
    "tipo: frontend,prioridade: baixo,epic: EPIC-006,status: backlog"
if ($url) { $issueUrls.Add($url) }

Write-Host ""
Write-Host "Issues criados: $($issueUrls.Count)" -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────
# STEP 3 — CRIAR PROJETO
# ─────────────────────────────────────────
Write-Host "📋 [3/4] Criando GitHub Project..." -ForegroundColor Yellow

$projectUrl = gh project create `
    --owner $OWNER `
    --title $PROJECT_TITLE `
    --format json `
    --jq '.url'

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO ao criar o projeto." -ForegroundColor Red
    exit 1
}

$projectNumber = ($projectUrl -split '/')[-1]

Write-Host "  Projeto criado: $projectUrl"   -ForegroundColor Green
Write-Host "  Numero: $projectNumber"         -ForegroundColor Green
Write-Host ""

# ─────────────────────────────────────────
# STEP 4 — ADICIONAR ISSUES AO PROJETO
# ─────────────────────────────────────────
Write-Host "🔗 [4/4] Adicionando issues ao projeto..." -ForegroundColor Yellow

foreach ($url in $issueUrls) {
    if (-not [string]::IsNullOrWhiteSpace($url)) {
        gh project item-add $projectNumber --owner $OWNER --url $url 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ok  $url" -ForegroundColor Green
        } else {
            Write-Host "  err $url" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Migracao concluida!" -ForegroundColor Green
Write-Host ""
Write-Host " Projeto: $projectUrl"
Write-Host " Issues criados: $($issueUrls.Count)"
Write-Host ""
Write-Host " Proximos passos no GitHub Projects:" -ForegroundColor Yellow
Write-Host "   1. Abra o projeto e configure as colunas do campo 'Status':"
Write-Host "      - Bug Ativo"
Write-Host "      - Em Validacao"
Write-Host "      - Pronto para Implementar"
Write-Host "      - Backlog"
Write-Host "      - Concluido"
Write-Host ""
Write-Host "   2. Distribua as issues nas colunas:"
Write-Host "      Bug Ativo    -> TASK-055"
Write-Host "      Em Validacao -> TASK-QA-BUG-001, TASK-058 a 065, TASK-E2E-001, TASK-E2E-003"
Write-Host "      Pronto       -> TASK-E2E-004, E2E-005, TASK-021, TASK-066, QA-MAN-003, QA-MAN-004"
Write-Host "      Backlog      -> TASK-033, 035, 037, 038, 040"
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan