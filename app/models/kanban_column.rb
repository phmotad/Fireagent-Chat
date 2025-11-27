# == Schema Information
#
# Table name: kanban_columns
#
#  id             :bigint           not null, primary key
#  name           :string           not null
#  position       :integer           default(0)
#  color          :string           default("#3B82F6")
#  wip_limit      :integer
#  settings       :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kanban_board_id :bigint           not null
#
# Indexes
#
#  index_kanban_columns_on_kanban_board_id  (kanban_board_id)
#

class KanbanColumn < ApplicationRecord
  belongs_to :kanban_board

  has_many :kanban_cards, -> { order(:position) }, dependent: :destroy_async

  validates :name, presence: true
  validates :kanban_board_id, presence: true
  validates :wip_limit, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:position, :created_at) }

  before_validation :set_defaults

  def set_defaults
    self.position ||= 0
    self.color ||= '#3B82F6'
    self.settings ||= {}
  end

  def cards_count
    kanban_cards.count
  end

  def wip_limit_reached?
    return false unless wip_limit

    cards_count >= wip_limit
  end

  # Configuração de labels a serem aplicadas quando um card é movido para esta coluna
  def auto_assign_labels
    settings['auto_assign_labels'] || []
  end

  def auto_assign_labels=(labels)
    self.settings ||= {}
    self.settings['auto_assign_labels'] = Array(labels).compact
  end

  def on_enter_actions
    Array(settings['on_enter'])
  end

  def on_exit_actions
    Array(settings['on_exit'])
  end
end

