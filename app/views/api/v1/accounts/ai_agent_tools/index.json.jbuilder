json.array! @tools do |tool|
  json.id tool.id
  json.name tool.name
  json.tool_type tool.tool_type
  json.description tool.description
  json.configuration tool.configuration
  json.conditions tool.conditions
  json.enabled tool.enabled
  json.created_at tool.created_at
  json.updated_at tool.updated_at
end
