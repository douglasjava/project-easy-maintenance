# TASK-296 — Fila de ações do dashboard: chave React duplicada quando o mesmo item aparece duas vezes

## Tipo
BUGFIX (FRONTEND)

## Prioridade
🟢 Baixo — sem sintoma visível confirmado, mas é comportamento indefinido do React

## Contexto
Achado ao recapturar os prints da conta demo (TASK-294/295, 25/09/2026): o console do navegador acusa
`Encountered two children with the same key` no dashboard.

## Problema
`src/components/dashboard/compliance/ActionQueue.tsx:76` renderiza cada ação com `key={action.id}`,
que é o **id do item**. O mesmo item pode entrar na fila por dois motivos (ex.: item 164 aparece como
"vencendo" e como "sem evidência"), gerando duas linhas com a mesma chave. Com chave duplicada, o React
pode reaproveitar a linha errada ao atualizar a lista, por exemplo depois de "Adiar" ou "Concluir":
uma linha pode sumir ou ficar duplicada até o próximo reload.

## Correção sugerida
- Chave composta pelo motivo (`${action.id}-${action.type ?? action.reason}`), conferindo o nome do
  campo no contrato de `/dashboard/actions`;
- ou avaliar se o backend deveria consolidar as ações do mesmo item numa linha só (decisão de produto).

## Critérios de Aceite
- [ ] Sem warning de chave duplicada no console do dashboard
- [ ] Item com dois motivos continua aparecendo corretamente, e Adiar/Concluir atualiza as linhas certas

## Status
Backlog
