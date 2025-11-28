class Api::V1::Accounts::AiAgentKnowledgeController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent
  before_action :check_authorization

  def index
    @knowledge_sources = @ai_agent.ai_agent_knowledge_sources
  end

  def create
    @knowledge_source = @ai_agent.ai_agent_knowledge_sources.new(knowledge_params)

    # Handle file upload if provided
    if params[:document].present?
      @knowledge_source.document.attach(params[:document])
    end

    if @knowledge_source.save
      # Trigger background job to process file and generate embeddings
      AiAgents::ProcessKnowledgeSourceJob.perform_later(@knowledge_source.id)
      render :show
    else
      render_error_response(@knowledge_source)
    end
  end

  def destroy
    @knowledge_source = @ai_agent.ai_agent_knowledge_sources.find(params[:id])
    @knowledge_source.destroy
    head :ok
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def knowledge_params
    # Accept both wrapped and unwrapped params for flexibility
    knowledge_data = params[:ai_agent_knowledge_source] || params
    knowledge_data.permit(:file_path, :content_type, :status, metadata: {})
  end

  def check_authorization
    authorize(@ai_agent || AiAgent)
  end
end
