# frozen_string_literal: true

class AiAgents::MessageProcessorJob < ApplicationJob
  queue_as :high
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(ai_agent_id, message_id)
    @ai_agent = AiAgent.find(ai_agent_id)
    @message = Message.find(message_id)
    @conversation = @message.conversation

    begin
      process_message
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  def process_message
    # Build payload for fireagent-brain
    payload = build_payload

    # Call fireagent-brain /webhook endpoint
    response = send_to_fireagent_brain(payload)

    # Create response message if there's content
    create_response_message(response) if response[:message].present?
  end

  def build_payload
    {
      event: 'message_created',
      account: {
        id: @conversation.account_id
      },
      conversation: {
        id: @conversation.id,
        status: @conversation.status,
        inbox_id: @conversation.inbox_id,
        account_id: @conversation.account_id,
        contact_id: @conversation.contact_id
      },
      message: {
        id: @message.id,
        content: @message.content,
        message_type: @message.message_type,
        created_at: @message.created_at,
        attachments: @message.attachments.map do |attachment|
          {
            file_type: attachment.file_type,
            data_url: attachment.file_url
          }
        end
      },
      sender: {
        id: @message.sender_id,
        name: @message.sender&.name,
        email: @message.sender&.email
      },
      inbox: {
        id: @conversation.inbox_id,
        name: @conversation.inbox&.name
      }
    }
  end

  def send_to_fireagent_brain(payload)
    require 'net/http'
    require 'json'

    uri = URI("#{fireagent_brain_url}/webhook")

    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.read_timeout = 30
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body, symbolize_names: true)
    else
      Rails.logger.error("FireAgent Brain returned error: #{response.code} - #{response.body}")
      { message: nil }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to call FireAgent Brain: #{e.message}")
    { message: nil }
  end

  def create_response_message(response)
    return if response[:message].blank?

    @conversation.messages.create!(
      content: response[:message],
      message_type: :outgoing,
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id
    )
  end

  def fireagent_brain_url
    ENV.fetch('FIREAGENT_BRAIN_URL', 'http://fireagent-brain:8000')
  end

  def handle_error(error)
    Rails.logger.error("Failed to process message #{@message.id} with AI Agent #{@ai_agent.id}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end
end
