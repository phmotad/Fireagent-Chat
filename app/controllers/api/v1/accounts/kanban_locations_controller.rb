class Api::V1::Accounts::KanbanLocationsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :set_location, only: [:show, :update, :destroy]

  def index
    authorize KanbanLocation
    @locations = Current.account.kanban_locations.order(:name)
  end

  def show
    authorize @location
  end

  def create
    authorize KanbanLocation
    @location = Current.account.kanban_locations.new(location_params)
    if @location.save
      render :show
    else
      render json: { error: @location.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    authorize @location
    if @location.update(location_params)
      render :show
    else
      render json: { error: @location.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @location
    if @location.destroy
      head :ok
    else
      render json: { error: @location.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_location
    @location = Current.account.kanban_locations.find(params[:id])
  end

  def location_params
    params.require(:kanban_location).permit(:name, :description, :max_capacity, settings: {})
  end
end


