# TASK-205 — Frontend: indicador visual de sincronização pendente com Asaas

## Tipo
FRONTEND

## Categoria
Billing / Onboarding — Confiabilidade

## Prioridade
🟡 Médio

## Épico
[EPIC-002](../epics/EPIC-002.md) — Confiabilidade Operacional

## QA obrigatório
Sim — QA manual: abrir a aba Pagamento de uma conta com `externalCustomerId` nulo (ex.: o Ricardo,
antes da correção) e confirmar que o indicador aparece; corrigir/sincronizar (TASK-201) e confirmar
que o indicador some depois do reload.

---

## Contexto

Hoje, pra saber se uma conta está sem `externalCustomerId` (cliente não criado na Asaas —
sintoma exato do caso do Ricardo Cerqueira), só olhando log bruto ou consultando o banco
diretamente. A resposta `BillingAccountDTO.BillingAccountResponse` já retorna `externalCustomerId`
pro frontend (`AdminBillingController.getAccount`), então o dado já está disponível — só não é
exibido em lugar nenhum.

## Objetivo

Badge de aviso na aba Pagamento do admin (`/private/users/[id]`) quando a conta ainda não tem
`externalCustomerId`, pra Douglas identificar contas com problema sem precisar ir atrás de log/banco.

## Escopo

`src/app/private/users/[id]/page.tsx`, aba Pagamento: se `accountData.externalCustomerId` for
vazio/nulo, exibir um badge (ex.: "⚠️ Pendente de sincronização com Asaas", estilo consistente com
os badges já usados na tela) próximo ao cabeçalho da aba ou do campo de método de pagamento — visível
sem precisar expandir nada. Quando preenchido, não exibe nada (comportamento atual, sem indicador).

Naturalmente complementar ao botão de TASK-201 ("Ressincronizar com Asaas") — o badge mostra o
problema, o botão resolve.

## Critérios de Aceite

- [ ] Badge "Pendente de sincronização com Asaas" aparece quando `externalCustomerId` é nulo/vazio
- [ ] Badge não aparece quando `externalCustomerId` está preenchido
- [ ] `npm run build` sem regressão

## Fora de Escopo

- Indicador equivalente em outras telas (ex.: lista de usuários) — escopo restrito à aba Pagamento
  do detalhe do usuário, onde o admin já vai pra investigar/corrigir.

## Dependências
Nenhuma — mas faz sentido implementar junto de TASK-201 (mesma tela, mesmo contexto de trabalho).

## Riscos
Baixo — só leitura/exibição de um campo que a API já retorna.

## Esforço
Baixo

## Status
🟡 Em validação — implementada em `feature/EPIC-002-fase3-asaas-sync` (web), commit `0620743`
(junto de TASK-201 — mesmo arquivo/mesma tela). Badge "⚠️ Pendente de sincronização com Asaas" na
aba Pagamento quando `externalCustomerId` está vazio. `npm run build` limpo.
