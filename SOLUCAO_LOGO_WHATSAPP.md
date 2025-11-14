# Solução para Logo SVG e WhatsApp Campaign

## Problema 1: Logo ainda usando SVG

### O que foi corrigido:
1. ✅ `config/installation_config.yml` - Atualizado para usar PNG
2. ✅ `app.json` - Atualizado para usar PNG
3. ✅ Todos os favicons copiados como PNG

### Por que ainda pode aparecer SVG:
O `globalConfig.logoThumbnail` vem do Rails através de `GlobalConfig.get('LOGO_THUMBNAIL')`, que lê do `installation_config.yml`. 

**Solução:**
1. Após o redeploy, limpe o cache do navegador (Ctrl+Shift+Delete)
2. Se ainda aparecer SVG, pode ser cache do Rails. Execute no Rails console:
   ```ruby
   GlobalConfig.find_by(name: 'LOGO_THUMBNAIL')&.update(value: '/brand-assets/logo_thumbnail.png')
   ```
3. Reinicie o serviço Rails no Coolify

## Problema 2: WhatsApp Campaign não aparece

### Causa:
O `whatsapp_campaign` precisa ser habilitado **na conta específica**, não apenas globalmente no `features.yml`.

### Solução via Rails Console:

1. Acesse o Rails console no container:
   ```bash
   docker exec -it <container_rails> bundle exec rails console
   ```

2. Encontre sua conta:
   ```ruby
   account = Account.find_by(name: 'Nome da sua conta')
   # ou
   account = Account.first
   ```

3. Verifique se o feature flag está habilitado:
   ```ruby
   account.feature_enabled?(:whatsapp_campaign)
   # Deve retornar false
   ```

4. Habilite o feature flag:
   ```ruby
   account.enable_features!(:whatsapp_campaign)
   ```

5. Verifique novamente:
   ```ruby
   account.feature_enabled?(:whatsapp_campaign)
   # Deve retornar true agora
   ```

6. Recarregue a página no navegador (Ctrl+F5 para forçar reload)

### Solução via Rake Task:

Existe uma rake task para habilitar o WhatsApp Campaign em todas as contas:

```bash
docker exec -it <container_rails> bundle exec rake enable_whatsapp_campaign
```

### Verificar todas as features da conta:

```ruby
account.all_features
# Mostra todas as features e seu status
```

### Habilitar múltiplas features:

```ruby
account.enable_features!(:whatsapp_campaign, :campaigns)
```

## Notas Importantes:

1. O `config/features.yml` apenas **define** quais features existem no sistema
2. Cada **conta** precisa ter o feature flag habilitado individualmente
3. O `whatsapp_campaign` não está na lista de `PREMIUM_FEATURES`, então não requer plano Enterprise
4. Após habilitar, pode ser necessário fazer logout e login novamente

## Verificação Final:

1. Logo PNG aparece corretamente ✅
2. WhatsApp Campaign aparece no menu de campanhas ✅
3. É possível criar campanhas WhatsApp ✅

