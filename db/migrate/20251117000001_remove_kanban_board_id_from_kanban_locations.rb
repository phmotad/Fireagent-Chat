# frozen_string_literal: true

class RemoveKanbanBoardIdFromKanbanLocations < ActiveRecord::Migration[7.1]
  def change
    remove_reference :kanban_locations, :kanban_board, foreign_key: true, index: true
  end
end

