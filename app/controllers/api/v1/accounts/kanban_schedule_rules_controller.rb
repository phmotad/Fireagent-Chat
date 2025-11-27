class Api::V1::Accounts::KanbanScheduleRulesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :set_rule, only: [:show, :update, :destroy]

  def index
    authorize KanbanScheduleRule
    @rules = Current.account.kanban_schedule_rules.includes(:kanban_location, :kanban_board).order(:title).to_a
  end

  def show
    authorize @rule
  end

  def create
    authorize KanbanScheduleRule
    @rule = Current.account.kanban_schedule_rules.new(rule_params)
    if @rule.save
      render :show
    else
      render json: { error: @rule.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    authorize @rule
    if @rule.update(rule_params)
      render :show
    else
      render json: { error: @rule.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @rule
    if @rule.destroy
      head :ok
    else
      render json: { error: @rule.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_rule
    @rule = Current.account.kanban_schedule_rules.find(params[:id])
  end

  def rule_params
    params.require(:kanban_schedule_rule).permit(
      :kanban_board_id,
      :kanban_column_id,
      :kanban_location_id,
      :title,
      :description,
      :rule_type,
      :max_capacity_override,
      :active,
      weekdays: [],
      settings: {}
    )
  end
end


