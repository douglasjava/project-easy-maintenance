# TASK-QA-MAN-003 — Teste E2E do Fluxo PIX com Sandbox Asaas

## Tipo
QA Manual — E2E

## Categoria
Billing / PIX / Integração

## Prioridade
🔴 Crítico

## Épico
EPIC-010 — PIX como Método de Pagamento Funcional

## Flow relacionado
[FLOW-003](../Flow/FLOW-003.md)

## Documento de Teste
[MTD-003](../MTD/MTD-003.md)

## Descrição
Validação manual end-to-end do fluxo completo de pagamento PIX recorrente. Cobre desde o recebimento do webhook `PAYMENT_CREATED`, exibição do QR Code na página de billing, envio do e-mail de vencimento (PAYMENT_OVERDUE), até o desaparecimento automático do card após confirmação do pagamento.

Cobre as tasks TASK-046, TASK-047 e TASK-048 que formam o EPIC-010.

## Pré-condições
- Ambiente sandbox do Asaas configurado com credenciais de teste
- Assinatura ativa com método PIX no ambiente sandbox
- Acesso ao painel sandbox do Asaas para disparar webhooks manualmente
- Acesso à caixa de entrada do e-mail do usuário de teste (ou painel MailerSend sandbox)
- Variável `ASAAS_WEBHOOK_TOKEN` correta no ambiente

## Passos

### Passo 1 — Estado inicial sem card PIX
1. Logar como usuário com assinatura PIX no sandbox
2. Acessar `/billing`
3. Confirmar que não há card de pagamento pendente

### Passo 2 — Disparar PAYMENT_CREATED e verificar QR Code
1. No painel sandbox do Asaas, disparar webhook `PAYMENT_CREATED` com `billingType=PIX`
2. Aguardar 10 segundos
3. Recarregar `/billing`
4. Verificar o card "Pagamento PIX Pendente":
   - QR Code exibido (não quebrado)
   - String Copia e Cola visível
   - Botão "Copiar" funcional
   - Countdown de expiração correto
   - Valor formatado em R$

### Passo 3 — Disparar PAYMENT_OVERDUE e verificar e-mail
1. No sandbox, disparar webhook `PAYMENT_OVERDUE`
2. Aguardar 15 segundos
3. Verificar caixa de entrada do usuário de teste
4. Verificar conteúdo do e-mail (valor, link de pagamento, template em PT-BR)
5. Na página `/billing`, verificar banner vermelho de OVERDUE no card

### Passo 4 — Confirmar pagamento e verificar auto-desaparecimento
1. No sandbox, confirmar o pagamento (disparar `PAYMENT_RECEIVED`)
2. Permanecer em `/billing` sem recarregar
3. Aguardar até 30 segundos
4. Verificar que o card desaparece automaticamente

### Passo 5 — Regressão com cartão de crédito
1. Logar como usuário com assinatura via cartão de crédito
2. Disparar `PAYMENT_CREATED` com `billingType=CREDIT_CARD`
3. Acessar `/billing`
4. Confirmar que card PIX NÃO aparece

### Passo 6 — Responsividade mobile
1. Com o card PIX visível, abrir DevTools → Toggle Device Toolbar
2. Selecionar viewport 375px (iPhone SE)
3. Verificar layout: sem overflow, QR Code visível, botão acessível

## Resultado Esperado
- Card PIX completo após PAYMENT_CREATED
- E-mail de lembrete recebido após PAYMENT_OVERDUE
- Card desaparece automaticamente após pagamento confirmado (≤ 30s)
- Nenhum card PIX para usuário de cartão de crédito
- Layout responsivo no mobile

## Evidências Necessárias
- [ ] Screenshot do card com QR Code visível
- [ ] Screenshot do e-mail recebido com conteúdo completo
- [ ] Screenshot do banner OVERDUE vermelho
- [ ] Sequência de screenshots (card presente → card ausente após pagamento)
- [ ] Screenshot do layout mobile
- [ ] Screenshot da resposta 403 ao tentar Copia e Cola por usuário não autorizado (se aplicável)

## Status
Pendente — executar antes do lançamento
