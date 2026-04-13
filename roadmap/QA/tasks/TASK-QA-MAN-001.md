# TASK-QA-MAN-001 — Validação Manual do Fluxo de Autenticação com Cookie HttpOnly

## Tipo
QA Manual

## Categoria
Segurança / Autenticação

## Prioridade
🔴 Crítico

## Épico
EPIC-001 — Segurança Crítica

## Flow relacionado
[FLOW-001](../Flow/FLOW-001.md)

## Documento de Teste
[MTD-001](../MTD/MTD-001.md)

## Descrição
Validação manual completa do fluxo de autenticação implementado pelas tasks TASK-001 e TASK-002. Verificar que o token JWT é armazenado exclusivamente em cookie HttpOnly (não em localStorage), que a sessão sobrevive a reinicializações do servidor, e que o logout remove o cookie corretamente.

Esta validação é **pré-requisito para o lançamento** — falha aqui significa que o produto não pode ser disponibilizado publicamente.

## Pré-condições
- Ambiente de staging ou produção com variáveis JWT_RSA_PRIVATE_KEY e JWT_RSA_PUBLIC_KEY configuradas
- Usuário cadastrado com credenciais válidas
- Acesso para reiniciar o servidor (simular deploy)
- Browser com DevTools disponível

## Passos

### Passo 1 — Verificar cookie HttpOnly no login
1. Acessar a tela de login
2. Inserir credenciais válidas e submeter
3. Abrir DevTools → Application → Cookies
4. Localizar cookie `accessToken`
5. Confirmar flags: HttpOnly ✓, Secure ✓, SameSite=Strict

### Passo 2 — Verificar ausência de token no localStorage
1. Ainda em DevTools, ir em Application → Local Storage
2. Confirmar que não há nenhum item com "token", "jwt" ou "auth" no nome
3. Verificar também Session Storage

### Passo 3 — Sessão pós-restart
1. Com o usuário logado, reiniciar o servidor da API
2. Aguardar o servidor subir completamente
3. Recarregar a página no browser
4. Confirmar que o usuário ainda está autenticado (sem redirect para login)

### Passo 4 — Logout limpa cookie
1. Clicar no botão de logout
2. Verificar em DevTools → Cookies que `accessToken` foi removido
3. Tentar acessar `/items` diretamente — confirmar redirect para `/login`

### Passo 5 — Rate limiting (11 tentativas)
1. Na tela de login, executar 11 tentativas com senha errada em sequência rápida
2. Verificar que a 11ª retorna HTTP 429 com header `Retry-After`

## Resultado Esperado
- Cookie `accessToken` com flags HttpOnly, Secure, SameSite=Strict
- Zero tokens em localStorage/sessionStorage
- Sessão ativa após restart do servidor
- Logout remove o cookie completamente
- 429 com Retry-After na 11ª tentativa de login

## Evidências Necessárias
- [ ] Screenshot DevTools → Cookies com cookie e flags visíveis
- [ ] Screenshot DevTools → LocalStorage vazia
- [ ] Screenshot do dashboard acessível após restart do servidor
- [ ] Log do servidor confirmando carregamento de chave RSA (não geração)
- [ ] Screenshot da resposta 429 com header Retry-After

## Status
Pendente — executar antes do lançamento
