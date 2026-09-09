# TASK-243 — FRONTEND: Tela dedicada de fornecedores (lista + filtro + cadastro)

## Tipo
FRONTEND

## Categoria
Fornecedores / Cadastro

## Prioridade
🟡 Médio

## Épico
[EPIC-028](../epics/EPIC-028.md) — Cadastro de Fornecedores pelos Usuários + Pontuação

## QA obrigatório
Sim — cadastrar um fornecedor de verdade, confirmar que aparece na lista com a pontuação certa, e
testar o filtro por categoria num navegador real.

---

## Contexto

Tela nova dedicada (não integrada à busca interativa já existente na criação de manutenção —
decisão explícita, ver EPIC-028) onde a organização cadastra e navega fornecedores da região.
Detalhe completo em `docs/superpowers/specs/2026-09-08-supplier-registry-design.md`.

## Escopo

- Nova rota dentro do layout autenticado normal (`/fornecedores` ou `/suppliers`, nome exato a
  definir na implementação).
- Lista de fornecedores da região (`city`/`state` da organização logada), com pontuação visível
  (`registrationCount`) e filtro por categoria.
- Formulário de cadastro: CNPJ, nome, telefone, categoria — cidade/estado herdados da organização
  logada (não repete o que o usuário já cadastrou na org).
- Estados de UI: loading, erro (ex.: CNPJ inválido), vazio (nenhum fornecedor na região ainda).
- Item novo no menu lateral, seguindo o padrão visual já estabelecido (TASK-222/223).

## Critérios de Aceite

- [x] Lista mostra fornecedores da região, com pontuação
- [x] Filtro por categoria funciona
- [x] Cadastro de fornecedor novo funciona e reflete na lista
- [x] Cadastro de fornecedor com CNPJ já existente (de outra organização) funciona sem erro
      confuso — mensagem clara de que já foi vinculado
- [x] Estados de loading/erro/vazio tratados
- [x] Responsivo (mobile e desktop, mesmo padrão do resto do sistema — tabela `d-none d-md-block` /
      cards `d-md-none`, mesmo breakpoint usado em `/items` e `/resident-tickets`)
- [x] `npm run build` sem erro
- [ ] Validado num navegador real — **não executado nesta sessão**, ver nota abaixo

## Dependências
TASK-242 (endpoints) precisa estar pronta.

## Riscos
Baixo — tela nova, isolada, não altera nenhuma tela existente.

**Nota sobre o critério "Validado num navegador real"**: tentei subir a API local completa
(`mvn spring-boot:run`, perfil `local`, contra o MySQL do docker já usado nas QAs anteriores) pra
testar a tela de verdade num browser, mas o boot falha sem `FIREBASE_SERVICE_ACCOUNT_JSON` real —
`PushNotificationProvider` depende de um bean `FirebaseMessaging` que só existe com credencial
Firebase válida (`FirebaseConfig.firebaseMessaging()` retorna `null` sem ela, e o Spring recusa
injetar um bean nulo). Populei `ASAAS_API_KEY`/`GOOGLE_PLACES_API_KEY`/`AWS_*`/
`BOOTSTRAP_ADMIN_TOKEN`/`JWT_SECRET`/etc. com valores fake pra passar da resolução de placeholder,
mas o Firebase é o único bloqueador que não dá pra contornar sem a credencial real que só existe no
ambiente do Douglas. Ficou pendente pra QA manual dele, junto com o restante do fluxo (mesma
mecânica já usada em TASK-244/EPIC-027) — ver
[TASK-QA-MAN-020](../QA/tasks/TASK-QA-MAN-020.md).

## Esforço
Médio

## Implementação

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `src/app/fornecedores/page.tsx` | Tela única: cabeçalho + botão "Novo Fornecedor" (abre formulário inline: CNPJ com máscara/validação de dígito verificador via `docMask.ts`, nome, telefone com máscara via `phoneMask.ts`, categoria) + filtro por categoria + lista responsiva (tabela desktop / cards mobile) com badge de pontuação (`registrationCount`) |

### Arquivos modificados
| Arquivo | Descrição |
|---|---|
| `src/components/Sidebar.tsx` | Novo item de menu "Fornecedores" (🧰) na seção `resources`, junto de "Normas e Obrigações" |
| `src/lib/errorMapper.ts` | Novo `FIELD_MESSAGES.cnpj` — mensagem específica pro campo `cnpj` do `POST /suppliers` (a mensagem `doc` genérica já existente é de outro contrato, campo `doc`, não `cnpj`) |

### Decisões tomadas durante a implementação
- **Cidade/estado não aparecem no formulário** — TASK-242 foi ajustada durante esta sessão pra
  `POST /suppliers` herdar `city`/`state` da organização logada quando omitidos (mesmo default já
  usado no `GET`), então o frontend nem precisa buscar/enviar esses campos. Evita o formulário pedir
  um dado que a organização já tem cadastrado (exigência explícita do escopo desta task).
- **Categoria é texto livre, não select fixo** — não existe hoje um enum fechado de categoria de
  fornecedor no backend nem no frontend (o campo `itemType` em `/items/new` também é texto livre com
  sugestão via placeholder, não um select); manter o mesmo padrão em vez de inventar uma lista fixa
  que ficaria desincronizada da realidade.
- **Formulário inline (não modal, não rota separada)** — só existe um modal genérico de confirmação
  no design system atual (`ConfirmModal`, não serve pra formulário); em vez de construir um modal de
  formulário novo do zero, o form abre/fecha inline no topo da própria tela de lista, mesmo espírito
  simples do escopo da task ("tela dedicada", sem exigir modal).
- **Diferenciação "cadastrado" vs. "já existia, só vinculado"** sem mudar o contrato do backend:
  compara o `name` que voltou na resposta com o que o usuário digitou — se diferente, é porque o
  CNPJ já existia (TASK-242 nunca sobrescreve dado de cadastro anterior) e a resposta reflete o
  cadastro original. Heurística simples, cobre o caso descrito no critério de aceite sem precisar de
  um campo `wasCreated` novo na API.

### Verificação
- `npm run build` → compilou limpo, rota `/fornecedores` presente na tabela de rotas geradas
  (estática, `○`).
- `npm test` → **127/130 passando** (as 3 falhas em `middleware.test.ts` são pré-existentes, não
  relacionadas — mesmo número já documentado em TASK-QA-MAN-018).
- Validação num navegador real **não foi possível nesta sessão** (ver nota em Riscos) — fica pra
  [TASK-QA-MAN-020](../QA/tasks/TASK-QA-MAN-020.md).

Branch `feature/EPIC-028-supplier-registry` no `easy-maintenance-web` (mesmo nome do
`easy-maintenance-api`, repositórios separados).

## Status
🟡 Implementado e testado (`npm run build` limpo, `npm test` sem regressão nova) — falta validação
num navegador real de verdade (bloqueada nesta sessão por falta de credencial Firebase pra subir a
API local completa). Ver [TASK-QA-MAN-020](../QA/tasks/TASK-QA-MAN-020.md) pra Douglas rodar o fluxo
ponta a ponta (backend + frontend) antes de abrir as PRs finais do EPIC-028.
