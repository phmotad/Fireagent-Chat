# Como Executar o Comando Corretamente

## ❌ ERRADO - Não faça isso:

Se você já está dentro do container (`/app #`), NÃO execute linha por linha. Saia primeiro.

## ✅ CORRETO - Faça assim:

### Opção 1: Executar direto (Recomendado)

**Saia do container primeiro** (digite `exit` se estiver dentro), depois execute:

```bash
docker exec -it rails-agogkcc88o480ccs8gowowkg bundle exec rake fireagent:enable_whatsapp_campaign
```

### Opção 2: Se já estiver dentro do container

Se você já está dentro do container (`/app #`), execute:

```bash
bundle exec rake fireagent:enable_whatsapp_campaign
```

**Importante:** Execute o comando completo de uma vez, não copie e cole a saída esperada!

## Exemplo Completo:

```bash
# 1. Se estiver dentro do container, saia primeiro
exit

# 2. Execute o comando completo
docker exec -it rails-agogkcc88o480ccs8gowowkg bundle exec rake fireagent:enable_whatsapp_campaign
```

## Saída Esperada:

Você deve ver algo como:

```
Habilitando WhatsApp Campaign para todas as contas...
  ✓ Habilitado para conta: Nome da Conta (ID: 1)

Concluído! WhatsApp Campaign habilitado para todas as contas.
```

## Alternativa: Via Rails Console

Se a rake task não funcionar, use o Rails console:

```bash
# Entrar no console
docker exec -it rails-agogkcc88o480ccs8gowowkg bundle exec rails console

# Dentro do console, execute (uma linha de cada vez):
account = Account.first
account.enable_features!(:whatsapp_campaign)
account.feature_enabled?(:whatsapp_campaign)
exit
```

