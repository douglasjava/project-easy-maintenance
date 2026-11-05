# TASK-231 — FRONTEND: Destaca visualmente o card de opt-in de WhatsApp no Perfil

## Tipo
FRONTEND

## Categoria
UX / Perfil do usuário

## Prioridade
🟡 Médio

## QA obrigatório
Sim — QA manual: conferir os dois toggles (utilidade e marketing) num navegador real, os dois
estados (ligado/desligado) legíveis à distância.

---

## Contexto

Achado de Douglas numa call de demo real: o cliente estava ativamente procurando o toggle de
notificações por WhatsApp na tela de Perfil (sabia que precisava ativar) e mesmo assim quase não
achou/entendeu — Douglas quase precisou pegar o mouse da mão dele. O toggle de utilidade
(`whatsappOptIn`, já existente há tempo) e o novo de marketing (`whatsappMarketingOptIn`, TASK-229,
mesmo padrão visual) sofrem do mesmo problema: são só uma linha dentro de um formulário grande,
separada por um `border-top` sutil — lê como texto informativo, não como uma ação clara.

## Objetivo

Tornar a seção de opt-in de WhatsApp impossível de ignorar, sem redesenhar a tela inteira.

## Escopo

`profile/page.tsx`:
- Seção de WhatsApp (os dois toggles) passa a viver dentro de um card com fundo e borda em tom
  verde (`border-success-subtle` + `bg-success-subtle bg-opacity-25`, Bootstrap 5.3), em vez do
  `border-top` sutil anterior — separa visualmente do resto do formulário como um bloco de
  configuração de verdade.
- Cada toggle ganha um rótulo de estado explícito em texto (**Ativado**/**Desativado**, verde/cinza)
  ao lado do switch — o switch sozinho (bolinha ligada/desligada) é sutil demais numa tela
  compartilhada; o texto deixa o estado legível à distância.
- Mesmo tratamento nos dois toggles (utilidade e marketing) — o problema era dos dois.

## Validação

Sem acesso a credenciais de teste pra abrir `/profile` logado — validei visualmente com um mockup
estático replicando exatamente as classes Bootstrap usadas (Chrome + servidor local, mesma técnica
já usada nesta sessão pra validar CSS da sidebar). Card se destaca claramente do restante da tela,
estado "Ativado"/"Desativado" legível à distância.

## Critérios de Aceite

- [x] Seção de WhatsApp visualmente destacada (card com fundo/borda), não mais um divisor sutil
- [x] Estado de cada toggle legível em texto, não só pela posição do switch
- [x] Mesmo tratamento visual nos dois toggles (utilidade e marketing)
- [x] `npm run build` limpo
- [x] Validado visualmente via mockup estático (sem acesso a login real)

## Dependências
Nenhuma técnica — mudança puramente visual na mesma seção que a TASK-229 já tinha criado.

## Riscos
Baixo — só classes CSS/Bootstrap e reposicionamento de texto, nenhuma mudança de lógica/estado.

## Esforço
Baixo

## Status
✅ Mergeada em `staging`, PR `staging→main` aberta: [web#73](https://github.com/douglasjava/easy-maintenance-web/pull/73).
Implementada na mesma branch/PR original da TASK-229
([web#72](https://github.com/douglasjava/easy-maintenance-web/pull/72)).
