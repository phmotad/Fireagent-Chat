class AiAgentTool < ApplicationRecord
  belongs_to :ai_agent

  validates :name, presence: true
  validates :tool_type, presence: true, inclusion: { in: %w[chatwoot mcp custom] }
  validates :configuration, presence: true
end
