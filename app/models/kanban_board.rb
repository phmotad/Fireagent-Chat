# == Schema Information
#
# Table name: kanban_boards
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :text
#  board_type  :string           default("custom")
#  settings    :jsonb
#  position    :integer           default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  created_by_id :bigint
#
# Indexes
#
#  index_kanban_boards_on_account_id  (account_id)
#  index_kanban_boards_on_created_by_id (created_by_id)
#

class KanbanBoard < ApplicationRecord
  include AccountCacheRevalidator

  BOARD_TYPES = %w[sales_funnel scheduling classes custom].freeze

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :kanban_columns, -> { order(:position) }, dependent: :destroy_async
  has_many :kanban_cards, dependent: :destroy_async

  validates :name, presence: true
  validates :board_type, inclusion: { in: BOARD_TYPES }
  validates :account_id, presence: true

  scope :ordered, -> { order(:position, :created_at) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  CARD_ENTITY_TYPES = %w[conversation contact].freeze

  validates :card_entity_type, inclusion: { in: CARD_ENTITY_TYPES }

  before_validation :set_defaults

  def set_defaults
    self.board_type ||= 'custom'
    self.position ||= 0
    self.settings ||= {}
    self.card_entity_type ||= 'conversation'
  end

  def archived?
    archived_at.present?
  end

  def archive!
    return if archived?

    update!(archived_at: Time.current)
    
    # Agendar job para deletar após 30 dias
    begin
      Kanban::DeleteArchivedBoardJob.set(wait: 30.days).perform_later(id)
    rescue StandardError => e
      Rails.logger.error("[KanbanBoard#archive!] Failed to enqueue DeleteArchivedBoardJob: #{e.class} - #{e.message}")
      # Não falha o arquivamento se o job não puder ser agendado
    end
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def default_columns
    # Delegate to Templates to avoid duplication and keep defaults in one place
    if defined?(Kanban::Templates)
      Kanban::Templates.columns_for(self)
    else
      []
    end
  end

  private

  def ensure_default_schedule_rule
    Kanban::EnsureDefaults.new(account, preferred_board: self).call
  rescue StandardError => e
    Rails.logger.error("[KanbanBoard] Failed to ensure default schedule rule: #{e.class} - #{e.message}")
  end
end

