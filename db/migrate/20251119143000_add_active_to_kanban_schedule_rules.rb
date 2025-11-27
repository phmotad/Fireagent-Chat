class AddActiveToKanbanScheduleRules < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_schedule_rules, :active, :boolean, default: true, null: false
    add_index :kanban_schedule_rules, :active
  end
end

