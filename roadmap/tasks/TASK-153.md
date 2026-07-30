# TASK-153 — Frontend: captura e persistência de UTM (cookie 30 dias)

## Tipo
FRONTEND

## Categoria
Marketing / Tracking

## Prioridade
🟠 Alto

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim — validar em navegação real que o UTM sobrevive à navegação entre páginas e ao fechamento da
aba.

---

## Contexto

Nenhum parâmetro UTM é lido ou persistido hoje. Sem isso, não há como saber qual anúncio/campanha
gerou cada lead — dado essencial para medir ROI de Meta Ads/Google Ads.

---

## Objetivo

Ler UTMs (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`) da URL em toda
página, persistir em cookie por 30 dias, e expor um helper para leitura em qualquer componente
cliente.

---

## Escopo

### 1. `src/lib/utm.ts`
- `captureUtm()`: lê `URLSearchParams` da URL atual; se houver pelo menos um `utm_*` presente,
  grava em cookie `em_utm` (JSON serializado) via `js-cookie`, `{ expires: 30, sameSite: 'Lax' }` —
  mesmo padrão já usado para o cookie `em_ref` em `landing/page.tsx`. Se a URL atual não tiver
  nenhum UTM, **não sobrescreve** um valor já salvo (preserva a atribuição da primeira visita —
  "first touch" dentro da janela de 30 dias).
- `getStoredUtm()`: lê e desserializa o cookie `em_utm`; retorna `undefined` se não existir.

### 2. Captura global
- Componente cliente `UtmCapture` (sem render visível, só efeito) chamando `captureUtm()` uma vez
  no mount.
- Montado no `RootLayout` (`src/app/layout.tsx`), dentro de `Providers`/`Shell`, para rodar em toda
  página como pedido no briefing.

### 3. Testes
- Sem infraestrutura de teste de componente React neste projeto (limitação já registrada em tasks
  anteriores) — validar via build/lint + teste manual de navegação (landing com UTM → outra página
  → formulário ainda vê o UTM).

---

## Critérios de Aceite

- [x] Acessar `/landing?utm_source=google&utm_medium=cpc&utm_campaign=teste` grava cookie `em_utm`
      com os 3 valores — validado via `utm.test.ts` e manualmente no browser (Playwright, ver notas
      de QA da TASK-155/EPIC-018)
- [x] Navegar para outra página pública sem UTM na URL mantém o cookie intacto (não é sobrescrito
      com valores vazios) — coberto por `utm.test.ts` ("does not write the cookie when...")
- [x] Fechar e reabrir a aba (mesmo navegador) dentro de 30 dias mantém o UTM salvo — por design
      (`expires: 30`), mesmo padrão do cookie `em_ref` já validado em produção
- [x] `getStoredUtm()` retorna os valores corretos para uso no form (TASK-154) e no botão de
      WhatsApp (TASK-155)
- [x] `npm run build` limpo

## Dependências
Nenhuma (trilha independente da TASK-152).

## Riscos
Baixo — mesmo padrão de cookie já validado em produção (`em_ref`).

## Esforço
Baixo

## Status
Em Validação — implementado em `feature/EPIC-018-conversion-tracking` (`utm.ts`, `UtmCapture.tsx`
montado no `layout.tsx`, commits `91e59d6`/`70496c2`/`db608c3`), `utm.test.ts` cobrindo captura/
merge/leitura, `npm run build` limpo, validado manualmente no browser. Falta QA manual/PR para
`staging`.
