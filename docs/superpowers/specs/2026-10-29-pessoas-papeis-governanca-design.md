# Pessoas e Papéis — Registro de Governança do Condomínio

**Data:** 29/10/2026 (fechada em 31/10/2026, decisões 1/3/4/5/6 tomadas direto por Douglas, sem
esperar validação externa do Tiago — ver seção "Perguntas em aberto")
**Status:** Fechada — pronta pra virar EPIC com tasks.

## Motivação

Tiago (sócio que entrou com foco em produto) desenhou no Lovable um protótipo de tela "Pessoas e
Papéis" (`https://screenshot-to-spark-8443.lovable.app/pessoas`) cobrindo síndico, conselho,
moradores, fornecedores e unidades do condomínio. Pedido de Douglas (29/10/2026): analisar o que já
existe no sistema, os impactos de absorver esse desenho, e formas de incluir papéis adicionais —
antes de transformar isso em trabalho de implementação.

Hoje o Easy Maintenance **não tem nenhum registro formal de governança do condomínio**. O que existe
é:

- `User` + `Role` (`org_users/domain/enums/Role.java`): `ADMIN, SYNDIC, TECH, READER` — é o
  **perfil de login no sistema** (quem acessa o app e o que pode clicar). Hoje o controle de acesso
  real é quase todo via assinatura/billing (`FeatureAccessService`, `AccessMode.FULL_ACCESS` vs
  `READ_ONLY`), não por papel — `TECH`/`READER` praticamente não aparecem em lógica de permissão
  diferenciada além do módulo de configurações recém-desenhado (`organization-settings-module`).
- `Supplier` (`supplier/domain/Supplier.java`, EPIC-028): cadastro de fornecedor como empresa,
  compartilhado entre organizações (dedup por documento). O próprio protótipo do Tiago reaproveita
  esse cadastro no combo de "Fornecedor" (ex.: "Fogo Zero Prevenção Ltda").
- `ResidentTicket` (EPIC-027): nome/telefone do morador são **texto livre**, sem vínculo com unidade
  ou cadastro formal de morador.
- **Não existe**: Unidade/apartamento como entidade, Conselho, mandato, remuneração, aprovação de
  orçamento, nem registro formal de Síndico/Zelador/Administradora/Construtora.

## Distinção conceitual central (base de toda a spec)

O protótipo mistura, numa única tela, duas coisas que são **conceitualmente diferentes**:

1. **Perfil de acesso ao sistema** — quem loga no Easy Maintenance e o que pode fazer nele. Já
   existe (`Role` em `User`).
2. **Papel de governança do condomínio** — quem é síndico, quem está no conselho, qual unidade cada
   morador ocupa, quando o mandato vence. **Não existe hoje.** A maioria dessas pessoas (conselheiro
   fiscal, morador, zelador) **nunca loga no sistema** — é dado cadastral/institucional do
   condomínio, não controle de acesso ao app.

Não dá para estender o enum `Role` atual para isso — viraria uma entidade nova, multi-tenant,
independente de login. O nome dessa entidade nesta spec é `CondoPerson` (papel: `CondoRole`, para
não colidir com `org_users.domain.enums.Role`, que continua sendo só o perfil de acesso ao sistema).

**Evolução esperada (não é trabalho desta entrega, mas orienta decisões futuras):** `Role` não fica
obsoleto — continua controlando acesso ao app (login, menus, gates de assinatura). O que deve
acontecer, à medida que features de governança forem construídas (aprovação de orçamento,
notificação por autoridade do condomínio, SLA por responsável), é que **essas features consultem
`CondoPerson`, não `Role`** — hoje um fluxo desse tipo provavelmente checaria `User.role == SYNDIC`,
o que é impreciso (o `ADMIN` que loga pode não ser o síndico de fato, ex. administradora
terceirizada). O aprovador/autoridade correto é quem tem o papel de governança certo em
`CondoPerson` (ex. `approvesBudgets=true`), não quem tem determinado `Role` de sistema. É mais um
motivo para dar peso à pergunta 2 (vínculo `CondoPerson.user_id`) quando essas features chegarem —
sem esse vínculo, não dá pra saber qual `User` logado corresponde a qual `CondoPerson`.

