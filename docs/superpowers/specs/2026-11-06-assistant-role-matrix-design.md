# Assistente WhatsApp — Menus e Funcionalidades por Papel

**Data:** 05/11/2026 (decisões fechadas em 06/11/2026 por Douglas)
**Status:** Fechada (06/11/2026) — todas as perguntas respondidas por Douglas (D1 a D13).
**Revisada em 10/11/2026** com a Parte B do Tiago: D14 a D22 (abrir chamado pela equipe, fornecedor
habitual × responsável, funções novas, ativação de personas sem login). Pronta para virar EPIC com tasks. **Atenção ao custo de WhatsApp** (seção "Custo de mensagens WhatsApp").
**Matriz em imagem (para o time):** [`assets/2026-11-06-assistant-role-matrix.png`](assets/2026-11-06-assistant-role-matrix.png)

## Motivação

O assistente de WhatsApp (EPIC-031) já tem menu e fluxo funcionais, mas foi desenhado antes de o
produto ter papéis de governança. Com o EPIC-039 (Pessoas e Papéis) e o EPIC-040 (aprovação de
identidade do morador), o sistema passou a saber **quem é quem no condomínio** — síndico,
conselheiro, zelador, morador, fornecedor — e o assistente ainda não usa nada disso. Pedido de
Douglas (05/11/2026): definir menus e funcionalidades específicos por papel, em formato de matriz.

## Estado atual (levantado no código em 05/11/2026)

- **Papel de login** (`org_users/domain/enums/Role.java`): `ADMIN, SYNDIC, TECH, READER`. Fica no
  `User` e vale para **todas** as organizações da pessoa — o vínculo usuário↔organização não guarda
  papel.
- **Papel de governança** (`condo_people/domain/enums/CondoRole.java`, EPIC-039): `SINDICO,
  SUBSINDICO, CONSELHEIRO, MORADOR, FORNECEDOR, ZELADOR, ADMINISTRADORA, CONSTRUTORA`. É cadastro
  informativo; o assistente não consome.
- **Quem fala com o bot:** só quem tem `User` + `AssistantLink` ativo + consentimento da versão atual
  + está no piloto (`AssistantIdentityService.resolve`). `AssistantIdentity`, `AssistantConsent` e
  `AssistantConversation` são todos chaveados por `userId`.
- **Menu** (`IntentStep.sendMenu`): igual para todos — Vencimentos da semana, Itens vencidos,
  Registrar manutenção; + "Trocar de condomínio" se tiver mais de 1 organização; + "Nova empresa" só
  para `ADMIN`.
- **Permissão no bot** (`AssistantAccessGuard`): leitura exige ser membro + assinatura em
  `FULL_ACCESS`; escrita barra só `READER`; nova empresa exige `ADMIN`.

### Problemas encontrados

1. **Menu mostra o que o papel não pode fazer.** `READER` vê "Registrar manutenção", toca e só então
   recebe `WRITE_DENIED_READER`.
2. **Bot e web divergem no financeiro.** `checkWrite` deixa `TECH` iniciar um lançamento financeiro;
   quem barra é `FinancialEntryService` (só `ADMIN`/`SYNDIC`), e só na confirmação, depois de todo o
   rascunho. No web a tela de financeiro já esconde do `TECH`. (Some com a remoção do `TECH`, mas o
   padrão — guard genérico + regra real no serviço — continua sendo o problema de fundo.)
3. **Funções sem atalho no menu.** Lançamento financeiro, índice de conformidade e histórico só
   funcionam por texto livre (consome crédito de IA). O atalho numérico `4` leva para "trocar" mesmo
   com uma organização só.
4. **Regra de permissão espalhada:** guard, `if role == ADMIN` no `IntentStep`, checagens nos
   serviços e comparação de string do `localStorage` no web. Não há um lugar único que diga o que
   cada papel pode fazer.
