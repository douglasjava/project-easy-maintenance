# TASK-126 — Frontend: Reformulação da landing — bloco "O risco real" + redução de scroll mobile

## Tipo
FRONTEND

## Categoria
Marketing / Landing / Conversão

## Prioridade
🟠 Alto

## Épico
EPIC-006 — Produto / Experiência do Usuário

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — validar responsividade mobile (scroll sensivelmente menor, nada de conteúdo sumindo), que as
citações do bloco novo aparecem de forma legível, e que o card antigo ("Medo de multa e processo") não
ficou duplicado.

---

## Contexto e motivação

Douglas revisou a landing e trouxe 2 ajustes que decidimos tratar num único card, já que os dois mexem na
mesma página e um influencia o outro (o bloco novo não pode reintroduzir o problema de scroll que a outra
parte do card resolve):

### 1) Bloco "O risco real" (conteúdo)

A seção de problema (`#problema`, hoje "Por que as empresas perdem o controle?") fica só no ângulo de dor
operacional (planilha, WhatsApp, troca de síndico) e não transmite a gravidade real de não ter a
manutenção comprovada: risco de processo, multa/interdição e acidente.

Antes de escrever qualquer copy, pesquisei fontes confiáveis (15/07/2026) pra não colocar estatística
inventada numa página pública — resultado revisado e aprovado por Douglas:

- **IBAPE Nacional** (XV COBREAP, 2009) — 66% dos problemas em edificações no Brasil vêm de falha de
  manutenção, não de defeito de construção. Dado amplamente citado no meio de perícia predial, mas de
  2009 e recirculado via blogs — recomendo tentar validar a fonte primária do IBAPE antes do publish
  final, se quiser rigor total (não bloqueante).
- **Seciesp** (Sindicato das Empresas de Elevadores do Estado de São Paulo) — no Brasil, uma pessoa morre
  em acidente de elevador a cada 10 dias (+40 mortes em 2024). Corroborado por múltiplas publicações do
  setor de condomínios, mas sem link direto pro boletim oficial do Seciesp.
- **Código Civil, Art. 1.348** — síndico pode responder civil e criminalmente, inclusive com patrimônio
  pessoal, por acidente ligado a falta de manutenção comprovada. Fato jurídico, não estatística — base
  mais sólida do trio.
- **Corpo de Bombeiros** — multa por falta de AVCB pode chegar a R$ 265 mil + interdição do prédio (faixa
  varia por estado, não é um valor nacional único).

#### Copy aprovada por Douglas (15/07/2026)

**Eyebrow**: O RISCO REAL

**Headline**: Falta de manutenção não é só bagunça na planilha — é risco jurídico, financeiro e humano

**Subline (estatística de abertura)**: "66% dos problemas em edificações no Brasil não vêm de defeito de
construção. Vêm de falta de manutenção." — *Fonte: IBAPE Nacional*

**3 cards**:
1. ⚖️ **Processo** — "Síndicos podem responder civil e criminalmente — inclusive com o próprio
   patrimônio — por acidentes ligados à falta de manutenção comprovada." — *Fonte: Código Civil, Art.
   1.348*
2. 💰 **Multa e interdição** — "A falta de laudo de segurança (AVCB) pode gerar multas de até R$ 265 mil
   e levar à interdição do prédio." — *Fonte: Corpo de Bombeiros*
3. 🚨 **Acidente** — "No Brasil, uma pessoa morre em acidente de elevador a cada 10 dias — a maioria por
   falta de manutenção contínua." — *Fonte: Seciesp*

**Linha de fechamento**: "O Easy Maintenance existe pra isso: ter a prova de que a manutenção foi feita,
antes que alguém precise perguntar depois que já deu errado."

### 2) Redução de scroll mobile (estrutura)

Levantamento no código (`landing/page.tsx`) confirmou a queixa do Douglas: 6 seções com
`padding: 110px 1.2rem` cada no mobile (~660px de padding puro, sem contar conteúdo) e os grids
(`col-md-4`/`col-lg-*`) colapsam pra 1 coluna, empilhando **20 cards na vertical** (5 em Problema + 6 em
Solução + 5 em Diferenciais + 4 em Para quem) — mais os 3 novos do bloco de risco, se não tratados.

Decisão de abordagem (avaliada e aprovada por Douglas): **não** criar uma versão mobile separada
(duplicaria manutenção e o Google pode tratar como cloaking se mobile/desktop tiverem conteúdo muito
diferente — mobile-first indexing). Em vez disso, **densidade responsiva dentro do mesmo componente**:
- Grids de 5-6 cards viram carrossel horizontal (swipe) ou accordion no mobile — sem remover nenhum
  conteúdo, só reorganizando como ele aparece.
