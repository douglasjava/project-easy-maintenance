# Easy Maintenance — Contexto Comercial
**Use este texto como contexto de produto em prompts para a frente comercial (follow-up de leads, prospecção, negociação, parcerias).**
*Versão: 01/09/2026 — limite de empresas do Business atualizado de 15 para 20 (V105), ver `pricing-rationale.md`*

---

## O produto em uma frase

Easy Maintenance é um SaaS brasileiro de gestão de manutenção preventiva que tira condomínios, hospitais, escolas e indústrias das planilhas e do WhatsApp, centralizando ativos, prazos, evidências e conformidade com normas ABNT em uma única plataforma.

## Público-alvo

**Segmentos primários**: condomínios (~500.000 no Brasil), hospitais/clínicas (~80.000), escolas/universidades (~220.000), indústrias/galpões (~1.200.000).

**Quem paga**: administradoras de condomínios (múltiplos clientes → plano Enterprise), síndicos profissionais (5-20 condomínios → plano Business), gestores de facilities, responsáveis técnicos.

**Quem influencia sem pagar**: síndicos moradores, consultores de manutenção, empresas de terceirização de manutenção — bons alvos pra indicação/afiliado, não pra venda direta.

**Dor real que motiva a busca**: planilhas espalhadas sem histórico consolidado, ordens perdidas em conversas de WhatsApp, perda de memória técnica quando o síndico/gestor troca, e risco jurídico real por falta de comprovação documental (ABNT NBR 5674 exige plano formal de manutenção com evidência).

## Modelo de negócio

**Planos mensais**:
| Plano | Preço/mês | Empresas | Usuários | Itens | Suporte |
|---|---|---|---|---|---|
| Starter | R$149 | até 3 | até 3 | até 100 | Comunidade |
| Business | R$299 | até 20 | até 10 | até 500 | E-mail prioritário |
| Enterprise | R$899 | até 50 | até 100 | até 5.000 | Dedicado |

**Planos anuais** (17% de desconto = 2 meses grátis): Starter R$1.490/ano, Business R$2.990/ano, Enterprise R$8.990/ano. **Não existe outro desconto documentado** — qualquer coisa além disso precisa de aprovação do Douglas antes de ser prometida a um prospect.

**Trial**: 14 dias grátis no plano Business, sem cartão de crédito obrigatório. Ao final, escolhe plano e paga via PIX ou cartão (Asaas).

**Formas de pagamento**: PIX recorrente e cartão de crédito recorrente, via Asaas. **Sem política de reembolso** — cancelamento interrompe cobranças futuras, não devolve valor já pago.

**Programa de afiliados**: cadastro em `easymaintenance.com.br/indicador/novo`, comissão de **20% do primeiro pagamento** de cada cliente convertido, pago via PIX manual em até 10 dias úteis. Essa comissão é para quem indica — nunca oferecer isso como desconto ao cliente final.

## Diferenciais e argumentos de venda

Posicionamento: **"Compliance ABNT acessível"** — conformidade normativa a preço de PME (concorrentes como Engeman/TOTVS cobram R$2k–10k; Fracttal cobra em USD/usuário; ManFácil é mais barato mas não tem conformidade ABNT explícita nem evidências fotográficas).