## O que o protótipo mostra (mapeado tela a tela, 29/10/2026)

Tela `/pessoas`, abas **Gestão / Conselho / Moradores / Fornecedores / Unidades**, todas lendo da
mesma listagem, filtrada por papel. Formulário único "Adicionar pessoa" com:

- Documento (CPF/CNPJ), Nome, Tipo (Pessoa física/jurídica), E-mail, Telefone/WhatsApp (com toggle
  de opt-in).
- **Papel** (`CondoRole`): `SINDICO, SUBSINDICO, CONSELHEIRO, MORADOR, FORNECEDOR, ZELADOR,
  ADMINISTRADORA, CONSTRUTORA`.
- **Detalhe** (subtipo, condicional ao papel — confirmado campo a campo no protótipo):

  | Papel                                   | Detalhe no protótipo                                                               |
  |-----------------------------------------|------------------------------------------------------------------------------------|
  | Síndico                                 | Síndico profissional / Síndico morador / Síndico morador remunerado                |
  | Subsíndico                              | (protótipo reaproveita a lista de Morador — parece placeholder, não desenho final) |
  | Conselheiro                             | Conselheiro fiscal / Conselheiro consultivo                                        |
  | Morador                                 | Proprietário / Inquilino                                                           |
  | Fornecedor                              | Prestador recorrente / Prestador avulso — **mais** um segundo combo linkando ao    |
  | cadastro de `Fornecedores` já existente |                                                                                    |
  | Zelador                                 | sem detalhe                                                                        |
  | Administradora                          | sem detalhe                                                                        |
  | Construtora                             | sem detalhe                                                                        |

- **Unidade**: select de apartamento (vazio para papéis sem unidade, ex. Fornecedor/Zelador no
  protótipo, mas o campo aparece disponível mesmo assim).
- **Início/fim de mandato** (datas).
- **Remunerado** (toggle) e **Aprova orçamentos** (toggle).

Aba **Unidades**: grade por andar, cada unidade com número, tipo (apartamento/cobertura), fração
ideal (ex. `0,0625`), status ocupada/vaga, e nome+papel da pessoa vinculada quando houver. Botão
"Gerar unidades" (provável wizard de criação em lote por andar/padrão).

## Escopo proposto (para validação, não implementação)

**Dentro:**
- Entidade `CondoPerson` por organização: documento, tipo PF/PJ, nome, contato, papel, detalhe,
  unidade (opcional), mandato (início/fim, opcional), remunerado, aprova orçamentos (metadado, sem
  enforcement — ver pergunta 4).
- Entidade `Unit` por organização: número, andar, tipo, fração ideal, status (derivado de ter ou não
  pessoa vinculada, não campo próprio).
- Papel `FORNECEDOR` em `CondoPerson` referencia `Supplier` existente por FK (reaproveita cadastro,
  não duplica — ver pergunta 1).
- Tela `/pessoas` no frontend espelhando as abas do protótipo.
- Multi-tenant (`X-Org-Id`), mesmo padrão de permissão do módulo de configurações
  (`ADMIN`/`SYNDIC`, `organization-settings-module-design.md`).

**Fora (nesta entrega, mas desenhado pra encaixar depois):**
- Nenhuma automação consome `CondoPerson` ainda — `ResidentTicket` continua com texto livre (ver
  pergunta 3); "Aprova orçamentos" não bloqueia nada (não existe feature de orçamento no sistema).
- Sem alerta automático de fim de mandato.
- Sem histórico de ocupação de unidade (quem morou antes) — só estado atual.
- Sem geração em lote de unidades ("Gerar unidades" do protótipo) nesta primeira entrega.

