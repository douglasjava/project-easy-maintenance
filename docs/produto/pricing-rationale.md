# Easy Maintenance — Racional de Precificação
**Reconstruído em 30/08/2026, a pedido de Douglas — não existia documento anterior explicando o "porquê" dos valores dos planos.**

---

## 1. Histórico — como chegamos em R$149 / R$299 / R$899

| Data       | O que mudou                                                                                        | Onde está registrado                                                  |
|------------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
| 01/02/2026 | Lançamento original: STARTER R$99, BUSINESS R$199, ENTERPRISE R$499. `maxOrganizations`: 1/3/10    | `V17`, `V21`, `V63`                                                   |
| 15/06/2026 | Preços sobem para os valores atuais (R$149/299/899). `maxOrganizations` do STARTER sobe de 1→3     | `V69__update_plan_prices_and_starter_orgs.sql`                        |
| 15/07/2026 | IA desativada no STARTER (`aiEnabled=false`)                                                       | `V77__disable_ai_on_starter_billing_plans.sql`                        |
| 30/08/2026 | `maxOrganizations` do BUSINESS 3→15 e ENTERPRISE 10→50 (corrige incoerência com o ICP documentado) | `V103__increase_business_enterprise_max_organizations.sql` — mergeada |
| 01/09/2026 | `maxOrganizations` do BUSINESS 15→20 (V103 tinha parado 5 abaixo do teto do próprio ICP; achado com lead de trial real de 20 condomínios) | `V105__increase_business_max_organizations_to_20.sql` |

**O racional original existia — só estava certo em uma migration SQL, não em um documento.** Comentário do `V69`:

> *"Ajuste de pricing baseado em análise de mercado (2026-06-15). Sobe preços para refletir diferencial competitivo (IA inclusa vs concorrentes sem IA). STARTER: maxOrganizations 1 → 3 (viabiliza administradoras de pequeno porte)."*

**Ponto em aberto, não resolvido**: a subida de R$99→R$149 no STARTER foi justificada por "IA inclusa vs concorrentes sem IA" — um mês depois (`V77`) a IA foi desligada nesse mesmo plano. O racional original não vale mais para esse tier especificamente; ninguém reavaliou o preço do STARTER depois do corte. Fica registrado aqui como pendência, não decisão.

---

## 2. Grade atual (confirmada no banco, pós-V105)

| Plano      | Preço/mês | Empresas | Usuários | Itens     | IA            | Suporte            |
|------------|-----------|----------|----------|-----------|---------------|--------------------|
| Starter    | R$149     | até 3    | até 3    | até 100   | ❌ (desde V77) | Comunidade         |
| Business   | R$299     | até 20   | até 10   | até 500   | ✅             | E-mail prioritário |
| Enterprise | R$899     | até 50   | até 100  | até 5.000 | ✅             | Dedicado           |

Anual: 17% de desconto (2 meses grátis) — R$1.490 / R$2.990 / R$8.990. Trial: 14 dias no Business, sem cartão.

**Por que mexemos no `maxOrganizations` (V103)**: até 29/08, Business e Starter empatavam em 3 empresas — pagar 2x mais (R$299 vs R$149) não comprava nenhuma empresa a mais. O doc comercial (`contexto-comercial.md`) 
descreve o ICP do Business como "síndico profissional, 5-20 condomínios" — matematicamente impossível com limite de 3. Ajustado para 15 (Business) e 50 (Enterprise), mantendo o padrão de escala já usado em `maxUsers`/`maxItems` no resto da grade.

**Por que mexemos de novo (V105, 01/09/2026)**: a V103 corrigiu a incoerência com o Starter, mas
parou em 15 — 5 empresas abaixo do teto de "5-20 condomínios" que o próprio ICP já documentava.
Achado ao avaliar um lead de trial real com exatamente 20 condomínios: não era o cliente que não se
encaixava no Business, era a grade que tinha ficado aquém do próprio critério escrito. Como o trial
roda no plano Business sem cartão, sem esse ajuste o cliente nem conseguiria completar o cadastro
dos 20 condomínios dentro do período de teste. Enterprise não mudou — segue sendo o plano de
administradora com múltiplos clientes, perfil diferente de um síndico profissional com portfólio
próprio; empurrar esse tipo de lead pro Enterprise (3x o preço) contradiria o ICP já documentado.

---

## 3. Benchmark de mercado

| Concorrente                       | Preço                                                              | Observação                                                                                                         |
|-----------------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| Engeman / TOTVS                   | R$2k–10k/mês                                                       | Enterprise pesado, fora do nosso ICP                                                                               |
| Fracttal One                      | USD 35-80/usuário                                                  | Preço em dólar, suporte não-BR                                                                                     |
| ManFácil                          | R$99–299                                                           | Barato, sem compliance ABNT                                                                                        |
| **Condo Guardian** (achado 17/08) | Não divulgado                                                      | Mesmo ICP e ângulo normativo nosso — concorrente mais próximo. Zero prova social também (fase inicial igual a nós) |
| **Easy Alert** (achado 30/08)     | Não divulgado — "agende demonstração", valor por nº de edificações | Mesmo padrão: sem preço público, sem trial self-serve                                                              |

