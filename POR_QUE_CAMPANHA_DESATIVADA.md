# Por Que a Campanha WhatsApp Estava Desativada?

## Como Funciona o Sistema de Feature Flags do Chatwoot

O Chatwoot usa um sistema de **feature flags** em dois níveis:

### 1. Nível Global (`config/features.yml`)
- Define quais features **existem** no sistema
- O `whatsapp_campaign` está definido aqui como `enabled: true`
- Isso significa que a feature está **disponível** no sistema

### 2. Nível de Conta (Account)
- Cada **conta** precisa ter o feature flag habilitado **individualmente**
- Quando uma conta é criada, ela usa `ACCOUNT_LEVEL_FEATURE_DEFAULTS` para habilitar features padrão
- O `whatsapp_campaign` **não estava** na lista de defaults

## Por Que Não Estava Habilitado?

### Motivos:

1. **Conta criada antes da feature ser adicionada**
   - Se sua conta foi criada antes de habilitarmos o `whatsapp_campaign` no `features.yml`, ela não foi habilitada automaticamente

2. **Não está nos defaults**
   - O `whatsapp_campaign` não está configurado em `ACCOUNT_LEVEL_FEATURE_DEFAULTS`
   - Apenas features essenciais são habilitadas por padrão (como `campaigns`, `inbox_management`, etc.)

3. **Feature relativamente nova**
   - O WhatsApp Campaign é uma feature mais recente
   - Por padrão, features novas não são habilitadas automaticamente para contas existentes

## Como Funciona o `enable_default_features`

Quando uma nova conta é criada, o sistema executa:

```ruby
def enable_default_features
  config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
  return true if config.blank?
  
  features_to_enabled = config.value.select { |f| f[:enabled] }.pluck(:name)
  enable_features(*features_to_enabled)
end
```

Isso significa que apenas features listadas em `ACCOUNT_LEVEL_FEATURE_DEFAULTS` são habilitadas automaticamente.

## Solução Aplicada

A rake task `fireagent:enable_whatsapp_campaign` habilita o feature flag para **todas as contas existentes**, garantindo que:

1. ✅ Contas antigas recebem a feature
2. ✅ Contas novas também podem receber (se adicionarmos aos defaults)
3. ✅ Não precisa habilitar manualmente para cada conta

## Para Habilitar Automaticamente em Contas Novas

Se quiser que contas futuras tenham o WhatsApp Campaign habilitado automaticamente, você pode:

1. Adicionar aos defaults via Rails console:
   ```ruby
   config = InstallationConfig.find_or_create_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
   defaults = config.value || []
   defaults << { name: 'whatsapp_campaign', enabled: true } unless defaults.any? { |f| f[:name] == 'whatsapp_campaign' }
   config.update(value: defaults)
   ```

2. Ou adicionar via Super Admin (se disponível)

## Resumo

- **Não estava desativado por erro** - é o comportamento padrão do Chatwoot
- **Feature flags precisam ser habilitados por conta** - por design de segurança e controle
- **Agora está habilitado** - a rake task resolveu para todas as contas existentes
- **Contas futuras** - podem precisar de configuração adicional se quiser habilitar automaticamente

