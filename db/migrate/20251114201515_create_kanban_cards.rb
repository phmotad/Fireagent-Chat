# frozen_string_literal: true

class CreateKanbanCards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_cards do |t|
      t.references :kanban_column, null: false, foreign_key: true, index: true
      t.references :kanban_board, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.text :description
      t.datetime :due_date
      t.datetime :start_date
      t.datetime :end_date
      t.integer :position, default: 0, null: false
      t.jsonb :custom_attributes, default: {}
      t.references :contact, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true
      t.references :assigned_to, foreign_key: { to_table: :users }, index: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end

    add_index :kanban_cards, [:kanban_column_id, :position]
    add_index :kanban_cards, [:kanban_board_id, :due_date]
  end
end

