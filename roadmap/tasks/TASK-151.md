# TASK-151 — Bug: Política de Privacidade inacessível para visitantes não logados

## Metadados

| Campo | Valor |
|-------|-------|
| **ID** | TASK-151 |
| **Tipo** | BUGFIX |
| **Prioridade** | 🔴 Crítico |
| **Severidade** | ALTA |
| **Épico** | EPIC-003 (Multi-tenancy e Autorização — fecha critério de aceite pendente de TASK-038) |
| **Sprint** | Hotfix — fora de sprint |
| **Status** | Em Validação |
| **Criado em** | 29/07/2026 |

---

## Problema

A página `/privacidade` existe e tem conteúdo completo (LGPD), e já está declarada como URL pública em `sitemap.ts`, mas **qualquer visitante sem sessão ativa é redirecionado para `/login` ao tentar acessá-la**. Isso viola a exigência da LGPD de que a política de privacidade esteja acessível publicamente antes da coleta de dados, e bloqueia o uso da URL em formulários de captação de leads (Meta Ads Lead Forms), que é a motivação imediata desta task.

### Comportamento atual

1. Visitante sem cookie de sessão acessa `https://easymaintenance.com.br/privacidade`.
2. `middleware.ts` (Edge) é um no-op — não bloqueia nada (o cookie `accessToken` vive no domínio da API Railway e não é enviado ao domínio Next, então o middleware nunca conseguiria validar sessão mesmo se tentasse).
3. O guard real está em `src/components/Shell.tsx`: toda rota que não está na whitelist `isAuth` exige `token` de `useAuth()`; sem token, `window.location.replace("/login")` é chamado antes de qualquer conteúdo ser exibido.
4. `/privacidade` não está na whitelist `isAuth` → visitante anônimo nunca vê a página.

### Comportamento esperado

- `/privacidade` acessível sem login, para qualquer visitante.
- Usuários logados que acessam via `Sidebar`/`profile` continuam funcionando normalmente (sem regressão).
- Rodapé do site público (landing) linka para a página.

---

## Root Cause

**Causa única (frontend):** `Shell.tsx` — a rota `/privacidade` não está incluída na condição `isAuth` (linhas 22-30), que é a whitelist de rotas públicas/full-screen que pulam o auth gate client-side. `middleware.ts` não é a causa (é no-op por design, ver comentário nas linhas 4-11 do próprio arquivo).

---

## Arquivos Impactados

### Frontend (`easy-maintenance-web`)
- `src/components/Shell.tsx` — adicionar `/privacidade` à whitelist `isAuth`
- `src/app/privacidade/page.tsx` — adicionar cabeçalho público (logo + link para `/landing`) e trocar CTA final que assumia sessão ativa
- `src/app/landing/page.tsx` — adicionar link "Política de Privacidade" no rodapé

### Fora de escopo desta task
- Reescrita do conteúdo jurídico da política (conteúdo já é considerado completo para o lançamento)
- Correção do link morto "Termos de Uso" (`href="#"`) no rodapé — bug pré-existente não relacionado
- Introdução de nova identidade visual (cores/fontes) — decisão explícita do produto: manter estilo Bootstrap atual do site

---

## Fix Proposto

Adicionar `/privacidade` à condição `isAuth` em `Shell.tsx`, tornando a rota full-screen (sem sidebar/topbar) e sem exigência de token — mesmo tratamento hoje aplicado a `/landing`, `/login`, `/checkout`, etc.

Ajustar `privacidade/page.tsx` para funcionar tanto para visitante anônimo quanto usuário logado: cabeçalho simples com `Logo` linkando para `/landing`, e substituir o botão final "← Voltar para Minha Conta" (que pressupõe sessão) por "← Voltar para o site" apontando para `/landing`.

Adicionar link para `/privacidade` na coluna "Acesso" do rodapé em `landing/page.tsx`.

---

## Critérios de Aceite

- [x] Visitante sem login acessa `/privacidade` diretamente pela URL e vê o conteúdo completo, sem redirect para `/login`
- [x] Página renderiza corretamente em mobile e desktop, com logo no topo
- [x] Usuário logado continua acessando `/privacidade` normalmente a partir de `Sidebar` e `/profile`, sem regressão
- [x] Rodapé da landing page tem link visível para "Política de Privacidade" apontando para `/privacidade`
- [x] `/privacidade` continua na sitemap (`sitemap.ts`) sem alterações — já estava correta
- [ ] QA manual: validar em produção (Vercel) que a URL pública funciona em janela anônima antes do uso em Meta Ads

## Follow-up (não bloqueante para o lançamento desta semana)

- Nomear um encarregado de dados (DPO) ou canal formal, hoje a página só expõe um e-mail comercial genérico
- Rotular explicitamente a base legal de cada tratamento de dados (Art. 7º da LGPD: execução de contrato, obrigação legal, etc.)

---

## Testes a Validar

- Acesso anônimo (janela anônima / sem cookie) direto em `/privacidade` → conteúdo visível, sem redirect
- Acesso logado via link em `Sidebar` → conteúdo visível, sem regressão
- Acesso logado via `/profile` → link "Minha Conta → Privacidade e Dados" continua funcionando
- Link do rodapé da landing (`/landing`) → navega corretamente para `/privacidade`
- Build de produção (`next build`) sem erros
