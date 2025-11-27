# frozen_string_literal: true

class CreateKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_boards do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.string :board_type, default: 'custom', null: false
      t.jsonb :settings, default: {}
      t.integer :position, default: 0, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true, index: true

      t.timestamps
    end

    add_index :kanban_boards, [:account_id, :position]
  end
end