## Decisões (fechadas por Douglas, 31/10/2026, sem esperar validação do Tiago)

### 1. Fornecedor-pessoa: reaproveitar `Supplier` ou cadastro independente? — DECIDIDO
**Opção A — Reaproveitar `Supplier`.** `CondoPerson` de papel `FORNECEDOR` só guarda a FK pro
`Supplier` + papel/detalhe/mandato/remunerado; nome/documento/contato vêm do `Supplier`. Evita
duplicar e dessincronizar dois cadastros da mesma empresa — mesmo caminho que o próprio protótipo do
Tiago já sugeria (combo linkando a fornecedores existentes).

### 2. Vínculo entre `CondoPerson` (síndico/conselho) e `User` (login) — DECIDIDO (29/10/2026)
Síndico e subsíndico normalmente SÃO o usuário `ADMIN`/`SYNDIC` que loga no sistema. Hoje essas são
entidades completamente separadas.

**Decisão: opção B — FK opcional `user_id` em `CondoPerson`, desde já.**

Motivo concreto que tirou isso do "talvez depois": o assistente de WhatsApp (EPIC-031) precisa
reconhecer **moradores** como remetentes, não só usuários logados (`AssistantLink` hoje só resolve
`User` — ver discussão de 29/10/2026 sobre "morador falar com o robô sem ter conta no app"). O
modelo fica assim:

- **`CondoPerson` é criado para todo papel de governança**, sempre — é o registro de "quem é essa
  pessoa pro condomínio". Não dá acesso a nada por si só.
- **`User` só é criado quando essa pessoa precisa logar/ver o sistema.** Quando existir, liga via
  `CondoPerson.user_id`.
- Isso **não é "User OU CondoPerson"**, é "`CondoPerson` sempre, `User` adicionalmente quando
  necessário":
  - **Morador**: só `CondoPerson` (papel `MORADOR`), sem `User`. É o caso de uso que motivou abrir
    essa pergunta agora — permite o assistente resolver identidade de morador via `CondoPerson`
    (telefone) em vez de exigir `User`, sem gambiarra de criar usuário fake pra alguém que nunca
    loga (evita poluir contagem de seats de billing — `OrganizationUsageResponse.currentUsers`
    conta `UserOrganization`).
  - **Síndico/Subsíndico/Conselheiro**: tipicamente também precisam acessar o painel → `CondoPerson`
    (papel de governança) **+** `User` (login), linkados por `user_id`.
- Regra de sincronização quando `User` é removido da organização: `user_id` em `CondoPerson` vira
  `NULL` (não deleta/inativa o `CondoPerson` — a pessoa continua tendo o papel de governança mesmo
  sem mais acessar o sistema).
- **Side-note sobre `Role` (`org_users.domain.enums.Role`)**: hoje só tem `ADMIN, SYNDIC, TECH,
  READER`, nenhum encaixa perfeitamente em Conselheiro (pode precisar ver financeiro/aprovar
  orçamento sem administrar a organização). Decisão de qual `Role` usar para o `User` ligado a um
  `CondoPerson` de papel `CONSELHEIRO` (reaproveitar `READER`/`TECH` vs. criar valor novo de `Role`)
  fica **fora desta spec** — é decisão de permissão de app, não de modelo de governança; revisitar
  quando a tela de Pessoas e Papéis entrar em implementação.

### 3. `ResidentTicket` passa a linkar `CondoPerson`/`Unit`? — DECIDIDO
**Opção A — Não muda nesta entrega.** Mantém texto livre; `CondoPerson`/`Unit` nascem como módulo
cadastral independente. Integração fica para uma entrega futura, quando fizer sentido (ex.:
autocompletar pelo CPF no fluxo público, ou a esteira de identidade desenhada em
`2026-10-31-resident-whatsapp-identity-approval-design.md`, que já cria `CondoPerson` a partir do QR
Code sem depender desta integração).

