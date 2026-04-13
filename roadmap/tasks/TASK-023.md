# TASK-023 — Indicador de uso vs limite de plano

## Tipo
Produto / UX

## Categoria
Frontend / Produto

## Prioridade
🟡 Médio

## Fase
2 — Pós-lançamento

## Épico
EPIC-006 — Produto SaaS

## Descrição
O sistema bloqueia operações quando o usuário atinge o limite do plano (máximo de usuários, itens, organizações), mas não há indicação visual de quantos recursos o usuário já consumiu vs o limite do plano. O usuário é surpreendido com um erro quando tenta criar o 31º item no plano FREE (limite: 30).

## Problema
- Usuário não sabe que está próximo do limite
- Bloqueio inesperado gera frustração e suporte
- Oportunidade de conversão perdida ("você está usando 28/30 itens — faça upgrade para ilimitado")

## Impacto
Indicadores de uso são tanto uma feature de UX (evitar frustração) quanto de produto (gatilho de upgrade).

## Dependências
- Backend precisa retornar uso atual nos endpoints de acesso context
- TASK-023 depende de API que retorna `currentUsage` vs `maxAllowed`

## Critérios de Aceite
- [ ] Tela de usuários mostra "X de Y usuários usados"
- [ ] Tela de itens mostra "X de Y itens usados"
- [ ] Indicador visual (barra de progresso ou texto) próximo ao botão de criar
- [ ] Quando uso está em 80%+, indicador muda de cor e sugere upgrade
- [ ] Quando limite atingido, botão de criar mostra tooltip "Limite do plano atingido — faça upgrade"
- [ ] Link de upgrade acessível diretamente do indicador

## Subtasks
- [ ] Verificar se endpoint de access context retorna `currentUsage` para cada recurso
- [ ] Se não, adicionar ao endpoint de access context ou criar endpoint específico
- [ ] Criar componente `UsageMeter` reutilizável (barra de progresso com label)
- [ ] Integrar `UsageMeter` nas telas de usuários, itens e organizações
- [ ] Implementar lógica de cor (verde → amarelo → vermelho com base em %)

## Esforço
Médio (1 dia)

## Risco de não fazer
Usuários chocados com bloqueio inesperado geram tickets de suporte e churn.

## Status
Concluído
