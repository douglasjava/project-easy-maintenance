# Easy Maintenance — Contexto de Marca e Materiais
**Use este texto como contexto em prompts para produzir materiais de venda e documentação: apresentação (PPT) para clientes, one-page comercial e documentação do produto.**
*Versão: 25/09/2026 — primeira versão*

---

## Para que serve este documento

Os outros contextos dizem **o que** falar (produto, preços, argumentos). Este diz **como** o material
deve parecer e **com o quê** montá-lo: marca, cores, tipografia, imagens liberadas e proibidas, e o
formato esperado de cada material.

Fonte de verdade para conteúdo (não repetir aqui, consultar lá):
- `context-brief.md` — funcionalidades, planos, diferenciais, FAQ (revisado em 25/09/2026)
- `contexto-comercial.md` — argumentos de venda, mensagens por público, restrições comerciais
- `manual-uso-sistema.html` — fluxo real de cada tela (base para documentação e para descrever telas)

---

## 1. Marca

- **Nome**: sempre **Easy Maintenance** — duas palavras, E e M maiúsculos. Nunca "EasyMaintenance",
  "Easy Manutenção" ou "EM" em material de cliente.
- **Assistente de IA**: **SAMU** (maiúsculo) — "Seu Assistente de Manutenção".
- **Domínio**: easymaintenance.com.br

### Logo oficial (decisão do Douglas, 25/09/2026)
O logo oficial é o **conjunto em SVG**: ícone de engrenagem com check + "EASY / MAINTENANCE".

| Arquivo | Uso |
|---|---|
| `logo-horizontal.svg` | Padrão: capa de PPT, cabeçalho do one-page, documentação |
| `logo-stacked.svg` | Espaços quadrados ou verticais (ex.: slide de encerramento, avatar) |
| `logo-icon.svg` | Só o ícone: favicon, rodapé, marca d'água discreta |

Arquivos no repositório `easy-maintenance-web`, em `public/assets/brand/logos/`. Se não estiverem
anexados a este projeto, peça ao Douglas — **nunca redesenhar o logo nem gerar uma versão por IA**.

⚠️ **Não usar o logo antigo** (`easymaintenance-logo-horizontal-hires.png`: engrenagem com setas
circulares e "Easy Maintenance" em fonte serifada). Ele ainda aparece em algumas telas públicas do
sistema, mas foi substituído e não entra em material novo.

Regras de uso: fundo claro (branco ou `#F1F5F9`) de preferência; respeitar margem livre ao redor
equivalente à altura do ícone; não esticar, rotacionar, trocar cores ou aplicar sombra.

---

## 2. Cores (extraídas do logo oficial)

| Papel | Cor | Hex | Uso |
|---|---|---|---|
| Primária | Azul | `#2563EB` | Títulos de destaque, botões/CTA, ícones principais |
| Primária clara | Azul claro | `#3B82F6` | Gradientes, detalhes, gráficos |
| Secundária | Verde | `#10B981` | "Em dia", conformidade, checks, resultados positivos |
| Secundária clara | Verde claro | `#34D399` | Detalhes, gradientes com o verde |
| Texto principal | Navy | `#0F172A` | Títulos e texto de corpo |
| Texto secundário | Slate | `#475569` | Subtítulos, legendas |
| Apoio | Slate claro | `#94A3B8` | Linhas, divisores, notas de rodapé |
| Fundo | Cinza gelo | `#F1F5F9` | Fundos de seção, caixas |
| Alerta | Âmbar | `#F59E0B` | "Vencendo", atenção (usar com moderação) |
| Crítico | Vermelho | `#EF4444` | "Vencido/atrasado" — só para status, nunca decorativo |

Regra: azul + branco dominam; verde é o acento de "resultado bom"; âmbar e vermelho aparecem só para
representar status (em dia / vencendo / vencido), igual ao sistema.

---

## 3. Tipografia

- **Inter** (a mesma do logo) — títulos em peso 700/800, corpo em 400/500.
- Fallback quando Inter não estiver disponível (ex.: PowerPoint sem a fonte instalada): **Segoe UI**
  ou **Arial**. Avisar o Douglas se o arquivo final depender de fonte não embutida.
- Hierarquia sugerida para slides: título 32–40pt, subtítulo 18–22pt, corpo 14–18pt. Nunca menos de
  12pt em material impresso.

---

## 4. Estilo visual

