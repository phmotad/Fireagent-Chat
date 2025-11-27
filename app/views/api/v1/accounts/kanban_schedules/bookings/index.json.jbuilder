json.payload do
  json.array! @bookings do |booking|
    json.id booking.id
    json.kanban_schedule_rule_id booking.kanban_schedule_rule_id
    json.kanban_location_id booking.kanban_location_id
    json.kanban_board_id booking.kanban_board_id
    json.kanban_card_id booking.kanban_card_id
    json.contact_id booking.contact_id
    json.start_time booking.start_time
    json.end_time booking.end_time
    json.status booking.status
    json.source booking.source
    json.metadata booking.metadata || {}
    json.created_at booking.created_at
    json.updated_at booking.updated_at
    
    if booking.contact
      json.contact do
        json.id booking.contact.id
        json.name booking.contact.name
        json.email booking.contact.email
        json.phone_number booking.contact.phone_number
      end
    end
    
    if booking.kanban_location
      json.kanban_location do
        json.id booking.kanban_location.id
        json.name booking.kanban_location.name
        json.description booking.kanban_location.description
        json.max_capacity booking.kanban_location.max_capacity
        json.is_default booking.kanban_location.is_default
      end
    end
    
    if booking.kanban_schedule_rule
      json.kanban_schedule_rule do
        json.id booking.kanban_schedule_rule.id
        json.title booking.kanban_schedule_rule.title
        json.description booking.kanban_schedule_rule.description
        json.rule_type booking.kanban_schedule_rule.rule_type
        json.active booking.kanban_schedule_rule.active
      end
    end
    
    # Informações de ocupação para este horário/local
    occupancy_key = "#{booking.kanban_location_id}_#{booking.start_time.iso8601}"
    if @occupancy_data && @occupancy_data[occupancy_key]
      occupancy = @occupancy_data[occupancy_key]
      json.occupancy do
        json.max_capacity occupancy[:max_capacity]
        json.booked_count occupancy[:booked_count]
        json.available_slots occupancy[:available_slots]
        json.is_full occupancy[:is_full]
      end
    end
  end
end

