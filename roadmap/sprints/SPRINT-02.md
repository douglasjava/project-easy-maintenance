# SPRINT-02 — Produto SaaS + Confiabilidade de Integrações

> **Período:** Semana 3–5 (estimado)
> **Objetivo:** Entregar a "camada SaaS" visível ao usuário (EPIC-006) e fechar a última lacuna de confiabilidade operacional (circuit breaker)
> **Capacidade estimada:** 9 tasks
> **Critério de saída:** Trial com feedback visual, onboarding sem erros silenciosos, exportação disponível, integrações externas protegidas com circuit breaker

---

## Meta da Sprint

> "Ao final desta sprint, o produto comunica valor de forma clara para o usuário em trial, converte upgrade de forma autônoma e não fica fora do ar quando o Asaas ou a OpenAI ficam indisponíveis."

---

## Tasks da Sprint

---

### 🟠 TASK-008 — Circuit breaker para serviços externos
**Arquivo:** [TASK-008.md](../tasks/TASK-008.md)
**Épico:** EPIC-002 — Confiabilidade Operacional

**Objetivo nesta sprint:** Evitar que uma falha no Asaas, OpenAI ou S3 derrube endpoints não relacionados.

**Por que está na Sprint 2:**
É o único item de prioridade 🟠 Alto pendente após a Sprint 1. Falha em cascata de integração é um risco de produção imediato, especialmente com usuários reais onboarding.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Simular Asaas indisponível → endpoint de checkout retorna resposta de fallback, não 500
- [ ] Circuit breaker abre após N falhas consecutivas
- [ ] Logs indicam estado do circuit (OPEN / CLOSED / HALF_OPEN)

**Área impactada:** Backend (AsaasService, OpenAiService, S3Service)

**Esforço:** 4-8h

---

