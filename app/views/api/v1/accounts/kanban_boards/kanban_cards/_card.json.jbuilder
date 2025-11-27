json.id card.id
json.title card.title
json.description card.description
json.due_date card.due_date
json.start_date card.start_date
json.end_date card.end_date
json.position card.position
json.custom_attributes card.custom_attributes
json.archived_at card.archived_at
json.created_at card.created_at
json.updated_at card.updated_at
json.kanban_column_id card.kanban_column_id
json.kanban_board_id card.kanban_board_id
json.contact_id card.contact_id
json.conversation_id card.conversation_id
json.assigned_to_id card.assigned_to_id
json.label_list card.label_list

json.assigned_to do
  json.id card.assigned_to.id
  json.name card.assigned_to.name
end if card.assigned_to.present?

json.contact do
  json.id card.contact.id
  json.name card.contact.name
end if card.contact.present?

json.conversation do
  json.id card.conversation.id
  json.display_id card.conversation.display_id
end if card.conversation.present?

json.labels do
  json.array! card.labels do |label|
    json.id label.id
    json.title label.name
    json.color label.color
  end
end

