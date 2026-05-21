# 📄 Documento de Requisitos — Easy Maintenance

## 1. 🎯 Objetivo

Definir os requisitos funcionais e não funcionais do sistema **Easy Maintenance**, garantindo alinhamento técnico, produto e escalabilidade antes da publicação.

---

## 2. 📌 Visão Geral do Sistema

O **Easy Maintenance** é um SaaS multi-tenant para gestão de manutenções, com foco em:

- Controle de itens regulatórios e operacionais
- Gestão de manutenções periódicas
- Alertas e notificações
- Integração com fornecedores
- Apoio com Inteligência Artificial
- Gestão de organizações e usuários
- Controle por planos (billing)

---

## 3. 👥 Perfis de Usuário

- **ADMIN** → Gerencia organização e usuários
- **SYNDIC** → Gestão operacional
- **TECH** → Execução de manutenções
- **READER** → Apenas visualização
- **ADMIN GLOBAL (Private)** → Gestão do sistema (fora do tenant)

---

## 4. ⚙️ Requisitos Funcionais (RF)

### 🔐 Autenticação e Segurança

- **RF-001:** Usuário deve conseguir realizar login via e-mail e senha
- **RF-002:** Sistema deve retornar JWT para autenticação
- **RF-003:** Sistema deve validar o tenant via header `X-Org-Id`
- **RF-004:** Usuário deve conseguir fazer logout
- **RF-005:** Sistema deve suportar controle por roles (ADMIN, TECH, etc)

---

### 🏢 Organização

- **RF-010:** Criar organização
- **RF-011:** Listar organizações
- **RF-012:** Associar usuários a organizações
- **RF-013:** Cada organização deve ser isolada (multi-tenant)

---

### 👤 Usuários

- **RF-020:** Criar usuário
- **RF-021:** Listar usuários por organização
- **RF-022:** Atualizar dados do usuário
- **RF-023:** Controlar status (ACTIVE/INACTIVE)

---

### 🛠️ Itens de Manutenção

- **RF-030:** Criar item de manutenção
- **RF-031:** Listar itens com filtros (status, tipo, categoria)
- **RF-032:** Atualizar item (restrito se já tiver manutenção)
- **RF-033:** Calcular automaticamente próximo vencimento
- **RF-034:** Classificar status (OK, NEAR_DUE, OVERDUE)

---

### 📅 Manutenções

- **RF-040:** Registrar manutenção de um item
- **RF-041:** Listar manutenções por item
- **RF-042:** Impedir duplicidade na mesma data
- **RF-043:** Atualizar status do item após manutenção

---

### 📊 Dashboard

- **RF-050:** Exibir resumo de itens
- **RF-051:** Mostrar itens próximos do vencimento
- **RF-052:** Mostrar itens vencidos
- **RF-053:** Permitir configuração de thresholds

---

### 🤖 Inteligência Artificial

- **RF-060:** Sugerir itens com base no tipo de empresa
- **RF-061:** Gerar resumo de dados
- **RF-062:** Assistente para dúvidas operacionais

---

### 📍 Fornecedores

- **RF-070:** Buscar fornecedores próximos via geolocalização
- **RF-071:** Exibir rating, endereço e link do Google Maps

---

### 💳 Billing / Planos

- **RF-080:** Sistema deve controlar planos por organização
- **RF-081:** Limitar funcionalidades por plano
- **RF-082:** Bloquear ações conforme status (READ_ONLY, BLOCKED)
- **RF-083:** Controlar limites (itens, usuários, IA, emails)

---

### 📩 Notificações

- **RF-090:** Enviar notificações por e-mail
- **RF-091:** Alertar itens próximos/vencidos
- **RF-092:** Notificar eventos de billing
- **RF-093:** Respeitar limite mensal de envio por plano

---

### 🔒 Área Administrativa (Private)

- **RF-100:** Validar acesso via `X-Admin-Token`
- **RF-101:** Criar organizações
- **RF-102:** Visualizar métricas do sistema

---

## 5. 🚀 Requisitos Não Funcionais (RNF)

### ⚡ Performance

- **RNF-001:** API deve responder em até 500ms (p95)
- **RNF-002:** Suportar crescimento de até 10k organizações

---

### 🔐 Segurança

- **RNF-010:** Dados devem ser isolados por tenant
- **RNF-011:** JWT deve ter expiração configurável
- **RNF-012:** Não armazenar dados sensíveis em logs
- **RNF-013:** Proteção contra acesso indevido entre tenants

---

### 📈 Escalabilidade

- **RNF-020:** Sistema deve ser stateless
- **RNF-021:** Suportar deploy em cloud (Railway/Vercel)
- **RNF-022:** Banco deve suportar crescimento horizontal futuro

---

### 🧩 Manutenibilidade

- **RNF-030:** Código deve seguir arquitetura modular (DDD)
- **RNF-031:** Uso de DTOs para comunicação externa
- **RNF-032:** Documentação via OpenAPI

---

### 📡 Observabilidade

- **RNF-040:** Logs devem conter `requestId` e `orgId`
- **RNF-041:** Integração com Sentry para erros
- **RNF-042:** Monitoramento de falhas críticas

---

### 🌐 Disponibilidade

- **RNF-050:** Disponibilidade mínima de 99%
- **RNF-051:** Sistema deve tolerar falhas de serviços externos

---

### 🎯 Usabilidade

- **RNF-060:** Interface responsiva (mobile-first)
- **RNF-061:** Feedback visual para ações bloqueadas
- **RNF-062:** UX clara para planos e limitações

---

## 6. ⚠️ Regras de Negócio Críticas

- **RN-001:** Item com manutenção não pode ser editado
- **RN-002:** Não pode haver manutenção duplicada na mesma data
- **RN-003:** Usuário sem plano ativo entra em modo READ_ONLY
- **RN-004:** Limites de plano devem ser respeitados (hard limit)
- **RN-005:** Toda requisição deve conter tenant válido

---