### 4. `Aprova orçamentos` — só metadado ou já prepara enforcement? — DECIDIDO
**Opção A — Só metadado agora.** Campo booleano guardado e exibido, sem nenhuma lógica de
autorização ligada a ele. Quando a feature de orçamento existir, decide-se ali como consumir esse
flag — não há ainda o que aprovar, então desenhar o relacionamento agora seria especulativo.

### 5. Papel `SUBSINDICO`: detalhe próprio — DECIDIDO
Sem detalhe (`role_detail = NULL`), mesmo tratamento de Zelador/Administradora/Construtora. A
reutilização da lista de Morador (Proprietário/Inquilino) no protótipo do Tiago foi tratada como
artefato de protótipo rápido (Lovable), não desenho intencional — decidido direto por Douglas sem
esperar confirmação externa, por ser baixo risco de reverter se o Tiago discordar depois.

### 6. Unidade: fração ideal e geração em lote — DECIDIDO
**Opção A — Cadastra `Unit` sem fração nesta v1.** Número, andar, tipo, status. Fração ideal (sinaliza
futuro rateio/cálculo proporcional) e geração em lote entram quando houver um consumidor real (ex.
rateio de taxa condominial) — sem isso hoje, cadastrar o campo sem uso seria desenho especulativo.

## Modelo de dados proposto

> Migrations novas: a confirmar o número exato no momento da implementação (há outra spec recente —
> `organization-settings-module-design.md` — também reivindicando `V128` em aberto; checar o que já
> foi mergeado).

### `units`
| Campo                     | Tipo                 | Observação                       |
|---------------------------|----------------------|----------------------------------|
| `id`                      | Long                 | PK                               |
| `organization_id`         | BIGINT NOT NULL      | isolamento multi-tenant          |
| `number`                  | VARCHAR(10) NOT NULL | ex. `"801"`                      |
| `floor`                   | INTEGER              |                                  |
| `type`                    | VARCHAR(30)          | `APARTAMENTO`, `COBERTURA`, etc. |
| ~~`ideal_fraction`~~      | —                    | fora da v1 (decisão 6) — não cadastrar coluna agora |
| `created_at`/`updated_at` | TIMESTAMP            | padrão já usado                  |

`UNIQUE (organization_id, number)`.

### `condo_people`
| Campo                     | Tipo                                 | Observação                                                                                                                            |
|---------------------------|--------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `id`                      | Long                                 | PK                                                                                                                                    |
| `organization_id`         | BIGINT NOT NULL                      | isolamento multi-tenant                                                                                                               |
| `document`                | VARCHAR(20) NULL                     | CPF/CNPJ                                                                                                                              |
| `person_type`             | VARCHAR(2)                           | `PF`/`PJ`                                                                                                                             |
| `name`                    | VARCHAR(200) NOT NULL                |                                                                                                                                       |
| `email`                   | VARCHAR(160) NULL                    |                                                                                                                                       |
| `phone`                   | VARCHAR(20) NULL                     |                                                                                                                                       |
| `whatsapp_opt_in`         | BOOLEAN NOT NULL DEFAULT FALSE       | mesmo padrão de opt-in já usado em `User`/`ResidentTicket`                                                                            |
| `role`                    | VARCHAR(20) NOT NULL                 | `CondoRole` — `SINDICO, SUBSINDICO, CONSELHEIRO, MORADOR, FORNECEDOR, ZELADOR, ADMINISTRADORA, CONSTRUTORA`                           |
| `role_detail`             | VARCHAR(40) NULL                     | varia por `role`, validado no backend (não no banco)                                                                                  |
| `unit_id`                 | BIGINT NULL                          | FK `units`                                                                                                                            |
| `supplier_id`             | BIGINT NULL                          | FK `suppliers`, preenchida quando `role=FORNECEDOR` (decisão 1)                                                                      |
| `user_id`                 | BIGINT NULL                          | FK `users`, opcional — preenchido quando a pessoa também tem login (decisão 2)                      |
| `term_start` / `term_end` | DATE NULL                            | mandato                                                                                                                               |
| `paid`                    | BOOLEAN NOT NULL DEFAULT FALSE       | "Remunerado"                                                                                                                          |
| `approves_budgets`        | BOOLEAN NOT NULL DEFAULT FALSE       | "Aprova orçamentos" — metadado, sem enforcement (decisão 4)                                                                           |
| `status`                  | VARCHAR(10) NOT NULL DEFAULT 'ATIVO' | `ATIVO`/`INATIVO` (soft state, não soft delete — mesmo padrão de `Supplier.marketplaceEnabled` como flag de estado, não `deleted_at`) |
| `created_at`/`updated_at` | TIMESTAMP                            | padrão já usado                                                                                                                       |

