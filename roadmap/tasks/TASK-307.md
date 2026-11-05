# TASK-307 — Links diretos no web

## Tipo
FRONTEND

## Prioridade
🟡 Médio

## Épico
[EPIC-031](../epics/EPIC-031.md) — Assistente no WhatsApp · **Onda 2**

## Depende de
—

## QA obrigatório
Sim. Ver cenários da TASK-312 e as seções de Segurança e Controle de fluxo do EPIC-031.

## Contexto
Desenho completo, achados do código, decisões e riscos em
[`roadmap/epics/EPIC-031.md`](../epics/EPIC-031.md) (aprovado em 26/09/2026). Ler as seções
Arquitetura, Guarda-corpos, Segurança e identidade e Controle de fluxo antes de implementar.
Base: `staging` · branch `feature/TASK-307-<descricao-curta>`.

**Escopo**: itens, manutenções, dashboard e relatórios aceitam organização e filtros pela URL
(ex.: `?org=…&status=OVERDUE`), trocando a organização ativa se o usuário tiver acesso. Sem login
automático: link sem sessão leva ao login e volta para o destino.

**Critérios de aceite**
- [x] Link para organização sem acesso → mensagem clara, sem vazar dado.
- [x] Após o login, o usuário cai na tela filtrada.

**Prompt**: `execute a TASK-307 (EPIC-031): links diretos com organização e filtros pela URL nas
telas de itens, manutenções, dashboard e relatórios.`

## Execução (29/09/2026)
- Web [web#108](https://github.com/douglasjava/easy-maintenance-web/pull/108): `?org=` troca a organização ativa (ou "sem acesso",
  sem renderizar a tela); `/login?next=` volta para a tela filtrada (pula a seleção se o link traz a organização);
  `?maintenanceId=` abre o detalhe; `?tab=` em relatórios; proteção contra open redirect.
- API [api#142](https://github.com/douglasjava/easy-maintenance-api/pull/142): `AssistantLinks` — todos os links do bot com a
  organização da conversa e o filtro certo (vencidos, histórico do item, manutenção registrada, dashboard, relatórios).
- Validado no navegador: deslogado → login → tela filtrada; troca de empresa; detalhe da manutenção; empresa de outro
  cliente bloqueada; aba de relatórios; login normal sem regressão; mobile.
- Achado à parte: `middleware.test.ts` (3 testes) espera redirecionamento no servidor, mas o middleware virou no-op — teste
  desatualizado, falha igual na `staging`.

## Status
In Validation
