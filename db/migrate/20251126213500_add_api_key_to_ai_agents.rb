class AddApiKeyToAiAgents < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :api_key, :string
  end
end
