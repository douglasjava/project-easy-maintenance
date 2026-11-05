# TASK-225 — BACKEND: Sobe limite de empresas do Business pra bater com o ICP documentado

## Tipo
BACKEND

## Categoria
Backend / Billing (limites de plano)

## Prioridade
🔴 Alto — lead de trial real com 20 condomínios batendo no teto do plano hoje (grade não bate com o
próprio ICP documentado), risco direto de perder conversão numa fase com 0 clientes pagantes.

## Contexto

Cliente pedindo trial com 20 condomínios. `contexto-comercial.md` já documenta o ICP do Business
como "síndico profissional (5-20 condomínios)", mas a `V103__increase_business_enterprise_max_organizations.sql`
(própria migration do Douglas, ainda não commitada quando isso foi identificado) subiu o limite de
empresas do Business de 3 pra **15** — 5 abaixo do teto que o próprio ICP documenta. Achado durante
uma análise de produto: não é o cliente que não se encaixa, é a grade que ficou aquém do próprio
critério já escrito.

Agravante: o trial roda no plano Business ("Trial: 14 dias grátis no plano Business", sem cartão) —
sem esse ajuste, o cliente nem consegue completar o cadastro dos 20 condomínios dentro do trial.

## Decisão (Douglas, 01/09/2026)

Subir `maxOrganizations` do Business de 15 para **20**, batendo exatamente com o teto que
`contexto-comercial.md` já documenta pro ICP desse plano. Enterprise fica como está — é o plano de
administradora com múltiplos clientes (100 usuários, 5.000 itens), perfil diferente de um síndico
profissional com 20 prédios próprios; empurrar esse lead pro Enterprise (R$899, 3x o preço)
contradiria o próprio ICP documentado.

## Escopo

- Nova migration `V105__increase_business_max_organizations_to_20.sql`: `maxOrganizations` do
  Business (mensal e anual) de 15 → 20.
- Atualizar `docs/produto/pricing-rationale.md` (linha do histórico + grade da seção 2) e
  `docs/produto/contexto-comercial.md` (tabela de planos) pra refletir o novo valor.

## Critérios de Aceite

- [ ] `billing_plans` com `maxOrganizations=20` pro Business (mensal e anual)
- [ ] Starter e Enterprise sem alteração
- [ ] Docs de produto atualizados com o novo valor e o motivo

## Dependências
Depende da `V103` (do Douglas, ainda não commitada nesta sessão) já estar aplicada antes — a `V105`
parte do valor 15 que a `V103` estabelece.

## Riscos
Baixo — só um valor de config num catálogo já existente, sem mudança de lógica.

## Esforço
Baixo

## Status
✅ Implementada, PR aberta contra `staging`:
[api#71](https://github.com/douglasjava/easy-maintenance-api/pull/71). Branch
`feature/TASK-225-business-plan-org-limit`. `mvn compile` limpo (só migration SQL, sem código
Java). Docs de produto (`pricing-rationale.md`, `contexto-comercial.md`) já atualizados no repo do
roadmap. **Urgente — cliente de trial real esperando**, recomendado mergear e deployar assim que
revisar.
