# Como Encontrar o Nome do Container Rails

## Opção 1: Via Coolify (Recomendado)

No Coolify, você pode executar comandos diretamente na interface:

1. Acesse o serviço **rails** no Coolify
2. Vá para a aba **"Terminal"** ou **"Console"**
3. Execute o comando diretamente:
   ```bash
   bundle exec rake fireagent:enable_whatsapp_campaign
   ```

## Opção 2: Via Docker (Local ou no Servidor)

### Passo 1: Listar todos os containers

```bash
docker ps
```

Isso mostrará algo como:
```
CONTAINER ID   IMAGE                                    STATUS         NAMES
abc123def456   ghcr.io/phmotad/fireagent-chat:latest   Up 2 hours     coolify_rails_abc123
def456ghi789   ghcr.io/phmotad/fireagent-chat:latest   Up 2 hours     coolify_sidekiq_def456
...
```

### Passo 2: Identificar o container Rails

Procure pelo container que:
- Usa a imagem `ghcr.io/phmotad/fireagent-chat:latest`
- Tem "rails" no nome (geralmente `coolify_rails_...` ou similar)
- Está rodando na porta 3000 (se você ver os ports)

### Passo 3: Usar o nome ou ID do container

Você pode usar **qualquer um** dos dois:

**Usando o NOME do container:**
```bash
docker exec -it coolify_rails_abc123 bundle exec rake fireagent:enable_whatsapp_campaign
```

**Usando o ID do container:**
```bash
docker exec -it abc123def456 bundle exec rake fireagent:enable_whatsapp_campaign
```

## Opção 3: Via Docker Compose (Se estiver usando)

Se você estiver usando Docker Compose diretamente:

```bash
cd /caminho/do/docker-compose
docker-compose exec rails bundle exec rake fireagent:enable_whatsapp_campaign
```

## Exemplo Completo

```bash
# 1. Listar containers
docker ps

# 2. Copiar o nome/ID do container rails (exemplo: coolify_rails_xyz789)
# 3. Executar o comando
docker exec -it coolify_rails_xyz789 bundle exec rake fireagent:enable_whatsapp_campaign
```

## Alternativa: Via Rails Console

Se preferir fazer manualmente via Rails Console:

```bash
# 1. Entrar no console do Rails
docker exec -it <container_rails> bundle exec rails console

# 2. Dentro do console, executar:
account = Account.first  # ou Account.find_by(name: 'Nome da sua conta')
account.enable_features!(:whatsapp_campaign)
account.feature_enabled?(:whatsapp_campaign)  # Deve retornar true
exit
```

## Dica: Criar um Alias (Opcional)

Para facilitar, você pode criar um alias no seu shell:

```bash
# No Linux/Mac
alias rails-exec='docker exec -it $(docker ps --filter "ancestor=ghcr.io/phmotad/fireagent-chat:latest" --filter "name=rails" --format "{{.Names}}" | head -1)'

# Depois usar:
rails-exec bundle exec rake fireagent:enable_whatsapp_campaign
```

## Verificar se Funcionou

Após executar o comando, você deve ver uma saída como:

```
Habilitando WhatsApp Campaign para todas as contas...
  ✓ Habilitado para conta: Minha Conta (ID: 1)

Concluído! WhatsApp Campaign habilitado para todas as contas.
```

