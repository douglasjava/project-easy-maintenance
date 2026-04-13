# TASK-015 — Banner de trial expirando no dashboard

## Tipo
Produto / UX

## Categoria
Frontend / Produto / Conversão

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-006 — Produto SaaS

## Descrição
Usuários em trial precisam de visibilidade clara sobre quantos dias restam antes do bloqueio. Atualmente não há indicação visível no dashboard sobre o status do trial. Quando o sistema bloquear acesso após o trial, a experiência será frustrante por falta de aviso prévio.

## Problema
Sem aviso visual:
- Usuário é surpreendido pelo bloqueio
- Taxa de conversão trial → pago é menor (sem urgência percebida)
- Aumento de tickets de suporte ("por que fui bloqueado?")

## Dependências
- Backend precisa retornar `daysRemainingInTrial` na resposta de subscription status (verificar se já existe)
- TASK-012 (e-mails) deve estar funcionando para comunicação complementar

## Critérios de Aceite
- [ ] Banner visível no topo do dashboard quando subscription está em trial
- [ ] Banner mostra: "Seu trial expira em X dias" com link para upgrade
- [ ] Quando restam ≤ 3 dias, banner muda para cor de alerta (vermelho/laranja)
- [ ] Quando trial já expirou mas acesso ainda não foi bloqueado (grace period), banner muda para urgente
- [ ] Banner possui botão de CTA para ir à tela de billing/upgrade
- [ ] Banner pode ser dispensado (fechado) mas reaparece no próximo login

## Subtasks
- [ ] Verificar se API já retorna `daysRemainingInTrial` ou `trialExpiresAt`
- [ ] Se não existe, adicionar campo ao endpoint de access context ou subscription guard
- [ ] Criar componente `TrialBanner` no frontend
- [ ] Integrar `TrialBanner` no layout do dashboard (abaixo do header)
- [ ] Implementar lógica de cores por urgência (> 7 dias: azul, 3-7: amarelo, < 3: vermelho)

## Esforço
Pequeno (3-5h)

## Risco de não fazer
Conversão de trial baixa por falta de urgência percebida. Usuários chocados com o bloqueio gerando suporte excessivo.

## Status
Concluído
