# Easy Maintenance — Contexto Corporate & Business Operations
**Use este texto como contexto de produto/empresa em prompts para controladoria, obrigações societárias/fiscais e governança corporativa.**
*Versão: 14/08/2026 — primeira versão, vários campos ainda a preencher*

---

## A empresa

- **Razão social**: BrainByte Consultoria TI Ltda
- **CNPJ**: 50.047.256/0001-22
- **Produto**: Easy Maintenance (easymaintenance.com.br) — único produto/receita da empresa hoje
- **Regime tributário**: A PREENCHER (Douglas)
- **Sócios/quadro societário**: A PREENCHER (Douglas)
- **Contador responsável**: A PREENCHER (nome/escritório, se já houver)
- **Advogado/assessoria jurídica**: A PREENCHER (se já houver, mesmo que pontual)

> Esta frente **nunca deve supor** nenhum dos campos acima marcados "A PREENCHER" — pergunte a
> Douglas antes de qualquer peça (prazo fiscal, cláusula contratual, cálculo de pró-labore) que
> dependa desse dado.

## O que esta frente cobre (e o que não cobre)

**Cobre**: saúde financeira da própria empresa (não do cliente), obrigações fiscais e societárias
da BrainByte, governança e compliance corporativo (LGPD como empresa, termos jurídicos publicados,
propriedade intelectual, riscos jurídicos gerais do negócio).

**Não cobre** (fica com outras frentes já existentes):
- Cobrança/billing do **cliente** (planos, Asaas, inadimplência) — isso é o produto, tratado no
  código (`easy-maintenance-api`, módulo `billing`) e no painel `/private/admin/billing`.
- Custo de **infraestrutura do produto** (Railway, OpenAI, S3, Asaas) e comissão de afiliado — já
  tem painel dedicado, `/private/admin/billing/financeiro` (EPIC-020), com histórico mês a mês.
- Argumento de venda, funil de lead, negociação com prospect — isso é `docs/produto/contexto-comercial.md`.
- Copy/campanha de tráfego pago — isso é `docs/produto/contexto-trafego-pago.md`.
- Conformidade ABNT que o **produto** oferece ao cliente (NBR 5674 etc.) — isso é posicionamento
  de produto, não a governança interna da empresa.

## Despesas gerais da empresa (gap conhecido)

O EPIC-020 (painel financeiro admin) marca explicitamente **"despesas gerais do negócio
(ferramentas, contador, etc.)"** como fora de escopo — só cobre infraestrutura do produto e
comissão de afiliado. Ou seja: **hoje não existe nenhum lugar, nem sistema nem planilha
documentada, controlando o custo operacional da própria BrainByte** (contador, ferramentas SaaS
internas — ex.: o que a empresa paga de Claude/ChatGPT/outras assinaturas de uso interno, banco,
eventuais taxas societárias). Até que Douglas decida se isso vira funcionalidade no sistema ou fica
como controle externo (planilha/manual), esta frente trabalha só em cima do que for colado na
conversa — nunca supor um valor.

## Governança e compliance corporativo

- **Termos de Uso** (`/termos`) e **Política de Privacidade** (`/privacidade`) são os documentos
  jurídicos publicados hoje — qualquer sugestão de alteração é só rascunho para revisão humana
  (advogado), nunca publicar direto.
- **LGPD como empresa**: além do consentimento já implementado no formulário da landing (produto),
  esta frente cobre a postura da empresa como controladora de dados de forma mais ampla (ex.:
  dados de leads/afiliados armazenados, retenção, resposta a eventual solicitação de titular).
- **Propriedade intelectual**: marca "Easy Maintenance", domínio, eventual registro de marca — A
  PREENCHER se já há algo formalizado (INPI, etc.).

## Ferramentas de apoio já existentes no projeto

- A skill `easy-maintenance-pricing` (usada dentro do Claude Code, não neste cowork) já cobre
  precificação, CAC/LTV/churn/break-even e análise comercial de plano — para essas perguntas
  específicas, prefira rodar essa skill numa sessão de Claude Code em vez de duplicar a análise aqui.
- `/private/admin/billing/financeiro` (EPIC-020) tem receita/custo/lucro mês a mês do produto — pode
  ser colado aqui como insumo para uma visão financeira mais ampla da empresa (produto + despesas
  gerais), mas os dados de despesas gerais não vêm de lá.

## Links relevantes

- Termos de Uso: https://www.easymaintenance.com.br/termos
- Política de Privacidade: https://www.easymaintenance.com.br/privacidade
- Painel financeiro (produto): `/private/admin/billing/financeiro` (acesso admin)

## Tom de voz

Direto, sem juridiquês desnecessário quando o público é o próprio Douglas. Ao gerar rascunho de
peça jurídica/fiscal para revisão externa, aí sim usar o registro formal adequado ao documento.

---

*Este documento nasce sem o mesmo lastro de dado real que `contexto-comercial.md` e
`contexto-trafego-pago.md` têm — a maior parte do trabalho inicial desta frente deve ser ajudar
Douglas a levantar e organizar os dados "A PREENCHER" acima, não assumir que já existem.*
