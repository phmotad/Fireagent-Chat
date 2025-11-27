class CreateKanbanBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_bookings do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :kanban_schedule_rule, null: false, foreign_key: true, index: true
      t.references :kanban_location, null: false, foreign_key: true, index: true
      t.references :kanban_board, null: false, foreign_key: true, index: true
      t.references :kanban_card, null: true, foreign_key: true, index: true
      t.references :contact, null: false, foreign_key: true, index: true

      t.datetime :start_time, null: false
      t.datetime :end_time
      t.string :status, null: false, default: 'booked' # booked | cancelled
      t.string :source, null: false, default: 'manual'
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :kanban_bookings, [:kanban_schedule_rule_id, :start_time], name: 'index_kanban_bookings_on_rule_and_start_time'
  end
end


