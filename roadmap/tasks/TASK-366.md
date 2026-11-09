# TASK-366 — Jurídico/Produto: avaliar necessidade de contrato formal assinado (além do clickwrap `/termos`)

## Tipo
INFRA / CONFIG (jurídico/produto, não é código)

## Prioridade
🟢 Baixo

## Épico
— (tema jurídico/comercial, sem épico técnico associado)

## Depende de
—

## QA obrigatório
Não (não envolve código).

## Contexto
Discussão em 19/10/2026: Douglas perguntou se o produto precisa de contrato assinado nas duas
pontas (bilateral) além do clickwrap de Termos de Uso já em produção em
[`easy-maintenance-web/src/app/termos/page.tsx`](../../easy-maintenance-web/src/app/termos/page.tsx)
(BRAINBYTE CONSULTORIA TI LTDA, CNPJ 50.047.256/0001-22 — **não confundir** com o novo CNPJ em
abertura para NFS-e, ver [[project_fiscal_invoice_nfse]]).

**Conclusão da conversa (sem ação imediata):**
- Clickwrap é válido juridicamente no Brasil para contrato de adesão e cobre bem a venda
  self-service (STARTER/BUSINESS), sem fricção no checkout automático.
- Contrato formal assinado (papel ou e-signature — Clicksign/DocuSign/Autentique) só tende a ser
  necessário/exigido quando: (1) cliente ENTERPRISE/administradora grande com departamento de
  compliance/procurement que exige instrumento assinado; (2) condições negociadas fora do padrão
  do clickwrap (SLA customizado, prazo, cláusula específica); (3) ticket/risco alto o suficiente
  para justificar segurança jurídica extra.
- Decisão: **não produzir nada agora**. Manter o clickwrap como está. Preparar um contrato
  formal (reaproveitando o conteúdo do `/termos`, com qualificação das partes + campo de
  assinatura) só quando um cliente grande pedir — não antes, para não gerar trabalho sem
  demanda real.

Esta task existe só para não perder o histórico da decisão, não para disparar produção de
documento agora.

**Prompt**: `quando um cliente ENTERPRISE/administradora pedir contrato assinado, reabrir esta
task e gerar o contrato formal reaproveitando o texto de /termos (Word/PDF, assinável via
Clicksign/DocuSign/Autentique), com revisão de um advogado antes do uso real.`

## Critérios de aceite
- [ ] Gatilho real identificado (cliente concreto pedindo contrato assinado) antes de qualquer
      produção de documento.
- [ ] Contrato formal gerado reaproveitando o texto de `/termos`, com campos de qualificação das
      partes e assinatura.
- [ ] Revisão por advogado antes de enviar para assinatura real (este trabalho é orientação de
      produto, não assessoria jurídica formal).

## Status
Backlog — aguardando gatilho real (sem demanda concreta ainda em 19/10/2026).
