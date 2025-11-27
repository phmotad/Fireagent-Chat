module Kanban
  class TriggerOnMoveJob < ApplicationJob
    queue_as :low

    # params: board_id, card_id, from_column_id, to_column_id, user_id
    def perform(board_id:, card_id:, from_column_id:, to_column_id:, user_id: nil)
      board = ::KanbanBoard.find_by(id: board_id)
      card = ::KanbanCard.find_by(id: card_id)
      return unless board && card

      from_column = from_column_id.present? ? ::KanbanColumn.find_by(id: from_column_id) : nil
      to_column   = ::KanbanColumn.find_by(id: to_column_id)
      user        = user_id.present? ? ::User.find_by(id: user_id) : nil
      return unless to_column

      # 1) Evento interno para futuras automações genéricas
      ActiveSupport::Notifications.instrument(
        'kanban.card.moved',
        board_id: board_id,
        card_id: card_id,
        from_column_id: from_column_id,
        to_column_id: to_column_id,
        account_id: board.account_id
      )

      # 2) Mensagem automática ao entrar em uma coluna (apenas boards de conversas)
      if board.card_entity_type == 'conversation' && card.conversation_id.present?
        auto_message = to_column.settings&.dig('auto_message')
        if auto_message.present?
          begin
            conversation = card.conversation
            conversation.messages.create!(
              account_id: board.account_id,
              inbox_id: conversation.inbox_id,
              message_type: :outgoing,
              content: auto_message,
              sender: user
            )
          rescue StandardError => e
            Rails.logger.error("[Kanban::TriggerOnMoveJob] auto_message failed: #{e.class} - #{e.message}")
          end
        end
      end

      # 3) Ações avançadas configuradas na coluna (on_exit da coluna antiga, on_enter da nova)
      Array(from_column&.on_exit_actions).each do |action|
        apply_action(action, board: board, card: card, column: from_column, user: user)
      end

      Array(to_column.on_enter_actions).each do |action|
        apply_action(action, board: board, card: card, column: to_column, user: user)
      end
    end

    private

    # Action schema (exemplos):
    # { "type": "add_labels", "values": ["qualificar", "vip"] }
    # { "type": "remove_labels", "values": ["frio"] }
    # { "type": "close_conversation" }
    # { "type": "assign_to", "user_id": 123 }
    def apply_action(action, board:, card:, column:, user:)
      return if action.blank? || action['type'].blank?

      case action['type']
      when 'add_labels'
        labels = Array(action['values']).compact
        return if labels.empty?
        begin
          card.add_labels(labels)
          card.contact&.add_labels(labels) if card.contact_id.present?
          card.conversation&.add_labels(labels) if card.conversation_id.present?
        rescue StandardError => e
          Rails.logger.error("[Kanban::TriggerOnMoveJob] add_labels failed: #{e.class} - #{e.message}")
        end
      when 'remove_labels'
        labels = Array(action['values']).compact
        return if labels.empty?
        begin
          card.remove_labels(labels)
          card.contact&.remove_labels(labels) if card.contact_id.present?
          card.conversation&.remove_labels(labels) if card.conversation_id.present?
        rescue StandardError => e
          Rails.logger.error("[Kanban::TriggerOnMoveJob] remove_labels failed: #{e.class} - #{e.message}")
        end
      when 'close_conversation'
        return unless board.card_entity_type == 'conversation' && card.conversation_id.present?
        begin
          conv = card.conversation
          conv.update!(status: :resolved)
        rescue StandardError => e
          Rails.logger.error("[Kanban::TriggerOnMoveJob] close_conversation failed: #{e.class} - #{e.message}")
        end
      when 'assign_to'
        user_id = action['user_id'].presence
        return unless user_id
        begin
          card.update!(assigned_to_id: user_id)
        rescue StandardError => e
          Rails.logger.error("[Kanban::TriggerOnMoveJob] assign_to failed: #{e.class} - #{e.message}")
        end
      else
        Rails.logger.warn("[Kanban::TriggerOnMoveJob] unknown action type: #{action['type']}")
      end
    end
  end
end


