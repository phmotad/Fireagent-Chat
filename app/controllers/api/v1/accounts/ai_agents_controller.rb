class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  prepend_before_action :debug_auth
  before_action :check_authorization
  before_action :fetch_ai_agent, only: [:show, :update, :destroy]

  def index
    @ai_agents = Current.account.ai_agents
  end

  def show; end

  def create
    @ai_agent = Current.account.ai_agents.new(ai_agent_params)
    if @ai_agent.save
      render :show
    else
      render_error_response(@ai_agent)
    end
  end

  def update
    if @ai_agent.update(ai_agent_params)
      render :show
    else
      render_error_response(@ai_agent)
    end
  end

  def destroy
    @ai_agent.destroy
    head :ok
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  end

  def ai_agent_params
    params.require(:ai_agent).permit(:name, :description, :system_prompt, :model, :temperature, :memory_window_size, :agent_bot_id, :api_key, settings: {})
  end

  def check_authorization
    super(AiAgent)
  end

  def debug_auth
    Rails.logger.info "=== DEBUG AUTH ==="
    Rails.logger.info "Headers: #{request.headers['api_access_token']}"
    Rails.logger.info "Current User: #{current_user&.id} - #{current_user&.email}"
    Rails.logger.info "Current Account: #{Current.account&.id} - #{Current.account&.name}"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "=================="
  end
end
