json.payload do
  json.array! @slots do |slot|
    json.rule_id slot[:rule_id]
    json.location_id slot[:location_id]
    json.start_time slot[:start_time]
    json.end_time slot[:end_time]
    json.capacity slot[:capacity]
    json.booked slot[:booked]
    json.available slot[:available]
  end
end

