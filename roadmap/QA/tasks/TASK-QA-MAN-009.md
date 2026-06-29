# TASK-QA-MAN-009 — QA Manual: E2E fluxo completo de convite e gestão de usuários

## Tipo
QA — Manual

## Prioridade
🟠 Alto

## Épico
EPIC-013 — Gestão de Usuários por Organização

---

## Objetivo

Validar end-to-end o fluxo de convite de usuários por organização, garantindo que:
- Somente ADMIN consegue criar, editar e remover usuários
- O e-mail de convite é enviado corretamente
- O limite do plano (`maxUsers`) é respeitado
- Os estados de UI (loading, empty, error) funcionam corretamente

---

## Pré-condições

- Ambiente: staging
- Conta admin com org ativa e plano com `maxUsers >= 2`
- Conta non-admin (role USER) para testar bloqueio de acesso
- Acesso a uma caixa de e-mail para validar o e-mail de convite

---

## Cenários de Teste

### C1 — Navegação: "Usuários" visível apenas para ADMIN

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como ADMIN e abrir dropdown do UserTopBar | Item "Usuários" deve aparecer |
| 2 | Logar como USER e abrir dropdown do UserTopBar | Item "Usuários" **não** deve aparecer |
| 3 | Como USER, acessar `/users` diretamente na URL | Deve ser redirecionado (não 403 bruto) |

---

### C2 — Listagem: `/users` exibe usuários da org

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como ADMIN e acessar `/users` | Lista de usuários da org atual é exibida |
| 2 | Verificar UsageMeter | Exibe `currentUsers / maxUsers` corretamente |
| 3 | Verificar role badges | ADMIN em azul, USER em cinza (ou equivalente) |
| 4 | Verificar ações | Botões "Editar" e "Remover" visíveis apenas para ADMIN |

---

### C3 — Convite: novo usuário recebe e-mail de primeiro acesso

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Acessar `/users/new` como ADMIN | Formulário carrega sem campo de senha |
| 2 | Selecionar organização no select | Org ativa pré-selecionada; outras orgs listadas |
| 3 | Selecionar role via select (USER ou ADMIN) | UI sem campo de texto livre para role |
| 4 | Preencher nome e e-mail válidos e submeter | Toast de sucesso + mensagem de e-mail enviado |
| 5 | Verificar caixa de entrada do e-mail convidado | E-mail de convite recebido com link de primeiro acesso |
| 6 | Clicar no link do e-mail e definir nova senha | Usuário consegue fazer login com a nova senha |
| 7 | Verificar listagem `/users` | Novo usuário aparece na lista |

---

### C4 — Guard ADMIN: não-ADMIN não acessa `/users/new`

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Logar como USER e acessar `/users/new` | Redirecionamento (não carrega o formulário) |
| 2 | Tentar POST direto para `/organizations/{orgCode}/users` como USER | Backend retorna 403 |

---

### C5 — Convite duplicado: reenvio não acontece para e-mail existente

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Convidar um e-mail já cadastrado no sistema | Backend vincula o usuário existente à org |
| 2 | Verificar caixa de e-mail do usuário existente | **Nenhum** novo e-mail de convite é enviado |

---

### C6 — Limite do plano: `maxUsers` bloqueado

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Atingir o limite de usuários da org | UsageMeter exibe `maxUsers / maxUsers` |
| 2 | Tentar convidar mais um usuário | Backend retorna erro com mensagem de limite atingido |
| 3 | Frontend exibe o erro | Toast ou alert com instrução de upgrade |

---

### C7 — Edição: `/users/[id]/edit` atualiza dados

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Clicar em "Editar" na listagem | Navega para `/users/{id}/edit` com dados pré-populados |
| 2 | Alterar nome e salvar | Toast de sucesso; listagem reflete nome atualizado |
| 3 | Alterar role para ADMIN e salvar | Usuário promovido; verificar acesso às funcionalidades de ADMIN |
| 4 | Tentar alterar a própria role | UI bloqueia com aviso; PATCH não é enviado |

---

### C8 — Desativação: status INACTIVE bloqueia acesso

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Desativar um usuário via botão "Desativar" | Confirmação solicitada; após confirmação: status muda para INACTIVE |
| 2 | Usuário desativado tenta fazer login | Login bloqueado ou sessão inválida (a definir conforme lógica de auth) |
| 3 | Listagem exibe badge INACTIVE | Badge vermelho (ou equivalente) visível |

---

### C9 — Remoção: DELETE remove vínculo sem excluir usuário

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Clicar em "Remover" na listagem com confirmação | Usuário removido da listagem da org |
| 2 | Verificar que o usuário ainda existe no sistema | Em `/private/users` (admin interno) o usuário aparece |
| 3 | Tentar acessar org removida como usuário removido | Acesso negado à org específica |

---

## Critérios de Aceite da Suite

- [ ] C1: navegação condicional por role validada
- [ ] C2: listagem com usage meter e badges funcionando
- [ ] C3: fluxo completo de convite com e-mail de primeiro acesso
- [ ] C4: guard ADMIN bloqueando acesso frontend e backend
- [ ] C5: sem reenvio de convite para e-mail existente
- [ ] C6: limite `maxUsers` bloqueando e exibindo mensagem
- [ ] C7: edição de nome e role com proteção de auto-edição
- [ ] C8: desativação reflete na UI e no acesso
- [ ] C9: remoção de vínculo sem excluir usuário do sistema