Validação de `role_detail` por `role` fica no backend (enum Java por papel ou mapa
`role → Set<detail válido>`), nunca em `@Valid`/Bean Validation — mesmo motivo já documentado na
spec de configurações: o `GlobalExceptionHandler` atual devolve 422 pra erro de Bean Validation, e
aqui a intenção é 400 (erro de regra, não de formato de payload).

## API (rascunho)

Módulo novo `condo_people` (`domain`/`application`/`infrastructure`, mesmo padrão de
`resident_tickets`/`settings`):

- `GET /organizations/condo-people?role=` — lista, filtro opcional por papel (cobre as abas
  Gestão/Conselho/Moradores/Fornecedores do protótipo sem endpoint por aba).
- `POST /organizations/condo-people` — cria.
- `PUT /organizations/condo-people/{id}` — atualiza.
- `DELETE /organizations/condo-people/{id}` — soft (muda `status` pra `INATIVO`, não `deleted_at`).
- `GET /organizations/units` — lista (aba Unidades).
- `POST /organizations/units` — cria uma unidade (criação em lote fica fora desta v1, pergunta 6).
- `PUT /organizations/units/{id}` — atualiza.

Tenant scoping: mesmo padrão de `resident_tickets`/`settings`
(`TenantContext.get()` → `organizationRepository.findByCode(...)` → filtra por `Organization.getId()`
Long). Permissão `ADMIN`/`SYNDIC`, mesmo padrão do módulo de configurações.

## Frontend (rascunho)

Rota `/pessoas`, abas Gestão/Conselho/Moradores/Fornecedores/Unidades como no protótipo, mesmo
padrão de aba sem sub-rota já adotado em `/configuracoes` (state local, não `AdminTabs.tsx`/router).
Formulário único "Adicionar pessoa" com campo `Detalhe` condicional ao `Papel` selecionado
(equivalente ao que o protótipo já faz).

## Testes (quando virar tasks)

- Backend: validação de `role_detail` por `role` (rejeita combinação inválida), CRUD de
  `CondoPerson`/`Unit` isolado por organização, FK `supplier_id` só aceita quando `role=FORNECEDOR`
  (se pergunta 1 → A), negação de acesso para `TECH`/`READER`.
- Frontend: `tsc --noEmit`/build limpos; componente condicional de `Detalhe` por `Papel`.

## Próximo passo

Spec fechada — as 6 decisões foram tomadas direto por Douglas em 31/10/2026, sem esperar validação
externa do Tiago (risco aceito: se ele discordar de algo depois, principalmente a decisão 5
— Subsíndico sem detalhe —, é reversível sem redesenho grande). Pronta pra virar EPIC com tasks,
seguindo o mesmo processo das specs anteriores (`organization-settings-module-design.md`,
`resident-tickets-category-protocol-notification-design.md`). Desbloqueia a esteira de aprovação de
identidade via WhatsApp (`2026-10-31-resident-whatsapp-identity-approval-design.md`), que dependia
desta spec existir.
