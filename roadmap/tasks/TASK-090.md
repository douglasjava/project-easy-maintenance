# TASK-090 — Backend: DTOs + AffiliateService + CommissionService

## Tipo
BACKEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🔴 Crítico

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Implementar a camada de aplicação do módulo `affiliates/`: DTOs de entrada/saída e os dois services principais.

**AffiliateService:**
- `createAffiliate()` — valida e-mail único, gera código de 6 chars, salva com taxa padrão 20%
- `getDashboard()` — agrega leads, conversões e comissões para o painel público
- `suggestForEmail()` — busca afiliado via match de e-mail no `LandingLead` (usado na criação de org)
- `listAllActive()` — lista para o admin

**CommissionService:**
- `createCommission()` — idempotente via `existsByOrganizationId`, calcula `planPrice * commissionRate`
- `markAsPaid()` — seta `status=PAID` e `paidAt=now()`
- `listAll()` — lista ordenada por data para o admin

## Arquivos

**Criar:**
- `affiliates/application/dto/CreateAffiliateRequest.java`
- `affiliates/application/dto/AffiliateResponse.java`
- `affiliates/application/dto/AffiliateDashboardResponse.java`
- `affiliates/application/dto/ReferralLeadResponse.java`
- `affiliates/application/dto/CommissionAdminResponse.java`
- `affiliates/application/service/AffiliateService.java`
- `affiliates/application/service/CommissionService.java`

## Critérios de Aceite
- [ ] `createAffiliate` lança erro se e-mail duplicado
- [ ] Código gerado tem 6 chars, único, UPPERCASE alfanumérico
- [ ] `commissionAmount = planPrice * commissionRate` arredondado em 2 casas
- [ ] `createCommission` retorna `null` (no-op) se `organizationId` já existe
- [ ] `markAsPaid` preenche `paidAt` e troca status para PAID
- [ ] E-mail no dashboard é mascarado: `jo***@gmail.com`
- [ ] Testes: AffiliateServiceTest (4 cenários) + CommissionServiceTest (3 cenários)

## Esforço
Médio (4-6h)

## Status
Em Validação

## Dependências
TASK-089
