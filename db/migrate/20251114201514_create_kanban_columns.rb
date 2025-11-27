# frozen_string_literal: true

class CreateKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_columns do |t|
      t.references :kanban_board, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :position, default: 0, null: false
      t.string :color, default: '#3B82F6', null: false
      t.integer :wip_limit
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :kanban_columns, [:kanban_board_id, :position]
  end
end

