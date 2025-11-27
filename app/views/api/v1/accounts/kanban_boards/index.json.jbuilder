json.payload do
  json.array! @kanban_boards do |board|
    json.id board.id
    json.name board.name
    json.description board.description
    json.board_type board.board_type
     json.card_entity_type board.card_entity_type
    json.settings board.settings || {}
    json.position board.position
     json.archived_at board.archived_at
    json.created_at board.created_at
    json.updated_at board.updated_at
    if board.created_by.present?
      json.created_by do
        json.id board.created_by.id
        json.name board.created_by.name
      end
    else
      json.created_by nil
    end
  end
end

