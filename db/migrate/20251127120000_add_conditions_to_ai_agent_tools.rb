class AddConditionsToAiAgentTools < ActiveRecord::Migration[7.0]
  def change
    # Add conditions field for configurable tool execution criteria
    add_column :ai_agent_tools, :conditions, :jsonb, default: {}

    # Add index for faster queries on enabled tools
    add_index :ai_agent_tools, :enabled
    add_index :ai_agent_tools, :tool_type
  end
end
