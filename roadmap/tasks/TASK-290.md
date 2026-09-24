# TASK-290 — Contato com o suporte (WhatsApp) nas telas de onboarding

## Tipo
FRONTEND

## Categoria
Onboarding / Aquisição / Suporte

## Prioridade
🟠 Alto — reduz abandono no ponto mais caro do funil

## QA obrigatório
Sim — teste unitário do link + QA no browser (desktop e mobile).

---

## Contexto

Levantado por Douglas logo após o bug da [TASK-289](TASK-289.md) (24/09/2026): o cliente travou no
passo 2 do onboarding e não tinha como falar com a gente — só descobrimos pelo log de produção. Com um
contato à mão, ele teria pedido ajuda no primeiro minuto.

## Escopo

- Link discreto **"Precisa de ajuda? Fale com a gente no WhatsApp"** abaixo dos botões dos dois passos
  do `/onboarding` — **não** o botão flutuante (no celular ele cobre/encosta nos botões "Próximo" e
  "Criar minha conta").
- Mensagem pré-preenchida com o contexto do passo (ex.: *"Olá! Estou fazendo meu cadastro (passo 2 —
  dados da organização) e preciso de ajuda."*).
- No banner de erro que já existe ("Tentar novamente"), reforço **"ou fale com o suporte"**.
- Clique rastreado com `trackContact()` (Meta Pixel `Contact` + GA `contact`).
- Número do suporte numa constante única em `src/lib` (hoje está duplicado em `landing`, `obrigado`
  e `WhatsAppFloatButton` — esses 3 ficam como estão, fora do escopo).

## Critérios de Aceite
- [x] Link de suporte visível nos dois passos, abaixo dos botões, em desktop e mobile
- [x] Link abre `wa.me/5531999826634` com mensagem que identifica o passo
- [x] Banner de erro oferece o contato com o suporte (empilha no celular)
- [x] Clique dispara `trackContact()` (`fbq Contact` + `gtag contact` conferidos no browser)
- [x] Nenhum elemento sobreposto aos botões no mobile (390px); sem scroll horizontal
- [x] `supportWhatsApp.test.ts` (4); `tsc` limpo; `npm test` 181/184 (3 pré-existentes)

## Implementação
- `src/lib/supportWhatsApp.ts` (+ teste), `src/components/onboarding/OnboardingSupportLink.tsx`,
  `src/app/onboarding/page.tsx`
- Branch `feature/TASK-290-onboarding-whatsapp-support` (web, a partir de `staging`)
- PR: [web#98](https://github.com/douglasjava/easy-maintenance-web/pull/98) (`staging`)

## Status
🟡 Em Validação — PR aberta contra `staging`.
