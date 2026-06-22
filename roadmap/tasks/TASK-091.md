# TASK-091 — Backend: Controllers + atualização de leads e orgs

## Tipo
BACKEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🔴 Crítico

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Expor os endpoints do módulo de afiliados e integrar o rastreio nos fluxos existentes de leads e criação de organizações.

**Novos endpoints públicos:**
- `POST /api/v1/affiliates` — cadastro de afiliado
- `GET /api/v1/affiliates/{code}/dashboard` — painel do afiliado

**Novos endpoints admin:**
- `GET /api/v1/admin/affiliates-commissions/commissions`
- `PATCH /api/v1/admin/affiliates-commissions/commissions/{id}/pay`
- `GET /api/v1/admin/affiliates-commissions`

**Atualizações em módulos existentes:**
- `CreateLeadRequest` — campo opcional `affiliateCode`
- `LeadService.createLead()` — persistir `affiliateCode`
- `CreateOrganizationRequest` — campo opcional `referralCode`
- `OrganizationsService.create()` — auto-match por e-mail via `AffiliateService.suggestForEmail()` quando `referralCode` não informado

## Critérios de Aceite
- [ ] `POST /api/v1/affiliates` retorna 201 com `code` e `link`
- [ ] `GET /api/v1/affiliates/{code}/dashboard` retorna 200 com dados mascarados
- [ ] Lead criado com `affiliateCode` persiste no banco
- [ ] Org criada com `referralCode` explícito salva o código
- [ ] Org criada sem `referralCode`, mas com e-mail que bate em `LandingLead`, auto-preenche o código
- [ ] Org criada sem match algum salva `referralCode = null` (sem erro)
- [ ] Teste de controller slice: AffiliateControllerTest

## Esforço
Médio (4-5h)

## Status
Em Validação

## Dependências
TASK-090
