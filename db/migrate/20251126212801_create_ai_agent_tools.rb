class CreateAiAgentTools < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_tools do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.string :tool_type, null: false
      t.jsonb :configuration, default: {}
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end
