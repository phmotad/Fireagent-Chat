# Script to check AI Agent Inbox connections

puts "Checking AI Agent Inbox connections..."
puts "=" * 50

# Check total ai_agent_inboxes
total_connections = AiAgentInbox.count
puts "Total AI Agent Inbox connections: #{total_connections}"

# Check active connections
active_connections = AiAgentInbox.active.count
puts "Active connections: #{active_connections}"

# List all connections
AiAgentInbox.includes(:ai_agent, :inbox).each do |connection|
  puts "\n"
  puts "Connection ID: #{connection.id}"
  puts "  AI Agent: #{connection.ai_agent.name} (ID: #{connection.ai_agent_id})"
  puts "  Inbox: #{connection.inbox.name} (ID: #{connection.inbox_id})"
  puts "  Status: #{connection.status}"
  puts "  Account ID: #{connection.account_id}"
end

# Check inbox 2 (from logs)
inbox_2 = Inbox.find_by(id: 2)
if inbox_2
  puts "\n"
  puts "=" * 50
  puts "Inbox ID 2 Details:"
  puts "  Name: #{inbox_2.name}"
  puts "  Has AI Agent Inboxes: #{inbox_2.ai_agent_inboxes.any?}"
  puts "  Active AI Agent Inboxes: #{inbox_2.ai_agent_inboxes.active.count}"

  inbox_2.ai_agent_inboxes.active.each do |ai_inbox|
    puts "  - Agent: #{ai_inbox.ai_agent.name}"
  end
else
  puts "\nInbox ID 2 not found!"
end

puts "\n"
puts "=" * 50
