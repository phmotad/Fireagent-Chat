# == Schema Information
#
# Table name: kanban_cards
#
#  id               :bigint           not null, primary key
#  title            :string           not null
#  description      :text
#  due_date         :datetime
#  start_date       :datetime
#  end_date         :datetime
#  position         :integer           default(0)
#  custom_attributes :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  kanban_column_id :bigint           not null
#  kanban_board_id  :bigint           not null
#  contact_id       :bigint
#  conversation_id  :bigint
#  assigned_to_id   :bigint
#  created_by_id    :bigint           not null
#
# Indexes
#
#  index_kanban_cards_on_assigned_to_id    (assigned_to_id)
#  index_kanban_cards_on_contact_id         (contact_id)
#  index_kanban_cards_on_conversation_id    (conversation_id)
#  index_kanban_cards_on_created_by_id     (created_by_id)
#  index_kanban_cards_on_kanban_board_id   (kanban_board_id)
#  index_kanban_cards_on_kanban_column_id   (kanban_column_id)
#

class KanbanCard < ApplicationRecord
  include Labelable
  include AccountCacheRevalidator

  belongs_to :kanban_column
  belongs_to :kanban_board
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true

  validates :title, presence: true
  validates :kanban_column_id, presence: true
  validates :kanban_board_id, presence: true
  validates :created_by_id, presence: true
  validate :validate_dates

  scope :ordered, -> { order(:position, :created_at) }
  scope :with_due_date, -> { where.not(due_date: nil) }
  scope :overdue, -> { where('due_date < ?', Time.current) }
  scope :assigned_to_user, ->(user) { where(assigned_to_id: user.id) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  before_validation :set_defaults
  after_update :apply_column_labels, if: :saved_change_to_kanban_column_id?

  def set_defaults
    self.position ||= 0
    self.custom_attributes ||= {}
  end

  def validate_dates
    return unless start_date && end_date

    errors.add(:end_date, 'deve ser após a data de início') if end_date < start_date
  end

  def overdue?
    due_date.present? && due_date < Time.current
  end

  def apply_column_labels
    labels_to_apply = kanban_column.auto_assign_labels
    return if labels_to_apply.blank?

    # Aplicar labels ao card
    add_labels(labels_to_apply)

    # Se o card está relacionado a um contato, aplicar labels ao contato também
    if contact.present?
      contact.add_labels(labels_to_apply)
    end

    # Se o card está relacionado a uma conversa, aplicar labels à conversa também
    if conversation.present?
      conversation.add_labels(labels_to_apply)
    end
  end

  def account
    kanban_board.account
  end

  def label_list
    labels.map(&:name)
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end
end

