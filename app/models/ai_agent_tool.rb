class AiAgentTool < ApplicationRecord
  belongs_to :ai_agent

  validates :name, presence: true
  validates :tool_type, presence: true, inclusion: { in: %w[native http https mcp] }

  # Ensure configuration and conditions are always hashes
  before_validation :ensure_json_fields

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(tool_type: type) }

  private

  def ensure_json_fields
    self.configuration ||= {}
    self.conditions ||= {}
  end
end
