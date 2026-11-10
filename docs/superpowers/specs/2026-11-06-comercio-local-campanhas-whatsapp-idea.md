# Comércio Local — Campanhas via WhatsApp para Moradores

**Data:** 06/11/2026 (ideia trazida por Tiago, sócio)
**Status:** Embrionária — só o registro da ideia. Sem levantamento técnico, jurídico ou de produto
ainda. Não entra em EPIC/tasks até fazer o levantamento completo.

## Ideia

Oferecer a comerciantes locais (do entorno dos condomínios atendidos) a possibilidade de enviar
campanhas/ofertas diretamente aos moradores via WhatsApp, usando a plataforma Easy Maintenance como
intermediária. Visão de Tiago: monetizar o acesso que a plataforma já tem aos moradores, abrindo uma
fonte de receita adicional fora do core (manutenção predial).

## Por que pode fazer sentido

- Público hiperlocal e cativo (moradores do próprio condomínio/região) é algo que comerciante local
  valoriza e hoje não tem canal direto pra isso.
- Receita adicional não dependente de upsell dentro do produto atual de manutenção.

## Riscos/preocupações já identificados (a validar no levantamento completo)

1. **LGPD** — uso de dados de contato de moradores para fins comerciais de terceiros exige base
   legal e consentimento específico, separado do consentimento de uso do assistente para manutenção.
   Ponto que o próprio Douglas já sinalizou que precisa ser levantado.
2. **Risco reputacional/técnico no WhatsApp** — o número/assistente hoje é usado para comunicação
   transacional (chamados, manutenção, aprovações — ver EPIC-031/039/040). Misturar campanhas
   promocionais no mesmo canal pode degradar a qualidade do número no WhatsApp Business (rate
   limiting/banimento) e a confiança do morador no canal. Recomendação inicial: número e lista de
   opt-in **separados** do assistente de manutenção, nunca o mesmo canal.
3. **Prioridade** — produto ainda está com 0 clientes pagantes no core (ver memória
   `project_zero_customers_landing_copy`); isso é uma frente de produto nova (marketplace de atenção
   local) dentro de um produto que ainda não provou monetização do core. Avaliar depois, não agora.

## Próximos passos (quando for fazer o levantamento completo)

- Mapear base legal LGPD (opt-in explícito do morador para campanhas de terceiros, finalidade
  distinta de manutenção, direito de revogar).
- Desenhar modelo de negócio (quem paga: comerciante por envio/mês? comissão por conversão?).
- Decidir separação de canal/número WhatsApp vs. assistente de manutenção.
- Validar apetite real de comerciantes locais (não só hipótese de Tiago).