- Limpo, profissional, bastante espaço em branco — cara de SaaS sério, não de panfleto.
- Ícones lineares simples (estilo Lucide/Feather), monocromáticos em azul ou navy.
- Fotos: manutenção predial real (técnico trabalhando, casa de máquinas, extintor, quadro elétrico).
  Nada de clip-art, "pessoas de terno apertando mão" ou banco de imagem genérico de escritório.
- Números e status com os mesmos selos do sistema: **Em dia** (verde), **Vencendo** (âmbar),
  **Atrasado/Vencido** (vermelho).

---

## 5. Imagens — liberadas, com ressalva e proibidas

### ✅ Liberadas
- **Logos oficiais em SVG** (seção 1).
- **Foto de técnico** (`para-fornecedores-hero.webp`, repositório web, `public/`) — foto de Emmanuel
  Ikwuegbu via Unsplash, licença de uso comercial gratuita. Crédito não é obrigatório pela licença, mas
  é boa prática em documentação.
- **Prints reais do sistema** — ver seção 6. São a melhor imagem possível para vender: mostram o
  produto de verdade.

### ⚠️ Com ressalva
- **Mascote SAMU** (`samu-atende.png`, repositório web, `public/`) — pode ilustrar o assistente de IA,
  mas o crachá do uniforme está escrito **"SANU"** (erro na arte). Usar pequeno, ou recortado sem o
  crachá, até existir uma versão corrigida. Não usar como imagem principal de capa.
- **Imagens do blog** (`blog-*.webp`) — ilustrativas de artigos; servem para documentação/conteúdo, não
  para representar telas do produto.

