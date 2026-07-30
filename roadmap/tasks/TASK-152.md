# TASK-152 — Backend: `consent_accepted_at` em `landing_leads` + validação de consentimento obrigatório

## Tipo
BACKEND

## Categoria
Marketing / LGPD

## Prioridade
🟠 Alto

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim — validar que o endpoint rejeita submissão sem consentimento e grava `consent_accepted_at`
corretamente.

---

## Contexto

O formulário "Solicitar Demonstração" vai ganhar um checkbox de consentimento LGPD obrigatório
(TASK-154). O backend precisa aceitar esse sinal e registrar quando o consentimento foi dado, para
existir prova de consentimento junto ao registro do lead — exigência básica de conformidade LGPD
para captura de leads via anúncio.

`LandingLead`/`CreateLeadRequest` já têm `source`, `medium`, `campaign`, `referrer`, `landingPath`,
`utmJson` (não usados hoje pelo frontend, ver TASK-154) — falta apenas o campo de consentimento.

---

## Objetivo

Adicionar `consent_accepted_at` a `landing_leads`, aceitar um booleano `consentAccepted` no
`CreateLeadRequest`, e rejeitar a criação do lead (400) se `consentAccepted != true`.

---

## Escopo

### 1. Migração
- `V86__add_consent_accepted_at_to_landing_leads.sql`: `ALTER TABLE landing_leads ADD COLUMN
  consent_accepted_at TIMESTAMP NULL;`

### 2. Domínio
- `LandingLead`: novo campo `consentAcceptedAt` (`Instant`).

### 3. DTO
- `CreateLeadRequest`: novo campo `consentAccepted` (`Boolean`, obrigatório).

### 4. Serviço
- `LeadService.createLead`: se `request.consentAccepted() != Boolean.TRUE`, lançar erro de validação
  (400, `ProblemDetail`, mesmo padrão de erro já usado no restante da API — ver
  `shared/web` para o handler existente). Caso contrário, gravar `consentAcceptedAt =
  Instant.now()` — **timestamp gerado no servidor**, nunca recebido do cliente (timestamp de
  cliente não é confiável como prova de consentimento).

### 5. Testes
- Teste unitário/integração do `LeadService`/`LeadController`: cria lead com `consentAccepted:
  true` → sucesso, `consentAcceptedAt` preenchido; cria com `false`/ausente → 400, nenhum registro
  criado.

---

## Critérios de Aceite

- [ ] Migração aplicada, coluna `consent_accepted_at` existe em `landing_leads`
- [ ] `POST /easy-maintenance/api/v1/landing/leads` sem `consentAccepted: true` retorna 400 e não
      grava lead
- [ ] Lead criado com `consentAccepted: true` grava `consent_accepted_at` com o instante do
      servidor no momento da requisição
- [ ] Suíte de testes backend passa (sem regressão nos testes existentes de `LeadService`)

## Dependências
Nenhuma (trilha independente da TASK-153).

## Riscos
Baixo — mudança aditiva, não quebra nenhum consumidor existente (nenhum outro endpoint cria
`landing_leads`).

## Esforço
Baixo

## Status
Pronto para Implementar