5. **Morador e fornecedor não conversam com o bot.** O telefone do morador aprovado (EPIC-040) só é
   usado no botão Aprovar/Reprovar. Número desconhecido recebe `UNKNOWN_NUMBER` ("ative em Minha
   Conta"), que não faz sentido para quem não tem login.

## Decisões fechadas

| # | Decisão | Quem / quando |
|---|---|---|
| D1 | **`READER` não é conselheiro.** Continua sendo o papel de login somente leitura. | Douglas, 05/11 |
| D2 | **`TECH` sai do sistema.** Não há nenhum usuário com esse papel, então não há conversão de dados a decidir. Mesmo assim entra uma migration defensiva (`UPDATE users SET role='READER' WHERE role='TECH'`) antes de o valor sair do enum, para a API não quebrar ao carregar um usuário com valor desconhecido (`users.role` é `VARCHAR`). | Douglas, 06/11 |
| D3 | **Morador e Fornecedor entram neste ciclo.** | Douglas, 05/11 |
| D4 | **Zelador entra neste ciclo** e executa manutenção (registro enviado para validação do síndico) — ocupa o espaço que o `TECH` deixaria. | Douglas, 06/11 |
| D5 | **Conselheiro entra neste ciclo**, como persona identificada pelo `CondoRole.CONSELHEIRO`. | Douglas, 06/11 |
| D6 | **Papel por organização fica fora deste ciclo.** A regra desejada, quando vier, é validar pelo papel da organização a que a pessoa está se referindo; a chance de alguém ter papéis diferentes em organizações diferentes é baixa. | Douglas, 06/11 |
| D7 | **Aviso do prédio é entidade própria** (não derivado de manutenção — manutenção já tem o caminho dela) e é **só enviado** (proativo), não consultável pelo bot. | Douglas, 06/11 |
| D8 | **Fornecedor responsável fica na manutenção**, não no item: o síndico pode trocar o fornecedor de um item ao longo do tempo. | Douglas, 06/11 |
| D9 | **Execução (📝) não validada fica só como registro**, com status, para rastreamento. Não avança: não conta como manutenção feita, não recalcula vencimento, não entra no índice de conformidade. Sem expiração automática. | Douglas, 06/11 |
| D10 | **Conselheiro vê custo** no histórico (coerente com o acesso ao resumo financeiro). | Douglas, 06/11 |
| D11 | **Limite de IA com duas travas:** (a) quantidade de mensagens que passam pela IA por persona por dia (ex.: morador 10/dia); (b) teto mensal em créditos para todas as personas sem login somadas (ex.: 30% do crédito do plano). Números como configuração, calibrados no piloto. | Douglas, 06/11 |
| D12 | **Pessoa com login e papel de governança: soma as capacidades.** Ex.: zelador no cadastro com login `READER` tem tudo do READER + tudo do Zelador (incluindo o 📝). O vínculo é `CondoPerson.user_id`. | Douglas, 06/11 |
| D13 | **Destinatários do aviso: o síndico escolhe** a cada envio (ex.: todos, por bloco, por unidade, por papel). O custo estimado aparece **antes** de confirmar o envio (ver seção de custo). | Douglas, 06/11 |
| D14 | **A equipe também abre chamado** pelo WhatsApp: ADMIN, SYNDIC e Zelador, além do Morador (o "vi um problema na ronda"). O chamado sai com origem "equipe". Conflito C1 da Parte B. | Douglas, 10/11 |
| D15 | **Fornecedor em dois papéis:** o *habitual* fica no item, como sugestão (é ele que o "Acionar fornecedor" usa), e o *responsável* fica na manutenção, como registro de quem fez (D8 mantida). Trocar o habitual não reescreve o histórico. Conflito C2. | Douglas, 10/11 |
| D16 | **Funções novas no bot** (alterar vencimento, cadastrar fornecedor, item e local) ficam com **ADMIN e SYNDIC**. O Zelador pode **sugerir** item ou local pelo fluxo 📝. Conflito C3. | Douglas, 10/11 |
| D17 | **"Nova empresa"** sai do menu principal e vai para dentro de "Trocar condomínio". Continua só para ADMIN. Conflito C4. | Douglas, 10/11 |
| D18 | **Texto livre em primeiro lugar** para todos os papéis de login. As personas por telefone seguem o limite da D11 e a última linha da matriz. O painel de entrada ("N vencidos · N chamados · fora do SLA") é gerado pela mesma política: cada papel só vê os números que pode ver. O contexto curto (30 min) vem **depois** da identidade por persona. Conflitos C5, C6 e C7. | Douglas, 10/11 |
| D19 | **Zelador, Conselheiro e contato de Fornecedor são ativados por código de convite.** O síndico gera, em `/pessoas` ou no vínculo do fornecedor, um link `wa.me` com um código de uso único válido por 7 dias e repassa à pessoa. Ela manda a mensagem, o bot confere **código + telefone cadastrado** e pede o aceite do termo (LGPD, versão registrada). Só então a persona fica ativa. Um número digitado errado não ativa ninguém, e não há custo de template porque a conversa parte da pessoa. | Douglas, 10/11 |
| D20 | **O fornecedor é identificado pelo contato do vínculo condomínio × fornecedor** (1 ou mais técnicos por condomínio, cada um ativado pela D19), **não** pelo `Supplier.phone` global. O global (definido no primeiro cadastro, muitas vezes vindo do Google Places) fica só como contato comercial. O contato só acessa os dados do condomínio que o convidou. | Douglas, 10/11 |
| D20b | **Revisão da D20 (10/11): o fornecedor é uma conta global por CNPJ** que presta serviço para N condomínios. Ele vê, agrupado por condomínio, as manutenções em que é o responsável (D8), os serviços que vencem nos itens em que é o habitual (D15), os pedidos de orçamento e as cobranças, e nada além disso. Os **contatos** (técnicos) são cadastrados pelo próprio fornecedor no portal, cada um ativado por código de convite, e o alcance padrão é todos os condomínios vinculados. A conta é reivindicada pelo e-mail cadastrado ou pelo convite de um condomínio. Desligado de um condomínio, ele continua vendo só as execuções que ele mesmo registrou (data e serviço). O portal de serviços é **grátis**; o marketplace pago continua sendo a vitrine. Substitui a D20 onde ela diz "contato por condomínio". | Douglas, 10/11 |
| D21 | **O morador é ativado pela aprovação do EPIC-040** (QR Code → pendência → síndico aprova), sem código. Na primeira conversa com o bot, aceita o termo (LGPD). | Douglas, 10/11 |
| D22 | **Um número desconhecido** recebe uma mensagem neutra, sem IA, no máximo 1 por dia por número: "Este número não está cadastrado. Morador: abra seu chamado pelo QR Code do prédio. Equipe ou fornecedor: peça o convite ao síndico. Síndico: ative em Minha Conta." | Douglas, 10/11 |

## Modelo: dois tipos de identidade no bot

- **Papel de login** — `ADMIN`, `SYNDIC`, `READER`. Quem administra e acessa o sistema. Identificado
  pelo `AssistantLink` (ativação em Minha Conta), como hoje.
- **Persona pelo telefone** — `CONSELHEIRO`, `ZELADOR`, `MORADOR` (de `CondoPerson`) e `FORNECEDOR`
  (de `Supplier`). Quem não loga no sistema. Identificado pelo telefone cadastrado.
  - Morador: só depois de aprovado na esteira do EPIC-040.
  - Fornecedor: telefone do `Supplier` vinculado à organização.

**Regra de identidade:** a mesma pessoa nunca tem duas identidades no bot. Telefone sem login →
vale a persona do cadastro. Telefone com login **e** papel de governança (`CondoPerson.user_id`
preenchido) → **soma as capacidades** dos dois (D12).

## Ativação e revogação das personas sem login (D19 a D22, 10/11/2026)

| Persona | Como entra | Prova de que é a pessoa certa |
|---|---|---|
| Papel de login (ADMIN/SYNDIC/READER) | Minha Conta → `AssistantLink` (como hoje) | login + número |
| Morador | QR Code → pendência → síndico aprova (EPIC-040) | o síndico confirma nome e unidade; a mensagem prova o número |
| Zelador / Conselheiro | código de convite gerado em `/pessoas` | código (repassado pelo síndico) + telefone do cadastro |
| Fornecedor (contato) | código de convite gerado no portal do fornecedor (ou no convite do condomínio que reivindica a conta) | código + telefone do contato |

Todas as personas aceitam o termo na própria conversa (versão registrada) antes da primeira ação.

**Revogação automática** (regra derivada, sem decisão nova): a persona deixa de valer quando:
- o telefone do cadastro muda (é preciso refazer o convite);
- a pessoa sai do cadastro ou o vínculo com o fornecedor acaba;
- o mandato do conselheiro termina (EPIC-036, TASK-356);
- a pessoa responde "SAIR".

Código de convite: uso único, validade de 7 dias e um código ativo por pessoa (gerar outro invalida o anterior). As
tentativas erradas têm limite por número (anti força bruta). Ativação e revogação ficam registradas na auditoria.

## Matriz

Legenda: ✅ pode e aparece no menu · 👁 só leitura · 📝 envia, o síndico valida · — não vê

| Funcionalidade | ADMIN | SYNDIC | READER | Conselheiro | Zelador | Morador | Fornecedor |
|---|---|---|---|---|---|---|---|
| **Como é identificado** | login | login | login | convite + telefone (D19) | convite + telefone (D19) | telefone aprovado (EPIC-040, D21) | contato da conta do fornecedor + convite (D20b) |
| Vencimentos e itens vencidos | ✅ | ✅ | 👁 | 👁 | 👁 | — | — |
| Histórico de um item | ✅ | ✅ | 👁 | 👁 | 👁 | — | 👁 só itens dele ¹ |
| Registrar manutenção | ✅ | ✅ | — | — | 📝 com foto | — | 📝 foto, laudo, ART ¹ |
| Validar execução enviada (zelador/fornecedor) | ✅ | ✅ | — | — | — | — | — |
| Lançamento financeiro | ✅ | ✅ | — | — | — | — | — |
| Resumo financeiro | ✅ | ✅ | 👁 | 👁 | — | — | — |
| Índice de conformidade e relatório | ✅ | ✅ | 👁 | 👁 | — | — | — |
| Chamados de moradores | ✅ atende | ✅ atende | 👁 | 👁 | ✅ atende ² | — | — |
| Aprovar morador pendente | ✅ | ✅ | — | — | — | — | — |
| Avisos do prédio ³ | publica | publica | recebe | recebe | recebe | recebe | — |
| Áreas comuns: regras e horários (EPIC-038) | ✅ | ✅ | 👁 | 👁 | 👁 | 👁 | — |
| Abrir chamado (texto, foto ou áudio) | ✅ (D14) | ✅ (D14) | — | — | ✅ (D14) | ✅ | — |
| Status dos meus chamados | — | — | — | — | — | 👁 | — |
| Serviços que vencem para mim | — | — | — | — | — | — | 👁 ¹ |
| Minhas cobranças e pagamentos (EPIC-028) | — | — | — | — | — | — | 👁 |
| Trocar de organização | se tiver mais de 1 organização (qualquer papel) | | | | | | |
| Nova empresa (dentro de "Trocar condomínio", D17) | ✅ | — | — | — | — | — | — |
| Alterar vencimento (D16) | ✅ | ✅ | — | — | — | — | — |
| Cadastrar fornecedor, item ou local (D16) | ✅ | ✅ | — | — | 📝 sugere item/local | — | — |
| Usa IA (texto livre e áudio) | ✅ | ✅ | ✅ | ✅ | ✅ | só abrir chamado ⁴ | só registrar execução ⁴ |

**Nunca aparece:** custos e financeiro para zelador, morador e fornecedor; dados de outros moradores e
de outros fornecedores para morador e fornecedor.

1. Não existe hoje vínculo entre manutenção e fornecedor responsável (`assets` não referencia
   `supplier`). Precisa ser criado **na manutenção** (D8). "Itens dele" = itens com manutenção
   atribuída a ele; "serviços que vencem para mim" = próximas manutenções atribuídas a ele.
2. Zelador "atende" = muda o status do chamado (em andamento / resolvido) e manda foto. Não reprova
   nem apaga.
3. "Aviso" não existe hoje. Entidade própria, publicada pelo síndico/admin e **só enviada**
   (proativa) aos destinatários; não há consulta pelo bot (D7). Envio proativo exige template HSM
   aprovado pela Meta e tem custo por mensagem.
4. Crédito de IA é debitado do plano do condomínio (pagador). Limite por persona e menu sem IA fora
   dessas ações.

O 📝 (execução registrada por zelador/fornecedor e validada pelo síndico) é o ponto de produto mais
forte da matriz: alinha com a tese de "prova de manutenção" (EPIC-033) — quem executou registra a
evidência na hora; o síndico só confirma.

## Proposta técnica (direção, a detalhar nas tasks)

1. **Política única de permissões.** Enum `AssistantCapability` (uma capacidade por linha da matriz)
   + `AssistantRolePolicy` (papel/persona → `Set<AssistantCapability>`). Menu e guard leem da mesma
   tabela: o que aparece no menu é exatamente o que é permitido. Os serviços de domínio continuam
   com sua checagem própria (defesa em profundidade), mas o bot passa a barrar **antes** de abrir
   rascunho. Futuro: expor a mesma política em `GET /me/capabilities` para o web parar de comparar
   string do `localStorage`.
2. **Identidade por persona.** Generalizar `AssistantIdentity` de "um `User`" para uma persona
   (`User` | `CondoPerson` | `Supplier`), com organização(ões) e papel resolvidos. Consentimento e
   conversa deixam de ser chaveados só por `userId`. **É a maior mudança técnica do ciclo.**
3. **Menu por papel** como mensagem de lista do WhatsApp (até 10 linhas, em seções), gerado a partir
   da política. Atalhos numéricos derivados do menu exibido (resolve o "4" fixo).
4. **Número desconhecido** deixa de responder "ative em Minha Conta" para quem não tem login: cai na
   esteira do EPIC-040 (morador) ou recebe mensagem neutra.
5. **Execução enviada (📝)** gera registro com status próprio (ex.: `PENDENTE_VALIDACAO`,
   `VALIDADA`, `RECUSADA`), separado da manutenção. Só `VALIDADA` vira manutenção registrada de fato
   (com recálculo de vencimento e efeito no índice); os demais ficam como rastro, sem expirar (D9).
   Síndico valida pelo bot ou pelo web. Reaproveitar o padrão de pendência/idempotência do EPIC-040.
6. **Aviso do prédio** (D7): entidade nova por organização (título, texto, período, destinatários),
   envio em fan-out por template HSM, com registro de entrega. Não tem intenção de consulta no bot.
7. **Remoção do `TECH`:** migration defensiva → enum `Role` → 4 telas do web (`users/new`,
   `users/[id]/edit`, `private/users/new`, badge em `users/page.tsx`) e label em `lib/enums/labels.ts`.

## ⚠️ Custo de mensagens WhatsApp (ler antes de implementar)

**Todo aviso do prédio é pago por destinatário.** Aviso é mensagem iniciada pela empresa, então só
pode sair por template aprovado pela Meta, e a Meta cobra **por mensagem entregue**.

Tabela da Meta para números do Brasil (+55), em vigor desde 01/10/2026 (fontes abaixo — **conferir
no rate card oficial da Meta antes de fechar o preço do produto**):

| Categoria do template | Preço por mensagem entregue |
|---|---|
| Utilidade (aviso operacional) | **R$ 0,0350** |
| Marketing | **R$ 0,3217** (cerca de 9× mais caro) |

**Exemplo — prédio com 80 moradores:**

| Cenário | Utilidade | Se a Meta classificar como marketing |
|---|---|---|
| 1 aviso para todos | R$ 2,80 | R$ 25,74 |
| 4 avisos por mês para todos | R$ 11,20/mês | R$ 102,94/mês |
| 4 avisos/mês × 10 condomínios iguais | R$ 112,00/mês | R$ 1.029,36/mês |

**Pontos de atenção:**

- **Classificação é da Meta, não nossa.** Template de aviso com texto genérico ("comunicado",
  "novidade") corre risco de ser classificado como marketing. O template precisa ser estritamente
  operacional (manutenção, interdição, horário) para ficar em utilidade.
- **Quem paga** é a conta do Easy Maintenance na Meta, não o condomínio. Sem repasse ou limite, o
  custo cresce com o número de moradores e não com o plano. Decidir na precificação se aviso entra
  como cota do plano, pacote extra ou repasse.
- **Respostas do bot também podem passar a custar.** Algumas fontes indicam que, desde 01/10/2026,
  a Meta cobra também as respostas dentro da janela de atendimento (cerca de R$ 0,035 cada, com
  1.000 gratuitas por mês por número); outras ainda dizem que são gratuitas. Com morador e fornecedor
  conversando com o bot, o volume sobe — **confirmar no rate card oficial**.
- **Isso é além do custo de IA** (D11): uma mensagem de morador pode custar IA (créditos) **e**
  WhatsApp (Meta).

**Regras de produto derivadas:**

1. A tela de envio do aviso mostra **"Este aviso vai para N pessoas · custo estimado R$ X"** antes do
   botão de confirmar (D13).
2. Envio registra quantidade de destinatários, categoria do template e custo estimado, para
   relatório e cobrança.
3. Teto configurável de avisos (ou de mensagens) por organização por mês.

Fontes: [Vectalk — preços WhatsApp API Brasil 2026](https://vectalk.com.br/blog/en/whatsapp-api-pricing-brazil/) ·
[Zynfo — WhatsApp pricing Brazil](https://zynfo.ai/whatsapp-pricing/brazil) ·
[Aissist — WhatsApp API pricing 2026](https://aissist.io/insights/whatsapp-business-api-pricing) ·
[Zernio — WhatsApp API pricing](https://zernio.com/blog/whatsapp-business-api-pricing)

## Riscos

- **Custo de WhatsApp** dos avisos e do aumento de conversas — ver seção acima. Sem teto e sem
  estimativa visível, é custo que cresce com o número de moradores, não com a receita.

- **Identidade/persona:** mexe no ponto de entrada de todo turno do bot (`IdentityStep`). Regressão
  aqui derruba o assistente inteiro — precisa de teste de regressão do fluxo atual de usuário com
  login antes de qualquer persona nova.
- **Custo de IA:** morador é o público mais numeroso e o crédito sai do plano do condomínio. Sem
  limite por persona, um morador pode esgotar o crédito do mês.
- **Consentimento (LGPD):** morador, fornecedor, zelador e conselheiro não têm Minha Conta; o aceite
  do termo precisa acontecer na própria conversa, com versão registrada.
- **Vazamento entre personas:** morador/fornecedor não podem ver custo nem dado de terceiros. Cada
  consulta nova precisa de teste negativo por persona.
- **Multi-tenant:** fornecedor pode atender várias organizações (`Supplier` é compartilhado); toda
  consulta precisa estar restrita à organização da conversa (`TenantContext`), como hoje.
- **Assinatura:** o gate de `FULL_ACCESS` do EPIC-041 continua valendo para todas as personas — o
  check é por organização, então cobre persona sem billing próprio.

## Fora de escopo deste ciclo

- Papel por organização (D6).
- Reserva de área comum (não existe ainda; EPIC-038 deixou para depois).
- `SUBSINDICO`, `ADMINISTRADORA`, `CONSTRUTORA` como personas no bot.
- `GET /me/capabilities` consumido pelo web (fica como evolução da política única).

## Perguntas em aberto (fechar antes de quebrar em tasks)

Nenhuma — todas fechadas em 06/11 (D7 a D13). Pendente só a conferência dos preços da Meta no rate
card oficial antes de definir como o custo do aviso entra na precificação.

## Quebra proposta

**Virou o [EPIC-042](../../../roadmap/epics/EPIC-042.md) (TASK-414 a 430) em 10/11/2026.** A Parte B virou o
[EPIC-043](../../../roadmap/epics/EPIC-043.md). Lista original:

1. Política única de permissões + menu por papel (papéis de login atuais) — baixo risco, entrega valor sozinha.
2. Remoção do `TECH` (migration defensiva + enum + web).
3. Identidade por persona + consentimento na conversa + tratamento de número desconhecido.
4. Persona Morador (abrir chamado, status, avisos, áreas comuns).
5. Persona Conselheiro (leituras + resumo financeiro + índice).
6. Vínculo manutenção ↔ fornecedor.
7. Personas Zelador e Fornecedor + fluxo 📝 com validação do síndico.
8. Avisos do prédio (entidade, escolha de destinatários, estimativa de custo antes do envio, teto mensal, template HSM de utilidade).
9. Limite de IA por persona.
