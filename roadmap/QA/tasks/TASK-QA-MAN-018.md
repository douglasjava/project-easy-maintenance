# TASK-QA-MAN-018 — QA Manual: EPIC-027 (Chamados de Moradores)

## Tipo
QA Manual

## Categoria
Full-Stack / Notificações, Multi-tenant, Novo módulo público

## Prioridade
🟠 Alto

## Tasks cobertas
[TASK-237](../../tasks/TASK-237.md) / [TASK-238](../../tasks/TASK-238.md) / [TASK-239](../../tasks/TASK-239.md) / [TASK-240](../../tasks/TASK-240.md) — [EPIC-027](../../epics/EPIC-027.md)

---

## Descrição

Valida o fluxo completo de chamados de moradores: abertura pública (sem login), consulta por CPF,
kanban interno com drag-and-drop, notificação por e-mail e QR code. Toda a implementação está na
branch `feature/EPIC-027-resident-tickets` (nos dois repos, `easy-maintenance-api` e
`easy-maintenance-web`), sem PR aberta ainda.

Já validado numa rodada de QA anterior, num ambiente local isolado (não o seu): fluxo público
completo, kanban, drag-and-drop (via evento sintético — o gesto de mouse do automation tool não
ativa o `PointerSensor` do dnd-kit, então usei `PointerEvent` disparado via JS pra confirmar que o
`PATCH` real disparava e persistia) e QR code. **O que não deu pra validar sem o seu ambiente**:
upload de foto contra S3 real (usei credenciais AWS fake) e drag-and-drop com mouse de verdade —
os dois cenários mais importantes pra você confirmar aqui.

Achado real nessa rodada, já corrigido: existe um `TenantFilter` (separado do `SecurityConfig`) que
também exige `X-Org-Id` em toda rota por padrão — bloqueava os 3 endpoints públicos com 400 antes
mesmo de chegar no controller. Corrigido, adicionado ao bypass.

---

## Pré-condições

- Checkout de `feature/EPIC-027-resident-tickets` nos dois repos, API e frontend rodando local
  (perfil `local`) nas suas portas de sempre.
- Migration `V108__create_resident_tickets.sql` aplica sozinha no boot (Flyway) — nada manual aqui.
- MailHog rodando (padrão do perfil local) — necessário pro C7 (e-mail de novo chamado).
- Não precisa criar organização/usuário novo pra maioria dos cenários — dá pra usar sua própria
  conta/organização de teste de sempre. Só o C10 (isolamento multi-tenant) precisa de uma segunda
  organização, com setup mínimo abaixo.

⚠️ Se criar dado novo, prefixe com `QA-EPIC027-*` — sintético, seguro de rodar local/dev. **Não
rodar contra staging/produção.**

---

## Cenários de Teste

### C1 — Suítes automatizadas, sem regressão

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | `mvn test` na branch `feature/EPIC-027-resident-tickets` (`easy-maintenance-api`) | **935/935** |
| 2 | `npm run build` e `npm test` na branch equivalente (`easy-maintenance-web`) | Build limpo; jest sem regressão nova (3 falhas em `middleware.test.ts` são pré-existentes, não relacionadas) |

Já executado e confirmado durante a implementação.

---

### C2 — Pegar o código da sua organização de teste

```sql
SELECT code, name FROM organizations WHERE deleted_at IS NULL ORDER BY id DESC LIMIT 5;
```

Anote o `code` da organização que você vai usar pra logar (vai virar `<ORG_CODE>` nos passos
abaixo). Sua conta de ADMIN de sempre nessa organização já serve pro C8/C9/C11 — não precisa criar
usuário novo.

---

### C3 — Abrir chamado público sem foto

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Acessar `http://localhost:3000/c/<ORG_CODE>` (sem estar logado — vale abrir numa aba anônima) | Tela só com campo de CPF, sem sidebar/navbar interna |
| 2 | Informar um CPF válido (ex.: `529.982.247-25`) e clicar "Entrar" | Avança pra "Meus chamados", lista vazia (ou os que já existirem desse CPF) |
| 3 | Clicar "Abrir novo chamado", preencher nome/telefone/descrição, **sem** anexar foto, enviar | Toast "Chamado aberto com sucesso!", chamado aparece na lista com status "Solicitado" |
| 4 | Recarregar a página (`/c/<ORG_CODE>/chamados`) | Chamado continua na lista (persistido, não é só estado local) |

---

### C4 — Abrir chamado com foto (upload real ao S3) — **o mais importante pra você confirmar**

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Repetir o fluxo do C3, dessa vez anexando uma foto (JPEG/PNG/WEBP, poucos MB) | Upload completa sem erro, chamado é criado |
| 2 | Conferir no S3 (console AWS ou `aws s3 ls`) o objeto em `resident-tickets/<ORG_CODE>/...` | Arquivo presente, tamanho/tipo batem com o que foi enviado |
| 3 | No painel interno (`/resident-tickets`, ver C8), abrir o chamado com foto | Foto aparece renderizada no card |
| 4 | Tentar anexar um arquivo não-imagem (ex. `.pdf`) | Rejeitado — mensagem de erro clara, chamado não é criado sem foto válida |
| 5 | Tentar anexar uma imagem grande (acima de 5MB) | Rejeitado — mensagem de tamanho máximo excedido |

---

### C5 — Organização inválida

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Acessar `http://localhost:3000/c/00000000-0000-0000-0000-000000000000` (UUID que não existe) | Tela mostra erro claro, não quebra/branco |

---

### C6 — Consulta por CPF differente não vaza chamado de outro morador

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Voltar em `/c/<ORG_CODE>`, entrar com um CPF **diferente** do usado no C3/C4 | Lista vazia — nenhum chamado do outro CPF aparece |

