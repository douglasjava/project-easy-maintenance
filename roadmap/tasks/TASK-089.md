# TASK-089 — Backend: Migrations + Entidades + Repositórios do módulo affiliates

## Tipo
BACKEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🔴 Crítico

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Criar a fundação do módulo `affiliates/` no backend: migrations Flyway, entidades JPA, enums, e repositórios. Também adicionar os campos `affiliateCode` em `landing_leads` e `referralCode` em `organizations`.

## Arquivos

**Criar:**
- `db/migration/V72__create_affiliates_tables.sql` — tabelas `affiliates` e `referral_commissions`
- `db/migration/V73__add_affiliate_tracking_columns.sql` — colunas `affiliate_code` e `referral_code`
- `affiliates/domain/AffiliateStatus.java` — enum ACTIVE/INACTIVE
- `affiliates/domain/CommissionStatus.java` — enum PENDING/PAID
- `affiliates/domain/Affiliate.java` — entidade JPA
- `affiliates/domain/ReferralCommission.java` — entidade JPA
- `affiliates/infrastructure/persistence/AffiliateRepository.java`
- `affiliates/infrastructure/persistence/ReferralCommissionRepository.java`

**Modificar:**
- `leads/domain/LandingLead.java` — campo `affiliateCode`
- `leads/infrastructure/persistence/LandingLeadRepository.java` — métodos `findFirstByEmailAndAffiliateCodeIsNotNull` e `findAllByAffiliateCode`
- `org_users/domain/Organization.java` — campo `referralCode`

## Critérios de Aceite
- [ ] Migrations V72 e V73 aplicam sem erro
- [ ] `AffiliateRepository.findByCode()`, `existsByEmail()` funcionam
- [ ] `ReferralCommissionRepository.existsByOrganizationId()` tem constraint UNIQUE no banco
- [ ] `LandingLead.affiliateCode` e `Organization.referralCode` persistem corretamente
- [ ] Testes de repositório passando (3+ cenários)

## Esforço
Pequeno (3-4h)

## Status
Backlog

## Dependências
Nenhuma