- Padding das seções (`.section-padding`) reduz mais forte no mobile do que hoje.
- O bloco novo "O risco real" (item 1 deste card) já nasce usando esse mesmo padrão de densidade, pra não
  reintroduzir o problema que este item resolve.

---

## Escopo

### Frontend (`easy-maintenance-web`)

**Bloco "O risco real"**:
- Novo bloco/seção com a copy acima, posicionado **logo após o Hero**, antes da seção `#problema` atual.
- Citação de cada dado em texto pequeno/discreto (estilo rodapé de card — fonte visível, mas não compete
  visualmente com o texto principal), pra transmitir segurança sem virar bibliografia.
- **Remover o card "Medo de multa e processo"** da seção `#problema` atual — o conteúdo dele é absorvido
  pelo bloco novo, evitando duplicação da mesma mensagem.

**Densidade mobile**:
- Grids de cards das seções `#problema`, Solução, `#diferenciais` e `#para-quem` (e o bloco novo de
  risco) passam a usar carrossel horizontal (swipe) ou accordion no mobile, em vez de empilhamento
  vertical simples.
- Redução do padding mobile de `.section-padding` (hoje 110px) sem cortar conteúdo.
- Nenhum card/informação é removido — só reorganizado visualmente pro mobile.

**Componentização**:
- Seguindo o padrão já adotado na TASK-124 (isolar UI nova em componentes próprios em vez de inchar ainda
  mais o `landing/page.tsx`, que já está grande e monolítico):
  - `src/components/landing/RiskBlock.tsx` — bloco novo de risco.
  - `src/components/landing/CardCarousel.tsx` (ou nome equivalente) — componente reutilizável de
    carrossel/accordion mobile, usado pelos grids existentes e pelo `RiskBlock`.

### Fora de escopo desta task

- Validação jurídica formal da copy (revisão por advogado) — fora do escopo técnico, decisão de negócio
  do Douglas se quiser antes do publish.
- Redesenho visual completo da landing (cores, tipografia, novo hero) — este card é conteúdo + densidade
  mobile, não um redesign.

### QA / Testes

- Manual: conferir posicionamento do bloco de risco (logo após Hero), leitura das citações em mobile e
  desktop, ausência de duplicação com o card antigo removido, comparar scroll total do mobile antes/depois
  (deve ser sensivelmente menor), confirmar que nenhum conteúdo sumiu (só mudou de formato de exibição),
  `tsc`/`eslint`/`next build` limpos.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/components/landing/RiskBlock.tsx` (novo)
- `src/components/landing/CardCarousel.tsx` (novo, reutilizável)
- `src/app/landing/page.tsx` — inserir o bloco de risco após o Hero, remover o card "Medo de multa e
  processo" da seção `#problema`, trocar os grids existentes pelo componente de carrossel/accordion no
  mobile, ajustar `.section-padding` mobile

## Critérios de Aceite

- [x] Bloco "O risco real" implementado com a copy aprovada (eyebrow, headline, subline com stat IBAPE,
      3 cards processo/multa/acidente, linha de fechamento)
- [x] Citação pequena/discreta abaixo de cada dado, com a fonte indicada
- [x] Bloco posicionado logo após o Hero, antes da seção `#problema` atual
- [x] Card "Medo de multa e processo" removido da seção `#problema` (sem duplicar a mensagem)
- [x] Grids de `#problema`, Solução, `#diferenciais`, `#para-quem` e o bloco de risco usam
      carrossel no mobile (swipe horizontal com scroll-snap), em vez de empilhamento vertical de 5-6+
      itens
- [x] Padding das seções reduzido no mobile (110px → 64px), sem cortar nenhum conteúdo
- [~] Scroll total do mobile sensivelmente menor que o estado atual — confirmado por código (padding
      reduzido + carrossel troca N linhas empilhadas por 1 linha), **não confirmado visualmente**
      (ferramenta de browser instável nesta sessão — ver observação abaixo)
- [x] Responsivo e sem regressão no desktop (grids continuam em colunas normalmente, confirmado no
      browser)
- [x] Nenhuma alegação estatística sem fonte indicada no código/copy

## Dependências
Nenhuma bloqueante — copy já aprovada por Douglas e abordagem de mobile já validada (densidade
responsiva, sem página separada). Opcional: validar fonte primária do IBAPE antes do publish final, se
quiser rigor extra (não bloqueia a implementação).

