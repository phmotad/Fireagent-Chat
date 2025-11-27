json.payload do
  json.array! @kanban_columns do |column|
    json.id column.id
    json.name column.name
    json.position column.position
    json.color column.color
    json.wip_limit column.wip_limit
    json.settings column.settings
    json.created_at column.created_at
    json.updated_at column.updated_at
    
    json.kanban_cards do
      json.array! column.kanban_cards.ordered do |card|
        json.id card.id
        json.title card.title
        json.description card.description
        json.due_date card.due_date
        json.start_date card.start_date
        json.end_date card.end_date
        json.position card.position
        json.custom_attributes card.custom_attributes
        json.contact_id card.contact_id
        json.conversation_id card.conversation_id
        json.assigned_to_id card.assigned_to_id
        json.created_by_id card.created_by_id
        json.kanban_column_id card.kanban_column_id
        json.kanban_board_id card.kanban_board_id
        json.labels card.label_list
        json.created_at card.created_at
        json.updated_at card.updated_at
      end
    end
  end
end

