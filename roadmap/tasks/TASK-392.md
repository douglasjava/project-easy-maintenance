# TASK-392 — INFRA/CONFIG: template WhatsApp de aprovação (botões) — submissão Meta

## Tipo
INFRA/CONFIG

## Categoria
Esteira de Identidade do Morador

## Prioridade
🔴 Crítico

## Épico
[EPIC-040](../epics/EPIC-040.md) — Esteira de Aprovação de Identidade do Morador

## QA obrigatório
Sim (QA manual, em produção, depois da aprovação) — confirmar que o template renderiza
corretamente e que os botões Aprovar/Reprovar chegam até o webhook do assistente.

---

## Contexto
Mensagem proativa (fora de sessão) exige template HSM aprovado pela Meta, mesma exigência já vista
em TASK-368/TASK-372 (EPIC-023/EPIC-027). Ação do Douglas, não automatizável — precisa de acesso ao
Meta Business Manager. Detalhe completo na spec da esteira, seção "O que fica pro builder decidir".

## Escopo
- Criar e submeter template novo (ex. `aprovacao_identidade_morador_v1`) com variáveis: nome,
  telefone, apto/bloco informado, resumo da solicitação, e dois botões de resposta rápida
  (Aprovar/Reprovar).
- Confirmar nome exato do template e variáveis com o que o código da TASK-389 espera (alinhar antes
  da submissão, para não precisar resubmeter por divergência).

## Template a criar na Meta (proposta — mesmo padrão de `chamado_morador_protocolo_v1`/TASK-372)

- **Nome**: `aprovacao_identidade_morador_v1`
- **Categoria**: `UTILITY` — é uma atualização operacional sobre a própria organização (solicitação
  de acesso de um morador pendente de decisão do síndico/admin), não é Authentication (não envolve
  código de verificação) nem Marketing.
- **Idioma**: Português (BR) — `pt_BR`
- **Corpo (Body)**:
  ```
  Olá, {{1}}! Uma nova solicitação de acesso de morador está pendente de aprovação.

  Nome: {{2}}
  Telefone: {{3}}
  Apto/Bloco informado: {{4}}
  Resumo: {{5}}

  Toque em um dos botões abaixo para decidir.
  ```
- **Rodapé (Footer)**: `Easy Maintenance`
- **Botões**: 2 botões de resposta rápida (Quick Reply) — **"Aprovar"** e **"Reprovar"** (não são
  botões de URL; mesma mecânica de resposta rápida que a Meta oferece para HSM Utility).
- **Variáveis** (ordem exata a enviar pelo código, mesma convenção de `chamado_morador_protocolo_v1`):
  - `{{1}}` = nome do síndico/admin destinatário
  - `{{2}}` = nome do morador solicitante
  - `{{3}}` = telefone informado pelo morador
  - `{{4}}` = apto/bloco informado
  - `{{5}}` = resumo da solicitação (texto livre curto)
  - Exemplo para submissão: `{{1}}` = `"João"`, `{{2}}` = `"Maria Souza"`, `{{3}}` = `"(31) 99999-0000"`,
    `{{4}}` = `"Bloco B, apto 304"`, `{{5}}` = `"Primeiro acesso ao assistente"`

**Ponto de atenção para TASK-389/TASK-390 (quem implementa o envio e o webhook)**: botão de resposta
rápida da Meta devolve só o texto do botão ("Aprovar"/"Reprovar"), sem variável própria — ele **não**
carrega o id da `ResidentIdentityPending` sozinho. Como um síndico pode ter mais de uma pendência
simultânea, o webhook do assistente precisa correlacionar a resposta ao pending correto via
`context.id` (id da mensagem original do WhatsApp, que a Graph API devolve na resposta) e não só
pelo texto do botão — mesma necessidade já observada no fan-out de TASK-368/371. Confirmar esse
mapeamento antes de considerar a TASK-392 "pronta para submissão real", mesmo que a submissão em si
ao Meta Business Manager não dependa disso.

## Critérios de Aceite
- [x] Template submetido à Meta — **ação do Douglas**
- [x] Template aprovado pela Meta — **ação do Douglas, confirmado produtivo em 03/11/2026**
- [x] Nome do template e variáveis conferem com o que `ResidentIdentityNotificationService`
      (TASK-389) espera — divergência encontrada e corrigida em 02/11/2026 (o código mandava 4
      parâmetros com `{{1}}`=nome da organização; corrigido pra 5 parâmetros com `{{1}}`=nome do
      aprovador, alinhado com o corpo do template abaixo, ver commit `9235965`)
- [x] Teste real em produção: botão Aprovar/Reprovar chega corretamente ao webhook do assistente — **feito** (confirmado por Douglas em 10/11/2026; webhook entregue na TASK-395). Nota original:
      **continua bloqueado**: o webhook que consome o clique do botão não existe (ver "Gap
      adicional" no Status abaixo). Template aprovado só desbloqueia o envio da mensagem ao
      aprovador; a resposta ainda não tem o que a processe.

## Dependências
Nenhuma técnica — pode começar em paralelo com TASK-387 (quanto antes submeter, melhor, mesmo
raciocínio do TASK-372). Bloqueia o envio real em produção da TASK-389, mas não bloqueia
codificar/testar essa task contra mock.

## Riscos
Prazo de aprovação da Meta é incerto e fora do controle do time — mesmo risco já documentado em
TASK-372/EPIC-023.

## Esforço
Pequeno (esforço de código é zero — é ação de configuração externa do Douglas)

## Status
✅ Done — template `aprovacao_identidade_morador_v1` aprovado e produtivo; `WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED`
ligada em produção e QA com clique real feito (confirmado por Douglas em 10/11/2026).

**Histórico (antes de 10/11/2026):**
🟢 Template submetido, aprovado e produtivo (03/11/2026, confirmado pelo Douglas) — ação externa
dele no Meta Business Manager concluída. Código já estava alinhado com nome/variáveis do template
(ver critério de aceite acima). Flag `notification.whatsapp.resident-identity-pending-enabled`
estava hardcoded `false` no `@Value`, sem property pra configurar por ambiente (gap diferente do
padrão já usado em `resident-ticket-enabled`/TASK-372) — corrigido no mesmo dia: agora é
controlável via env var `WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED` em `application.properties`
(commit `a6b9dc1`, PR #174 mergeada em `staging`). **Falta setar essa env var como `true` no
ambiente de produção** — ação de infra do Douglas, fora do alcance de um agente de código (mesma
natureza da ação no Meta Business Manager).

**Gap que continua aberto, fora do escopo desta task**: o EPIC-040 não tem nenhuma task própria pra
consumir a resposta do botão Aprovar/Reprovar no webhook do assistente (EPIC-031) —
`ResidentIdentityApprovalService.approve()/reject()` já estão prontos pra isso (recebem
`Organization`/id explícito, não dependem de sessão HTTP), mas o handler que lê o clique do botão e
correlaciona com o `pending.id` certo via `context.id` da mensagem original (ver "Ponto de atenção"
abaixo) ainda precisa ser escrito. Agora que o template está aprovado, esse webhook é testável de
verdade — fica como próxima task a abrir.
