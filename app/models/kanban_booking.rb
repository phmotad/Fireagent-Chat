class KanbanBooking < ApplicationRecord
  STATUSES = %w[booked cancelled].freeze

  belongs_to :account
  belongs_to :kanban_schedule_rule
  belongs_to :kanban_location
  belongs_to :kanban_board
  belongs_to :kanban_card, optional: true
  belongs_to :contact

  validates :start_time, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :between_dates, ->(from, to) { where('start_time >= ? AND start_time <= ?', from, to) }
  scope :active, -> { where(status: 'booked') }

  def capacity
    kanban_schedule_rule.capacity
  end
end


