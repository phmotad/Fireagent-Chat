module Kanban
  class DeleteOldArchivedCardsJob < ApplicationJob
    queue_as :low

    def perform
      # Buscar todos os cards arquivados há mais de 30 dias
      cutoff_date = 30.days.ago
      old_archived_cards = KanbanCard.archived.where('archived_at < ?', cutoff_date)

      deleted_count = 0
      old_archived_cards.find_each do |card|
        begin
          card.destroy!
          deleted_count += 1
        rescue StandardError => e
          Rails.logger.error(
            "[Kanban::DeleteOldArchivedCardsJob] Failed to delete card #{card.id}: #{e.class} - #{e.message}"
          )
        end
      end

      Rails.logger.info(
        "[Kanban::DeleteOldArchivedCardsJob] Deleted #{deleted_count} archived card(s) older than 30 days"
      )

      deleted_count
    end
  end
end

