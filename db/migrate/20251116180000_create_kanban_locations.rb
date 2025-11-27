class CreateKanbanLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_locations do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :kanban_board, null: true, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.integer :max_capacity, null: true
      t.jsonb :settings, default: {}

      t.timestamps
    end
  end
end