**Concorrente mais próximo (achado 17/08/2026): [Condo Guardian](https://condoguardian.com.br/)**
Diferente dos quatro acima, esse mira o mesmo ICP e o mesmo ângulo normativo que a gente — não dá
pra tratar como concorrente distante:
- Posicionamento quase idêntico: NBR 5674, tira o síndico/administradora da planilha e do WhatsApp,
  cronograma automático + alertas de vencimento.
- Público: síndico morador, síndico profissional, administradora — mesmo ICP central nosso. Não
  ataca hospital/escola/indústria, que continuam diferencial nosso.
- Sem preço público — modelo de demonstração/WhatsApp assistido, não trial self-serve como o nosso.
- **Zero prova social também** (nenhum número de cliente, depoimento, logo) — não é sinal de que
  estão mais validados, só que também estão em fase inicial.
- Tem blog ativo (`condoguardian.com.br/blog`, ~quinzenal, 6 posts desde 12/07/2026) com conteúdo
  educacional SEO-driven nas mesmas keywords do nosso plano de SEO (NBR 5674, manutenção preventiva
  x corretiva, checklist de manutenção predial) — o Easy Maintenance não tem blog hoje, então essa é
  uma frente onde eles têm vantagem construída, não só potencial.

Os 5 argumentos mais fortes:
1. **"A ABNT exige, você comprova"** — cada manutenção gera evidência documental automática.
2. **"Da planilha para o compliance em 1 dia"** — onboarding guiado por IA, sem consultor.
3. **"Troca de síndico sem perda de histórico"** — memória técnica fica no sistema, não na pessoa.
4. **"R$149/mês vs. multa de R$50.000+"** — argumento de ROI imediato.
5. **"Feito para o Brasil"** — normas brasileiras, suporte em português, empresa local.

**Mensagens-chave por público**:
- Síndico/gestor predial: *"Nunca mais perca um prazo de manutenção. Comprove tudo para o Corpo de Bombeiros, Anvisa e ABNT em segundos — sem planilha, sem WhatsApp."*
- Administradora de condomínios: *"Gerencie todas as suas empresas em um único painel. Relatórios automáticos de conformidade para cada cliente."*
- Potencial afiliado: *"Cadastre-se, compartilhe seu link e receba 20% do primeiro pagamento de cada cliente que assinar. Sem limite de indicações."*

## Pipeline de leads (Painel de Leads — EPIC-021)

Existe um painel admin em `/private/admin/leads` (implementado em 11/08/2026, PRs #32 backend e #35 frontend ainda **não mergeadas em staging** — confirmar com Douglas se já está no ar antes de assumir que os dados de lá já refletem produção) com:
- Visão agregada: leads por status nos últimos 12 meses + top fontes (`source`) e top referrers.
- Lista individual: cada lead tem `source`, `medium`, `campaign`, `referrer`, `affiliateCode`, `status`, `consentAcceptedAt`, `createdAt`.
- **Status do lead** é um fluxo fechado: `NEW → CONTACTED → CONVERTED / LOST`. Todo lead nasce `NEW`.

**Este cowork não tem acesso direto a esse painel nem ao banco.** Douglas cola aqui os dados relevantes (exportados/copiados manualmente) a cada rodada de trabalho — trabalhar só em cima do que for colado, nunca supor ou inventar lead que não foi informado.

## ⚠️ Restrições importantes (não violar em script, e-mail, proposta ou negociação)

- **Zero clientes pagantes confirmados em 30/07/2026** — reconfirmar com Douglas antes de qualquer peça que sugira prova social (nº de clientes, depoimento, case, "outros gestores já confiam"). Isso já foi removido da landing por ser propaganda enganosa; a mesma regra vale pra qualquer material comercial.
- **Sem reembolso** — nunca prometer devolução de valor pago; só interrupção de cobranças futuras.
- Preço e condição citados numa negociação precisam bater exatamente com a tabela acima; desconto fora do anual documentado (17%) exige validação prévia do Douglas.
- LGPD: qualquer contato outbound que colete dado novo precisa do mesmo cuidado de consentimento já aplicado no formulário da landing.
- Não inventar números de mercado além dos já documentados aqui sem confirmar com Douglas antes.

## Links relevantes

- Landing: https://www.easymaintenance.com.br/landing
- Programa de afiliados: https://www.easymaintenance.com.br/indicador/novo
- Política de Privacidade: https://www.easymaintenance.com.br/privacidade
- Termos de Uso: https://www.easymaintenance.com.br/termos
- E-mail comercial: comercial@easymaintenance.com.br
- WhatsApp: (31) 99563-9390

## Tom de voz

Direto, sem jargão de SaaS genérico. Fala a língua de quem hoje resolve isso com planilha e grupo de WhatsApp. Português do Brasil, sem anglicismo desnecessário.

---

*Para contexto mais amplo (matriz competitiva completa, stack técnica, projeções financeiras, FAQ de atendimento), ver `docs/produto/context-brief.md` — atenção: esse documento é de junho/2026 e ainda descreve o lançamento como "iminente"; hoje a campanha de tráfego pago já roda (ver `docs/produto/contexto-trafego-pago.md`) e o painel de leads já foi implementado. Use o context-brief só para o que não contradiz este documento.*
