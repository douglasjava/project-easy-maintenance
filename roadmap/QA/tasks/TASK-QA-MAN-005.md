# TASK-QA-MAN-005 — Validação de Security Headers e Rate Limiting em Produção

## Tipo
QA Manual

## Categoria
Segurança / Infraestrutura

## Prioridade
🟠 Alto

## Épico
EPIC-001 — Segurança Crítica

## Flow relacionado
[FLOW-007](../Flow/FLOW-007.md)

## Documento de Teste
[MTD-006](../MTD/MTD-006.md)

## Descrição
Validação manual de todos os controles de segurança HTTP em produção: security headers, bloqueio de endpoints de desenvolvimento (Swagger, Actuator), restrições de CORS, e funcionamento do rate limiting nos endpoints de autenticação.

Cobre as tasks TASK-005, TASK-011, TASK-013, TASK-014 e TASK-006.

Esta é uma validação **obrigatória pré-lançamento** e deve ser executada no ambiente de produção ou staging que espelha produção.

## Pré-condições
- URL de produção ou staging disponível
- Ferramenta `curl` instalada no terminal
- Acesso ao site securityheaders.com
- Browser com DevTools

## Passos

### Passo 1 — Security headers via DevTools
1. Acessar a aplicação e abrir DevTools → Network
2. Selecionar qualquer request para a API backend
3. Verificar na aba Headers (Response Headers):
   - X-Frame-Options presente
   - X-Content-Type-Options: nosniff
   - Strict-Transport-Security presente
   - Content-Security-Policy presente

### Passo 2 — Auditoria no securityheaders.com
1. Acessar securityheaders.com
2. Inserir a URL da API de produção
3. Verificar nota obtida (mínimo B esperado)
4. Anotar quaisquer itens em vermelho para correção

### Passo 3 — Swagger bloqueado em produção
1. Tentar acessar no browser:
   - `/swagger-ui.html`
   - `/swagger-ui/index.html`
   - `/v3/api-docs`
2. Confirmar que cada URL retorna 404

### Passo 4 — Actuator bloqueado em produção
Executar via terminal:
```bash
curl -v https://[URL_API]/actuator/env
curl -v https://[URL_API]/actuator/beans
curl -v https://[URL_API]/actuator/health
```
Confirmar:
- `/actuator/env` e `/actuator/beans` → 403 ou 404
- `/actuator/health` → 200 com body `{"status":"UP"}` sem detalhes internos

### Passo 5 — Rate limiting no login (11 tentativas)
Executar no terminal:
```bash
for i in $(seq 1 12); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://[URL_API]/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"qa-test@example.com","password":"senhaerrada123"}')
  echo "Tentativa $i: HTTP $STATUS"
done
```
- Verificar que na 11ª tentativa o status muda de 401 para 429
- Verificar header `Retry-After` na resposta 429

### Passo 6 — Rate limiting no reset de senha
```bash
for i in $(seq 1 4); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://[URL_API]/auth/password-reset/request \
    -H "Content-Type: application/json" \
    -d '{"email":"qa-test@example.com"}')
  echo "Tentativa $i: HTTP $STATUS"
done
```
- Verificar que a 4ª tentativa retorna 429

### Passo 7 — CORS bloqueando origem não autorizada
```bash
curl -v \
  -H "Origin: https://site-malicioso.example.com" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS https://[URL_API]/items
```
Confirmar ausência de `Access-Control-Allow-Origin` na resposta.

## Resultado Esperado
- Nota B ou superior no securityheaders.com
- Swagger e docs inacessíveis em produção (404)
- Actuator sem exposição pública de detalhes (403/404)
- 429 com Retry-After na 11ª tentativa de login
- 429 na 4ª solicitação de reset de senha
- CORS bloqueando origens não autorizadas

## Evidências Necessárias
- [ ] Screenshot do relatório do securityheaders.com com nota
- [ ] Screenshot de /swagger-ui.html retornando 404
- [ ] Output do curl do /actuator/env (403/404)
- [ ] Output do script de rate limiting mostrando 429 na 11ª tentativa
- [ ] Header Retry-After visível na resposta 429
- [ ] Output do curl de CORS sem Access-Control-Allow-Origin

## Status
Pendente — executar antes do lançamento
