class AddIsDefaultToKanbanLocationsAndRules < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :kanban_locations, :is_default, :boolean, default: false, null: false
    add_column :kanban_schedule_rules, :is_default, :boolean, default: false, null: false

    add_index :kanban_locations,
              [:account_id],
              name: 'index_kanban_locations_on_account_id_default',
              where: 'is_default = true',
              unique: true,
              algorithm: :concurrently

    add_index :kanban_schedule_rules,
              [:account_id],
              name: 'index_kanban_schedule_rules_on_account_id_default',
              where: 'is_default = true',
              unique: true,
              algorithm: :concurrently

    backfill_default_flags
  end

  def down
    remove_index :kanban_schedule_rules, name: 'index_kanban_schedule_rules_on_account_id_default'
    remove_index :kanban_locations, name: 'index_kanban_locations_on_account_id_default'

    remove_column :kanban_schedule_rules, :is_default
    remove_column :kanban_locations, :is_default
  end

  private

  def backfill_default_flags
    say_with_time 'Marking default kanban locations and rules' do
      Account.find_each do |account|
        location = account.kanban_locations.order(:created_at).first
        location&.update_columns(is_default: true)

        rule = account.kanban_schedule_rules.order(:created_at).first
        rule&.update_columns(is_default: true)
      end
    end
  end
end

