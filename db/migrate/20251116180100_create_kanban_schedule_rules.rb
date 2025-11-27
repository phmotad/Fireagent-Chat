class CreateKanbanScheduleRules < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_schedule_rules do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :kanban_board, null: false, foreign_key: true, index: true
      t.references :kanban_column, null: true, foreign_key: true, index: true
      t.references :kanban_location, null: false, foreign_key: true, index: true

      t.string :title, null: false
      t.text :description

      # Recorrência básica
      t.string :rule_type, null: false, default: 'once' # once | weekly
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.jsonb :weekdays, default: [] # array de inteiros 0..6 (domingo..sábado)
      t.time :time_start, null: false
      t.time :time_end

      t.integer :max_capacity_override
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :kanban_schedule_rules, [:account_id, :kanban_board_id], name: 'index_kanban_schedule_rules_on_account_and_board'
  end
end