**Conclusão do benchmark**: os dois concorrentes de ICP mais parecido (Condo Guardian, Easy Alert) escondem o preço atrás de demonstração. Preço público + trial sem cartão continuam sendo diferencial real, não suposição — nenhum concorrente direto de posicionamento oferece isso hoje.

Starter/Business/Enterprise caem dentro da faixa observada de mercado (R$99–2.000+), coerentes com o posicionamento "compliance ABNT acessível".

---

## 4. Estrutura de custo (confirmada com Douglas, 30/08/2026)

| Item                      | Tipo                          | Valor                                                                                                                                               |
|---------------------------|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| Railway (backend+DB)      | Fixo/mês                      | R$110                                                                                                                                               |
| Meta Ads                  | Fixo/mês (investimento)       | R$1.000                                                                                                                                             |
| Vendedora (salário)       | Fixo/mês                      | R$700                                                                                                                                               |
| Vendedora (comissão)      | Variável, sobre valor líquido | 35%, recorrente pelos primeiros 6 meses de cada cliente                                                                                             |
| Grupo Silva (comissão)    | Variável, sobre valor líquido | 10%, recorrente pelos primeiros 6 meses de cada cliente                                                                                             |
| Asaas                     | Variável                      | ~2,5% médio estimado (PIX R$0,99-1,99 fixo; cartão R$0,49+1,99%)                                                                                    |
| S3 / OpenAI / outras SaaS | Variável / quase zero         | Volume atual desprezível                                                                                                                            |
| Grupo Silva — sinal       | One-time                      | R$5.000, pago 14/08/2026, **reembolsável se receita líquida < R$5.000 em 6 meses e Douglas provar implementação substancial das estratégias deles** |
| Congresso                 | One-time                      | R$5.000                                                                                                                                             |

"Valor líquido" = receita bruta menos todas as despesas (incluindo Asaas). Comissões incidem sobre esse líquido, não sobre o bruto.

---

## 5. Break-even e cenários (ticket de referência: Business R$299)

Custo fixo recorrente = R$1.810/mês (Railway + Ads + vendedora fixo).

**Break-even ≈ 7 clientes Business (R$1.856 de faturamento bruto/mês)** — o ponto de equilíbrio não muda com ou sem comissão, porque comissão só reduz o que sobra acima de zero, nunca o ponto onde o líquido chega a zero.

**Correção de leitura (31/08/2026)**: a Cláusula 4.1 do contrato Grupo Silva vincula a comissão a vendas "durante a vigência deste contrato" — um prazo de calendário fixo (14/08/2026 a 14/02/2027), não uma janela rolante de 6 meses por cliente. Ou seja: a comissão de 45% (35% vendedora + 10% Grupo Silva) corre para **todo** o faturamento da empresa até 14/02/2027, e cai pra zero de vez a partir daí (assumindo não-renovação) — não decai cliente a cliente conforme cada um completa 6 meses de casa. A tabela abaixo já usa essa leitura corrigida.

| Clientes Business | Bruto   | Líquido | Comissão (se dentro da vigência do contrato, até 14/02/27) | Resultado (dentro da vigência) | Resultado (após 14/02/27, comissão zerada) |
|-------------------|---------|---------|------------------------------------------------------------|--------------------------------|--------------------------------------------|
| 7                 | R$2.093 | R$231   | R$104                                                      | R$127                          | R$231                                      |
| 10                | R$2.990 | R$1.105 | R$497                                                      | R$608                          | R$1.105                                    |
| 20                | R$5.980 | R$4.020 | R$1.809                                                    | R$2.211                        | R$4.020                                    |

**Status real em 31/08/2026**: 0 clientes pagantes, 5 trials iniciados desde 31/07 (nenhum convertido ainda), R$10.000 já gastos em one-time (congresso + sinal Grupo Silva), ~R$1.810/mês de burn recorrente. CAC real via mídia paga ainda indefinido — sem conversão paga, não dá para calcular.

**Avaliação sobre operar no negativo nesta fase**: razoável para um SaaS pré-lançamento — o break-even é baixo (7 clientes) e o burn é conhecido e limitado. O ponto de atenção não é o negativo em si, é acompanhar a **taxa de conversão trial→pago**, 
não só volume de trial, para saber se o funil funciona antes de escalar o investimento em mídia.

### 5.1 Payback do buraco inicial (R$10.000 em custos únicos)

Quanto tempo até o saldo acumulado (partindo de -R$10.000) virar positivo, por ritmo de aquisição — plano Business, sem churn, comissão ativa só até 14/02/2027:

