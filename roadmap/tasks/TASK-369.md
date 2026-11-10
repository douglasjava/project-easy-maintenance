# TASK-369 — FRONTEND: Categoria e protocolo no fluxo público do morador

## Tipo
FRONTEND

## Categoria
Chamados de Moradores

## Prioridade
🟠 Alto

## Épico
[EPIC-027](../epics/EPIC-027.md) — Chamados de Moradores

## QA obrigatório
Sim — abrir chamado escolhendo cada uma das 3 categorias, confirmar protocolo exibido na
confirmação e na listagem "Meus chamados", responsividade mobile (público final acessa via QR code
no celular).

---

## Contexto

Parte frontend da extensão do EPIC-027 pedida por Douglas após conversa com a síndica Aliria
Emanuela (28/10/2026). Detalhe completo em
`docs/superpowers/specs/2026-10-28-resident-tickets-category-protocol-notification-design.md`.

## Escopo

- No formulário de abertura (`/chamados/[orgCode]`, tela 2): novo campo obrigatório de categoria
  (Sugestão/Reclamação/Manutenção — radio ou select, decisão de UI na implementação).
- Tela de confirmação após abrir: exibir o número de protocolo em destaque (ex. "Protocolo nº 12").
- Listagem "Meus chamados": cada item mostra categoria e protocolo.
- Estados de loading/erro consistentes com o resto do fluxo público já existente.

## Critérios de Aceite

- [x] Não é possível enviar o formulário sem escolher uma categoria (`<select required>` +
      `disabled={... || !category}` no botão)
- [x] Protocolo retornado pela API aparece na confirmação — toast com "Protocolo nº X" ao abrir
- [x] Protocolo e categoria aparecem em cada item da listagem "Meus chamados" (badge de categoria +
      linha "Protocolo nº X")
- [ ] Funciona em viewport mobile — **ainda não verificado**: QA manual de 29/10/2026 (ver
      abaixo) rodou contra API/frontend locais reais e cobriu os demais critérios, mas a tentativa
      de emulação de viewport mobile via automação de navegador não teve efeito (limitação da
      ferramenta usada, não da aplicação). Recomenda-se checagem manual rápida num celular real ou
      DevTools antes de promover.
- [x] `npm run build`/`tsc --noEmit` sem regressão

## QA manual (29/10/2026)
Executado contra API (`mvn spring-boot:run -Dspring-boot.run.profiles=local`) e frontend
(`npm run dev`) locais reais, banco MySQL real. Organização de teste criada via
`POST /private/admin/organizations` (bootstrap). Abertos 5 chamados reais em `/chamados/[orgCode]`
cobrindo as 3 categorias (Manutenção, Reclamação, Sugestão):
- [x] Não é possível enviar sem categoria — confirmado (botão bloqueado)
- [x] Protocolo exibido na confirmação ("Protocolo nº X") e sequencial (1, 2, 3... por organização)
- [x] Categoria (badge colorido) e protocolo aparecem em cada item de "Meus chamados"
- [x] Formulário consistente nas 3 categorias, sem erros de estado/loading

## Dependências
TASK-367 (contrato de API com `category`/`protocolNumber`). Independente de TASK-370/371.

## Riscos
Baixo — extensão de tela já existente, sem mudança estrutural de rota.

## Esforço
Pequeno

## Status
🟡 QA manual de fluxo/dados concluído (29/10/2026) — falta apenas confirmar viewport mobile antes
de promover. Branch `feature/EPIC-027-categoria-protocolo-notificacao` (`easy-maintenance-web`).
