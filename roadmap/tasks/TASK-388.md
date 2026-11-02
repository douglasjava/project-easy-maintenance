# TASK-388 — BACKEND: intake do QR Code — apto/bloco + desvio para pendência

## Tipo
BACKEND

## Categoria
Esteira de Identidade do Morador

## Prioridade
🟠 Alto

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim — abrir solicitação com telefone novo (confirma que vira pendência, não chamado), abrir com
telefone já aprovado (confirma que vai direto pro chamado), reenviar com o mesmo telefone pendente
(confirma atualização, não duplicação).

---

## Contexto
Ponto de entrada da esteira — decide se a solicitação processa direto ou fica retida. Detalhe
completo na spec da esteira, seção "Fluxo completo", passos 1 a 3 e 4.1.

## Escopo
- Novo campo **apto/bloco** (texto livre) no corpo de `POST /public/resident-tickets` (EPIC-027),
  opcional na validação de formato (síndico resolve a ambiguidade na aprovação), mas obrigatório
  por regra de negócio quando o telefone ainda não é `MORADOR` reconhecido.
- Antes de criar o `ResidentTicket`, verificar via `CondoPersonRepository
  .findByOrganizationIdAndPhoneAndRole(orgId, phone, "MORADOR")` (TASK-381):
  - **Encontrado** (`CondoPerson` ativo) → segue o fluxo normal do EPIC-027 sem mudança (cria o
    chamado, kanban, e-mail a ADMINs).
  - **Não encontrado** → não cria `ResidentTicket` ainda. Em vez disso: se já existe
    `ResidentIdentityPending` `PENDENTE` pro mesmo telefone+organização (TASK-387), atualiza o
    `request_payload`/`unit_hint`/`name` com os dados mais recentes; senão, cria uma nova
    pendência. Resposta pública ao morador confirma recebimento (sem mencionar protocolo — ele só
    existe depois da aprovação).

## Critérios de Aceite
- [x] Telefone com `CondoPerson` papel `MORADOR` ativo: solicitação cria `ResidentTicket` normal,
      sem passar pela pendência
- [x] Telefone sem `CondoPerson`: solicitação não cria `ResidentTicket`, cria
      `ResidentIdentityPending` com status `PENDENTE`
- [x] Segundo envio do mesmo telefone, ainda sem `CondoPerson` e com pendência `PENDENTE` aberta:
      atualiza a pendência existente, não cria uma segunda
- [x] Resposta pública nunca expõe número de protocolo para quem está em pendência (ele não existe
      ainda) — `ResidentTicketIntakeResponse` substitui `ResidentTicketResponse` como retorno
- [x] `mvn test` sem regressão (1624/1624)
- [ ] QA manual (smoke test ao vivo contra API local) — bloqueado: servidor local não pôde ser
      reiniciado nesta sessão

## Dependências
TASK-387 (entidade da pendência) e TASK-381 (consulta de `CondoPerson` por telefone/papel,
EPIC-039). Desbloqueia TASK-389/TASK-390.

## Riscos
Mudar o endpoint público mais sensível do EPIC-027 (ponto de entrada anônimo, já sob rate limit) —
testar que o comportamento pra quem já é `MORADOR` reconhecido não regride em nada (mesmo caminho
de hoje).

## Esforço
Médio

## Status
🟢 Implementado (02/11/2026) — branch `feature/EPIC-040-resident-identity-approval`, commit
`43556b5` (`easy-maintenance-api`). **Decisão de implementação não prevista no escopo original**:
embora a task esteja classificada como BACKEND, mudar o contrato de resposta de
`POST /public/resident-tickets` (`ResidentTicketResponse` → `ResidentTicketIntakeResponse`)
quebraria silenciosamente a tela pública de abertura de chamado já em produção (leria
`protocolNumber` de um ticket inexistente). Ajustado também o mínimo necessário no frontend —
campo apto/bloco no formulário + aviso "aguardando aprovação do síndico" quando `pending=true` —
commit `ebaeb41` (`easy-maintenance-web`), `tsc`/`build` limpos. Suíte completa: 1624/1624, 0
falhas. QA manual (smoke contra API real) pendente até reiniciar o servidor local. Desbloqueia
TASK-389/390.
