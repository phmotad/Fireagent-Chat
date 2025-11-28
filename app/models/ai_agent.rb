class AiAgent < ApplicationRecord
  belongs_to :account
  belongs_to :agent_bot, optional: true
  has_many :ai_agent_tools, dependent: :destroy
  has_many :ai_agent_knowledge_sources, dependent: :destroy

  validates :name, presence: true
  validates :model, presence: true
  validates :temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }
  validates :memory_window_size, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
end
