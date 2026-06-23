---
name: easy-maintenance-pricing
description: >
  Use esta skill SEMPRE que Douglas mencionar precificação, valores dos planos, viabilidade financeira,
  estudo de preços, CAC, LTV, churn, break-even, concorrentes de manutenção preventiva, ou qualquer
  análise comercial/financeira do Easy Maintenance. Também deve ser usada para sugestões de estratégias
  de vendas, upsell, retenção de clientes e potencialização de receita do SaaS. Trigger imediato
  quando houver perguntas como "quanto cobrar", "meus planos estão corretos", "como vender mais",
  "vale a pena esse preço", "análise de mercado" no contexto do Easy Maintenance.
---

# Easy Maintenance — Pricing & Viabilidade Financeira

## Contexto do Produto

**Easy Maintenance** é um SaaS B2B brasileiro de gestão de manutenção preventiva.

- **Segmento-alvo**: Condomínios, hospitais, escolas e instalações industriais
- **Proposta de valor**: Centraliza ativos, prazos, relatórios, fornecedores e evidências fotográficas em conformidade com normas ABNT
- **Modelo de negócio**: Assinatura mensal/anual
- **Stack**: React / Next.js
- **Domínio**: easymaintenance.com.br
- **Fase atual**: Pré-lançamento / testes finais

---

## Fluxo de Condução do Estudo

### FASE 1 — Coleta de Dados (sempre iniciar aqui se dados não fornecidos)

Pergunte ao Douglas de forma estruturada, em blocos:

**Bloco A — Custos Operacionais**
- Infraestrutura mensal (servidores, banco de dados, CDN)?
- Ferramentas SaaS usadas (email, analytics, suporte)?
- Custo com time (freelancers, sócios, próprio salário esperado)?
- Outros custos fixos mensais?

**Bloco B — Estrutura de Planos Atual**
- Quais planos está pensando? (nomes, limites, preços)
- Desconto para pagamento anual previsto?
- Algum plano gratuito ou trial?

**Bloco C — Aquisição de Clientes**
- Canais de aquisição previstos (inbound, outbound, parcerias)?
- Budget mensal para marketing/vendas?
- Já tem clientes beta? Quantos e a que preço?

**Bloco D — Expectativas**
- Meta de clientes em 6 meses? 12 meses?
- Receita mínima viável esperada por mês?
- Qual segmento quer priorizar primeiro?

---

## FASE 2 — Análise e Relatório

Quando tiver os dados, gere o relatório completo seguindo a estrutura em `/references/relatorio-template.md`.

Sempre calcule e apresente:

### 2.1 Benchmark de Mercado
Consulte `/references/concorrentes.md` para lista de concorrentes brasileiros do setor de manutenção/facilities.

Compare:
- Faixa de preços praticada no mercado
- Funcionalidades por tier
- Posicionamento (premium vs. acessível)
- Modelo de cobrança (por usuário, por ativo, flat)

### 2.2 Sugestão de Pricing

**Regras para sugestão de planos:**
1. Nunca sugerir menos de 3 tiers (Básico / Pro / Enterprise)
2. Ratio saudável entre tiers: Básico → Pro = 2,5x a 3x | Pro → Enterprise = 2x a 3x
3. Para mercado BR B2B facilities, faixa típica viável: R$149 a R$1.499/mês
4. Desconto anual: recomendar 15-20% (equivale a 2 meses grátis)
5. Ancoragem: enterprise sem preço fixo → "Fale conosco"
6. Considerar limite por: número de ativos, usuários, unidades/sedes

**Segmentos e sensibilidade a preço:**
- **Condomínios pequenos** (até 100 unidades): alta sensibilidade → R$149–299/mês
- **Condomínios médios/grandes**: média sensibilidade → R$299–599/mês
- **Escolas e hospitais**: baixa sensibilidade, exigem compliance → R$599–1.499/mês
- **Indústria**: menor sensibilidade, ticket maior possível → R$999–2.499/mês

### 2.3 Métricas de Viabilidade

Calcule com os dados fornecidos:

```
MRR necessário = Custos fixos mensais / (1 - margem desejada)
Clientes para break-even = MRR necessário / ticket médio
CAC estimado = Budget de marketing / novos clientes estimados por mês
LTV = Ticket médio / churn mensal estimado
Ratio LTV/CAC saudável = ≥ 3x (ideal ≥ 5x para SaaS B2B)
Payback period = CAC / (ticket médio × margem)
```

Apresente em tabela clara com cenários: pessimista / realista / otimista.

### 2.4 Estratégias de Venda

Sempre inclua estratégias adaptadas ao estágio de Douglas (pré-lançamento, lean, bootstrap):

**Estratégias de entrada no mercado:**
- Piloto gratuito por 30-60 dias (sem cartão de crédito)
- Parceria com síndicos profissionais e administradoras de condomínio
- Parceria com prestadores de manutenção (eles vendem ao cliente final)
- Abordagem direta via LinkedIn para gestores de facilities
- Conteúdo educativo sobre ABNT NBR e responsabilidade técnica

**Estratégias de retenção e expansão:**
- Plano anual com desconto agressivo no lançamento (20-25% primeiros 50 clientes)
- Upsell por volume: mais ativos, mais usuários, mais unidades
- NPS e feedback ativo nos primeiros 90 dias
- Relatórios automáticos de valor entregue (quantos ativos gerenciados, laudos gerados)

**Estratégias de potencialização de receita:**
- Add-ons: laudos técnicos em PDF personalizados (+R$50-100/mês)
- White-label para administradoras
- Integração com fornecedores de manutenção (marketplace)
- Comissão de indicação (programa de referral entre clientes)

### 2.5 Pontos de Atenção

Sempre alertar sobre:
- Churn alto nos primeiros 3 meses: investir em onboarding
- Precificação muito baixa reduz percepção de valor no B2B
- ABNT compliance como diferencial de vendas (não só feature)
- Contratos anuais reduzem churn e melhoram previsibilidade de caixa

---

## FASE 3 — Formato de Saída

O relatório final deve ser entregue como:
1. **Resumo executivo** (5-7 bullets com as principais conclusões)
2. **Tabela de planos sugeridos** (comparativo visual)
3. **Tabela de métricas financeiras** (cenários pessimista/realista/otimista)
4. **Lista de estratégias priorizadas** (quick wins primeiro, depois médio prazo)
5. **Próximos passos** (ações concretas para Douglas executar)

Se possível, gere também como arquivo `.md` ou componente visual interativo.

---

## Referências

- `/references/concorrentes.md` — Lista de concorrentes BR do setor (leia antes do benchmark)
- `/references/relatorio-template.md` — Template completo do relatório final
