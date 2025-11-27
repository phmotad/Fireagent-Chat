module Kanban
  class DeleteArchivedBoardJob < ApplicationJob
    queue_as :low

    def perform(board_id)
      board = ::KanbanBoard.find_by(id: board_id)
      return unless board

      # Delete only if it is still archived and past 30 days
      return unless board.archived? && board.archived_at <= 30.days.ago

      board.destroy!
    end
  end
end


