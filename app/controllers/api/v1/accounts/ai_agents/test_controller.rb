class Api::V1::Accounts::AiAgents::TestController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :set_agent

  def create
    response = send_test_message(params[:message])
    
    render json: {
      response: response[:content],
      tool_calls: response[:tool_calls],
      context_used: response[:context_used]
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def clear_context
    # Clear test context from Redis
    test_conversation_id = "test_#{@agent.id}_#{current_user.id}"
    # This would call the fireagent-brain service to clear context
    render json: { success: true }
  end

  private

  def set_agent
    @agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def send_test_message(message)
    require 'net/http'
    require 'json'

    test_conversation_id = "test_#{@agent.id}_#{current_user.id}"
    
    uri = URI("#{ENV.fetch('FIREAGENT_BRAIN_URL', 'http://fireagent-brain:8000')}/test")
    
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = {
      agent_id: @agent.id,
      conversation_id: test_conversation_id,
      message: message,
      user_id: current_user.id
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    JSON.parse(response.body, symbolize_names: true)
  end

  def check_authorization
    super(AiAgent)
  end
end
