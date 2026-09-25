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
- [ ] Landing sem a ilustração; hero com print real do produto
- [ ] Nenhuma tela ou PDF usa o logo antigo
- [ ] Mascote com "SAMU" correto
- [ ] Um logo só (o oficial) em todas as telas e PDFs
- [ ] Nomes de tipo/categoria legíveis nas telas e PDFs
- [ ] Um único conceito de "conformidade" (ou dois com nomes diferentes e claros)

## Status
Backlog
