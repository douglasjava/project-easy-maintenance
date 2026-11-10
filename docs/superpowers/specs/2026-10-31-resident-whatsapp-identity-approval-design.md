# Esteira de Aprovação de Identidade do Morador (QR Code → WhatsApp)

**Data:** 31/10/2026
**Status:** Rascunho — depende da spec `2026-10-29-pessoas-papeis-governanca-design.md` (ainda
"Rascunho — aguardando validação externa com Tiago"). **Não implementar nenhuma das duas sem essa
validação ter acontecido primeiro** — esta spec assume `CondoPerson`/`CondoRole`/`Unit` como já
decididos lá.

## Motivação

Hoje (EPIC-027) o chamado de morador via QR Code é 100% anônimo: nome/telefone/CPF em texto livre,
sem criar nenhum registro formal e sem vínculo com papel de governança. A spec de Pessoas e Papéis
(29/10/2026) decidiu que o assistente de WhatsApp (EPIC-031) precisa reconhecer **moradores** como
remetentes — não só `User` logado — via uma nova entidade `CondoPerson` (papel `MORADOR`).

Isso cria um risco novo: se o papel `MORADOR` (e o acesso ao chat do assistente que vem com ele)
fosse concedido automaticamente a qualquer número que abre uma solicitação via QR Code, qualquer
pessoa que escaneou o código — visitante, entregador, vizinho de outro prédio — ganharia acesso ao
bot como se fosse moradora de fato. Esta spec desenha a esteira de verificação que resolve isso: a
primeira solicitação de um número novo não é processada até o síndico confirmar que quem pediu é
morador/locatário de verdade.

## Decisões (confirmadas por Douglas, 31/10/2026)

- **Gate é por pessoa, não por solicitação.** Só a primeira solicitação de um número novo passa pela
  esteira de aprovação de identidade. Depois que o número é aprovado e o `CondoPerson` (papel
  `MORADOR`) existe, as solicitações seguintes vão direto pro fluxo operacional normal (ex. kanban de
  chamados, já existente).
- **Nada é processado antes da aprovação.** O chamado (ou, no futuro, a reserva de área comum) não é
  criado de verdade enquanto a identidade está pendente — fica retido. O morador só recebe a
  confirmação do que pediu **depois** da aprovação, nunca antes.
- **Dois canais de aprovação, ambos desenhados desde já** (reaproveitando a tela `/pessoas` da spec
  de Pessoas e Papéis, aba nova "Pendentes"):
  - **WhatsApp (canal principal)**: mensagem ao síndico com botões de resposta rápida
    **Aprovar**/**Reprovar** — só funciona para síndicos já linkados ao assistente (`AssistantLink`).
    Hoje isso é só o piloto do Douglas (EPIC-031 Onda 1); outros síndicos são liberados manualmente
    por ID na mesma regra de pilotagem, antes da Onda 2 valer para todos (TASK-305/306). **O desenho
    cobre as duas pontas desde já** — não espera a Onda 2.
  - **Tela `/pessoas` → aba "Pendentes"**: sempre disponível, independente de WhatsApp — mesmos
    dados, aprovar/rejeitar manual. É o caminho único para síndicos ainda não linkados ao
    assistente.
- **Apto/bloco entra como campo novo na intake do QR Code.** Na aprovação, o síndico pode **vincular
  a uma `Unit` já cadastrada OU criar a `Unit` na hora** — não exige que o condomínio já tenha
  cadastrado todas as unidades antes.
- **Reprovação é silenciosa para o morador** — nenhum aviso é enviado a ele (ele ainda não é
  `CondoPerson`, não tem opt-in de notificação confirmado, não há canal confiável pra isso sem abrir
  outro vetor de spam). Fica registrado em métricas/logs para o time acompanhar volume de
  reprovações, mas não gera notificação de volta.
- **E-mail de fallback na criação da pendência** (confirmado por Douglas, 31/10/2026): toda
  organização recebe e-mail aos ADMINs quando uma pendência de identidade é criada, mesmo canal já
  usado hoje na criação de chamado (EPIC-027). Garante visibilidade mesmo quando o síndico ainda não
  está linkado ao assistente (toda organização fora do piloto, até a Onda 2) — sem isso, a única
  forma de notar a pendência seria abrir a aba "Pendentes" por conta própria, e a pendência não
  expira (ver "Fora de escopo").
- **Lock/idempotência entre os dois canais de aprovação** (minha decisão, builder check 31/10/2026):
  a pendência tem um status (`PENDENTE`/`PROCESSADO`). A primeira ação — aprovar ou reprovar, por
  WhatsApp ou pela tela — trava o item (`PROCESSADO`); qualquer ação seguinte no mesmo item é no-op.
  Evita duplo-processamento (dois `CondoPerson` criados, ou a solicitação retida processada duas
  vezes) quando mais de um síndico está linkado ou quando o mesmo síndico age pelos dois canais.
- **Fan-out de WhatsApp quando houver mais de um síndico linkado** (minha decisão, builder check
  31/10/2026): a notificação de aprovação vai para todos os síndicos linkados ao assistente daquela
  organização, mesmo padrão já usado no e-mail de ADMINs do chamado normal. O lock acima garante que
  só a primeira resposta conta.
- **Reenvio enquanto a pendência ainda está aberta** (minha decisão, builder check 31/10/2026): se o
  mesmo telefone enviar uma nova solicitação antes do síndico responder à primeira, atualiza a
  pendência existente (mesmo registro, conteúdo da solicitação substituído pelo mais recente) em vez
  de criar uma segunda entrada na aba "Pendentes". Chave de unicidade: telefone + organização +
  status `PENDENTE`.

## Fluxo completo

1. Morador escaneia o QR Code → preenche nome, telefone, CPF (como já existe hoje em EPIC-027) +
   **apto/bloco** (novo campo, texto livre na intake — a resolução pra `Unit` existente ou nova
   acontece só na aprovação, não na intake).
2. Morador envia a solicitação (chamado, descrição livre, como hoje).
3. Backend verifica: esse telefone já tem `CondoPerson` (papel `MORADOR`, ativo) na organização?
   - **Sim** → segue o fluxo operacional normal direto (cria o chamado, cai no kanban, notifica
     ADMINs por e-mail como já acontece hoje). Fim do fluxo desta spec.
   - **Não** → a solicitação é retida (não cria o chamado ainda) e entra na esteira de aprovação de
     identidade.
4. Síndico é notificado:
   - Se um ou mais síndicos estão linkados ao assistente: mensagem WhatsApp para **todos** eles
     (fan-out), com nome, telefone, apto/bloco informado, resumo da solicitação, e botões
     **Aprovar**/**Reprovar**.
   - Em paralelo, sempre: item novo na aba "Pendentes" de `/pessoas`, mesmos dados, com os mesmos
     dois botões; e e-mail aos ADMINs da organização (mesmo canal já usado na criação de chamado).
   - Qualquer ação (aprovar/reprovar) em qualquer canal trava o item — demais tentativas são no-op
     (ver "Decisões").
