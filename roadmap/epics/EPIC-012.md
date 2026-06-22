# EPIC-012 — Sistema de Indicação (Affiliate Referral)

## Status
Em Validação — 8/8 tasks entregues

## Objetivo
Permitir que qualquer pessoa se cadastre como afiliado, receba um link único de rastreio, 
e ganhe uma comissão de 20% sobre o primeiro pagamento de cada cliente indicado.

## Descrição
Com a aproximação do lançamento, o Easy Maintenance precisa de um canal de aquisição escalável. 
O programa de indicação permite que síndicos, consultores, administradoras e qualquer pessoa da rede se tornem 
divulgadores ativos — sem custo fixo para a empresa, com comissão paga apenas quando há conversão real (primeiro pagamento).

O sistema é deliberadamente simples: sem login de afiliado, sem comissão recorrente, sem integração de pagamento 
automático. O afiliado se cadastra, compartilha o link, e você paga via PIX manualmente quando a comissão é gerada. 
O painel do afiliado é acessível pelo próprio código do link.

## Impacto no Produto
- **Sem este épico:** Aquisição depende apenas de marketing direto (Instagram, WhatsApp do admin). Crescimento limitado.
- **Com este épico:** Qualquer pessoa pode se tornar divulgador. Afiliados têm incentivo financeiro. Admin tem visibilidade total das comissões pendentes.

## Contexto Técnico
- Landing page existente (`/landing`) e tabela `landing_leads` já prontos — extensão mínima
- `PaymentReceivedHandler` já processa `cycleNumber` — hook natural para a comissão
- Novo módulo `affiliates/` no backend segue o padrão do módulo `leads/` existente
- Atribuição via cookie `em_ref` (30 dias) + auto-match por email ao criar organização

## Tasks

| ID       | Título                                                      | Prioridade   | Fase |
|----------|-------------------------------------------------------------|--------------|------|
| TASK-089 | Backend: migrations + entidades + repositórios              | 🔴 Crítico   | 3    |
| TASK-090 | Backend: DTOs + AffiliateService + CommissionService        | 🔴 Crítico   | 3    |
| TASK-091 | Backend: controllers + atualização de leads e orgs          | 🔴 Crítico   | 3    |
| TASK-092 | Backend: trigger de comissão no PaymentReceivedHandler      | 🔴 Crítico   | 3    |
| TASK-093 | Frontend: cookie na landing page + middleware update        | 🟠 Alto      | 3    |
| TASK-094 | Frontend: página /indicador/novo (cadastro de afiliado)     | 🟠 Alto      | 3    |
| TASK-095 | Frontend: página /indicador/[code] (dashboard do afiliado)  | 🟠 Alto      | 3    |
| TASK-096 | Frontend: painel admin de comissões                         | 🟠 Alto      | 3    |

## Critério de Conclusão do Épico
- [ ] Qualquer pessoa consegue se cadastrar em `/indicador/novo` e receber um link único
- [ ] Link com `?ref=CODE` seta cookie e registra `affiliateCode` no `LandingLead`
- [ ] Admin vê sugestão de afiliado ao criar organização cujo e-mail veio via link
- [ ] Primeiro pagamento de organização com `referralCode` gera `ReferralCommission` com status `PENDING`
- [ ] Afiliado acessa `/indicador/{code}` e vê leads, conversões e comissões pendentes
- [ ] Admin marca comissão como `PAID` no painel `/private/admin/affiliates`
- [ ] `UNIQUE(organization_id)` garante que nunca há comissão duplicada para a mesma org
