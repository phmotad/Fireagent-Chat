class Api::V1::Accounts::AiAgents::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent
  before_action :check_authorization

  def index
    # List inboxes connected to this agent using direct association
    @inboxes = @ai_agent.inboxes
  end

  def create
    # Find inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])

    # Create direct connection between AI Agent and Inbox
    ai_agent_inbox = @ai_agent.ai_agent_inboxes.find_or_initialize_by(
      inbox: inbox,
      account: Current.account
    )

    ai_agent_inbox.status = :active
    ai_agent_inbox.save!

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
    # Disconnect inbox from agent using direct association
    inbox_id = params[:id]

    @ai_agent.ai_agent_inboxes
      .where(inbox_id: inbox_id)
      .destroy_all

    head :ok
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def check_authorization
    authorize @ai_agent
  end
end
