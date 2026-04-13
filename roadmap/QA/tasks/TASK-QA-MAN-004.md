# TASK-QA-MAN-004 — Validação do Onboarding em Cenários de Erro

## Tipo
QA Manual

## Categoria
Onboarding / UX / Resiliência

## Prioridade
🟠 Alto

## Épico
EPIC-006 — Produto SaaS

## Flow relacionado
[FLOW-004](../Flow/FLOW-004.md)

## Documento de Teste
[MTD-004](../MTD/MTD-004.md)

## Descrição
Validação manual do fluxo de onboarding com foco em cenários de erro. Verificar que erros exibem mensagens específicas, orientativas e no campo correto (não apenas toast genérico), e que falhas de integração (Asaas indisponível) não impedem o usuário de prosseguir para o trial.

Cobre a task TASK-016 e o comportamento de fallback implementado com TASK-008 (circuit breaker).

## Pré-condições
- Ambiente de staging configurado
- E-mail de teste não cadastrado no sistema
- CPF de teste válido (usar gerador) e inválido (000.000.000-00)
- Capacidade de simular falha do Asaas (circuit breaker ou desligar serviço no ambiente local)
- DevTools disponível para inspeção de requests

## Passos

### Passo 1 — Happy path (fluxo completo com dados válidos)
1. Acessar a URL de registro
2. Preencher: nome completo, CPF válido, e-mail novo, senha, nome da organização
3. Avançar pelo fluxo completo
4. Verificar loading state durante submissão (Slow 3G no DevTools)
5. Confirmar redirecionamento para o dashboard com trial ativo

### Passo 2 — CPF/CNPJ inválido
1. No formulário, inserir CPF: `000.000.000-00`
2. Manter outros campos válidos e submeter
3. Verificar:
   - Mensagem aparece diretamente no campo de CPF (não em toast global)
   - Mensagem é específica e orientativa
   - Formulário não é submetido

### Passo 3 — E-mail duplicado
1. No formulário, inserir e-mail já cadastrado no sistema
2. Submeter o formulário
3. Verificar mensagem específica com orientação para fazer login

### Passo 4 — Falha do Asaas (circuit breaker ativo)
1. Simular falha do Asaas no ambiente local (desligar ou forçar circuit breaker OPEN)
2. Preencher o formulário de onboarding com dados válidos e selecionar pagamento
3. Submeter e verificar:
   - Mensagem explica que o serviço de pagamento está indisponível
   - Opção de continuar para trial sem configurar pagamento
   - Usuário consegue acessar o produto após o fallback

### Passo 5 — Timeout de rede
1. Ativar DevTools → Network → throttling → Offline por 5 segundos durante submissão
2. Verificar:
   - Mensagem de erro de conectividade
   - Botão "Tentar novamente" visível
   - Dados do formulário não perdidos

### Passo 6 — Verificação no Sentry
1. Após executar os cenários acima em staging
2. Acessar o painel Sentry do projeto
3. Confirmar que nenhum `console.error()` não tratado foi capturado durante o onboarding

## Resultado Esperado
- Happy path: onboarding completo em < 3 minutos com loading states visíveis
- CPF inválido: mensagem inline no campo, não toast
- E-mail duplicado: mensagem específica com orientação
- Asaas indisponível: opção de trial sem pagamento funcionando
- Timeout: botão de retry com dados preservados
- Sentry: zero erros não tratados no fluxo

## Evidências Necessárias
- [ ] Screenshot do dashboard após onboarding bem-sucedido
- [ ] Screenshot do campo CPF com mensagem de erro inline
- [ ] Screenshot da mensagem de e-mail duplicado com link para login
- [ ] Screenshot da mensagem de fallback do Asaas com opção de trial
- [ ] Screenshot do estado de loading durante submissão (Slow 3G)

## Status
Pendente — executar antes do lançamento
