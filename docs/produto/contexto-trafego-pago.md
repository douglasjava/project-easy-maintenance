# Easy Maintenance — Contexto para Tráfego Pago
**Use este texto como contexto de produto em prompts para gestão/criação de campanhas (Meta Ads, Google Ads).**
*Versão: 07/08/2026*

---

## O produto em uma frase

Easy Maintenance é um SaaS brasileiro de gestão de manutenção preventiva que tira condomínios, hospitais, escolas e indústrias das planilhas e do WhatsApp, centralizando ativos, prazos, evidências e conformidade com normas ABNT em uma única plataforma.

## Público-alvo (segmentos e quem decide a compra)

- **Segmentos**: condomínios, hospitais/clínicas, escolas, indústrias/galpões.
- **Quem paga**: síndicos profissionais, administradoras de condomínios, gestores de facilities, responsáveis técnicos.
- **Dor real que motiva a busca**: planilhas espalhadas sem histórico consolidado, ordens de manutenção perdidas em conversas de WhatsApp, perda de memória técnica quando o síndico/gestor troca, e risco jurídico real por falta de comprovação documental (a ABNT NBR 5674 exige plano formal de manutenção com evidência).

## Diferenciais (usar estes ângulos, não "feature-speak" genérico de SaaS)

O posicionamento validado — testado e corrigido durante o próprio processo de otimização da landing — é **contrastar com a alternativa real do cliente (planilha/WhatsApp), não com concorrentes de SaaS**:
- "Nada de planilha por prédio" — uma estrutura só, com hierarquia entre organizações/filiais.
- "Histórico que não se perde" — diferente da planilha que some a cada troca de síndico, o histórico técnico fica registrado pra sempre.
- "Evidência que não se perde no zap" — cada manutenção nasce com a foto de execução vinculada, não perdida numa conversa de WhatsApp.
- "Foco em legislação brasileira" — conformidade com ABNT NBR 5674, 14037, 16280 (não é feature genérica de "compliance", é a obrigação legal real do cliente).

## Oferta / CTA

- CTA principal: **"Solicitar Demonstração"** — captura só o e-mail, sem fricção (não pedir mais campos, isso já foi testado e mantido deliberadamente simples pra tráfego frio).
- Trial: **14 dias grátis**, sem cartão de crédito.
- Planos (mensal): Starter R$149, Business R$299, Enterprise R$899. Anual com desconto (~17%, "2 meses grátis").
- **Sem política de reembolso** — cancelamento interrompe cobranças futuras, não devolve valor já pago (isso é regra confirmada, não use linguagem que sugira reembolso em anúncio).

## ⚠️ Restrições importantes (não violar em copy/criativo)

- **Zero clientes pagantes até agora** — não use nem sugira prova social numérica ("centenas de clientes", contadores, depoimentos, logos de clientes). Isso já foi removido da landing por ser propaganda enganosa. Qualquer prova social só pode entrar depois que houver números reais confirmados.
- **LGPD**: o formulário já tem checkbox de consentimento obrigatório; qualquer peça de anúncio que colete dado (formulário nativo do Meta, por exemplo) precisa do mesmo cuidado — não prometer nada sobre uso de dados que a Política de Privacidade não confirme.
- Não inventar números de mercado além dos já documentados (ver `docs/produto/context-brief.md`, seção 4) sem confirmar comigo antes.

## Estado atual do tracking (o que já funciona e o que não)

- **Meta Pixel**: instalado e validado em produção (`window.fbq`, eventos `PageView` e `Lead` confirmados chegando de verdade no Meta) desde 31/07/2026. **Campanha do Meta Ads já está no ar.**
- **Google Tag**: ainda **não instalado** — sem ID fornecido. Nenhuma conversão do Google Ads está sendo reportada até isso ser resolvido.
- **UTM**: capturado e persistido em cookie de 30 dias (atribuição "first touch"), chega até o payload do lead e até o link de WhatsApp da página de agradecimento.
- **Fluxo pós-conversão**: lead preenchido → `/obrigado` (página de confirmação, dispara evento `Lead`, oferece fallback de WhatsApp com contexto da campanha) — não é mais um simples alert de sucesso.
- **Conversions API / server-side tracking**: não implementado ainda (fase 2 documentada, dependente de credenciais que ainda não foram levantadas).

## Links relevantes

- Landing: https://www.easymaintenance.com.br/landing
- Página de obrigado (pós-lead): https://www.easymaintenance.com.br/obrigado
- Política de Privacidade: https://www.easymaintenance.com.br/privacidade
- Termos de Uso: https://www.easymaintenance.com.br/termos

## Tom de voz

Direto, sem jargão de SaaS genérico. Fala a língua de quem hoje resolve isso com planilha e grupo de WhatsApp — não de quem já usa outra ferramenta de gestão. Português do Brasil, sem anglicismo desnecessário.

---

*Para contexto mais amplo de produto (modelo de negócio completo, matriz competitiva, stack técnica, projeções financeiras), ver `docs/produto/context-brief.md` — mas atenção: aquele documento é de 23/06/2026 e ainda descreve o lançamento como "iminente"; hoje a campanha já está rodando, então essa seção específica dele está desatualizada.*
