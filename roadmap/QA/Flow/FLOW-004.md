# FLOW-004 — Onboarding

## Criticidade
🔴 CRITICAL

## Launch Relevance
First impression — abandono no onboarding = lead perdido permanentemente. É o fluxo de maior impacto em conversão.

## Tasks Relacionadas
- TASK-016 — Tratamento de erro claro no onboarding
- TASK-008 — Circuit breaker para serviços externos (fallback Asaas)

## Descrição do Fluxo

1. Novo usuário acessa a tela de cadastro
2. Preenche dados pessoais e da organização (nome, CPF/CNPJ, e-mail, senha)
3. Seleciona método de pagamento (ou avança para trial sem cartão)
4. Sistema cria conta Asaas e configura assinatura
5. Usuário é redirecionado para o dashboard com trial ativo
6. Erros em qualquer etapa mostram mensagens específicas e orientativas

## Camadas Impactadas
- **Backend:** Controllers de onboarding, Asaas integration, circuit breaker (TASK-008)
- **Frontend:** Formulários de onboarding, exibição de erros por campo, estados de loading

## Cenários Críticos

| Cenário | Tipo | Cobertura Atual |
|---------|------|----------------|
| Onboarding completo com dados válidos | Happy path | Manual |
| CPF/CNPJ inválido → mensagem inline no campo | Validação | Manual (TASK-016) |
| E-mail já cadastrado → mensagem específica | Validação | Manual (TASK-016) |
| Falha do Asaas → opção de prosseguir para trial | Resiliência | Manual (TASK-016 + TASK-008) |
| Timeout de rede → botão "Tentar novamente" | Resiliência | Manual (TASK-016) |
| Loading state durante criação da conta | UX | Manual |
| Zero console.error() em produção | Qualidade | Sentry (TASK-022) |
| Nome de organização duplicado → orientação ao usuário | Validação | A validar |

## Validação Recomendada
- **Manual:** [MTD-004](../MTD/MTD-004.md) — executar com cenários de erro controlados
- **Automatizada:** Testes de API para validação de campos (próxima sprint)

## Gaps
- Sem teste automatizado do fluxo de onboarding
- Comportamento de "continuar sem pagamento" quando Asaas falha precisa de validação explícita
- Mapeamento completo de todos os códigos de erro do backend para mensagens em PT-BR

## Status de Validação
- [ ] Happy path validado manualmente
- [ ] Cenários de erro de campo validados
- [ ] Fallback de Asaas validado
- [ ] Sentry capturando exceções (TASK-022 concluída — verificar)