### ❌ Proibidas
- **`dashboard_preview.png/.webp`** (a imagem de "dashboard" que aparece no topo da landing) — **não é
  print do produto**, é uma ilustração: mostra funcionalidades que o sistema não tem ("Ordens de
  Serviço/OS", "PMOC", "AVCB", "NR-12 Máquinas"), valor em dólar ("$23.450") e erros de digitação
  ("Actius", "Manutanção"). Usar em material de venda = prometer o que o produto não entrega.
- Qualquer tela "fake" gerada por IA ou mockup inventado de funcionalidade que não existe.
- O logo antigo (seção 1).

---

## 6. Prints do sistema

Existe um banco de **prints reais** de uma conta de demonstração com dados fictícios (Condomínio
Residencial Jardim das Acácias, BH), capturados em 24/09/2026: pasta `docs/produto/prints/`. O
`README.md` dessa pasta lista cada arquivo, o uso sugerido e os **cuidados** (QR code do cartaz aponta
para ambiente local, nomes técnicos crus em algumas telas, logo antigo em algumas telas, 75% × 88%).

Já disponíveis: dashboard/índice de conformidade (completo e primeira dobra), histórico e detalhe de
manutenção com anexo, PDF de prestação de contas, chamados (cartaz A4, quadro do gestor, fluxo do
morador no celular), fornecedores (selos e solicitar orçamento), página e kanban do fornecedor.

**Ainda faltam** (placeholder no material até chegarem): upload de foto no registro de manutenção,
pré-cadastro com IA, alerta recebido no WhatsApp e cartaz A4 com QR de produção.

Se um print pedido não estiver na pasta, use placeholder explícito ("[PRINT: ...]") — nunca imagem
inventada.

---

## 7. Especificação de cada material

### 7.1 Apresentação comercial (PPT) — público: clientes
- **Quem assiste**: síndico profissional, administradora de condomínios, gestor de facilities — em
  reunião de venda ou demonstração. **Não é pitch de investidor** (sem projeção financeira, sem
  tamanho de mercado em destaque, sem stack técnica).
- **Tamanho**: 10 a 14 slides, 16:9. Pensada para ser apresentada ao vivo e também enviada depois
  (cada slide precisa se sustentar sozinho, sem depender da fala).
- **Estrutura sugerida**:
  1. Capa — logo + promessa ("Manutenção preventiva em dia, com prova para auditoria")
  2. A dor — planilha, WhatsApp, troca de síndico, risco jurídico (NBR 5674)
  3. O custo de não fazer — multa/responsabilidade vs. mensalidade (sem inventar valores de multa além dos documentados)
  4. O que é o Easy Maintenance — uma frase + 3 pilares (controlar, comprovar, agir)
  5. Índice de conformidade (dashboard)
  6. Alertas no WhatsApp + sugestão de fornecedor
  7. Registro com evidência + prestação de contas em PDF
  8. Chamados de moradores por QR code
  9. Fornecedores e orçamento pelo WhatsApp
  10. IA: pré-cadastro em minutos + assistente SAMU
  11. Normas cobertas (ABNT, NR, Anvisa, Bombeiros) — escopo predial
  12. Planos e preços (tabela oficial) + trial de 14 dias sem cartão
  13. Como começar — passos + CTA (agendar demonstração / testar grátis) + contatos
- Versão para **administradora** pode reforçar multi-empresa, ranking por unidade e relatórios por cliente.

### 7.2 One-page comercial
- **Formato**: A4 retrato, **uma página**, pensada para PDF (enviar por WhatsApp/e-mail) e impressão.
- **Público**: síndico/administradora que ainda não conhece o produto.
- **Blocos, de cima para baixo**: logo + promessa → a dor em 3 linhas → 4 a 6 benefícios com ícone →
  1 print (ou placeholder) → tabela de planos resumida (ou "a partir de R$ 149/mês") → trial 14 dias
  sem cartão → CTA com QR code/link para `/agendar` ou `/landing` + WhatsApp.
- Uma versão alternativa para **fornecedores** pode existir (R$ 15,99/mês, zero comissão,
  `/para-fornecedores`) — nunca misturar as duas ofertas no mesmo one-page.

### 7.3 Documentação do produto
- **Base**: `manual-uso-sistema.html` — é o fluxo real de cada tela, com os nomes exatos dos botões.
  Documentação nova deve partir dele, não reinventar passos.
- Tipos esperados: guia rápido de primeiros passos, FAQ de atendimento, guia por público (gestor,
  morador, fornecedor), material de treinamento/onboarding de cliente.
- Formato: o que o Douglas pedir (DOCX, PDF, página); linguagem de manual — passo a passo numerado,
  nomes de botão entre aspas ou em destaque, uma ação por passo.

---

## 8. Regras de conteúdo (valem para todos os materiais)

- **Preços e condições** exatamente como na tabela do `context-brief.md`: Starter R$149, Business
  R$299, Enterprise R$899/mês; anual com 17% de desconto; **trial de 14 dias no Business, sem cartão**.
- **IA (pré-cadastro e SAMU)** só nos planos Business e Enterprise — não prometer IA no Starter.
- **Sem prova social numérica**: nada de "X condomínios", "Y clientes", depoimentos, logos de clientes
  ou cases, a menos que o Douglas confirme números reais.
- **Sem comparação nominal com concorrentes** em material de cliente. A matriz competitiva do
  `context-brief.md` é para uso interno; no material externo, contrastar com a alternativa real do
  cliente (planilha, WhatsApp, caderno), não com outra empresa.
- **Sem reembolso**: falar em "cancele quando quiser, sem multa"; nunca "devolvemos seu dinheiro".
- **Normas**: escopo de manutenção **predial** — não sugerir que cobre equipamento clínico ou
  industrial de produção.
- **Só funcionalidade que existe** (ver `context-brief.md`, seção 3, e o manual). Itens de roadmap
  (app mobile, Pix Automático para organizações etc.) não entram como se já existissem.

---

## 9. Glossário (usar sempre os mesmos termos)

| Termo | Significado no produto |
|---|---|
| **Organização / empresa** | Cada edificação ou unidade cadastrada (condomínio, hospital, escola...). Na interface aparece como "empresa" |
| **Item** | Equipamento ou rotina que precisa de manutenção (extintor, elevador, caixa d'água) |
| **Manutenção** | Registro de um serviço feito num item, com data, responsável, custo e evidência |
| **Evidência** | Foto ou documento anexado à manutenção (foto, laudo, ART, nota fiscal) |
| **Índice de conformidade** | Pontuação única de quanto a edificação está em dia |
| **Chamado** | Solicitação aberta por um morador via QR code |
| **Fornecedor** | Prestador de serviço cadastrado ou participante do marketplace |
| **Prestação de contas** | Relatório em PDF do período, para assembleia/auditoria |

---

## 10. Contatos e links para CTA

- Site: https://www.easymaintenance.com.br
- Testar grátis / landing: https://www.easymaintenance.com.br/landing
- Agendar demonstração: https://www.easymaintenance.com.br/agendar
- Para fornecedores: https://www.easymaintenance.com.br/para-fornecedores
- WhatsApp: (31) 99982-6634
- E-mail comercial: comercial@easymaintenance.com.br

## Tom de voz

Direto, confiante e concreto — fala a língua de quem hoje resolve manutenção com planilha e grupo de
WhatsApp. Português do Brasil, sem jargão de SaaS ("solução robusta", "plataforma disruptiva") e sem
anglicismo desnecessário. Frases curtas; benefício antes de funcionalidade.
