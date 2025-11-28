json.array! @knowledge_sources do |source|
  json.id source.id
  json.file_path source.file_path
  json.content_type source.document.attached? ? source.document.content_type : nil
  json.status source.status
  json.metadata source.metadata
  json.created_at source.created_at
  json.updated_at source.updated_at
end
