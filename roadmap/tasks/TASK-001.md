# TASK-001 — Persistir chaves RSA JWT

## Tipo
Segurança / Débito técnico

## Categoria
Backend / Segurança

## Prioridade
🔴 Crítico

## Fase
1 — Antes do lançamento

## Épico
EPIC-001 — Segurança Crítica

## Descrição
As chaves RSA usadas para assinar e verificar tokens JWT são geradas em memória a cada inicialização da aplicação (`KeyPairGenerator.generateKeyPair()` em `AuthorizationServerConfig.java`). Isso significa que cada restart do servidor invalida todos os tokens emitidos anteriormente.

## Problema
Todo deploy, reinicialização ou crash do servidor força logout de todos os usuários ativos. Em produção com Railway (que reinicia em deploys), isso acontece a cada publicação de nova versão.

## Impacto
- Todos os usuários são deslogados a cada deploy
- Sessões ativas são destruídas sem aviso
- Impossibilita escalonamento horizontal (múltiplas instâncias com chaves diferentes)
- Refresh tokens se tornam inválidos ao reiniciar

## Dependências
- Nenhuma

## Critérios de Aceite
- [ ] Par RSA é carregado de variável de ambiente ou secret manager, não gerado em memória
- [ ] Restart da aplicação NÃO invalida tokens existentes
- [ ] Token emitido antes de um restart ainda é aceito após o restart
- [ ] Chave não está hardcoded em nenhum arquivo versionado
- [ ] Documentação de como configurar a variável de ambiente da chave

## Subtasks
- [x] Criar `RsaKeyGenerator.java` — utilitário standalone para gerar e imprimir as chaves
- [x] Criar variáveis `jwt.rsa.private-key` e `jwt.rsa.public-key` em `application.properties`
- [x] Modificar `AuthorizationServerConfig.java` para carregar do environment via `@Value`
- [x] Key ID derivado deterministicamente (SHA-256 da chave pública) — estável entre restarts
- [x] Fallback com aviso explícito para dev (ephemeral key quando env vars não estão configuradas)
- [ ] **Ação necessária:** Executar `RsaKeyGenerator` e configurar env vars no Railway
- [ ] **Ação necessária:** Testar restart sem perda de sessão em staging

## Como gerar as chaves (executar uma vez por ambiente)
```bash
cd easy-maintenance-api
mvn exec:java -Dexec.mainClass="com.brainbyte.easy_maintenance.shared.security.RsaKeyGenerator"
```
Copiar os valores impressos e configurar no Railway como variáveis de ambiente:
- `JWT_RSA_PRIVATE_KEY` — chave privada (manter secreta)
- `JWT_RSA_PUBLIC_KEY` — chave pública

## Arquivos alterados
- `config/AuthorizationServerConfig.java` — carrega do env, deriva kid, fallback dev
- `resources/application.properties` — adicionadas propriedades `jwt.rsa.*`
- `shared/security/RsaKeyGenerator.java` — novo utilitário gerador

## Esforço
Pequeno (2-4h)

## Risco de não fazer
Cada deploy em produção desloga todos os usuários simultaneamente. Inaceitável para um SaaS com clientes ativos.

## Status
Concluído
