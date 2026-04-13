# SPRINT-05 — Escalabilidade + Compliance + Produto Complementar

> **Período:** Semana 11–12 (estimado)
> **Objetivo:** Fechar o backlog de itens de baixa prioridade que completam a plataforma para operação de longo prazo — compliance, escalabilidade e polimento de produto
> **Capacidade estimada:** 7 tasks
> **Critério de saída:** LGPD implementada, jobs escaláveis, paginação sem degradação, 2FA disponível, status page pública, retenção de audit_logs ativa

---

## Meta da Sprint

> "Ao final desta sprint, o produto está pronto para crescer além dos primeiros clientes — com compliance legal, escalabilidade horizontal e polimento de experiência completo."

---

## Tasks da Sprint

---

### 🔵 TASK-033 — Status page básica
**Arquivo:** [TASK-033.md](../tasks/TASK-033.md)
**Épico:** EPIC-005 — Observabilidade e Operação

**Objetivo nesta sprint:** Oferecer transparência sobre disponibilidade do serviço.

**Por que está na Sprint 5:**
Status page é o último item de observabilidade — complementa alertas e Sentry entregues na Sprint 4 com comunicação pública.

**Dependências:** TASK-021, TASK-022 concluídas (Sprint 4)

**Como validar:**
- [ ] Página pública mostrando status dos serviços principais (API, billing, IA)
- [ ] Atualização automática baseada em health checks
- [ ] Histórico de incidentes visível
- [ ] URL pública acessível sem autenticação

**Área impactada:** DevOps / infra (betteruptime, statuspage.io ou similar)

**Esforço:** 2-4h

---

### 🔵 TASK-035 — Política de retenção para audit_logs
**Arquivo:** [TASK-035.md](../tasks/TASK-035.md)
**Épico:** EPIC-004 — Banco de Dados e Persistência

**Objetivo nesta sprint:** Evitar crescimento ilimitado da tabela de audit_logs.

**Por que está na Sprint 5:**
Com dados em produção acumulando, audit_logs cresce indefinidamente. Purge automático evita degradação de performance a longo prazo.

**Dependências:** Nenhuma

**Como validar:**
- [ ] Job de retenção remove registros com `created_at` > 2 anos (configurável)
- [ ] Job executa com ShedLock (não duplica em múltiplas instâncias)
- [ ] Registros removidos são arquivados em S3 antes da deleção (opcional mas recomendado)
- [ ] Log indica quantos registros foram removidos por execução

**Área impactada:** Backend (novo job de retenção, AuditLogRepository)

**Esforço:** 3-5h

---

### 🔵 TASK-036 — Paginação cursor-based em listagens grandes
**Arquivo:** [TASK-036.md](../tasks/TASK-036.md)
**Épico:** EPIC-007 — Performance e Escalabilidade

**Objetivo nesta sprint:** Eliminar degradação de performance em listagens com volume grande.

**Por que está na Sprint 5:**
Paginação `OFFSET` degrada com volume (O(n)). Cursor-based é necessário quando tabelas atingem dezenas de milhares de registros por tenant.

**Dependências:** TASK-019 (índices) concluída ✅

**Como validar:**
- [ ] Endpoints de listagem principais suportam `cursor` como parâmetro de paginação
- [ ] Tempo de resposta não degrada com aumento de volume (teste com 10k registros)
- [ ] Backward compatibility mantida para clientes usando offset (deprecação gradual)

**Área impactada:** Backend (controllers de listagem, repositories JPA) + Frontend (infinite scroll ou paginação)

**Esforço:** 6-10h

---

### 🔵 TASK-037 — Jobs de billing assíncronos com fila
**Arquivo:** [TASK-037.md](../tasks/TASK-037.md)
**Épico:** EPIC-007 — Performance e Escalabilidade

**Objetivo nesta sprint:** Evitar que jobs de billing travem com base de clientes grande.

**Por que está na Sprint 5:**
Jobs processando todo o banco de uma vez vão demorar horas com centenas de tenants. Processamento em lotes com commit parcial resolve o problema.

**Dependências:** TASK-003 (ShedLock) concluída ✅

**Como validar:**
- [ ] Job de billing processa em lotes de N registros (configurável)
- [ ] Falha em um lote não cancela o processamento dos lotes seguintes
- [ ] Progress logging: X de Y processados
- [ ] Rollback parcial não afeta registros já processados com sucesso

