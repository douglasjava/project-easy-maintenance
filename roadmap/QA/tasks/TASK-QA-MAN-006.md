# TASK-QA-MAN-006 — Validação do Banner de Trial e Indicador de Uso de Plano

## Tipo
QA Manual

## Categoria
Produto SaaS / UX / Conversão

## Prioridade
🟠 Alto

## Épico
EPIC-006 — Produto SaaS

## Flow relacionado
[FLOW-005](../Flow/FLOW-005.md)

## Documento de Teste
[MTD-005](../MTD/MTD-005.md)

## Descrição
Validação manual do banner de trial e do indicador de uso vs limite de plano. Verificar que o banner exibe os dias corretos com cores de urgência progressivas, que o CTA direciona para o upgrade, e que o indicador de uso comunica proativamente quando o usuário está próximo do limite do plano.

Cobre as tasks TASK-015, TASK-023 e TASK-030.

## Pré-condições
- Usuário em trial ativo no banco de dados
- Acesso ao banco para manipular `trial_expires_at` (UPDATE SQL)
- Usuário com plano ACTIVE pago (para verificar ausência do banner)
- Usuário com uso próximo do limite (ex: 24 de 30 itens)

## Passos

### Passo 1 — Banner com > 7 dias (cor neutra)
1. Garantir que `trial_expires_at` está definido para > 7 dias no futuro
2. Logar e acessar o dashboard
3. Verificar presença do banner com texto de dias restantes
4. Verificar que a cor é **neutra** (azul ou cinza, não alerta)

### Passo 2 — Banner com 5 dias (amarelo)
1. Executar SQL: `UPDATE subscriptions SET trial_expires_at = DATE_ADD(NOW(), INTERVAL 5 DAY) WHERE ...`
2. Relogar ou aguardar refresh de dados de subscription
3. Verificar que o banner muda para **cor amarela/laranja**

### Passo 3 — Banner com 2 dias (vermelho)
1. Executar SQL: `UPDATE subscriptions SET trial_expires_at = DATE_ADD(NOW(), INTERVAL 2 DAY) WHERE ...`
2. Relogar e verificar que o banner muda para **cor vermelha**

### Passo 4 — CTA do banner
1. Com banner visível, clicar no botão de ação (ex: "Fazer upgrade", "Ver planos")
2. Verificar redirecionamento para tela de billing, upgrade ou comparação de planos
3. Verificar que a tela de destino exibe planos disponíveis

### Passo 5 — Banner reaparece após dispensar
1. Clicar no botão de fechar/dispensar o banner
2. Confirmar que o banner desaparece
3. Fazer logout e logar novamente
4. Confirmar que o banner **reaparece**

### Passo 6 — Banner ausente para plano ACTIVE
1. Logar como usuário com assinatura ACTIVE paga
2. Acessar o dashboard
3. Confirmar que **nenhum banner de trial** aparece

### Passo 7 — Indicador de uso em 80% (alerta)
1. Garantir que o usuário tem 24 de 30 itens no plano FREE
2. Acessar `/items`
3. Verificar indicador "24 de 30 itens usados" com **cor laranja**
4. Verificar se há link ou botão de upgrade próximo ao indicador

### Passo 8 — Bloqueio no limite (100%)
1. Garantir que o usuário tem exatamente 30 itens (limite)
2. Acessar `/items` e tentar criar um novo item
3. Verificar tooltip ou mensagem bloqueando a ação
4. Confirmar que há indicação de upgrade disponível

## Resultado Esperado
- Banner com cores corretas por faixa de urgência (neutra → amarelo → vermelho)
- CTA funcional direcionando para tela de upgrade
- Banner reaparece após re-login
- Banner ausente para usuários pagos (regressão)
- Indicador de uso em 80%+ com cor de alerta
- Botão bloqueado no limite com tooltip de upgrade

## Evidências Necessárias
- [ ] Screenshot do banner em cada estado de urgência (3 screenshots)
- [ ] Screenshot da tela de destino após clicar no CTA
- [ ] Screenshot do dashboard sem banner para usuário ACTIVE
- [ ] Screenshot do indicador de uso com 80%+ e cor de alerta
- [ ] Screenshot do botão bloqueado com tooltip de limite

## Status
Pendente — executar antes ou logo após o lançamento
