# TASK-QA-MAN-009 — QA Manual: E2E fluxo completo de convite e gestão de membros da equipe

## Tipo
QA — Manual

## Prioridade
🟠 Alto

## Épico
EPIC-013 — Gestão de Equipe por Conta (Team Members)

---

## Objetivo

Validar end-to-end o fluxo de gestão de equipe do dono (ADMIN): convidar membros, atribuir orgs,
editar vínculos, remover membros — com enforcement de plano e guards de role.

---

## Pré-condições

- Ambiente: staging
- Conta **dono** (role ADMIN, plano com `maxUsers >= 2`, com ao menos 2 organizações cadastradas)
- Conta **membro** (role READER — criada pelo fluxo de convite durante o teste)
- Acesso a uma caixa de e-mail para validar o convite
- Conta **não-ADMIN** para testar bloqueio de acesso

---

## Cenários de Teste

### C1 — Navegação: "Usuários" visível apenas para ADMIN

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como ADMIN, abrir dropdown do UserTopBar | Item "Usuários" visível |
| 2 | Logar como READER/não-ADMIN, abrir dropdown | Item "Usuários" **não** visível |
| 3 | Como não-ADMIN, acessar `/users` diretamente | Redirecionamento para `/` |

---

### C2 — Listagem: `/users` exibe membros e suas orgs

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como ADMIN, acessar `/users` | Lista de membros da equipe exibida |
| 2 | Verificar UsageMeter | Exibe `membros / maxUsers` do plano |
| 3 | Verificar badges de orgs | Cada membro mostra as orgs que ele acessa |
| 4 | Verificar badges de role e status | ADMIN/READER com cores distintas; ACTIVE/INACTIVE |

---

### C3 — Convite: novo membro recebe e-mail de primeiro acesso

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Clicar em "+ Convidar membro" → `/users/new` | Formulário sem campo de senha |
| 2 | Preencher nome e e-mail | Campos obrigatórios validados |
| 3 | Selecionar role (READER) | Select com opções válidas |
| 4 | Selecionar 2 organizações do dono via multi-select | Ambas selecionadas |
| 5 | Submeter | Toast de sucesso mencionando e-mail de convite |
| 6 | Verificar caixa do e-mail convidado | E-mail recebido com link de primeiro acesso |
| 7 | Clicar no link e definir senha | Membro consegue fazer login |
| 8 | Verificar listagem `/users` | Membro aparece com as 2 orgs vinculadas |

---

### C4 — Guard ADMIN: não-ADMIN bloqueado em toda a rota

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como READER e acessar `/users/new` | Redirecionamento para `/` |
| 2 | Tentar `POST /me/team/users` sem ser ADMIN | Backend retorna 403 |

---

### C5 — Multi-org: membro acessa todas as orgs selecionadas

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Membro João vinculado a Org A e Org B | Ao logar como João, consegue alternar entre Org A e Org B |
| 2 | João tenta acessar Org C (não vinculada) | Acesso negado (403 ou org não aparece na lista) |

---

### C6 — Convite para e-mail existente: sem reenvio

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Convidar um e-mail já cadastrado no sistema | Backend vincula o usuário às novas orgs |
| 2 | Verificar caixa do usuário existente | **Nenhum** e-mail de convite novo enviado |
| 3 | Verificar listagem `/users` | Usuário aparece com as orgs recém-adicionadas |

---

### C7 — Limite do plano: `maxUsers` bloqueado

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Atingir o `maxUsers` do plano | UsageMeter exibe `maxUsers / maxUsers` |
| 2 | Tentar convidar mais um membro | Botão desabilitado e/ou erro com mensagem de upgrade |
| 3 | Backend bloqueio direto | `POST /me/team/users` retorna RuleException com mensagem clara |

---

### C8 — Edição: alterar role e orgs do membro

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Clicar em "Editar" na listagem | `/users/{id}/edit` com dados pré-populados |
| 2 | Remover Org B do membro (desmarcar) e salvar | João perde acesso a Org B; listagem reflete |
| 3 | Adicionar Org C ao membro e salvar | João passa a acessar Org C; listagem reflete |
| 4 | Alterar role para VIEWER e salvar | Badge de role atualizado na listagem |
| 5 | Tentar editar a si mesmo (dono) | Formulário desabilitado com aviso |

---

### C9 — Remoção: membro desvinculado das orgs do dono

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Clicar em "Remover" na listagem | Confirmação solicitada |
| 2 | Confirmar remoção | Membro some da listagem do dono |
| 3 | Membro tenta acessar as orgs do dono | Acesso negado |
| 4 | Verificar em `/private/users` (admin interno) | Conta do membro ainda existe no sistema |

---

## Critérios de Aceite da Suite

- [ ] C1: navegação condicional por role validada
- [ ] C2: listagem com membros, orgs, UsageMeter e badges funcionando
- [ ] C3: fluxo completo de convite com e-mail de primeiro acesso + multi-org
- [ ] C4: guard ADMIN bloqueando frontend e backend
- [ ] C5: membro acessa exatamente as orgs selecionadas (não mais, não menos)
- [ ] C6: sem reenvio de convite para e-mail já existente
- [ ] C7: limite `maxUsers` bloqueado com mensagem de upgrade
- [ ] C8: edição de role e orgs reflete imediatamente na listagem
- [ ] C9: remoção desvincula sem apagar conta do sistema
