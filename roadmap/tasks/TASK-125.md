# TASK-125 — Frontend: Botão de WhatsApp na landing + atualização do número de contato

## Tipo
FRONTEND

## Categoria
Marketing / Landing / Conversão

## Prioridade
🟠 Alto

## Épico
EPIC-006 — Produto / Experiência do Usuário

## Fase
2 — Pós-lançamento

## QA obrigatório
Sim — validar que o link abre o WhatsApp corretamente com o número novo, que não sobrou nenhuma
referência ao número antigo, e que o botão aparece de forma consistente (desktop/mobile).

---

## Contexto e motivação

Pedido do Douglas em 15/07/2026: trocar o número de WhatsApp usado na aplicação e adicionar um botão de
WhatsApp na landing page.

Levantamento feito antes de abrir o card (`easy-maintenance-web/src/app/landing/page.tsx`):

- O número atual (**`5531995639390`** / **`(31) 99563-9390`**) aparece em **apenas 2 lugares, no mesmo
  arquivo**:
  - Linha 331: link `href="https://wa.me/5531995639390"` no CTA "Falar com Consultor" (fim da landing).
  - Linha 362: texto `WhatsApp: (31) 99563-9390` no rodapé — **hoje é só um `<p>`, sem `href`, não é
    clicável**.
- Já existe uma classe CSS **`.whatsapp-float`** definida no `<style jsx>` do próprio arquivo (ícone verde
  `#25d366`, `position: fixed`, círculo) que **não está sendo usada em nenhum elemento do JSX** — parece
  ter sido copiada de algum template para um botão flutuante que nunca foi implementado. É o candidato
  natural a reaproveitar para o botão pedido, em vez de criar um componente novo do zero.
- Não há nenhum outro telefone/link de WhatsApp hardcoded em nenhum outro lugar do frontend ou do backend
  (`/help` só tem e-mail). Ou seja, a troca do número fica contida neste único arquivo.
- **Não confundir com a TASK-122** (canal de notificações via WhatsApp para usuários logados — ainda só
  um esqueleto, `WhatsAppNotificationProvider` com TODO). Este card é sobre o botão de **contato
  comercial na landing pública**, feature completamente separada.

### Número novo
`(31) 9 9982-6634` — confirmado com Douglas em 15/07/2026. Formato E.164 para o link:
`https://wa.me/5531999826634`.

### Mensagem pré-preenchida do link
Ainda não definida — Douglas vai passar o texto a ser usado no parâmetro `?text=` do link do WhatsApp.
Não bloqueia a criação do card, mas bloqueia fechar a implementação.

---

## Escopo

### Frontend (`easy-maintenance-web/src/app/landing/page.tsx`)

- Trocar as 2 ocorrências do número antigo pelo número novo (CTA "Falar com Consultor" + texto do
  rodapé).
- Transformar o texto do rodapé em link clicável (hoje é texto puro).
- Ativar o botão flutuante reaproveitando a classe `.whatsapp-float` já existente no arquivo — ícone fixo
  visível durante o scroll da landing, aponta para o mesmo link `wa.me` com o número novo.
- Incluir a mensagem pré-preenchida (`?text=`) assim que definida com Douglas.

### Fora de escopo da v1

- Qualquer botão de WhatsApp fora da landing pública (área logada do app não tem e não é o pedido).
- Canal de notificações via WhatsApp para usuários (TASK-122 — feature não relacionada).
- Redirecionamento/aviso para quem já tinha o número antigo salvo (fora do escopo técnico deste card).

### QA / Testes

- Manual: clicar no botão flutuante e no CTA do rodapé, confirmar que abre o WhatsApp (Web/App) com o
  número novo e a mensagem pré-preenchida; conferir em mobile e desktop; garantir que não sobrou nenhuma
  referência ao número antigo no código.

---

## Arquivos impactados (estimativa)

### Frontend
- `src/app/landing/page.tsx` — únicos pontos de mudança (link do CTA, texto do rodapé, ativação do
  `.whatsapp-float`)

## Critérios de Aceite

- [x] Botão de WhatsApp visível e clicável na landing (reaproveitando `.whatsapp-float` ou padrão visual
      equivalente aprovado)
- [x] Número atualizado para `(31) 9 9982-6634` (`wa.me/5531999826634`) em todas as ocorrências da landing
- [x] Texto do rodapé também vira link clicável (hoje é só `<p>`, sem `href`)
- [x] Link abre corretamente o WhatsApp com o número novo (testado manualmente)
- [x] Nenhuma referência ao número antigo (`5531995639390` / `(31) 99563-9390`) remanescente no código
- [x] Mensagem pré-preenchida incluída no link, conforme texto definido com Douglas

## Dependências
- ~~Confirmar com Douglas o formato completo do número novo~~ — confirmado: `(31) 9 9982-6634`.
- ~~Definir com Douglas a mensagem pré-preenchida~~ — confirmado (tom casual/consultivo):
  "Olá, tudo bem? Vi a Easy Maintenance no site e quero entender como ela pode ajudar na gestão de
  manutenção do meu condomínio/empresa."

## Riscos
Baixo tecnicamente — mudança isolada em um único arquivo de frontend, sem impacto em backend/dados/outros
fluxos. Risco de negócio (fora do escopo técnico): se o número antigo já vinha recebendo mensagens de
clientes, avaliar separadamente se precisa de algum aviso/transição.

## Esforço
Baixo — troca de texto/link + ativação de um botão flutuante com CSS já existente.

## Status
Em Validação

## Implementação (15/07/2026)

Branch `feature/TASK-125` criada a partir de `staging` (só `easy-maintenance-web` — nenhuma outra
ocorrência do número foi encontrada no backend nem em outros arquivos do frontend).

- Número/mensagem centralizados em 3 constantes no topo de `landing/page.tsx`
  (`WHATSAPP_NUMBER`/`WHATSAPP_MESSAGE`/`WHATSAPP_LINK`), evitando duplicar o link em 3 lugares.
- CTA "Falar com Consultor" e o texto do rodapé agora usam `WHATSAPP_LINK`; rodapé virou link clicável
  (`<a>` em vez de `<p>`); `rel="noopener noreferrer"` adicionado nos `target="_blank"`.
- Botão flutuante ativado reaproveitando a classe `.whatsapp-float` (já existia no CSS, nunca usada) +
  ícone SVG inline (sem depender de `bootstrap-icons`, que não está importado no projeto).
- `eslint` limpo, `next build` (produção) sem erros.
- Verificado no browser (dev server local, `/landing` não depende do backend para renderizar): botão
  flutuante visível, ícone renderiza corretamente; os 3 links (flutuante, CTA, rodapé) confirmados via
  accessibility tree apontando para `https://wa.me/5531999826634?text=...` com a mensagem corretamente
  URL-encoded. Nenhuma referência ao número antigo restante (`grep` confirmou).
