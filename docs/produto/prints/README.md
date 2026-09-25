# Prints do sistema — conta de demonstração

*Capturados em 24/09/2026 (TASK-295) no ambiente local, com o código de produção (`main`).*

## Conta demo (dados 100% fictícios)

- **Organização**: Condomínio Residencial Jardim das Acácias — Belo Horizonte/MG
- **Gestora**: Carla Mendes (`carla.demo@example.com`) — conta criada pelo próprio fluxo de onboarding
- **Dados**: 16 itens (12 regulatórios, 4 operacionais), 12 manutenções com prestadores e custos,
  4 chamados de moradores, 6 fornecedores, 5 pedidos de orçamento
- Existe só no banco **local** de desenvolvimento — nada foi criado em staging ou produção.

### O que é real e o que foi preparado
- **Telas, cálculos e textos são os reais do sistema** — nenhuma tela foi montada ou editada, com uma
  exceção: no print `05a-chamados-qrcode-card.png` o domínio `http://localhost:3000` foi trocado por
  `https://www.easymaintenance.com.br` (é o que aparece em produção).
- Foram **preparados direto no banco local** (porque o ambiente local não tem S3, e uma conta nova não
  tem histórico nem outras organizações na região):
  - registros de anexo (foto/laudo/ART) em 10 das 12 manutenções — deixa o índice de conformidade
    realista (75%, 2 itens sem evidência). Os arquivos em si não existem: o botão "Download" não
    funciona na conta demo;
  - 6 fotos mensais de conformidade (abril a setembro) — alimentam o "+12 p.p. vs. mês anterior";
  - contagem de organizações dos fornecedores (7, 5, 3, 2, 1, 1) — mostra os três selos;
  - assinatura ativa + link de gerenciamento do fornecedor "Fire Safe BH" (os pedidos de orçamento a
    ele foram criados pelo fluxo real da API).

## Índice

| Arquivo | Tela | Uso sugerido |
|---|---|---|
| `01-dashboard-indice-conformidade.png` | Dashboard completo (índice 75%, fila de ações, próximos 90 dias, custo, planejado × realizado) | Documentação, página interna do PPT |
| `01b-dashboard-primeira-dobra.png` | Dashboard — só a primeira tela (1440×900) | **Capa/hero de PPT e one-page** |
| `02a-manutencoes-historico.png` | Lista de manutenções | Documentação |
| `02b-manutencao-detalhe-evidencia.png` | Detalhe da manutenção com anexo (foto) | "Evidência de cada manutenção" |
| `03-prestacao-de-contas-p1.png` | PDF de prestação de contas (página 1) | "Relatório pronto para assembleia" |
| `03-prestacao-de-contas.pdf` | O PDF original gerado pelo sistema | Anexo/amostra |
| `05a-chamados-cartaz-a4.png` | Cartaz A4 "Precisa de manutenção?" com QR code | Chamados de moradores |
| `05a-chamados-qrcode-card.png` | Card do QR code na página da organização | Documentação |
| `05b-chamados-quadro-gestor.png` | Quadro do gestor (Solicitado / Em andamento / Concluído) | Chamados de moradores |
| `05c/05d/05e-chamados-morador-*-celular.png` | Morador no celular: CPF → meus chamados → novo chamado | Chamados (mostrar "sem login") |
| `06a-fornecedores-lista-selos.png` | Lista de fornecedores com selos Muito usado / Confiável / Novo | Fornecedores |
| `06b-fornecedores-solicitar-orcamento.png` | Modal "Solicitar orçamento" com aviso de compartilhamento | Fornecedores |
| `07a/07b-para-fornecedores-*.png` | Página pública para fornecedores (desktop e celular) | Material para fornecedores |
| `08a/08b-fornecedor-kanban-pedidos*.png` | Kanban de pedidos do fornecedor (desktop e celular) | Material para fornecedores |

## ⚠️ Cuidados ao usar

- **O QR code do cartaz (`05a-chamados-cartaz-a4.png`) aponta para o ambiente local** e o rodapé mostra
  `localhost`. Use só como ilustração pequena — **nunca como QR escaneável** em material impresso.
- Aparecem **nomes técnicos crus** nas telas ("CAIXA_DAGUA", "REGULATORY", "OPERATIONAL") — é o sistema
  hoje (TASK-294). Em close-up, prefira recortes onde isso não domina.
- O **logo antigo** aparece no cartaz A4 e nas telas do morador/fornecedor, e um **terceiro logo**
  (escudo) na `/para-fornecedores` (TASK-294). Não usar esses prints como referência de marca.
- O dashboard mostra **75%** (índice de conformidade) e o PDF mostra **88%** ("taxa de conformidade",
  fórmula mais simples). Não coloque os dois números lado a lado num mesmo slide.
- O canto inferior direito mostra o botão do assistente SAMU (normal do sistema).

## Pendentes — capturar em staging ou no celular

| Tela | Por que não foi capturada aqui | Como capturar |
|---|---|---|
| **Registro de manutenção com upload de foto** | Upload vai para o S3 (sem credencial local) | Staging: Manutenções → + Registrar → passo 2 com foto → Finalizar; print do detalhe com a miniatura |
| **Pré-cadastro com IA** | Precisa da chave da OpenAI | Staging: IA Onboarding → Condomínio + descrição → Gerar → print da lista "✨ Gerado por IA" |
| **Alerta no WhatsApp** | Precisa de envio real para um celular | Conta demo em staging com WhatsApp ativado no Perfil → aguardar/forçar alerta → print do celular |
| **Cartaz A4 com QR de produção** | O QR local aponta para localhost | Em produção/staging: Minhas Empresas → Acessar → "Baixar página para impressão (A4)" |
