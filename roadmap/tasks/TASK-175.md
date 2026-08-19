# TASK-175 — Frontend: página `/agendar` (embed Cal.com) + botão na navbar da landing

## Tipo
FRONTEND

## Categoria
Marketing / Funil Comercial

## Prioridade
🟠 Alto

## Épico
[EPIC-024](../epics/EPIC-024.md) — Agendamento de Demonstração (Cal.com)

## QA obrigatório
Sim — QA manual: testar o embed do Cal.com de ponta a ponta (escolher horário, preencher
formulário, confirmar) e checar que a landing existente (formulário de e-mail, botão "Solicitar
Demonstração", CTA final) continua idêntica.

---

## Contexto

Inspirado no `/agendar` do concorrente Easy Alert. Detalhe completo da decisão em
`docs/superpowers/specs/2026-08-19-agendamento-demo-design.md`. **Não é substituição** do fluxo
atual — é um caminho novo e paralelo.

## Objetivo

Nova página `/agendar` com o widget do Cal.com embutido, e um botão novo na navbar da landing
levando até ela — sem alterar mais nada na landing existente.

## Escopo

### 1. Nova rota `/agendar`
Mesmo padrão visual de `/blog`/`/termos` (navbar simples com `Logo` linkando pra `/landing`).
Embed do Cal.com (`@calcom/embed-react` ou script embed direto) ocupando o corpo da página.

### 2. Propagação de UTM/afiliado
UTM (cookie `em_utm`, `getStoredUtm()` já existente em `src/lib/utm.ts`) e `affiliateCode` (cookie
`em_ref`) são passados como parâmetros de URL pro embed do Cal.com — mesmo dado que o formulário
de e-mail já envia manualmente hoje em `landing/page.tsx` (`handleSubmit`).

### 3. Botão novo na navbar da landing
`src/app/landing/page.tsx` — item novo `<Link href="/agendar">Agendar demonstração</Link>` na
navbar, ao lado de "Login Cliente". **Não tocar** em nenhum outro elemento: formulário de e-mail,
botão "Solicitar Demonstração", CTA final, footer — tudo continua exatamente como está.

## Critérios de Aceite

- [ ] `/agendar` acessível publicamente, embed do Cal.com carrega e funciona (escolher
      dia/horário, preencher formulário, confirmar)
- [ ] UTM e `affiliateCode` armazenados no navegador chegam como parâmetro de URL no embed
- [ ] Botão "Agendar demonstração" visível na navbar da landing, leva pra `/agendar`
- [ ] Formulário de e-mail, botão "Solicitar Demonstração" e CTA final da landing continuam
      idênticos — nenhuma mudança visual ou funcional nesses elementos
- [ ] `npm run build` limpo

## Dependências
Nenhuma (independente da TASK-176 do ponto de vista de código).

## Riscos
Baixo — página nova, aditiva. Depende de conta/configuração no Cal.com (fora do código).

## Esforço
Baixo-Médio

## Status
Pronto para implementar.
