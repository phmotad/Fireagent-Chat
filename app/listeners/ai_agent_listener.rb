class AiAgentListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless connected_ai_agent_exist?(inbox)
    return unless message.incoming?
    return if message.private?
    return if message.conversation.resolved?

    # Process message with all connected AI agents
    inbox.ai_agent_inboxes.active.each do |ai_agent_inbox|
      process_message_with_agent(ai_agent_inbox.ai_agent, message)
    end
  end

  private

  def connected_ai_agent_exist?(inbox)
    inbox.ai_agent_inboxes.active.exists?
  end

  def process_message_with_agent(ai_agent, message)
    # Call fireagent-brain service directly
    AiAgents::MessageProcessorJob.perform_later(ai_agent.id, message.id)
  end
end
