json.payload do
  json.array! @rules do |rule|
    json.id rule.id
    json.title rule.title
    json.description rule.description
    json.kanban_board_id rule.kanban_board_id
    json.kanban_column_id rule.kanban_column_id
    json.kanban_location_id rule.kanban_location_id
    json.rule_type rule.rule_type
    json.starts_at rule.starts_at
    json.ends_at rule.ends_at
    json.time_start rule.time_start
    json.time_end rule.time_end
    json.active rule.active
    json.is_default rule.is_default
    json.weekdays rule.weekdays || []
    json.max_capacity_override rule.max_capacity_override
    json.settings rule.settings || {}
    json.created_at rule.created_at
    json.updated_at rule.updated_at
    
    if rule.kanban_location
      json.kanban_location do
        json.id rule.kanban_location.id
        json.name rule.kanban_location.name
      end
    end
    
    if rule.kanban_board
      json.kanban_board do
        json.id rule.kanban_board.id
        json.name rule.kanban_board.name
      end
    end
  end
end

