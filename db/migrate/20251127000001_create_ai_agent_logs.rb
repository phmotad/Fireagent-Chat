class CreateAiAgentLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_logs do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.integer :conversation_id, null: false
      t.text :user_message
      t.text :ai_response
      t.string :action_taken
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :ai_agent_logs, :conversation_id
  end
end
