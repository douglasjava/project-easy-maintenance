# TASK-QA-MAN-033 — QA Manual: Samu conversacional pelo WhatsApp (EPIC-043 + ações de chamado e previstos)

## Tipo
QA Manual, executado pelo Douglas (de preferência com o Tiago), em produção controlada

## Categoria
Assistente WhatsApp (Samu): painel, contexto, chamados, registro, cadastros pelo chat, anexos

## Prioridade
🟠 Alto: cobre o QA manual da [TASK-439](../../tasks/TASK-439.md) (casos 5.6 do Tiago)

## Onde fica cada teste do bot
| Manual | O que cobre | Personas |
|---|---|---|
| [QA-MAN-031](TASK-QA-MAN-031.md) | Matriz de papéis: menu por papel, convites, morador, conselheiro, zelador, fornecedor, avisos, limite de IA | Todas |
| **QA-MAN-033 (este)** | Conversa do dia a dia: painel, contexto de 30 min, comandos, chamados pela equipe, registro, remarcar, cadastro de item e fornecedor, anexos | Síndico, zelador, leitor |
| [QA-MAN-032](TASK-QA-MAN-032.md), bloco G | Previstos do Financeiro v2 pelo Samu | Síndico, conselheiro |

Ordem sugerida: **031 A** (síndico funcionando) → **031 B** (ativar o zelador) → **este** → **031 C a G** → **032 G**.

## Pré-requisitos (produção)
- Usar um **condomínio de teste** em produção, não o de um cliente: o bot grava manutenções, chamados, fornecedores e lançamentos de verdade.
- Flags (todas `false` por padrão, ver `application.properties`):
  - `ASSISTANT_PERSONAS_ENABLED=true`: sem ela só síndico/admin/leitor com login falam com o bot.
  - `WHATSAPP_RESIDENT_TICKET_ENABLED=true`: para o "Responder morador" (H5).
  - `NOTICES_WHATSAPP_ENABLED=true`: só para os avisos do 031 G (template `aviso_predio_v1` já aprovado).
  - `ASSISTANT_CLASSIFIER_PROMPT_V2`: deixar `false` (a TASK-410 ainda depende da avaliação com a chave OpenAI).
- Números: síndico (o seu), um segundo celular para zelador (e, no 031, conselheiro/morador/fornecedor) e um leitor com login.
- Dados no condomínio de teste: um item **vencido**, um item que **vence nesta semana**, "Limpeza caixa de gordura · Garagem subsolo"
  com histórico, um item com norma (ex.: extintor ou SPDA), um fornecedor com telefone vinculado como habitual de um item, e um
  morador aprovado com opt-in de WhatsApp (para H5).
- Para medir custo: anotar o consumo de créditos de IA antes e depois (~650 créditos por áudio; texto é bem menos).

## Tasks cobertas
TASK-431 a TASK-438 ([EPIC-043](../../epics/EPIC-043.md)), ações de chamado da TASK-433 e TASK-453.

---

## Cenários

### H. Painel e entrada sem portão (TASK-431)
| # | Persona | Ação | Esperado |
|---|---|---|---|
| H1 | Síndico | Primeira mensagem do dia: "oi" | Painel do condomínio direto (vencidos, vencem esta semana, chamados abertos e fora do SLA) com 3 atalhos, **sem** pedir "menu" |
| H2 | Síndico | "Mais opções" no painel | Menu completo do síndico (o mesmo do 031 A1) |
| H3 | Síndico | Primeira mensagem já com intenção: "troquei a lâmpada da garagem hoje" | Pula o painel e vai direto ao registro |
| H4 | Zelador | "oi" | Painel **sem custo** e sem financeiro |
| H5 | Leitor | "oi" | Painel só de consulta; nenhum atalho de registrar/lançar |
| H6 | Síndico | Ficar 30 min parado e mandar "oi" | Painel de novo |

### I. Contexto de 30 min e comandos (TASK-432)
| # | Ação | Esperado |
|---|---|---|
| I1 | "histórico do alarme" e depois "e para caixa de gordura?" | Responde o histórico da caixa de gordura, sem perguntar de novo o que é |
| I2 | Repetir o I1 com mais de 30 min entre as mensagens | A pergunta solta não usa mais o contexto antigo (cai no painel ou pede o item) |
| I3 | No meio de um registro, mandar `voltar` | Volta um passo, sem perder o que já foi dito |
| I4 | No meio de um registro, mandar `cancelar` | Cancela; nada é gravado (conferir no web) |
| I5 | No meio de qualquer fluxo, mandar `menu` | Abre o menu e encerra o fluxo |
| I6 | Admin com 2 condomínios: `trocar condomínio` no meio de um fluxo | Lista de condomínios; depois da troca, o contexto é do novo condomínio |

### J. Registro de manutenção (TASK-434 + Onda 1)
| # | Ação | Esperado |
|---|---|---|
| J1 | Tocar "Registrar" | Modelo com os dados e um exemplo + lista curta de itens sugeridos (vencidos e mais usados) |
| J2 | Tocar um item sugerido | Registro com o item já preenchido |
| J3 | "manutenção da caixa de gorduro ontem, R$ 300" | Sugere "Limpeza caixa de gordura · Garagem subsolo"; **não** cria item novo; data = ontem |
| J4 | No cartão: Corrigir → "o item é o alarme" | Troca o item e reapresenta o cartão |
| J5 | "feita hj às 08:00" | Data de hoje, 08:00, sem a marca "não informada" |
| J6 | Item com norma ou periodicidade | Cartão mostra a próxima data e a regra usada; não pergunta periodicidade |
| J7 | Registro com custo, confirmado | Cartão mostra a despesa que vai ser lançada; no web, aparece no Financeiro vinculada à manutenção (sem "R$ R$") |
| J8 | Depois de confirmar: "Quer anexar foto ou nota?" → mandar foto em até 10 min | "Anexado ao registro de …"; no web a foto está na manutenção |
| J9 | "posso anexar uma imagem?" | "Pode! Mande agora" e a foto vai para o último registro |
| J10 | "Vencimentos da semana" com itens atrasados | Mostra os atrasados junto; nunca "✅ nada vence" se houver vencido |