## Riscos
Baixo tecnicamente — mudança de frontend/copy + um componente novo reutilizável, sem impacto em
backend/dados. Risco de negócio (fora do escopo técnico): os números do bloco de risco vieram de fontes
secundárias corroboradas por múltiplas publicações, mas não verificadas contra a fonte primária direta
(IBAPE/Seciesp) — avaliar se vale a pena essa validação extra antes de publicar em produção.

## Esforço
Médio — copy já pronta, mas o carrossel/accordion mobile é um componente novo aplicado em 4-5 seções
diferentes, não é só troca de texto.

## Status
Em Validação

## Implementação (15/07/2026)

Branch `feature/TASK-126` criada a partir de `staging`.

- `src/components/landing/RiskBlock.tsx` — bloco "O risco real" com a copy aprovada.
- `src/components/landing/CardCarousel.tsx` — carrossel horizontal reutilizável (CSS `scroll-snap`, sem
  lib externa), visível só no mobile (`d-flex d-md-none`); grids desktop ficam intactos, só ganharam um
  wrapper `d-none d-md-block`.
- `landing/page.tsx`: `RiskBlock` inserido logo após o Hero; card "Medo de multa e processo" removido de
  `#problema`; os 4 grids existentes (Problema, Solução, Diferenciais, Para quem/personas) passaram a
  renderizar cada card via um componente próprio no nível do módulo (`ProblemCard`, `SolutionCard`,
  `DiferencialCard`, `PersonaCard`) reaproveitado tanto no grid desktop quanto no `CardCarousel` mobile —
  evita duplicar a marcação visual de cada card; `.section-padding` mobile reduzido de 110px para 64px,
  `.hero-section` mobile também ganhou padding reduzido.
- `eslint` limpo, `next build` (produção) sem erros.
- Verificado no browser: **desktop confirmado visualmente** (bloco de risco renderiza com copy, cores,
  ícones e citações corretos; grids desktop sem regressão). **Mobile não verificado visualmente** — a
  ferramenta de automação de browser ficou instável nesta sessão (timeouts repetidos de captura de tela)
  e não insisti além do razoável. O padrão de responsividade usado (`d-none d-md-block` /
  `d-flex d-md-none`) é o mesmo já validado funcionando na TASK-124 (listagem `/items`), então a
  confiança técnica é alta, mas recomendo Douglas testar no celular de verdade (ou DevTools) antes de
  aceitar/mover para Done.

### Polimento pós-crítica de design (15/07/2026, commit `6470eb2`)

Rodei uma revisão de design (skill frontend-design) pedida pelo Douglas na implementação já em Em
Validação. Achados e correções, todos dentro do escopo do card (sem redesign):

- `RiskCard` era visualmente idêntico aos cards genéricos de `#problema` (mesma `.card`, mesma borda,
  mesmo hover) — o bloco que precisa bater mais forte não se diferenciava em nada. Corrigido: fundo com
  tint vermelho, borda esquerda mais grossa, badge circular com ícone SVG próprio (balança/octógono/
  triângulo, substituindo emoji — que renderiza diferente por SO), sem hover-lift (o "levantar" suave
  de `.card:hover` ficava incoerente numa seção sobre processo/multa/morte).
- Headline do bloco (`display-6`) tinha o mesmo peso visual de todo outro H2 da página — subiu pra
  `display-5` pra ganhar hierarquia.
- `CardCarousel` não tinha `role`/`aria-label`/`tabIndex` — usuário de teclado ou leitor de tela não
  recebia nenhum sinal de que aquela era uma região rolável no mobile. Adicionado `role="region"`,
  `aria-label` contextual por seção, `tabIndex={0}` e foco visível via `globals.css`.
- **Bug real encontrado no processo** (não relacionado à crítica de design, achado testando): as classes
  escopadas do `styled-jsx` usadas em `RiskCard`/`CardCarousel` paravam de anexar aos elementos depois
  que um hydration mismatch pré-existente do Next (boundary interno de metadata/Suspense, não introduzido
  por esta task) força um re-render só no client — o `<style>` ficava no `<head>` mas a classe escopada
  não chegava no DOM. Troquei os dois componentes de `styled-jsx` para estilo inline + uma regra em
  `globals.css`, que é o padrão dominante no resto do projeto de qualquer forma.
- `eslint`/`next build` limpos após as mudanças. Desktop reconfirmado visualmente. Mobile real (viewport
  estreito) segue não verificado — a ferramenta de resize de janela do ambiente não estava afetando o
  viewport de fato (`window.innerWidth` continuou reportando a largura desktop mesmo após o resize).
