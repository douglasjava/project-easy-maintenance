## O produto e o modelo de receita

Easy Maintenance é um SaaS brasileiro de gestão de manutenção preventiva (condomínios, hospitais, escolas, indústrias).

**Planos mensais**: Starter R$149, Business R$299, Enterprise R$899.
**Planos anuais**: 17% de desconto (2 meses grátis) — Starter R$1.490/ano, Business R$2.990/ano, Enterprise R$8.990/ano.
**Trial**: 14 dias grátis no plano Business, sem cartão de crédito.
**Sem reembolso**: cancelamento interrompe cobranças futuras, não devolve valor já pago.

**Status em 21/08/2026**: zero clientes pagantes confirmados — qualquer projeção financeira deve partir de receita real informada, nunca supor cliente que não foi confirmado.

## Processamento de pagamento — Asaas

Pagamento via PIX recorrente e cartão de crédito recorrente, processado pelo Asaas.

**Estrutura real de taxas do Asaas** (referência pública, confirmar valor exato no extrato):
- PIX recorrente: taxa fixa por transação — R$0,99 (primeiros 3 meses) e R$1,99 depois.
- Cartão de crédito: R$0,49 fixo por cobrança + 1,99% sobre o valor (parcelado/assinatura).

Como a planilha de controle é mensal (não por transação), usamos uma **% média estimada** (hoje 2,5%) aplicada sobre o valor bruto, como simplificação — não é o cálculo exato do Asaas, é uma aproximação de controle gerencial. Ajustar essa % periodicamente com base no extrato real.

## Despesas recorrentes (categorias já mapeadas)

- Meta / Facebook Ads (tráfego pago)
- Railway (hospedagem — backend + banco de dados)
- Domínio (easymaintenance.com.br)
- Vídeos (produção de conteúdo)
- ChatGPT / OpenAI (IA SAMU — assistente do produto)
- E-mails transacionais
- WhatsApp (envio de notificações automáticas)
- Google Places API (busca de fornecedores próximos, dentro do produto)
- AWS S3 (armazenamento de evidências fotográficas e laudos)
- Claude / Anthropic (uso do Cowork/assistente)

Hoje (21/08/2026) a maioria dessas despesas variáveis está zerada ou próxima de zero, porque ainda não há usuários ativos gerando volume de uso.

## Canal de vendas — Grupo Silva

Contratado em agosto/2026 como canal de vendas terceirizado (não é o mesmo modelo do programa de afiliados abaixo):

- **Sinal de confiança**: R$5.000, pago uma vez. Reembolsável apenas se **nenhum cliente** fechar em 6 meses (gatilho de reembolso é baixo — qualquer cliente fechado, mesmo pequeno, encerra o direito ao reembolso).
- **Vendedor dedicado**: salário de R$1.500/mês, **pago pela Easy Maintenance** (confirmado com o Grupo Silva) + comissão de 1% a 2%.
- **Grupo Silva**: 10% sobre o **valor líquido** (receita bruta menos todas as despesas, incluindo a taxa do Asaas) — não sobre a receita bruta.
- Pendências a confirmar por escrito: se o vendedor é dedicado só à Easy Maintenance ou atende outras empresas da carteira do Grupo Silva; quem fica com os dados/leads gerados; cláusula de saída/rescisão.

## Programa de indicação / parcerias (diferente do Grupo Silva)

- **Indicador (padrão)**: 20% de comissão sobre o primeiro pagamento do cliente indicado, pago via PIX em até 10 dias úteis. Cadastro aberto em `easymaintenance.com.br/indicador/novo`.
- **Parceiro (estratégico)**: 20% recorrente por 6 meses, negociado individualmente com parceiros de alto potencial (corretores, administradoras, engenheiros de laudos).

## Estrutura da planilha de controle mensal

A planilha (`Easy_Maintenance_Controle_Mensal_v3.xlsx`) segue esta lógica, mês a mês:

1. **Valor Bruto** = quantidade de clientes por plano × preço do plano.
2. **Despesas** = taxa Asaas (calculada por fórmula) + todas as despesas recorrentes listadas acima (preenchimento manual).
3. **Valor Líquido** = Valor Bruto − Despesas.
4. **Comissões** = % Comissão Vendedor × Valor Líquido + % Grupo Silva × Valor Líquido (nunca negativas — travam em zero se o líquido for negativo).
5. **Despesa única** = sinal do Grupo Silva (aparece só no mês em que foi pago).
6. **Resultado do Mês** = Valor Líquido − Comissões − Despesa única.
7. **Saldo Acumulado** = soma do Resultado do Mês com o saldo do mês anterior.

Cores: azul = célula de entrada manual, amarelo = percentual/premissa ajustável, preto = fórmula calculada automaticamente.

## Restrições importantes (mesmas do projeto Comercial)

- Não supor cliente pagante ou receita que não foi confirmada — só lançar número real.
- Não inventar taxas ou custos — usar valor real informado ou marcar como estimativa, deixando isso explícito.
- Desconto ou condição comercial fora do documentado (17% anual) precisa de aprovação prévia do Douglas antes de entrar em qualquer projeção.

## Contato

Douglas Dias — fundador — douglasmarquesdias@gmail.com — (31) 99982-6634
