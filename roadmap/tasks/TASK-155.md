# TASK-155 — Frontend: página `/obrigado` + correção da whitelist `isAuth` no `Shell.tsx`

## Tipo
FRONTEND

## Categoria
Marketing / Tracking

## Prioridade
🟠 Alto

## Épico
[EPIC-018](../epics/EPIC-018.md) — Tracking de Conversão para Ads (UTM, Consentimento LGPD, Página de Obrigado)

## QA obrigatório
Sim — validar acesso anônimo direto à URL (mesma classe de bug do TASK-151) e responsividade
mobile/desktop.

---

## Contexto

Não existe hoje uma página de confirmação pós-lead — o único feedback é um `alert()` (TASK-154 vai
remover isso). Sem uma página real de destino, não é possível disparar um evento de conversão
"Lead" com confiança de que o formulário realmente completou (clique em botão não garante
submissão bem-sucedida).

**Achado crítico durante o design**: `Shell.tsx` faz o auth-gate client-side via whitelist
`isAuth` (linhas 22-31) — qualquer rota fora dessa lista redireciona visitante sem token para
`/login` via `window.location.replace`. `/obrigado` precisa entrar nessa lista, senão o próprio
fluxo que estamos construindo quebra: visitante anônimo enviaria o lead, seria redirecionado para
`/obrigado`, e imediatamente re-redirecionado para `/login` — mesma classe de bug documentada e
corrigida no TASK-151 para `/privacidade`.

---

## Objetivo

Nova rota pública `/obrigado`: confirmação + próximos passos + botão secundário de WhatsApp.

---

## Escopo

### 1. Correção do `Shell.tsx`
- Adicionar `pathname?.endsWith("/obrigado")` à condição `isAuth` (mesmo tratamento hoje aplicado a
  `/privacidade`, `/landing`, etc.).

### 2. `src/app/obrigado/page.tsx`
- Estilo Bootstrap padrão, consistente com o resto do site (decisão de escopo do épico — sem nova
  paleta/tipografia).
- Nav simples com `Logo` linkando para `/landing`, mesmo padrão usado em `privacidade/page.tsx`
  (não existe header componentizado para reaproveitar — ver Contexto Técnico do épico).
- Conteúdo: confirmação de recebimento + texto informando que a equipe entrará em contato + botão
  secundário "Falar agora no WhatsApp" para quem não quer esperar.
- Botão de WhatsApp usa `getStoredUtm()` (TASK-153) para anexar contexto de campanha à mensagem
  pré-preenchida (ex.: "...vim através da campanha X").
- `metadata`: `title`, `robots: { index: false, follow: false }` (página de obrigado não deve ser
  indexada/rankeada) e sem entrada em `sitemap.ts` (é destino de fluxo, não conteúdo de busca).

### 3. Testes
- Build/lint + teste manual: acesso anônimo direto via URL não redireciona para `/login`;
  responsivo mobile/desktop; link de WhatsApp abre com mensagem correta.

---

## Critérios de Aceite

- [ ] Visitante sem sessão acessa `/obrigado` diretamente pela URL e vê o conteúdo, sem redirect
      para `/login`
- [ ] Página renderiza corretamente em mobile e desktop
- [ ] Botão de WhatsApp abre `wa.me` com mensagem pré-preenchida (incluindo contexto de UTM quando
      disponível)
- [ ] `/obrigado` tem `robots: noindex` e não aparece em `sitemap.ts`
- [ ] `npm run build` limpo

## Dependências
- **TASK-153** — helper `getStoredUtm()` para o contexto do botão de WhatsApp (não bloqueia a
  página em si, só esse detalhe do botão).

## Riscos
Baixo, mas alto impacto se esquecido: sem a correção do `Shell.tsx`, toda a métrica de Lead do
épico fica quebrada silenciosamente (redirect para `/login` antes do JS de tracking rodar).

## Esforço
Baixo

## Status
Pronto para Implementar
