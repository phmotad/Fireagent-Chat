class AiAgentKnowledgeSource < ApplicationRecord
  belongs_to :ai_agent
  has_one_attached :document

  validates :file_path, presence: true
  validates :status, inclusion: { in: %w[pending processing ready error failed] }
end
