# Solução para Erro 500 "We're sorry, but something went wrong"

## Problema

O erro ocorria porque `@global_config['LOGO_THUMBNAIL']` estava retornando `nil` em alguns casos, causando um erro quando usado diretamente em templates ERB sem fallback.

## Causa

O `GlobalConfig.get('LOGO_THUMBNAIL')` pode retornar `nil` se:
1. O `InstallationConfig` ainda não foi criado no banco de dados
2. O valor não foi inicializado corretamente
3. Há um problema de cache do Redis

## Solução Aplicada

Adicionamos fallbacks seguros em todos os lugares onde `LOGO_THUMBNAIL` é usado:

### Arquivos Corrigidos:

1. **`app/views/layouts/vueapp.html.erb`**
   ```erb
   <!-- Antes -->
   <link rel="icon" type="image/png" sizes="512x512" href="<%= @global_config['LOGO_THUMBNAIL'] %>">
   
   <!-- Depois -->
   <link rel="icon" type="image/png" sizes="512x512" href="<%= @global_config['LOGO_THUMBNAIL'] || '/brand-assets/logo_thumbnail.png' %>">
   ```

2. **`app/views/public/api/v1/portals/_footer.html.erb`**
   ```erb
   <!-- Antes -->
   <img src="<%= @global_config['LOGO_THUMBNAIL'] %>" />
   
   <!-- Depois -->
   <img src="<%= @global_config['LOGO_THUMBNAIL'] || '/brand-assets/logo_thumbnail.png' %>" />
   ```

## Verificação e Correção Manual

Se o erro persistir após o redeploy, execute no Rails console:

```ruby
# Verificar se o LOGO_THUMBNAIL existe
config = InstallationConfig.find_by(name: 'LOGO_THUMBNAIL')
puts config.inspect

# Se não existir, criar/atualizar
if config.nil?
  InstallationConfig.create!(
    name: 'LOGO_THUMBNAIL',
    value: '/brand-assets/logo_thumbnail.png',
    locked: true
  )
else
  config.update(value: '/brand-assets/logo_thumbnail.png')
end

# Limpar cache do Redis
GlobalConfig.clear_cache
```

## Verificação de Outros Valores

Verifique se outros valores do `installation_config.yml` estão no banco:

```ruby
# Listar todas as configurações
InstallationConfig.all.each do |config|
  puts "#{config.name}: #{config.value}"
end

# Verificar configurações importantes
['LOGO_THUMBNAIL', 'LOGO', 'LOGO_DARK', 'BRAND_NAME', 'INSTALLATION_NAME'].each do |key|
  config = InstallationConfig.find_by(name: key)
  puts "#{key}: #{config ? config.value : 'MISSING'}"
end
```

## Inicialização Completa

Se muitos valores estiverem faltando, você pode inicializar todos de uma vez:

```ruby
# Carregar do installation_config.yml
require 'yaml'
config_file = Rails.root.join('config/installation_config.yml')
configs = YAML.safe_load(File.read(config_file))

configs.each do |config_data|
  name = config_data['name']
  value = config_data['value']
  
  existing = InstallationConfig.find_by(name: name)
  if existing
    existing.update(value: value) unless existing.value == value
    puts "✓ Atualizado: #{name}"
  else
    InstallationConfig.create!(
      name: name,
      value: value,
      locked: true
    )
    puts "✓ Criado: #{name}"
  end
end

# Limpar cache
GlobalConfig.clear_cache
```

## Próximos Passos

1. ✅ Correções aplicadas e commitadas
2. ⏳ Reconstruir imagem Docker
3. ⏳ Fazer push para GHCR
4. ⏳ Redeploy no Coolify
5. ⏳ Verificar se o erro foi resolvido

## Logs para Debug

Se o erro persistir, verifique os logs:

```bash
# Logs do Rails
docker logs <container_rails> --tail 100

# Logs do Sidekiq
docker logs <container_sidekiq> --tail 100

# Verificar erros específicos
docker logs <container_rails> 2>&1 | grep -i error
```

