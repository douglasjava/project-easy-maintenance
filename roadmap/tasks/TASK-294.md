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

## Critérios de Aceite
- [ ] Landing sem a ilustração; hero com print real do produto
- [ ] Nenhuma tela ou PDF usa o logo antigo
- [ ] Mascote com "SAMU" correto

## Status
Backlog
