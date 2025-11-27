class RemoveVigenceAndTimeFromKanbanScheduleRules < ActiveRecord::Migration[7.1]
  def change
    change_column_null :kanban_schedule_rules, :starts_at, true
    change_column_null :kanban_schedule_rules, :ends_at, true
    change_column_null :kanban_schedule_rules, :time_start, true
    change_column_null :kanban_schedule_rules, :time_end, true
  end
end

