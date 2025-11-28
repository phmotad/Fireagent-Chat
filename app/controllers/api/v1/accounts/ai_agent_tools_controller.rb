class Api::V1::Accounts::AiAgentToolsController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent
  before_action :fetch_tool, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @tools = @ai_agent.ai_agent_tools
  end

  def show
    @tool = @ai_agent_tool
  end

  def create
    @ai_agent_tool = @ai_agent.ai_agent_tools.new(tool_params)
    if @ai_agent_tool.save
      @tool = @ai_agent_tool
      render :show
    else
      render_error_response(@ai_agent_tool)
    end
  end

  def update
    if @ai_agent_tool.update(tool_params)
      @tool = @ai_agent_tool
      render :show
    else
      render_error_response(@ai_agent_tool)
    end
  end

  def destroy
    @ai_agent_tool.destroy
    head :ok
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def fetch_tool
    @ai_agent_tool = @ai_agent.ai_agent_tools.find(params[:id])
  end

  def tool_params
    # Accept both wrapped and unwrapped params for flexibility
    tool_data = params[:ai_agent_tool] || params
    tool_data.permit(:name, :description, :tool_type, :enabled, configuration: {}, conditions: {})
  end

  def check_authorization
    authorize(@ai_agent || AiAgent)
  end
end
