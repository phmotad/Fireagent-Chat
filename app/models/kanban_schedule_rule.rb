class KanbanScheduleRule < ApplicationRecord
  RULE_TYPES = %w[once weekly].freeze

  belongs_to :account
  belongs_to :kanban_board
  belongs_to :kanban_column, optional: true
  belongs_to :kanban_location

  has_many :kanban_bookings, dependent: :destroy

  validates :title, presence: true
  validates :rule_type, inclusion: { in: RULE_TYPES }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }

  def capacity
    max_capacity_override || kanban_location.capacity
  end
end


