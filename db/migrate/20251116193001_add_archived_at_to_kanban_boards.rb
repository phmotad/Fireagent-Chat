class AddArchivedAtToKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_boards, :archived_at, :datetime
    add_index :kanban_boards, :archived_at
  end
end


