# JORNADA-PRD-001 — Jornada Completa do Produto em Produção

> Criado em: 05/11/2026
> Objetivo: validar o produto de ponta a ponta rodando em PRD de verdade (WhatsApp real, e-mail
> real), do onboarding até fornecedor self-service, numa sequência que reaproveita os dados do
> bloco anterior. Dividido em blocos independentes -- pode ser executado aos poucos, um por vez,
> sem precisar fechar tudo numa sentada.

---

## Por que em PRD e não em staging

Alguns elos só existem de verdade em produção: número de WhatsApp Business real
(+553172139145), templates aprovados pela Meta, e-mail de produção (MailerSend), job de cobrança
real. Testar isso em staging valida código; só em PRD valida a jornada que o cliente real vai
viver.

## Isolamento (ler antes de começar)

- Organização de teste dedicada -- não reaproveitar a conta/organização que já roda piloto real
  (ex. a do Douglas usada no piloto do assistente). Criar uma organização nova só para esta
  jornada (sugestão de nome: "Easy Maintenance QA" ou similar, fácil de reconhecer e filtrar
  depois).
- Números de WhatsApp de teste -- usar números que você controla para cada persona (síndico,
  morador, conselheiro, fornecedor). Nunca usar um número de WhatsApp de um cliente real ou de
  alguém que não sabe que vai receber mensagem de teste -- os templates (vencimento, aprovação de
  identidade, ativação do assistente) disparam mensagem real.
- E-mails de teste -- idem; usar endereços que você controla (pode ser o mesmo e-mail com +tag,
  se o provedor de e-mail transacional não normalizar isso).
- Limpeza -- ao final (ou entre blocos, se preferir), a organização de teste pode ser apagada /
  marcada como inativa. Não é a mesma base local Docker (já limpa em 05/11/2026) -- isso aqui é
  PRD, então qualquer registro criado é real e precisa ser removido/isolado deliberadamente.

## Como usar este documento

- Cada bloco tem objetivo, pré-requisito (o que precisa estar pronto do bloco anterior), cenários
  (o que fazer e o que esperar) e um checklist de execução.
- Marque os checkboxes conforme for executando. Pode fechar o navegador/sessão entre blocos -- o
  próximo bloco só depende dos dados que o anterior deixou na organização de teste, não de nada
  desta sessão do Claude.
- Blocos que já têm FLOW/MTD próprio (Onboarding, Pessoas) linkam pra eles em vez de duplicar.

---

## Bloco 0 -- Preparação

### Objetivo
Ter a organização de teste e as personas (números/e-mails) prontos antes de começar o Bloco 1.

### Checklist
- [ ] Decidir e documentar (fora deste arquivo, por segurança) os números de WhatsApp de teste
      para: síndico, morador, conselheiro, fornecedor.
- [ ] Decidir o e-mail de teste a usar como ADMIN/síndico da organização nova.
- [ ] Confirmar que nenhum desses números/e-mails pertence a cliente real.

---

## Bloco 1 -- Onboarding

### Objetivo
Criar a organização de teste e o usuário ADMIN/síndico, do zero, pelo fluxo público de cadastro.

### Pré-requisito
Bloco 0 concluído.

### Referência
Flow/MTD já existentes (parcialmente desatualizados, focados em erro -- reexecutar o happy path
aqui): [FLOW-004](Flow/FLOW-004.md) / [MTD-004](MTD/MTD-004.md).

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Cadastro completo | Acessar /onboarding, preencher dados pessoais e da organização (nome, CPF/CNPJ, e-mail de teste, senha), avançar sem cartão (trial) | Conta criada, trial ativo, redirecionado ao Dashboard |
| Primeiro acesso ao Dashboard | Login com o usuário recém-criado | Dashboard carrega sem erro, KPIs zerados (0 itens, 0 manutenções) |
| E-mail de boas-vindas | Verificar a caixa do e-mail de teste | E-mail de boas-vindas/confirmação chegou |

### Checklist
- [ ] Organização de teste criada
- [ ] Login funcionando
- [ ] E-mail de boas-vindas recebido

