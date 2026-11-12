# TASK-QA-MAN-031 — QA Manual: matriz de papéis no assistente (EPIC-042)

## Tipo
QA Manual, executado pelo Douglas (de preferência com o Tiago), em `staging` e depois em produção controlada

## Categoria
Assistente WhatsApp (Samu): personas, permissões, fornecedor, avisos

## Prioridade
🟠 Alto: cobre o critério de QA manual da [TASK-430](../../tasks/TASK-430.md)

## Pré-requisitos
- `ASSISTANT_PERSONAS_ENABLED=true` no ambiente do teste.
- 1 número de WhatsApp por persona: síndico (login), leitor (login), zelador, conselheiro, morador aprovado (EPIC-040) e
  contato de fornecedor.
- Fornecedor vinculado ao condomínio, com pelo menos uma manutenção com ele como responsável.
- Avisos: `NOTICES_WHATSAPP_ENABLED` só depois do template `aviso_predio_v1` aprovado na Meta.

## Tasks cobertas
TASK-413 a TASK-429 (ver o [EPIC-042](../../epics/EPIC-042.md)).

Os fluxos de conversa do EPIC-043 (painel, contexto, chamados pela equipe, registro, remarcar, cadastros pelo chat,
anexos) estão no [QA-MAN-033](TASK-QA-MAN-033.md).

---

## Cenários

### A. Login (síndico, admin, leitor)
| # | Ação | Esperado |
|---|---|---|
| A1 | Síndico manda "menu" | Lista com vencimentos, vencidos, histórico, registrar, receita ou despesa, chamados abertos, validar execuções, conformidade, resumo financeiro |
| A2 | Leitor manda "menu" e depois "4" | Menu só de consulta; "4" abre a conformidade, não o registro |
| A3 | Leitor toca "Registrar" (ou manda foto sem legenda) | Recusa na hora, sem "me conte o que foi feito" |
| A4 | Admin com 2 condomínios toca "Trocar de condomínio" | "Nova empresa" aparece no fim da lista; não aparece no menu principal |
| A5 | Síndico registra uma corretiva num item operacional | Vencimento continua; com "também conta como periódica" no web, recalcula (TASK-440) |

### B. Convite (zelador e conselheiro)
| # | Ação | Esperado |
|---|---|---|
| B1 | Em `/people`, ação "WhatsApp" no zelador → Gerar convite → Enviar pelo WhatsApp | Link `wa.me` com "ATIVAR XXXXX", válido por 7 dias |
| B2 | Zelador manda o código do próprio celular | Termo com [Aceito] [Não aceito]; [Aceito] → "Seu acesso ao … está ativo" |
| B3 | Outro número manda o mesmo código | "Esse convite foi feito para outro número"; o convite não é ativado |
| B4 | Trocar o celular do zelador no cadastro | O número antigo deixa de ser reconhecido |
| B5 | Zelador manda "SAIR" | Acesso desativado; próxima mensagem cai na resposta de número desconhecido |

### C. Morador
| # | Ação | Esperado |
|---|---|---|
| C1 | Morador aprovado escreve pela primeira vez | Termo; depois do aceite, menu Abrir chamado / Meus chamados / Áreas comuns |
| C2 | "Lâmpada queimada no hall" → categoria Manutenção | Protocolo e prazo na resposta; o chamado aparece no kanban com o síndico avisado |
| C3 | Foto e depois a descrição | O chamado fica com a foto |
| C4 | "Meus chamados" | Só os chamados dele |
| C5 | Número desconhecido escreve | Mensagem neutra com QR Code / convite / Minha Conta, 1 vez por dia |

### D. Conselheiro
| # | Ação | Esperado |
|---|---|---|
| D1 | Histórico de um item | Mostra o custo (D10) |
| D2 | "Resumo financeiro" | Receitas, despesas e saldo do mês |
| D3 | Tenta registrar ou lançar | Recusa; nada é gravado |

### E. Zelador
| # | Ação | Esperado |
|---|---|---|
| E1 | Histórico de um item | **Sem** custo |
| E2 | "Chamados abertos" → chamado → [Resolvido] | Status muda no kanban; o morador é avisado |
| E3 | Foto + "limpeza da caixa d'água" → [Hoje] | "Enviado! O síndico vai validar"; o vencimento **não** muda ainda |
| E4 | Síndico: "Validar execuções" → [Validar] | Vira manutenção, com a foto; o vencimento recalcula |
| E5 | Validar a mesma execução pelo web/outro síndico | "Já foi validada ou recusada" (trava) |
| E6 | Síndico recusa com motivo | Fica como recusada, com o motivo |
| E7 | "Sugerir item ou local" | Vira chamado de Sugestão no kanban |

### F. Fornecedor
| # | Ação | Esperado |
|---|---|---|
| F1 | Cadastro com CNPJ já existente em `/suppliers/cadastro` | "Enviamos o link para o e-mail cadastrado"; nada de QR ou link na tela |
| F2 | Link antigo do portal | "Link inválido ou expirado" + formulário para receber link novo |
| F3 | Portal → aba WhatsApp → adicionar técnico → Convidar | Convite gerado; técnico ativa como no B2 |
| F4 | Técnico: "Serviços que vencem" | Itens dele de todos os condomínios vinculados, sem custo |
| F5 | Técnico manda texto livre | Vira execução enviada (sem IA); ao validar, o fornecedor fica como responsável |
| F6 | Desvincular o fornecedor de um condomínio | Aquele condomínio some do bot e do portal; no portal ficam só as próprias execuções (data e serviço) |
| F7 | Portal → aba Meus serviços | Itens por condomínio e execuções enviadas com status |

### G. Avisos e limite de IA
| # | Ação | Esperado |
|---|---|---|
| G1 | `/notices` → Calcular destinatários e custo | Número de pessoas ativas com opt-in, custo estimado e uso do teto do mês |
| G2 | Enviar com o envio desligado | Botão desabilitado; mensagem de template aguardando a Meta |
| G3 | Conselheiro manda mais de 10 textos livres no dia | Da 11ª em diante, menu sem IA |

## Resultado
Preencher cada cenário com ✅/❌ e o que foi visto. Ao terminar, fechar a [TASK-430](../../tasks/TASK-430.md).
