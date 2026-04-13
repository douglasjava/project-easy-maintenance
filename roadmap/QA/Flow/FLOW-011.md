# FLOW-011 — Funcionalidades SaaS

## Criticidade
🟡 MEDIUM

## Launch Relevance
Diferencia o produto de um CRUD básico. Impacta NPS e retenção nos primeiros 30 dias de uso.

## Tasks Relacionadas
- TASK-024 — Exportação de relatórios PDF/Excel
- TASK-031 — Notificações in-app (lista no header)
- TASK-032 — Tour guiado pós-onboarding
- TASK-034 — Central de ajuda / FAQ in-app

## Flows por Feature

### Exportação PDF/Excel (TASK-024)

| Cenário | Esperado |
|---------|---------|
| Exportar lista de manutenções (XLSX) | Arquivo com filtros aplicados gerado e download iniciado |
| Exportar relatório de conformidade (PDF) | PDF gerado com dados filtrados |
| Download no browser | Sem popup blocker ou erro |
| Filtros da tela refletidos no arquivo | Dados exportados = dados visíveis na tela |

### Notificações In-App (TASK-031)

| Cenário | Esperado |
|---------|---------|
| Ícone de sino com badge de não lidas | Badge visível com contagem correta |
| Abrir lista de notificações | Dropdown/painel exibe notificações em ordem cronológica |
| Marcar como lida | Badge diminui; notificação marcada como lida |
| Tipos: vencimento, trial expirando, pagamento confirmado | Cada tipo exibido com ícone/cor distintos |

### Tour Guiado (TASK-032)

| Cenário | Esperado |
|---------|---------|
| Primeira visita ao dashboard após onboarding | Tour ativa automaticamente |
| 3–5 passos destacando funcionalidades core | Highlights visíveis e orientativos |
| Pular o tour | Tour encerrado sem reaparecimento na mesma sessão |
| Segunda visita | Tour NÃO reativa |

### Central de Ajuda / FAQ (TASK-034)

| Cenário | Esperado |
|---------|---------|
| Acessar via ícone ou menu | Modal/painel abre com lista de perguntas |
| Busca funcional | Perguntas filtradas por palavra-chave |
| Mínimo 10 perguntas com respostas | Conteúdo base presente |
| Link para suporte externo | Link funcional presente |

## Validação Recomendada
- **Manual:** Validação exploratória de cada feature
- **Automatizada:** Não prioritário agora — features estáveis mas sem criticidade de segurança

## Gaps
- Exportação: sem teste automatizado do formato/conteúdo do arquivo gerado
- Notificações: zero testes identificados — contagem de não lidas especialmente frágil
- Tour: comportamento de "não reativar" depende de localStorage — frágil por ser state externo

## Status de Validação
- [ ] Exportação XLSX e PDF validada manualmente
- [ ] Notificações in-app validadas (badge, lista, marcar como lida)
- [ ] Tour guiado validado (primeira visita ativa, segunda não)
- [ ] FAQ acessível com conteúdo base presente
