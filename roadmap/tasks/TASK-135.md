# TASK-135 — Backend: Template WhatsApp v2 com botão de URL dinâmica

## Tipo
BACKEND

## Categoria
Notificações / Integração Externa (WhatsApp Cloud API)

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## QA obrigatório
Sim — muda o contrato do template aprovado na Meta; erro na ordem/quantidade de parâmetros faz a
Graph API rejeitar o envio inteiro.

---

## Contexto

O template `vencimento_manutencao` (3 variáveis: nome do destinatário, nome do item, data de
vencimento) foi substituído por um novo template aprovado na Meta, `vencimento_manutencao_v2`, que
exige 5 variáveis de corpo (adicionou nome da empresa/tenant e telefone de suporte) mais 1 variável
de botão de URL dinâmica separada — necessário porque usuários podem gerenciar múltiplas empresas, e
o botão leva direto pro item que está vencendo.

Card trazido diretamente por Douglas com a especificação técnica já pronta (nome do template,
variáveis exatas e estrutura do botão).

---

## Objetivo

Atualizar o fluxo de envio de WhatsApp para o template v2, sem quebrar o fallback pra e-mail nem a
idempotência já existentes (TASK-130).

---

## Escopo

### 1. Payload de 5 variáveis de corpo + 1 de botão

- `WhatsAppTemplateMessageRequest.Component` ganhou `subType`/`index`, pra suportar
  `components: [{type: "body", parameters: [...]}, {type: "button", sub_type: "url", index: "0",
  parameters: [{type: "text", text: itemId}]}]` — estrutura exigida pela Graph API pra botão de URL
  dinâmica (`https://www.easymaintenance.com.br/itens/{{1}}`).
- `WhatsAppClient.sendTemplateMessage(...)` ganhou um 4º parâmetro (`buttonUrlParam`), separado da
  lista de parâmetros do corpo — a Graph API trata `components[].type=button` como componente
  independente do `body`.
- `WhatsAppNotificationProvider` dividiu a extração em `extractBodyParams` (5 itens: nome, item,
  empresa, data, telefone de suporte) e `extractButtonParam` (id do item).

### 2. Novo dado: nome da empresa/tenant, sem round-trip extra

- `NotificationEvent`/`BusinessWhatsAppDispatch` só carregavam `organizationCode` (slug), não
  `Organization.name`. Em vez de uma query nova, estendeu-se a query já existente de resolução de
  destinatário (`UserOrganizationRepository.findAllByOrganizationCodeWithUser`) com um `JOIN
  Organization o ON o.code = uo.organizationCode` (mesmo padrão já usado em
  `OrganizationRepository.findAllByUserId`) — nova projeção `UserOrganizationRecipient(User user,
  String organizationName)` e novo método `findRecipientsWithOrganizationName`.

### 3. Telefone de suporte estático via configuração

- Novo `notification.whatsapp.support-phone` (default `(31) 99982-6634`, override via
  `WHATSAPP_SUPPORT_PHONE`) — nunca lido do banco, propositalmente, pra poder mudar sem deploy.

### 4. Data formatada no corpo da mensagem

- `dueDate` no `templateData` passou a ser reformatado de ISO (`2026-07-20`, formato real que
  `dispatch.getDueDate().toString()` produz) para `dd/MM/yyyy` antes de entrar no corpo da mensagem
  — mais legível pro destinatário final.

### 5. Testes

- TDD em cada mudança de assinatura (RED confirmado por falha de compilação antes do GREEN).
- `WhatsAppClientTest`: novo teste captura o body HTTP real e valida os 2 components (5 parâmetros
  no body, `sub_type=url`/`index=0`/parâmetro=id do item no button).
- `WhatsAppNotificationProviderTest`: ordem dos 5 parâmetros + telefone de suporte vindo da config,
  não do `templateData`.
- `BusinessWhatsAppNotificationServiceTest`: novo teste valida `companyName`/`itemId` no payload.

---

## Arquivos impactados

### Backend
- `infrastructure/notification/dto/WhatsAppTemplateMessageRequest.java` — `Component` ganha
  `subType`/`index`
- `infrastructure/notification/client/WhatsAppClient.java` — `buildRequest` monta 2 components
- `infrastructure/notification/provider/WhatsAppNotificationProvider.java` — split body/button,
  `supportPhone` via `@Value`
- `infrastructure/notification/service/BusinessWhatsAppNotificationService.java` — `buildPayload`
  ganha `companyName`/`itemId`; `resolveRecipient` usa a nova projeção
- `org_users/infrastructure/persistence/UserOrganizationRepository.java` — novo método
  `findRecipientsWithOrganizationName`
- `org_users/infrastructure/persistence/UserOrganizationRecipient.java` — **novo** (projeção)
- `application.properties` — `whatsapp.default-template-name` → `vencimento_manutencao_v2`,
  novo `notification.whatsapp.support-phone`

---

## Critérios de Aceite

- [x] Template `vencimento_manutencao_v2` enviado com 5 parâmetros de corpo na ordem correta
- [x] Botão de URL dinâmica enviado como component separado, com o id do item
- [x] Nome da empresa resolvido sem round-trip extra de banco (mesma query de resolução de
      destinatário, estendida)
- [x] Telefone de suporte vem de configuração, nunca do banco
- [x] Data formatada em `dd/MM/yyyy` no corpo da mensagem
- [x] Testes cobrindo a nova estrutura de payload (corpo + botão)

## Dependências
- TASK-130 (orquestração/fallback) e TASK-129 (`WhatsAppClient`) já implementadas.

## Riscos
- Nenhuma query JPQL nova (a de `findRecipientsWithOrganizationName`) foi validada contra banco real
  em teste automatizado — este repositório não tem `@DataJpaTest` — recomendado validar
  manualmente em staging antes de confiar 100%.

## Esforço
Médio (mudança de contrato bem especificada, mas toca 5 arquivos + a resolução de destinatário)

## Status
Concluído — implementado e testado (684/684 testes backend green). Commit direto em `staging`
(`aa2d667`, sem branch de feature dedicada), incluído no PR
[easy-maintenance-api#25](https://github.com/douglasjava/easy-maintenance-api/pull/25)
(`staging` → `main`).

## Implementação

- Sem branch de feature — commitado direto em `staging` (fora do padrão usual do projeto de
  `feature/TASK-XXX-...` + PR, registrado aqui só pra manter o histórico honesto).
- Query JPQL nova de resolução de destinatário+nome da organização segue o mesmo padrão de `JOIN ...
  ON` já usado em `OrganizationRepository.findAllByUserId`, por não haver `@ManyToOne` entre
  `UserOrganization` e `Organization`.