---

## Bloco 2 -- Pessoas e Papéis (cadastro direto pelo admin)

### Objetivo
Incluir conselheiro e fornecedor (vínculo) manualmente via /pessoas, e criar ao menos uma
unidade -- preparando o terreno para o morador real entrar pela esteira no Bloco 4.

### Pré-requisito
Bloco 1 concluído (usuário ADMIN logado na organização de teste).

### Referência
Reaproveitar os cenários de [MTD-009](MTD/MTD-009.md) ([FLOW-012](Flow/FLOW-012.md)) -- já cobrem
isolamento multi-tenant e matriz role/role_detail, não repetir aqui.

### Cenários (específicos desta jornada, além do MTD-009)
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Criar Conselheiro | /pessoas -> aba Conselho -> "Adicionar pessoa", papel CONSELHEIRO | Aparece na aba Conselho |
| Criar Unidade | Aba Unidades -> criar unidade (ex. "101") | Unidade aparece como "vaga" |
| Vincular Fornecedor existente | Aba Fornecedores -> vincular um Supplier já cadastrado (ou cadastrar um no Bloco 8 antes, se preferir inverter a ordem) | Fornecedor aparece vinculado à organização |

### Checklist
- [ ] Conselheiro criado
- [ ] Unidade "101" (ou equivalente) criada
- [ ] Fornecedor vinculado (pode usar o do Bloco 8, se executar fora de ordem)

---

## Bloco 3 -- Itens e Manutenções

### Objetivo
Validar o núcleo do produto: cadastro de ativo e registro de manutenção.

### Pré-requisito
Bloco 1 concluído.

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Cadastrar item manualmente | /items/new -> preencher tipo, norma (opcional), nível de risco, próxima manutenção | Item aparece em /items |
| Cadastrar item via IA (SAMU) | Abrir onboarding/assistente de IA, pedir "quero cadastrar um extintor" | Item criado via diálogo, sem preencher formulário manual |
| Registrar manutenção | /maintenances/new vinculado ao item do passo 1 | Manutenção aparece no histórico do item, próxima data atualizada |
| Dashboard reflete os dados | Voltar ao Dashboard | KPIs mudam (1 item, 1 manutenção no mês) |
| Item vencido aparece em destaque | Cadastrar um item com nextDueAt no passado | Aparece em "Atenção Agora" no Dashboard |

### Checklist
- [ ] Item cadastrado manualmente
- [ ] Item cadastrado via IA
- [ ] Manutenção registrada
- [ ] Dashboard atualizado
- [ ] Item vencido destacado

---

## Bloco 4 -- Chamados e Esteira de Aprovação de Identidade do Morador

### Objetivo
Validar a forma real como um morador entra no sistema hoje: QR Code -> pendência -> aprovação
do síndico -> chamado liberado. (EPIC-040, completo em produção -- ver nota de flag abaixo.)

### Pré-requisito
Bloco 2 concluído (precisa de ao menos uma Unit cadastrada para o síndico vincular na aprovação).

### Nota importante sobre o canal WhatsApp
A aprovação por botão no WhatsApp (Aprovar/Reprovar) depende da env var
WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED, que ainda não foi ligada em produção (ação de infra
do Douglas). Enquanto isso, o e-mail de fallback cobre 100% das organizações. Então:
- Se a flag não estiver ligada: testar só o caminho e-mail + aprovação manual em /pessoas.
- Se já estiver ligada: testar os dois caminhos (confirme o estado atual antes de montar o
  roteiro do dia).

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Morador novo escaneia QR Code | Do número de WhatsApp de teste do morador (nunca usado antes nesta organização), abrir o link público do chamado (/chamados/{orgCode}), informar apto/bloco e abrir uma solicitação | Solicitação fica retida, nada aparece ainda no kanban de chamados |
| Síndico é notificado | Checar e-mail do ADMIN/síndico (e WhatsApp, se a flag estiver ligada) | E-mail de pendência chega; aba "Pendentes" em /pessoas mostra a solicitação |
| Síndico aprova | Em /pessoas -> aba Pendentes -> aprovar, vinculando à unidade "101" (ou criando nova) | CondoPerson papel MORADOR criado; chamado retido vira chamado de verdade no kanban |
| Morador recebe confirmação | Checar o número de WhatsApp do morador (se canal WhatsApp ligado) ou tela pública | Confirmação do que foi pedido, só agora |
| Segunda solicitação do mesmo morador | Do mesmo número, abrir outro chamado | Pula a esteira -- vai direto pro kanban, sem pendência nova |
| Síndico reprova (cenário negativo) | Com outro número de teste, repetir a intake e reprovar em /pessoas | Nenhum CondoPerson criado, morador não recebe aviso (comportamento silencioso esperado) |

