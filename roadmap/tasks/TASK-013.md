# TASK-013 — Adicionar security headers HTTP

## Tipo
Segurança

## Categoria
Backend / Frontend / Segurança

## Prioridade
🟠 Alto

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
A aplicação não possui os headers de segurança HTTP básicos configurados. Esses headers instruem o browser a aplicar políticas de segurança que mitigam ataques comuns como clickjacking, MIME sniffing, downgrade de HTTPS e XSS.

Headers ausentes identificados:
- `Strict-Transport-Security` (HSTS)
- `Content-Security-Policy` (CSP)
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy`

## Problema
Sem esses headers:
- A aplicação pode ser embedada em iframe de outro site (clickjacking)
- Browser pode fazer MIME sniffing e executar scripts disfarçados de imagem
- Sem HSTS, conexão pode ser downgraded para HTTP em alguns cenários
- Sem CSP, qualquer script injetado na página executa livremente

## Dependências
- Nenhuma

## Critérios de Aceite
- [ ] Spring Security configurado para incluir os headers em todas as respostas
- [ ] `X-Frame-Options: DENY` presente em todas as respostas
- [ ] `X-Content-Type-Options: nosniff` presente
- [ ] `Strict-Transport-Security` com `max-age=31536000; includeSubDomains`
- [ ] `Referrer-Policy` configurado
- [ ] `next.config.ts` configurado com `headers()` para o frontend Next.js
- [ ] Validação via `securityheaders.com` ou equivalente

## Subtasks
**Backend (Spring Security):**
- [ ] Adicionar configuração em `SecurityConfig` (ou equivalente):
  ```java
  http.headers(headers -> headers
      .frameOptions(frame -> frame.deny())
      .contentTypeOptions(Customizer.withDefaults())
      .httpStrictTransportSecurity(hsts -> hsts
          .maxAgeInSeconds(31536000)
          .includeSubDomains(true))
  );
  ```

**Frontend (Next.js):**
- [ ] Adicionar bloco `headers()` em `next.config.ts` com os headers listados
- [ ] Incluir CSP básico para o Next.js que permita os recursos necessários (fonts, images, API)

## Esforço
Pequeno (2-3h)

## Risco de não fazer
Clickjacking, MIME sniffing e downgrade de conexão são ataques que se tornam mais prováveis com o crescimento da base de usuários.

## Status
Concluído
