# TASK-093 — Frontend: Cookie na landing page + middleware update

## Tipo
FRONTEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🟠 Alto

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Adaptar a landing page para capturar o código de afiliado via `?ref=CODE` e armazenar em cookie. Passar `affiliateCode` junto ao submit do lead. Adicionar `/indicador` às rotas públicas no middleware.

**Mudanças:**
- `npm install js-cookie @types/js-cookie`
- `landing/page.tsx`: `useEffect` lê `?ref=` da URL → `Cookies.set('em_ref', code, { expires: 30 })`
- `handleSubmit`: lê `Cookies.get('em_ref')` e envia no body da chamada `POST /landing/leads`
- `middleware.ts`: adicionar `'/indicador'` ao array `PUBLIC_ROUTES`

## Critérios de Aceite
- [ ] Acessar `/landing?ref=ABC123` seta cookie `em_ref=ABC123` válido por 30 dias
- [ ] Submit do form inclui `affiliateCode` no payload quando cookie presente
- [ ] Submit do form funciona normalmente sem cookie (campo ausente = null no backend)
- [ ] `/indicador/novo` e `/indicador/[code]` são acessíveis sem login
- [ ] Build Next.js sem erros de TypeScript

## Esforço
Pequeno (1-2h)

## Status
Backlog

## Dependências
TASK-091 (endpoint de leads precisa aceitar affiliateCode)