---

### C7 — E-mail pro ADMIN ao abrir chamado

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Confirmar que seu usuário de teste (o do C2) tem `role = ADMIN` na organização | — |
| 2 | Repetir a abertura de um chamado (C3 ou C4) | — |
| 3 | Abrir MailHog (`http://localhost:8025`) | E-mail "Novo chamado de morador — <nome da organização>" chegou pro seu e-mail de ADMIN, com a descrição do chamado no corpo |
| 4 | (Opcional) Repetir com um usuário `role != ADMIN` na mesma organização | Esse usuário **não** recebe o e-mail — só ADMINs |

---

### C8 — Painel interno: kanban carrega os chamados certos

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Logado como ADMIN da organização do C2, acessar `/resident-tickets` (item "Chamados" no menu lateral) | Kanban com 3 colunas (Solicitado / Em andamento / Concluído), chamados dos C3/C4 aparecem na coluna "Solicitado" |

---

### C9 — Drag-and-drop com mouse de verdade

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Arrastar um card de "Solicitado" pra "Em andamento" | Card muda de coluna visualmente, contadores das colunas atualizam |
| 2 | Recarregar a página | Card continua em "Em andamento" (persistido via `PATCH`, não é só estado local) |
| 3 | Arrastar o mesmo card de "Em andamento" pra "Concluído" | Mesmo comportamento — persiste |
| 4 | (Regressão) Abrir o DevTools → Network durante o drag | `PATCH /resident-tickets/{id}/status` com o novo status, resposta 200 |

---

### C10 — Isolamento multi-tenant (precisa de uma segunda organização)

Setup mínimo — rode só se você não tiver uma segunda organização de teste à mão:

```sql
INSERT INTO organizations (code, name, city, state, require_2fa)
VALUES (UUID(), 'QA EPIC027 Org B', 'Rio de Janeiro', 'RJ', 0);

SELECT code FROM organizations WHERE name = 'QA EPIC027 Org B' ORDER BY id DESC LIMIT 1;
```
Anote o `code` retornado (`<ORG_CODE_B>`) — não precisa de usuário novo pra este cenário, só a
organização em si.

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Abrir um chamado em `/c/<ORG_CODE_B>` com um CPF qualquer | Chamado criado normalmente, vinculado à Org B |
| 2 | Logado como ADMIN da organização do C2 (Org A), acessar `/resident-tickets` | Chamado da Org B **não aparece** — só os da Org A |
| 3 | Trocar pra Org B no seletor de organização (se sua conta tiver acesso) ou logar como ADMIN da Org B | Vê o chamado da Org B, não os da Org A |

Limpeza:
```sql
DELETE FROM resident_tickets WHERE organization_id = (SELECT id FROM organizations WHERE name = 'QA EPIC027 Org B');
DELETE FROM organizations WHERE name = 'QA EPIC027 Org B';
```

---

### C11 — QR code

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Acessar `/organizations/<ORG_CODE>` (Configurações da sua organização) | Nova seção "QR Code — Chamados de Moradores", QR renderizado, URL abaixo dele mostra `.../c/<ORG_CODE>` |
| 2 | Clicar "Baixar QR code" | Arquivo `qrcode-chamados-<ORG_CODE>.png` baixado |
| 3 | Escanear o QR (celular real, se disponível) ou colar a URL mostrada num navegador | Abre a tela de CPF do C3 |

---

### C12 (opcional) — Rate limit dos endpoints públicos

| Passo | Ação | Resultado esperado |
|-------|------|---------------------|
| 1 | Abrir 6 chamados seguidos rapidamente no mesmo `/c/<ORG_CODE>` (limite: 5 por IP a cada 10 min) | A 6ª tentativa retorna 429, com header `Retry-After` |
| 2 | Consultar por CPF 21 vezes seguidas (limite: 20 por IP a cada 10 min) | A 21ª retorna 429 |

Baixa prioridade — mecanismo (`RateLimiterService`) já é reaproveitado de auth/reset/IA, sem
mudança nele. Vale só como confirmação de que a config nova (`resident-ticket-create`,
`resident-ticket-query`, `resident-ticket-upload-url`) está ligada certa.

---

## Limpeza (dados sintéticos do C10, se criados)

Já incluída na seção C10 acima. C3/C4/C6/C7 usam sua organização real — se quiser remover os
chamados de teste depois:

```sql
DELETE FROM resident_tickets WHERE organization_id = (SELECT id FROM organizations WHERE code = '<ORG_CODE>')
  AND resident_name IN ('<nome usado no teste>');
```

---

## Critérios de Aceite da Suíte

- [ ] C1: suítes automatizadas sem regressão (backend + frontend)
- [ ] C2: código da organização de teste obtido
- [ ] C3: chamado sem foto — abre, lista, persiste
- [ ] C4: chamado com foto — upload S3 real confirmado, rejeição de tipo/tamanho inválido
- [ ] C5: organização inválida — erro claro
- [ ] C6: isolamento por CPF — sem vazamento entre moradores
- [ ] C7: e-mail chega pro ADMIN no MailHog, só pra ADMIN
- [ ] C8: kanban carrega os chamados certos
- [ ] C9: drag-and-drop com mouse real — persiste após reload
- [ ] C10: isolamento multi-tenant — org B não vaza pra org A
- [ ] C11: QR code renderiza, aponta pra URL certa, download funciona
- [ ] C12 (opcional): rate limit dispara depois do limite configurado

## Status
🔴 Não executada — aguardando Douglas rodar localmente.
