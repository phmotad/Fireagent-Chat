class CreateFireagentBot < ActiveRecord::Migration[7.0]
  def up
    return if AgentBot.find_by(name: 'FireAgent AI')

    AgentBot.create!(
      name: 'FireAgent AI',
      description: 'Agente de IA integrado com Google Gemini e FireAgent Brain',
      outgoing_url: 'http://fireagent-brain:8000/webhook',
      bot_type: :webhook
    )
  end

  def down
    AgentBot.find_by(name: 'FireAgent AI')&.destroy
  end
end
