class KanbanLocation < ApplicationRecord
  belongs_to :account

  has_many :kanban_schedule_rules, dependent: :destroy
  has_many :kanban_bookings, dependent: :destroy

  validates :name, presence: true
  validates :max_capacity, numericality: { greater_than: 0 }, allow_nil: true

  def capacity
    max_capacity || settings&.dig('default_capacity')
  end
end