4.1. Se o mesmo telefone enviar uma nova solicitação enquanto esta ainda está pendente (nenhum
   síndico respondeu ainda), a pendência existente é atualizada com o conteúdo mais recente — não
   cria uma segunda entrada.
5. **Síndico aprova**: escolhe vincular a uma `Unit` existente ou cria uma nova com os dados de
   apto/bloco informados. Sistema cria o `CondoPerson` (papel `MORADOR`, telefone, `unit_id`), depois
   processa a solicitação retida como se fosse nova agora (cria o chamado de verdade, cai no kanban,
   notifica ADMINs). Morador recebe a confirmação do que pediu (ex. protocolo) só neste momento.
6. **Síndico reprova**: a solicitação retida é descartada. Nenhum `CondoPerson` é criado. Nenhum
   aviso é enviado ao morador. Evento registrado em log/métrica (contagem de reprovações por
   organização, pelo menos).
7. Se o mesmo número enviar uma nova solicitação depois de reprovado (sem `CondoPerson` ainda), volta
   pro passo 3 como se fosse a primeira vez — cria uma nova pendência, cai na esteira de novo. Não há
   bloqueio permanente desenhado nesta spec (ver "Fora de escopo").

## Fora de escopo (nesta entrega)

- Reserva de área comum em si — a feature não existe ainda (`organization-settings-module-design.md`
  deixa isso explicitamente para depois). Esta spec só garante que, quando ela existir, vai se
  encaixar no mesmo gate de identidade sem redesenho.
- Limite de tentativas após reprovação (anti-abuso de reenvio repetido pelo mesmo número) — fica para
  quando houver sinal real de abuso; hoje o rate limit já existente nos endpoints públicos do
  EPIC-027 é a única defesa.
- Expiração/timeout de pendência (ex. auto-reprovar depois de X dias sem resposta do síndico) — não
  desenhado; pendência fica aberta indefinidamente até ação manual.
- Qualquer mudança no `Role` (perfil de login) — este fluxo só cria/atualiza `CondoPerson`, nunca
  `User`.

## O que fica pro builder decidir

- Nome exato do novo template HSM de aprovação (padrão dos existentes, ex.
  `aprovacao_identidade_morador_v1`) e submissão à Meta — mesma dependência externa já documentada em
  TASK-372/368, sem prazo garantido.
- Onde/como a solicitação retida fica guardada enquanto pendente (tabela própria vs. estado
  temporário dentro de `condo_people`) — decisão de implementação, sem impacto de produto.
- Formato exato do botão de resposta rápida (WhatsApp interactive message) e tratamento de resposta
  inesperada (síndico responde texto livre em vez de clicar no botão).
- Métrica/log exato de reprovação (nome do evento, campos) — só precisa existir, formato é decisão
  técnica.

## Dependência explícita

Esta spec só pode virar tasks depois de:
1. `2026-10-29-pessoas-papeis-governanca-design.md` ser validada com o Tiago e virar EPIC (precisa de
   `CondoPerson`/`CondoRole`/`Unit` existirem).
2. Decisão de qual `Role` de sistema cobre `CONSELHEIRO` (pergunta 5 daquela spec) não bloqueia esta
   — não é usada aqui.
