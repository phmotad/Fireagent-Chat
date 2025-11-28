class CreateAiAgentInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_inboxes do |t|
      t.references :ai_agent, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    # Ensure unique combination of ai_agent and inbox
    add_index :ai_agent_inboxes, [:ai_agent_id, :inbox_id], unique: true
  end
end
