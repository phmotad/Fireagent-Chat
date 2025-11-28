class Api::V1::Accounts::AiAgents::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent
  before_action :check_authorization

  def index
    # List inboxes connected to this agent
    if @ai_agent.agent_bot
      @inboxes = @ai_agent.agent_bot.inboxes
    else
      @inboxes = []
    end
  end

  def create
    # 1. Create or find AgentBot for this AI Agent
    agent_bot = @ai_agent.agent_bot || create_agent_bot_for_agent

    # 2. Find inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])

    # 3. Connect inbox to bot (check if already connected)
    agent_bot_inbox = agent_bot.agent_bot_inboxes.find_or_initialize_by(
      inbox: inbox,
      account: Current.account
    )

    agent_bot_inbox.status = :active
    agent_bot_inbox.save!

    # 4. Update ai_agent.agent_bot_id if not set
    @ai_agent.update!(agent_bot: agent_bot) unless @ai_agent.agent_bot_id

    render json: {
      success: true,
      inbox: inbox.as_json(only: [:id, :name, :channel_type]),
      message: 'Inbox conectada com sucesso'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Inbox não encontrada' }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    # Disconnect inbox from agent
    inbox_id = params[:id]

    if @ai_agent.agent_bot
      @ai_agent.agent_bot.agent_bot_inboxes
        .where(inbox_id: inbox_id)
        .destroy_all
    end

    head :ok
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def create_agent_bot_for_agent
    Current.account.agent_bots.create!(
      name: "AI: #{@ai_agent.name}",
      description: "Automated AI agent powered by #{@ai_agent.model}",
      bot_type: :webhook,
      outgoing_url: "#{ENV.fetch('FIREAGENT_BRAIN_URL', 'http://localhost:8000')}/webhook"
    )
  end

  def check_authorization
    authorize @ai_agent
  end
end
