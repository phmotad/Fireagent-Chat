json.id @kanban_card.id
json.title @kanban_card.title
json.description @kanban_card.description
json.due_date @kanban_card.due_date
json.start_date @kanban_card.start_date
json.end_date @kanban_card.end_date
json.position @kanban_card.position
json.custom_attributes @kanban_card.custom_attributes
json.contact_id @kanban_card.contact_id
json.conversation_id @kanban_card.conversation_id
json.assigned_to_id @kanban_card.assigned_to_id
json.created_by_id @kanban_card.created_by_id
json.kanban_column_id @kanban_card.kanban_column_id
json.kanban_board_id @kanban_card.kanban_board_id
json.label_list @kanban_card.label_list
json.created_at @kanban_card.created_at
json.updated_at @kanban_card.updated_at

if @kanban_card.contact
  json.contact do
    json.id @kanban_card.contact.id
    json.name @kanban_card.contact.name
    json.email @kanban_card.contact.email
  end
end

if @kanban_card.conversation
  json.conversation do
    json.id @kanban_card.conversation.id
    json.display_id @kanban_card.conversation.display_id
  end
end

if @kanban_card.assigned_to
  json.assigned_to do
    json.id @kanban_card.assigned_to.id
    json.name @kanban_card.assigned_to.name
    json.email @kanban_card.assigned_to.email
  end
end

