json.array! @knowledge_sources do |source|
  json.id source.id
  json.file_path source.file_path
  json.content_type source.content_type
  json.status source.status
  json.metadata source.metadata
  json.created_at source.created_at
  json.updated_at source.updated_at
end