### Checklist
- [ ] Confirmado estado atual da flag WHATSAPP_RESIDENT_IDENTITY_PENDING_ENABLED
- [ ] Pendência criada a partir do QR Code
- [ ] Notificação (e-mail e/ou WhatsApp) recebida pelo síndico
- [ ] Aprovação cria CondoPerson/Unit e libera o chamado retido
- [ ] Segunda solicitação do mesmo morador pula a esteira
- [ ] Reprovação testada (cenário negativo)

---

## Bloco 5 -- Financeiro e Prestação de Contas

### Objetivo
Validar lançamento financeiro e sua reflexão na prestação de contas.

### Pré-requisito
Bloco 1 concluído.

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Lançar receita | /finance -> Nova receita, categoria "Taxa Condominial" | Aparece na lista, valor correto |
| Lançar despesa | /finance -> Nova despesa, categoria "Conta de Consumo" | Aparece na lista |
| Cancelar lançamento | Cancelar um dos lançamentos acima | Lançamento some da lista ativa |
| Prestação de Contas reflete | /reports?tab=prestacao -> Visualizar relatório | Receitas/despesas aparecem corretamente, lançamento cancelado não aparece |

### Checklist
- [ ] Receita lançada
- [ ] Despesa lançada
- [ ] Cancelamento reflete na lista
- [ ] Prestação de contas correta

---

## Bloco 6 -- Notificações Automáticas

### Objetivo
Validar que o sistema avisa (e-mail/WhatsApp) sobre vencimento sem precisar esperar o cron
natural.

### Pré-requisito
Bloco 3 concluído (item com manutenção vencendo em breve).

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Disparo manual do job | Usar o endpoint de job sob demanda (JobController, perfil ADMIN) para o job de vencimento/cobrança, em vez de esperar o cron das 02:15 | Notificação disparada imediatamente |
| Notificação por e-mail | Checar e-mail de teste do ADMIN | E-mail de vencimento chega, com dados do item correto |
| Notificação por WhatsApp (se opt-in ativo) | Ativar opt-in de WhatsApp Marketing no perfil de teste antes do disparo | Mensagem de vencimento chega no WhatsApp de teste |
| Sugestão de fornecedores próximos (categoria Marketing) | Cadastrar fornecedor da categoria certa perto da organização de teste, disparar o job de novo | Template v3 (com fornecedores) chega, não o v2 |

### Checklist
- [ ] Job disparado sob demanda
- [ ] E-mail de vencimento recebido
- [ ] WhatsApp de vencimento recebido (se opt-in)
- [ ] Sugestão de fornecedores aparece quando aplicável

---

## Bloco 7 -- Assistente via WhatsApp (ativo)

### Objetivo
Validar a ativação por prova de posse e, depois, comandos reais pelo assistente.

### Pré-requisito
Bloco 3 concluído (bom ter pelo menos um item para o assistente consultar/registrar
manutenção).

