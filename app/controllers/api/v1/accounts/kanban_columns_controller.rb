class Api::V1::Accounts::KanbanColumnsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_kanban_board
  before_action :fetch_kanban_column, except: [:index, :create]
  before_action :check_authorization

  def index
    @kanban_columns = @kanban_board.kanban_columns.ordered.includes(:kanban_cards)
  end

  def show; end

  def create
    column_params = permitted_params.to_h
    
    # Processar settings se fornecido
    if params[:kanban_column][:settings].present?
      settings_hash = params[:kanban_column][:settings]
      if settings_hash.is_a?(ActionController::Parameters)
        settings_hash = settings_hash.to_unsafe_h
      elsif settings_hash.respond_to?(:to_h)
        settings_hash = settings_hash.to_h
      end
      column_params[:settings] = settings_hash || {}
    else
      column_params[:settings] = {}
    end
    
    @kanban_column = @kanban_board.kanban_columns.build(column_params)
    
    unless @kanban_column.save
      render json: { error: @kanban_column.errors.full_messages.join(', ') }, status: :unprocessable_entity
      return
    end
    
    # Recarregar a coluna para garantir que todos os dados estejam atualizados
    @kanban_column.reload
  end

  def update
    update_params = permitted_params.to_h
    
    # Processar settings se fornecido
    if params[:kanban_column][:settings].present?
      settings_hash = params[:kanban_column][:settings]
      if settings_hash.is_a?(ActionController::Parameters)
        settings_hash = settings_hash.to_unsafe_h
      elsif settings_hash.respond_to?(:to_h)
        settings_hash = settings_hash.to_h
      end
      update_params[:settings] = settings_hash || {}
    end
    
    unless @kanban_column.update(update_params)
      render json: { error: @kanban_column.errors.full_messages.join(', ') }, status: :unprocessable_entity
      return
    end
    
    # Reordenar se necessário
    if params[:kanban_column][:position].present?
      reorder_columns
    end
  end

  def destroy
    @kanban_column.destroy!
    reorder_columns
    head :ok
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.find(params[:kanban_board_id])
  end

  def fetch_kanban_column
    @kanban_column = @kanban_board.kanban_columns.find(params[:id])
  end

  def permitted_params
    params.require(:kanban_column).permit(:name, :position, :color, :wip_limit, settings: {})
  end

  def reorder_columns
    @kanban_board.kanban_columns.ordered.each_with_index do |column, index|
      column.update_column(:position, index)
    end
  end

  def check_authorization
    authorize(@kanban_column || KanbanColumn)
  end
end

