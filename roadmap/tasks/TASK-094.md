# TASK-094 — Frontend: Página /indicador/novo (cadastro de afiliado)

## Tipo
FRONTEND

## Épico
EPIC-012 — Sistema de Indicação

## Prioridade
🟠 Alto

## Fase
3 — Divulgação / Pós-Lançamento

## Descrição
Criar a página pública `/indicador/novo` onde qualquer pessoa pode se cadastrar como afiliado preenchendo nome, e-mail e WhatsApp. Após o cadastro bem-sucedido, exibir o link único gerado com botão de copiar e link para o painel de indicações.

**Dois estados:**
1. Formulário de cadastro (estado inicial)
2. Sucesso — exibe link copiável + link para `/indicador/{code}`

**Layout:** card centralizado, estilo consistente com a landing page (Bootstrap 5, navbar com logo).

## Critérios de Aceite
- [ ] Form com validação HTML5 (required, type=email)
- [ ] Erro exibido inline quando e-mail já cadastrado
- [ ] Estado de loading no botão durante submit
- [ ] Após sucesso: link exibido, botão "Copiar link" funcional (clipboard API)
- [ ] Link para `/indicador/{code}` visível após cadastro
- [ ] Página responsiva (mobile)

## Esforço
Pequeno-Médio (2-3h)

## Status
Backlog

## Dependências
TASK-091 (endpoint `POST /affiliates`)