### Nota importante
O assistente só responde a usuários na allowlist do piloto (ASSISTANT_PILOT_USER_IDS). O userId
do ADMIN da organização de teste precisa estar nessa lista antes de começar -- ação de infra do
Douglas, análoga à env var do Bloco 4.

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Confirmar allowlist | Verificar se o userId de teste está em ASSISTANT_PILOT_USER_IDS | Está presente (senão, pedir pro Douglas adicionar antes de continuar) |
| Gerar código de ativação | /profile -> aceitar termo -> gerar código | Código de 6 dígitos exibido, com validade (15 min) |
| Confirmar pelo WhatsApp dentro do prazo | Do número de WhatsApp de teste do ADMIN, enviar "ATIVAR codigo" pro número comercial | Vinculação concluída (assistant_links.wa_id/verified_at preenchidos) |
| Código expirado (cenário negativo) | Esperar passar os 15 min sem confirmar, tentar "ATIVAR" | Resposta de código inválido/expirado |
| Comando real: cadastrar manutenção por texto | Pelo WhatsApp já vinculado, pedir pro assistente registrar uma manutenção num item existente | Manutenção criada, refletida em /maintenances |
| Comando real: consultar item | Pedir status de um item pelo WhatsApp | Resposta correta com dados do item |
| Log de desfecho (regressão do achado do Tiago) | Depois de qualquer mensagem, checar o log "[Assistant] ... finalizadas: status=..." | Log aparece sem precisar consultar o banco |

### Checklist
- [ ] Allowlist confirmada
- [ ] Código gerado em /profile
- [ ] Ativação confirmada via "ATIVAR"
- [ ] Código expirado tratado corretamente
- [ ] Comando de cadastro de manutenção funciona
- [ ] Comando de consulta funciona
- [ ] Log de desfecho aparece

---

## Bloco 8 -- Fornecedor Self-Service

### Objetivo
Validar o autocadastro público de fornecedor e o link mágico de gerenciamento.

### Pré-requisito
Nenhum (fluxo público, independente da organização de teste -- mas pode alimentar o Bloco 2
depois).

### Cenários
| Cenário | Passos | Resultado Esperado |
|---|---|---|
| Autocadastro | /suppliers/cadastro, preencher documento, categorias/serviços, cidade/estado | Cadastro criado, QR Code/Pix de ativação exibido |
| Link de gerenciamento | Copiar o link manageLink exibido após o cadastro | Abre /suppliers/gerenciar/{token} corretamente |
| Ativação do marketplace | Simular/pagar a assinatura do fornecedor (sandbox ou valor real pequeno, a critério do Douglas) | marketplaceEnabled = true, e-mail de ativação chega com link /suppliers/gerenciar/... |
| Atualizar perfil pelo link mágico | Em /suppliers/gerenciar/{token}, editar categorias/telefone | Alterações persistidas |
| Kanban de pedidos de orçamento | Com uma organização (pode ser a de teste) solicitando orçamento a este fornecedor | Pedido aparece no kanban do fornecedor, status atualizável |
| Link antigo /fornecedores/... ainda funciona | Testar um link antigo (se houver algum já distribuído) | Redireciona para /suppliers/... sem erro |

### Checklist
- [ ] Autocadastro concluído
- [ ] Link mágico funciona
- [ ] Ativação do marketplace confirmada
- [ ] Edição via link mágico persiste
- [ ] Kanban de orçamento funcional
- [ ] Redirect do link antigo confirmado

---

## Resumo de Dependências entre Blocos

```
Bloco 0 (prep) -> Bloco 1 (onboarding) -> Bloco 2 (pessoas manuais) --+
                                        -> Bloco 3 (itens/manutenções) -+-> Bloco 4 (chamados + esteira)
                                                                         -> Bloco 5 (financeiro)
                                                                         -> Bloco 6 (notificações, precisa do Bloco 3)
                                                                         -> Bloco 7 (assistente, precisa do Bloco 3)
Bloco 8 (fornecedor self-service) -- independente, pode rodar em paralelo a qualquer momento
```

## Gaps conhecidos ao montar esta jornada
- Canal WhatsApp da esteira de identidade (Bloco 4) e allowlist do assistente (Bloco 7) dependem
  de ações de infra do Douglas fora do alcance de um agente (env vars em produção).
- Reserva de área comum (mencionada no EPIC-040) não existe ainda -- fora do escopo desta
  jornada.
- Nenhum destes blocos tem automação de teste E2E ainda; esta jornada é 100% manual, mesmo padrão
  dos MTDs existentes.
