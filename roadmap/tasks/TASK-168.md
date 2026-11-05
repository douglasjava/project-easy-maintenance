# TASK-168 — BUGFIX: botão "Ver todos os recursos" da landing não leva a lugar nenhum

## Tipo
BUGFIX

## Categoria
Landing Page / Marketing

## Prioridade
🟡 Médio

## Épico
—

## QA obrigatório
Sim — clicar no botão e confirmar que a página rola até a seção de recursos.

---

## Contexto

Achado por Douglas em revisão manual de `/landing`, fora do escopo de qualquer épico em andamento:
na seção "Diferenciais", o botão "Ver todos os recursos" era um `<button>` sem `onClick` nem
`href` — um botão morto, clicável mas sem nenhum efeito.

## Objetivo

Fazer o botão navegar até a seção de recursos existente na própria landing.

## Escopo

- `src/app/landing/page.tsx`: trocado `<button className="btn btn-primary rounded-pill px-4">Ver
  todos os recursos</button>` por `<a href="#solucao" className="btn btn-primary rounded-pill
  px-4">Ver todos os recursos</a>` — mesmo padrão de âncora interna já usado no menu do topo e no
  rodapé da própria página (`href="#solucao"`, `href="#problema"`, etc.), apontando pra seção
  "Tudo o que você precisa em um só lugar" (id `solucao`), que já lista os recursos da plataforma.
- Nenhuma rota nova, nenhum componente novo — reaproveita âncora já existente.

## Critérios de Aceite

- [x] Clicar no botão rola a página até a seção de recursos (confirmado via clique programático no
      browser: mesmo destino final — mesmo `scrollY` — do link "Solução" já existente no menu)
- [x] `npm run build` limpo

**Achado colateral (fora de escopo, não corrigido aqui)**: todos os links de âncora da landing
(inclusive o "Solução" do menu, que já existia antes desta task) rolam a página ~800px além do
topo real da seção alvo — é um comportamento pré-existente e uniforme em toda a página (CSS
`scroll-behavior: smooth` global, não algo introduzido por este fix), não o bug relatado ("não leva
a lugar nenhum"). Sinalizado a Douglas; se quiser corrigir o overshoot, é um problema à parte que
afeta todas as âncoras da landing, não só este botão.

## Dependências
Nenhuma.

## Riscos
Baixíssimo — troca de uma tag por outra, reaproveitando âncora já existente e testada em outros
links da mesma página.

## Esforço
Pequeno

## Status
Em Validação — branch `bugfix/TASK-168-landing-cta-recursos-sem-destino`, commit `9616b68`
(easy-maintenance-web). PR aberta pra `staging`: [#36](https://github.com/douglasjava/easy-maintenance-web/pull/36).
