json.id @kanban_board.id
json.name @kanban_board.name
json.description @kanban_board.description
json.board_type @kanban_board.board_type
json.card_entity_type @kanban_board.card_entity_type
json.settings @kanban_board.settings
json.position @kanban_board.position
json.archived_at @kanban_board.archived_at
json.created_at @kanban_board.created_at
json.updated_at @kanban_board.updated_at

json.created_by do
  json.id @kanban_board.created_by.id
  json.name @kanban_board.created_by.name
end if @kanban_board.created_by.present?

json.kanban_columns do
  columns = @kanban_board.kanban_columns || []
  json.array! columns.ordered do |column|
    json.id column.id
    json.name column.name
    json.position column.position
    json.color column.color
    json.wip_limit column.wip_limit
    json.settings column.settings || {}
    json.created_at column.created_at
    json.updated_at column.updated_at
  end
end

