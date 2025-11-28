class AiAgent < ApplicationRecord
  belongs_to :account
  has_many :ai_agent_tools, dependent: :destroy
  has_many :ai_agent_knowledge_sources, dependent: :destroy
  has_many :ai_agent_inboxes, dependent: :destroy
  has_many :inboxes, through: :ai_agent_inboxes

  validates :name, presence: true
  validates :model, presence: true
  validates :temperature, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }
  validates :memory_window_size, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
end
