# TASK-122 — Full-Stack: Dado do usuário — telefone e opt-in para notificações WhatsApp

## Tipo
FULL_STACK

## Categoria
Notificações / Produto / Consentimento (LGPD)

## Prioridade
🟡 Médio

## Épico
[EPIC-015](../epics/EPIC-015.md) — Notificações via WhatsApp (Meta Cloud API)

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — consentimento explícito (LGPD) é pré-requisito legal para qualquer envio real de WhatsApp; erro
aqui bloqueia ou compromete todo o resto do épico.

---

## Contexto

> **18/07/2026 — esta task era originalmente o card único do canal WhatsApp (TASK-122).** Foi quebrada em
> [EPIC-015](../epics/EPIC-015.md) por ter crescido demais para um card só. Esta task ficou só com a parte
> de **dado do usuário** (telefone + opt-in) — decisão de provedor, integração real, orquestração/
> urgência, quota e webhook agora são TASK-129/TASK-130/TASK-131/TASK-128, respectivamente.

**Não existe campo de telefone/WhatsApp no `User`** (`org_users/domain/User.java`) nem opt-in de
notificação de nenhum canal (nem EMAIL/PUSH têm hoje — este seria o primeiro mecanismo de preferência de
notificação do sistema).

> **Decisão (18/07/2026):** cogitou-se reaproveitar `billing_accounts.phone` (já existe, evitaria
> migration) em vez de criar campo novo em `users`. **Descartado**: `BillingAccount` é `@OneToOne` com
> um único `User` (o dono/pagador da conta) — usuários vinculados à mesma conta via EPIC-013 (Gestão de
> Equipe por Conta) não têm `BillingAccount` própria e nunca receberiam WhatsApp, quebrando a paridade
> com PUSH/EMAIL, que já notificam por usuário individual. Mantido o campo em `users`.

---

## Objetivo

Permitir que o usuário cadastre seu telefone e dê opt-in explícito de WhatsApp na tela de perfil, com
consentimento verificável (exigência da Meta, não só boa prática) — pré-requisito bloqueante para
qualquer envio real implementado em TASK-129/TASK-130.

---

## Escopo

### 1. Backend — Migration e endpoint

- Migration Flyway: adicionar `phone_number` (E.164, ex.: `+5531999999999`) e `whatsapp_opt_in`
  (boolean, default `false`) em `users`.
- Endpoint para o usuário cadastrar/editar o telefone e opt-in (`PATCH /me` ou endpoint dedicado
  `PATCH /me/notification-preferences`), com validação de formato E.164.
- **Consentimento explícito obrigatório antes do primeiro envio** — WhatsApp Business Platform (Meta)
  exige opt-in verificável para mensagens de marketing/utilidade fora de conversa iniciada pelo usuário;
  enviar sem opt-in pode levar ao bloqueio do número da conta business do Easy Maintenance (ver EPIC-015
  para o número já definido: `+55 31 97213-9145`).
- Fluxo de verificação do número (opcional na v1, recomendado na v2): envio de código via WhatsApp para
  confirmar que o número pertence ao usuário antes de marcar `whatsapp_opt_in = true`.

### 2. Frontend

- Tela de perfil/configurações do usuário: campo de telefone (com máscara BR) + toggle "Receber
  notificações por WhatsApp" (opt-in), com texto claro de consentimento (LGPD) explicando o que será
  enviado.
- Se houver fluxo de verificação de número (item 1): UI de "Enviamos um código, digite para confirmar".
- Estado de loading/erro/sucesso ao salvar preferência, seguindo os padrões já usados em
  `users/[id]/edit` (TASK-102).

### 3. QA / Testes

- Testes unitários: validação de formato E.164 (válido/inválido), endpoint de preferências (opt-in
  true/false, telefone ausente).
- Teste manual: cadastrar telefone + opt-in na tela de perfil, confirmar persistência e retorno correto
  do endpoint de preferências.

---

## Arquivos impactados (estimativa)

### Backend
- `org_users/domain/User.java` — campos `phoneNumber`, `whatsappOptIn`
- `org_users/application/service/UsersService.java` (ou serviço de perfil) — endpoint de preferências
- `db/migration/V8x__add_whatsapp_fields_to_users.sql` — **novo**

### Frontend
- Tela de perfil/configurações do usuário — campo telefone + toggle opt-in

---

## Critérios de Aceite

- [x] Usuário consegue cadastrar telefone e dar opt-in explícito de WhatsApp na tela de perfil
- [x] Telefone validado/normalizado em formato E.164 antes de persistir
- [x] Opt-out (desmarcar o toggle) é respeitado imediatamente pelo endpoint
- [x] Nenhum envio real de WhatsApp é possível sem `whatsapp_opt_in == true` (enforcement fica em
      TASK-130, mas o dado precisa existir e estar correto aqui — dado correto confirmado por teste)
- [x] Testes unitários cobrindo validação de telefone e endpoint de preferências

## Dependências
- Nenhuma bloqueante — esta task pode começar imediatamente, em paralelo com a TASK-129.
- TASK-102 — padrão de UI de loading/erro/sucesso a seguir no frontend.

## Riscos
- Envio sem opt-in verificável pode levar ao bloqueio do número business pela Meta (risco alto —
  perderia o canal para todos os clientes, não só o usuário afetado) — mitigado por este card ser
  pré-requisito bloqueante das tasks de envio real (TASK-129/TASK-130).

## Esforço
Pequeno/Médio (migration + endpoint + UI — sem integração externa)

## Status
Em Validação

## Implementação

- PRs abertos para `staging`: [easy-maintenance-api#19](https://github.com/douglasjava/easy-maintenance-api/pull/19) e [easy-maintenance-web#22](https://github.com/douglasjava/easy-maintenance-web/pull/22).
- Backend (`feature/TASK-122-user-phone-whatsapp-optin`): `phone_number`/`whatsapp_opt_in` em `users`
  (migration `V80`), novo `PhoneNumberNormalizer` (commons/utils, trata 9º dígito/DDI/máscara),
  `UsersService.updateUserDetails` valida e normaliza o telefone e aplica a regra "opt-in exige telefone"
  via `RuleException` (400). Endpoint reaproveitado: `PATCH /user/{id}` (campos aditivos, opcionais,
  sem quebrar o contrato existente). 23 testes novos (16 `PhoneNumberNormalizerTest` + 7
  `UsersServiceTest`), 601/601 testes backend green.
- Frontend (`feature/TASK-122-user-phone-whatsapp-optin`): `/profile` ganhou campo de telefone (máscara
  BR format-as-you-type, novo `src/lib/phoneMask.ts`) + toggle de opt-in com texto de consentimento
  LGPD; opt-in desabilitado sem telefone, e limpar o telefone desativa o opt-in automaticamente
  (evita toggle marcado e travado). 9 testes novos (`phoneMask.test.ts`), `tsc`/`next build` limpos.
  ⚠️ Não verificado visualmente no browser (sem ambiente local rodando) — recomendado testar o fluxo
  real (cadastrar telefone, ativar opt-in, tentar ativar sem telefone) antes de mover para Concluído.
- Falhas pré-existentes (não relacionadas): 2 erros de `tsc` em arquivos de teste e 3 falhas em
  `middleware.test.ts` já existiam identicamente em `staging` antes desta branch (confirmado via
  `git stash`).
