json.payload do
  json.array! @kanban_cards do |card|
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
    json.label_list card.label_list
    json.created_at card.created_at
    json.updated_at card.updated_at
    
    if card.contact
      json.contact do
        json.id card.contact.id
        json.name card.contact.name
        json.email card.contact.email
      end
    end
    
    if card.conversation
      json.conversation do
        json.id card.conversation.id
        json.display_id card.conversation.display_id
      end
    end
    
    if card.assigned_to
      json.assigned_to do
        json.id card.assigned_to.id
        json.name card.assigned_to.name
        json.email card.assigned_to.email
      end
    end
  end
end