**Área impactada:** Backend (BillingCycleJob, BillingCycleJobService)

**Esforço:** 5-8h

---

### 🔵 TASK-038 — LGPD: exportação e exclusão de dados pessoais
**Arquivo:** [TASK-038.md](../tasks/TASK-038.md)
**Épico:** EPIC-003 — Multi-tenant e Permissões

**Objetivo nesta sprint:** Atender direitos dos titulares de dados conforme LGPD.

**Por que está na Sprint 5:**
LGPD é obrigação legal. Exportação e exclusão de dados pessoais são os dois direitos mais exercidos pelos titulares. Risco regulatório se não implementado antes de crescimento da base.

**Dependências:** TASK-018 (soft delete) concluída ✅

**Como validar:**
- [ ] Endpoint para exportação de todos os dados pessoais do usuário (JSON/ZIP)
- [ ] Endpoint para solicitação de exclusão — inicia fluxo de anonimização
- [ ] Dados anonimizados: nome, e-mail, CPF/CNPJ substituídos por hash ou `[removido]`
- [ ] Histórico de manutenções preservado sem dados pessoais identificáveis
- [ ] Prazo de conclusão da exclusão documentado (ex: 15 dias úteis)

**Área impactada:** Backend (UserService, novos endpoints LGPD) + Frontend (configurações de conta)

**Esforço:** 8-12h

---

### 🔵 TASK-039 — Autenticação 2FA
**Arquivo:** [TASK-039.md](../tasks/TASK-039.md)
**Épico:** EPIC-001 — Segurança Crítica

**Objetivo nesta sprint:** Adicionar segunda camada de autenticação para usuários que desejam mais segurança.

**Por que está na Sprint 5:**
2FA não é bloqueador de lançamento, mas aumenta confiança de clientes enterprise e reduz risco de comprometimento de contas.

**Dependências:** TASK-002 (cookie HttpOnly) concluída ✅

**Como validar:**
- [ ] Usuário pode ativar 2FA via app TOTP (Google Authenticator, Authy)
- [ ] Login com 2FA ativo requer código após senha
- [ ] Códigos de backup disponíveis para recuperação
- [ ] 2FA pode ser desativado pelo próprio usuário com confirmação de senha

**Área impactada:** Backend (AuthController, UserService) + Frontend (configurações de segurança)

**Esforço:** 8-12h

---

### 🔵 TASK-040 — Acessibilidade básica (WCAG AA)
**Arquivo:** [TASK-040.md](../tasks/TASK-040.md)
**Épico:** EPIC-006 — Produto SaaS

**Objetivo nesta sprint:** Atender requisitos básicos de acessibilidade para conformidade e inclusão.

**Por que está na Sprint 5:**
Acessibilidade não é bloqueador de lançamento, mas é requisito para contratos enterprise e melhora a experiência para todos os usuários.

**Dependências:** Sprint 2 (EPIC-006 UX) concluída

**Como validar:**
- [ ] Auditoria com axe DevTools sem erros críticos nas páginas principais
- [ ] Navegação completa por teclado (tab order correto)
- [ ] Contraste de cores ≥ 4.5:1 nos textos principais
- [ ] Todos os inputs têm labels associados
- [ ] Imagens com alt text descritivo

**Área impactada:** Frontend (componentes globais, pages principais)

**Esforço:** 6-10h

---

## Definition of Done (DoD) desta Sprint

Para marcar uma task como concluída:
- [ ] Código implementado e revisado
- [ ] Testes unitários ou de integração adicionados para mudanças de backend
- [ ] Sem regressão nos fluxos críticos (login, billing, onboarding)
- [ ] Variáveis de ambiente atualizadas no Railway se necessário
- [ ] Task movida para "Concluído" no kanban

---

## Encerramento do Roadmap de Fase 1–3

Após a conclusão desta sprint, todas as tasks das fases 1, 2 e 3 do roadmap estarão endereçadas. As prioridades de evolução contínua do produto serão capturadas em um novo roadmap de fase 4.

---

## Retrospectiva (a preencher ao final)

**O que funcionou bem:**
_[preencher após sprint]_

**O que poderia melhorar:**
_[preencher após sprint]_

**Próximos passos:**
_[preencher após sprint]_
