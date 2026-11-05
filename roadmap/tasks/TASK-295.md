# TASK-295 — Banco de prints reais do sistema (conta de demonstração)

## Tipo
INFRA / CONTEÚDO

## Prioridade
🟠 Alto — bloqueia PPT, one-page e documentação com imagem real (e a troca do hero da landing, TASK-294)

## Contexto
Os materiais de venda (projeto Cowork de Materiais, 25/09/2026) não podem usar imagem inventada.
Hoje não existe nenhum print real atualizado do sistema.

## Escopo
1. Conta de demonstração com dados fictícios coerentes (condomínio exemplo, itens com status
   variados, histórico de manutenções com fotos, chamados de moradores, fornecedores com selos).
2. Capturar em alta resolução (desktop 1440px + mobile quando fizer sentido), nesta prioridade:
   índice de conformidade; registro de manutenção com foto; PDF de prestação de contas; alerta no
   WhatsApp (celular); chamados (QR code + quadro); fornecedores com selos e "Solicitar Orçamento";
   pré-cadastro com IA.
3. Guardar num lugar versionado (ex.: `docs/produto/prints/`) com nome por tela e data.

## Critérios de Aceite
- [ ] Nenhum dado de cliente real nos prints
- [ ] As 7 telas prioritárias capturadas
- [ ] Prints enviados ao projeto Cowork de Materiais

## Execução (24/09/2026)
Conta demo "Condomínio Residencial Jardim das Acácias" (BH) criada no ambiente **local** pelo fluxo real
de onboarding, com dados fictícios; 18 arquivos em `docs/produto/prints/` (índice, o que foi preparado
no banco e cuidados de uso no `README.md` da pasta). Decisão do Douglas: local agora, staging depois.

- [x] Nenhum dado de cliente real nos prints
- [~] Telas prioritárias: 4 de 7 capturadas (índice de conformidade, PDF de prestação de contas,
      chamados, fornecedores) + extras (detalhe com anexo, kanban e página do fornecedor, fluxo do
      morador no celular). Faltam: upload de foto (S3), pré-cadastro com IA (OpenAI), alerta no
      WhatsApp (celular) e cartaz A4 com QR de produção — roteiro no README da pasta.
- [ ] Prints enviados ao projeto Cowork de Materiais (Douglas)

Recaptura em 25/09/2026 com o código da TASK-294 (logo oficial, nomes legíveis, índice único 75% no
dashboard e no PDF, "Este ano" = 01/01–hoje). Os cuidados do README foram atualizados.

## Status
🟡 Em andamento — parte local concluída; captura em staging pendente.