### 🟠 TASK-015 — Banner de trial expirando no dashboard
**Arquivo:** [TASK-015.md](../tasks/TASK-015.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Tornar o período de trial visível e criar urgência de conversão.

**Por que está na Sprint 2:**
Sem banner de trial, usuários chegam ao fim do trial sem saber — churn silencioso. É o primeiro item de conversão do funil.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Usuário em trial vê banner com dias restantes no dashboard
- [ ] Banner muda de cor quando restam ≤ 3 dias
- [ ] Banner tem botão de ação para upgrade/billing
- [ ] Usuário com plano ACTIVE não vê o banner

**Área impactada:** Frontend (dashboard, AuthContext/subscription status)

**Esforço:** 3-5h

---

### 🟠 TASK-016 — Tratamento de erro claro no onboarding
**Arquivo:** [TASK-016.md](../tasks/TASK-016.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Eliminar erros silenciosos ou genéricos no fluxo de onboarding.

**Por que está na Sprint 2:**
Onboarding com erro genérico é a principal causa de abandono. Usuário que não consegue completar o onboarding não vira cliente.

**Dependências:** Nenhuma

**Como validar:**
- [ ] CPF/CNPJ inválido exibe mensagem específica
- [ ] Falha de pagamento exibe causa (cartão recusado, dados inválidos)
- [ ] Timeout de integração exibe mensagem orientando o usuário a tentar novamente
- [ ] Nenhum erro retorna apenas "Algo deu errado"

**Área impactada:** Frontend (onboarding pages) + Backend (error responses)

**Esforço:** 4-6h

---

### 🟡 TASK-023 — Indicador de uso vs limite de plano no frontend
**Arquivo:** [TASK-023.md](../tasks/TASK-023.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Comunicar proativamente limites do plano antes do bloqueio.

**Por que está na Sprint 2:**
Usuário bloqueado de surpresa por limite de plano cancela. Indicador de uso reduz churn e aumenta upsell.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Barra de progresso visível para recursos com limite (ex: nº de manutenções, usuários)
- [ ] Indicador muda para laranja ao atingir 80% do limite
- [ ] Indicador muda para vermelho ao atingir 100%
- [ ] Botão de upgrade acessível a partir do indicador

**Área impactada:** Frontend (dashboard, módulo de manutenções)

**Esforço:** 4-6h

---

### 🟡 TASK-024 — Exportação de relatórios PDF/Excel
**Arquivo:** [TASK-024.md](../tasks/TASK-024.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Entregar exportação de dados — funcionalidade crítica para o nicho de compliance.

**Por que está na Sprint 2:**
No nicho de manutenção regulatória, exportação para auditoria é frequentemente requisito de compra. Sem ela, perdemos clientes empresariais.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Lista de manutenções exportável em XLSX
- [ ] Relatório de conformidade exportável em PDF
- [ ] Arquivo gerado contém filtros aplicados na tela
- [ ] Download inicia corretamente no browser

**Área impactada:** Backend (export endpoint) + Frontend (botão de exportação)

**Esforço:** 6-10h

---

### 🟡 TASK-030 — Tela de comparação de planos (upgrade page)
**Arquivo:** [TASK-030.md](../tasks/TASK-030.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Criar a tela de conversão de trial para plano pago.

**Por que está na Sprint 2:**
Sem tela de comparação de planos, o upgrade é invisível. É o componente central do funil de conversão.

**Dependências:** TASK-015 (banner de trial) recomendado antes

**Como validar:**
- [ ] Tela exibe comparação lado a lado dos planos disponíveis
- [ ] Features destacadas por plano com checklist visual
- [ ] Botão de ação leva ao fluxo de pagamento
- [ ] Plano atual do usuário está destacado

**Área impactada:** Frontend (billing/upgrade page)

**Esforço:** 4-6h

---

### 🔵 TASK-031 — Notificações in-app (lista no header)
**Arquivo:** [TASK-031.md](../tasks/TASK-031.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Adicionar canal de comunicação in-app para eventos relevantes.

**Por que está na Sprint 2:**
Notificações in-app permitem comunicar expiração, vencimentos e atualizações sem depender de e-mail.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Ícone de sino no header mostra badge com contagem de não lidas
- [ ] Lista de notificações abre ao clicar
- [ ] Notificações podem ser marcadas como lidas
- [ ] Tipos suportados: vencimento próximo, trial expirando, pagamento confirmado

**Área impactada:** Backend (notification entity) + Frontend (header component)

**Esforço:** 6-10h

---

### 🔵 TASK-032 — Tour guiado pós-onboarding
**Arquivo:** [TASK-032.md](../tasks/TASK-032.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Reduzir time-to-value para novos usuários.

**Por que está na Sprint 2:**
Usuários sem tour abandonam o produto na primeira semana por não entender as funcionalidades principais.

**Dependências:** Onboarding concluído (existente)

**Como validar:**
- [ ] Tour ativa automaticamente na primeira visita ao dashboard
- [ ] 3-5 passos guiados destacando funcionalidades core
- [ ] Usuário pode pular o tour
- [ ] Tour não reativa em visitas subsequentes

**Área impactada:** Frontend (dashboard, onboarding flow)

**Esforço:** 4-6h

---

### 🔵 TASK-034 — Central de ajuda / FAQ in-app
**Arquivo:** [TASK-034.md](../tasks/TASK-034.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Reduzir suporte com autoatendimento básico.

**Por que está na Sprint 2:**
Com usuários reais, volume de suporte cresce. FAQ in-app resolve as dúvidas mais frequentes sem ticket.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Central de ajuda acessível via ícone ou menu
- [ ] Mínimo 10 perguntas frequentes com respostas
- [ ] Busca funcional dentro da central
- [ ] Link para suporte externo disponível

**Área impactada:** Frontend (help center page/modal)

**Esforço:** 3-5h

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída:
- [ ] Código implementado e revisado
- [ ] Validação manual executada conforme critérios da task
- [ ] Sem regressão nos fluxos de login, onboarding, dashboard e billing
- [ ] Variáveis de ambiente atualizadas no Railway se necessário
- [ ] Task movida para "Concluído" no kanban

---

## Backlog da Sprint (para Sprint 03)

Tasks que ficam para a próxima sprint após concluir S02:
- TASK-017 — Enforcement automático de tenant no repository
- TASK-018 — Soft delete nas entidades críticas
- TASK-019 — Índices ausentes no banco de dados
- TASK-020 — Schema formal para features JSON
- TASK-025 — Fila/retry para envio de e-mails
- TASK-026 — Testes de integração billing e auth

---

## Retrospectiva (a preencher ao final)

**O que funcionou bem:**
_[preencher após sprint]_

**O que poderia melhorar:**
_[preencher após sprint]_

**Próximos passos:**
_[preencher após sprint]_
