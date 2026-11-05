# TASK-294 — Marca: ilustração enganosa na landing, logo antigo em telas públicas e erro no mascote

## Tipo
FRONTEND (conteúdo/assets)

## Prioridade
🟠 Alto — a imagem da landing promete funcionalidades que o produto não tem

## Contexto
Levantado ao montar o contexto de marca para materiais de venda (25/09/2026). Decisão do Douglas:
o logo oficial é o conjunto SVG (`public/assets/brand/logos/`).

## Problemas
1. **`public/dashboard_preview.webp`** (hero da `/landing`) não é print do produto: mostra "Ordens
   de Serviço/OS", "PMOC", "AVCB", "NR-12 Máquinas", valor em dólar ("$23.450") e erros de digitação
   ("Actius em Alerta", "Manutanção", "Tur/Gat/Nun"). Trocar por print real do dashboard (índice de
   conformidade) — depende da TASK-295.
2. **Logo antigo** (`easymaintenance-logo-horizontal-hires.png`, engrenagem com setas + serifada)
   ainda usado em: `/fornecedores/cadastro`, `/fornecedores/gerenciar/[token]`,
   `/chamados/[orgCode]`, `/chamados/[orgCode]/meus-chamados` e no PDF do QR code de chamados
   (`ResidentTicketQrPdfDocument.tsx`). Trocar pelo SVG oficial.
3. **Mascote SAMU** (`public/samu-atende.png`): o crachá do uniforme diz "SANU". Corrigir a arte.
4. **Terceiro logo**: `/para-fornecedores` usa o escudo simples do componente `Logo.tsx` (nem o SVG
   oficial nem o PNG antigo). Achado na captura de prints (TASK-295, 24/09/2026).
5. **Nomes técnicos crus na interface**: fila de ações do dashboard, listas e PDF de prestação de
   contas mostram "CAIXA_DAGUA", "REGULATORY", "OPERATIONAL" em vez de "Caixa d'água",
   "Regulatória", "Operacional".
6. **PDF de prestação de contas sem logo** — documento que vai para assembleia sem a marca.
7. **Dois números de "conformidade" para a mesma conta**: dashboard 75% (índice: prazo + evidência +
   documentos) × PDF 88% ("taxa de conformidade": itens não vencidos ÷ total). Alinhar a fórmula ou
   o nome.
8. **"Este ano" na prestação de contas** gera os últimos 12 meses (25/09/2025 a 25/09/2026), não o ano
   corrente — renomear para "Últimos 12 meses" ou ajustar o período.

## Critérios de Aceite
- [x] Landing sem a ilustração; hero com print real do produto
- [x] Nenhuma tela ou PDF usa o logo antigo
- [ ] Mascote com "SAMU" correto
- [x] Um logo só (o oficial) em todas as telas e PDFs
- [x] Nomes de tipo/categoria legíveis nas telas e PDFs
- [x] Um único conceito de "conformidade" (ou dois com nomes diferentes e claros)

## Execução (25/09/2026)
Branch `feature/TASK-294-marca-e-nomes-legiveis` · PR [web#101](https://github.com/douglasjava/easy-maintenance-web/pull/101) → `staging`.

- **Logo** (135dfd0): versões do SVG oficial com cor fixa (`logo-*-on-light/on-dark.svg`), porque o SVG
  original seguia o tema do SO e sumia em fundo claro. `BrandLogo` ganhou `tone`. Telas públicas,
  topbar, `Logo.tsx` (o escudo), cartaz A4 e PDF de prestação de contas passam a usar o logo oficial.
  Removido o PNG antigo.
- **Nomes legíveis** (44d387e): `formatItemType`/`formatItemCategory` (`src/lib/itemLabels.ts`) em
  itens, manutenções, IA onboarding, calendário, fila de ações, relatórios e prestação de contas.
- **Conformidade**: decisão do Douglas, o PDF usa o índice do dashboard (`/dashboard/summary`). Rótulo
  "Índice de conformidade". Se a chamada falhar, mostra "—".
- **"Este ano"** = 01/01 até hoje.
- **Landing** (ebee78c): hero e imagens OG/Twitter (layout, landing, 5 posts) com print real do
  dashboard da conta demo. `dashboard_preview.*` removidos.
- Validação: tsc limpo, `npm test` 209/212 (as 3 falhas de `middleware.test.ts` já existiam), build ok,
  +24 testes novos. Conferência visual no navegador. Prints da pasta `docs/produto/prints/` recapturados.
- **Fora do escopo**: mascote "SANU", que precisa de designer (critério 3 continua aberto).
- Achado paralelo registrado: [TASK-296](TASK-296.md) (chave React duplicada na fila de ações).

## Status
🟡 Em validação — web#101 mergeada em `staging`; promoção para `main` em web#102 (critério do mascote pendente de designer)
