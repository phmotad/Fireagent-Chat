json.array! @inboxes do |inbox|
  json.id inbox.id
  json.name inbox.name
  json.channel_type inbox.channel_type
  json.avatar_url inbox.avatar_url
  json.webhook_url inbox.webhook_url
end
