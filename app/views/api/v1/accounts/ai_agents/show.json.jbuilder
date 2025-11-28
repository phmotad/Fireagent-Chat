json.id @ai_agent.id
json.name @ai_agent.name
json.description @ai_agent.description
json.model @ai_agent.model
json.temperature @ai_agent.temperature
json.memory_window_size @ai_agent.memory_window_size
json.system_prompt @ai_agent.system_prompt
json.api_key @ai_agent.api_key.present? ? '••••••••' : nil
json.settings @ai_agent.settings
json.created_at @ai_agent.created_at
json.updated_at @ai_agent.updated_at
