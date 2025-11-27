class AddCardEntityTypeToKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_boards, :card_entity_type, :string, default: 'conversation', null: false
    add_index :kanban_boards, :card_entity_type
  end
end


