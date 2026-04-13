# TASK-016 — Tratamento de erro claro no onboarding

## Tipo
Bug / UX / Produto

## Categoria
Frontend / Backend / Onboarding

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-006 — Produto SaaS

## Descrição
O fluxo de onboarding é crítico — é a primeira impressão do produto. Atualmente, erros no processo de onboarding (ex: falha na criação da conta Asaas, CPF/CNPJ inválido, erro de rede) mostram `console.error()` e provavelmente uma mensagem genérica para o usuário. Isso cria frustração no momento mais importante do ciclo de vida do cliente.

## Problema
Falhas comuns no onboarding:
- CPF/CNPJ inválido → mensagem de erro precisa ser específica e orientar correção
- Asaas fora do ar → usuário não deve ficar preso; deve poder continuar com trial sem cartão
- Nome de organização já existente → orientar o usuário a mudar ou entrar em contato
- Erro de rede → mensagem com instrução de retry

## Impacto
- Abandono no onboarding = perda permanente do lead
- Usuário que não consegue criar conta nunca paga

## Dependências
- Entender os possíveis erros que o backend retorna no onboarding
- TASK-008 (circuit breaker) para garantir que falha do Asaas não trava o onboarding completamente

## Critérios de Aceite
- [ ] Erros de validação do backend são mapeados para mensagens específicas no frontend (não toast genérico)
- [ ] CPF/CNPJ inválido mostra mensagem diretamente no campo
- [ ] Falha de comunicação com Asaas não bloqueia completamente o onboarding — usuário pode prosseguir para trial sem configurar pagamento agora
- [ ] Erros de rede mostram botão "Tentar novamente"
- [ ] Nenhum `console.error()` em produção (substituir por logger/Sentry)
- [ ] Fluxo de onboarding tem loading state durante operações assíncronas

## Subtasks
- [ ] Mapear todos os erros possíveis que o backend retorna no onboarding
- [ ] Criar mapeamento de códigos de erro → mensagens em português amigável
- [ ] Implementar exibição de erros por campo (não apenas toast global)
- [ ] Adicionar estado de loading/skeleton durante criação da conta
- [ ] Verificar e implementar fallback caso Asaas falhe
- [ ] Remover `console.error()` e substituir por handler adequado

## Esforço
Pequeno (4-8h)

## Risco de não fazer
Taxa de abandono no onboarding alta. Leads perdidos por erros técnicos que o usuário não consegue resolver sozinho.

## Status
Concluído
