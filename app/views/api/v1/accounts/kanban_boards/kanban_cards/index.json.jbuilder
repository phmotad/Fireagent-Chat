json.array! @kanban_cards do |card|
  json.partial! 'api/v1/accounts/kanban_boards/kanban_cards/card', card: card
end

