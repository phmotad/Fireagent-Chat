class AddConditionsToAiAgentTools < ActiveRecord::Migration[7.0]
  def change
    # Add conditions field for configurable tool execution criteria
    add_column :ai_agent_tools, :conditions, :jsonb, default: {}
  end
end