### K. Anexo sem contexto (TASK-438)
| # | Ação | Esperado |
|---|---|---|
| K1 | Foto sem legenda, mais de 10 min depois do último registro | Pergunta: [Evidência do último] [Registrar manutenção] [Outro]; **nunca** descarta em silêncio |
| K2 | [Evidência do último registro] | Anexa ao último registro **dessa persona** (conferir no web) |
| K3 | Em vez de tocar, escrever um texto (ex.: "limpeza do filtro") | O texto vira a descrição de um registro novo com essa foto. "Documento para ler" ainda não existe (depende da TASK-345) |
| K4 | Leitor manda foto sem legenda | Recusa (031 A3), sem oferecer evidência |

### L. Remarcar vencimento (TASK-435)
| # | Persona | Ação | Esperado |
|---|---|---|---|
| L1 | Síndico | "quero atualizar a manutenção do alarme" | Pergunta [Foi feita] ou [Remarcar data]; não presume data |
| L2 | Síndico | [Remarcar data] → [+30 dias] → [Fornecedor remarcou] | Confirmação mostra a data antiga e a nova; no web, o histórico do item tem data, motivo e autor |
| L3 | Síndico | [Outra data] com data passada | "A nova data precisa ser depois de hoje" e pede outra; nada é gravado |
| L4 | Leitor / Conselheiro | Mesmo pedido | Recusa; o vencimento não muda |
| L5 | Síndico (web) | Detalhe do item → alterar vencimento com motivo | Mesmo registro no histórico; o bot passa a mostrar a nova data |

### M. Cadastro de item pelo chat (TASK-436)
| # | Persona | Ação | Esperado |
|---|---|---|---|
| M1 | Síndico | Pedir para cadastrar "bomba da piscina" | Modelo: tipo (catálogo), local (sugere os já usados), última manutenção, fornecedor habitual |
| M2 | Síndico | Tipo **sem** norma | Pergunta a periodicidade com sugestões |
| M3 | Síndico | Tipo **com** norma (ex.: extintor) | Informa "Regulatório, … pela NBR X" e não pergunta periodicidade |
| M4 | Síndico | Chegar ao cartão e tocar Cancelar | Item **não** é criado (conferir no web) |
| M5 | Síndico | Confirmar o cartão | Item criado com local, periodicidade e próximo vencimento certos |
| M6 | Zelador | Mesmo pedido | Vê sugerir em vez de cadastrar; "Sugestão enviada ao síndico (protocolo nº …)" e o chamado de Sugestão aparece no kanban |

### N. Fornecedor pelo chat (TASK-437)
| # | Ação | Esperado |
|---|---|---|
| N1 | Compartilhar um contato do WhatsApp | Cadastro de fornecedor com nome e telefone preenchidos |
| N2 | Cadastrar um fornecedor que já existe (mesmo CNPJ/CPF ou nome) | "Já existe X nos seus fornecedores. É ele?" com [Sim, é ele] [Não, é outro]; "Sim" não duplica |
| N3 | Contrato: [Sim] → vigência e valor | Fornecedor salvo com contrato; [Não, é avulso] salva sem contrato |
| N4 | Vincular como habitual dos itens da categoria | No web, os itens aparecem com o fornecedor habitual |
| N5 | Convite opcional para o contato | Convite gerado (ativação como no 031 F3) |

### O. Chamados pela equipe (TASK-433)
| # | Persona | Ação | Esperado |
|---|---|---|---|
| O1 | Zelador | Abrir chamado: foto + "vazamento no hall" → local sugerido → [Urgente] | Protocolo e SLA na resposta; no kanban web, selo **Equipe** |
| O2 | Síndico | "Chamados por SLA" | Ordem: fora do SLA, vence hoje, no prazo |
| O3 | Síndico | Chamado → [Atualizar status] → concluído | Status muda no kanban e o bot oferece o registro da manutenção já com item e foto |
| O4 | Síndico | Chamado → [Acionar fornecedor] | Até 10 fornecedores com telefone, habituais primeiro com ⭐; ao escolher, vem nome, telefone e link wa.me com nº do chamado, descrição e prazo. O link abre o **seu** WhatsApp com a mensagem pronta; no web, o card mostra "📞 Fornecedor acionado" |
| O5 | Síndico | Chamado de **morador** com WhatsApp confirmado → [Responder morador] | O morador recebe a resposta. Se ele escreveu nas últimas 23h, sai como texto livre; senão, pelo template `chamado_resposta_morador_v1` (Marketing, cobrado) |
| O6 | Síndico | Chamado aberto pela equipe ou de morador sem opt-in | Botão [Responder morador] não aparece |

### P. Previstos (TASK-453)
Executar o [QA-MAN-032 bloco G](TASK-QA-MAN-032.md) (G1 a G4).

---

## Pontos de atenção em produção
- O5 fora da janela de 24h gera custo de template Marketing (decisão registrada na TASK-433).
- Conferir no log da API o status/motivo de cada mensagem processada (api#181) quando algo não responder.
- Taxa de resposta genérica ("Por aqui eu te ajudo só com...") é a métrica principal do EPIC-043: anotar quantas vezes apareceu.

## Resultado
Preencher cada cenário com ✅/❌ e o que foi visto. Ao terminar, marcar o QA manual da [TASK-439](../../tasks/TASK-439.md).