| Cenário    | Ritmo de novos clientes/mês | Sai do vermelho   | Clientes ativos nesse ponto |
|------------|-----------------------------|-------------------|-----------------------------|
| Pessimista | 1                           | mês 16 (dez/2027) | 16                          |
| Realista   | 2                           | mês 10 (jun/2027) | 20                          |
| Otimista   | 4                           | mês 7 (mar/2027)  | 28                          |

Nos três cenários o saldo piora antes de melhorar (o burn fixo supera a receita de poucos clientes nos primeiros meses) — no cenário realista, por exemplo, 
o pior ponto é ~R$11.900 negativo por volta do mês 3. A partir de 14/02/2027 (fim do contrato Grupo Silva, se não renovado), 
o resultado mensal dá um salto porque a comissão de 45% desaparece. Esses números são projeção sobre um ritmo de conversão hipotético — atualizar assim que houver a primeira venda paga real.

### 5.2 Meta de 200 clientes ativos em 12 meses — avaliação (01/09/2026)

**Agressiva**: exige ritmo médio de ~16,7 clientes novos/mês — 4,2x o cenário "otimista" da tabela acima (4/mês). Hoje: 0 clientes pagantes, 5 trials em ~1 mês de campanha, 0 conversões. Não é impossível, mas depende de canais/conversão ainda não validados (ex.: escala do time de closers/SDRs via Grupo Silva, aumento relevante do budget de Ads). Tratar como cenário-teto, não como base de planejamento de caixa.

**Se atingida, o lucro é folgado**: 200 clientes Business ≈ R$59.800 de bruto/mês, R$56.495 de líquido/mês — **28,6x o break-even de 7 clientes**. Como bater 200 em 12 meses significaria atingir esse patamar por volta de ago-set/2027, já bem depois do fim do contrato Grupo Silva (14/02/2027), não haveria mais os 45% de comissão descontando esse resultado — a conta seria essencialmente o líquido inteiro. Rentabilidade não é a dúvida nesse cenário; a dúvida é só se o ritmo de aquisição é alcançável.

---

## 6. Contrato Grupo Silva — resumo operacional

Documento completo: `docs/Contratos/Contrato_Grupo_Silva.pdf`. Pontos que importam para decisão de negócio:

- **Vigência**: 6 meses, 14/08/2026 a 14/02/2027, **sem renovação automática**. Não fazer nada = contrato encerra sozinho nessa data, sem multa.
- **Rescisão antecipada sem motivo**: não permitida, salvo acordo escrito mútuo. Se ocorrer sem acordo: sem devolução do já pago + multa de 20% sobre o aporte (R$1.000) + perde o direito à garantia de reembolso da cláusula 6.4.
- **Garantia de reembolso do sinal (Cláusula 6.4)**: se a receita líquida não atingir R$5.000 em 6 meses (mesmo implementando as estratégias deles substancialmente), dá para pedir 100% do sinal de volta, em até 60 dias após o fim do contrato (~até 15/04/2027). Só vale se o contrato correr o prazo natural completo.
- **Comissão (Cláusula 4.1)**: 10% sobre vendas "decorrentes ou provenientes das estratégias, ações e campanhas" deles — não é automático sobre tudo que for vendido durante a vigência, é sobre o que for atribuível ao trabalho deles.
- **Presunção de origem (Cláusula 4.6)**: em disputa sobre origem de um lead, presume-se válida a origem indicada pelo Grupo Silva — o ônus da prova em contrário é da Easy Maintenance.
- **Anti-evasão (Cláusula 4.7)**: veda manobra para driblar comissão via "alteração de canal de fechamento" com finalidade evasiva.
- **Não-aliciamento (Cláusulas 13.12 / 17)**: proibido contratar/aliciar colaboradores do Grupo Silva (incluindo a vendedora indicada) durante a vigência **e por mais 2 anos após o término**, qualquer que seja o motivo do término. Multa: 20x a última remuneração mensal do profissional, nunca menos que R$100.000 por profissional.

**Pendência aberta (30/08/2026)**: mensagem enviada ao Grupo Silva pedindo confirmação por escrito de que leads vindos de canais próprios (Meta Ads, prospecção pessoal como o congresso) e fechados sem envolvimento deles ficam fora do escopo da comissão da Cláusula 4. Resposta esperada a partir de 31/08 (domingo → segunda-feira). Atualizar esta seção quando responderem.

---

## 7. Itens em aberto

- [ ] Reavaliar o preço do Starter (R$149) agora que a IA foi desativada nesse tier — o racional original que justificou a subida de R$99 não se sustenta mais.
- [ ] Aguardar resposta por escrito do Grupo Silva sobre canais independentes (Meta Ads / prospecção pessoal) ficarem fora da comissão.
- [ ] Acompanhar taxa de conversão trial→pago nas próximas semanas antes de decidir escalar ou não o investimento em mídia paga.
