json.array! @ai_agents do |agent|
  json.id agent.id
  json.name agent.name
  json.description agent.description
  json.model agent.model
  json.temperature agent.temperature
  json.memory_window_size agent.memory_window_size
  json.system_prompt agent.system_prompt
  json.api_key agent.api_key.present? ? '••••••••' : nil
  json.settings agent.settings
  json.created_at agent.created_at
  json.updated_at agent.updated_at
end
