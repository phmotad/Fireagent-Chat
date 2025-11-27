json.payload do
  json.array! @locations do |location|
    json.id location.id
    json.name location.name
    json.description location.description
    json.max_capacity location.max_capacity
    json.is_default location.is_default
    json.settings location.settings || {}
    json.created_at location.created_at
    json.updated_at location.updated_at
  end
end

