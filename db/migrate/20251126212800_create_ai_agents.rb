class CreateAiAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agents do |t|
      t.string :name, null: false
      t.text :description
      t.text :system_prompt
      t.string :model, default: 'gemini-2.5'
      t.float :temperature, default: 0.7
      t.integer :memory_window_size, default: 10
      t.references :account, null: false, foreign_key: true
      t.references :agent_bot, foreign_key: true
      t.jsonb :settings, default: {}

      t.timestamps
    end
  end
end
