namespace :fireagent do
  desc 'Habilitar WhatsApp Campaign para todas as contas existentes'
  task enable_whatsapp_campaign: :environment do
    puts 'Habilitando WhatsApp Campaign para todas as contas...'
    
    Account.find_each do |account|
      unless account.feature_enabled?(:whatsapp_campaign)
        account.enable_features!(:whatsapp_campaign)
        puts "  ✓ Habilitado para conta: #{account.name} (ID: #{account.id})"
      else
        puts "  - Já habilitado para conta: #{account.name} (ID: #{account.id})"
      end
    end
    
    puts "\nConcluído! WhatsApp Campaign habilitado para todas as contas."
  end
end

