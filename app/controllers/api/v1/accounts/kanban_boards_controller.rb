class Api::V1::Accounts::KanbanBoardsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_kanban_board, except: [:index, :create]
  before_action :check_authorization, except: [:index]

  def index
    authorize KanbanBoard
    scope = Current.account.kanban_boards.includes(:created_by).ordered
    @kanban_boards = if ActiveModel::Type::Boolean.new.cast(params[:include_archived])
                       scope
                     else
                       scope.active
                     end
  end

  def show
    board_id = params[:id].to_s.gsub(/[^0-9]/, '')
    if board_id.blank?
      render json: { error: 'Invalid board ID' }, status: :bad_request
      return
    end
    
    @kanban_board = Current.account.kanban_boards.includes(:created_by, kanban_columns: []).find(board_id)
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Board not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("[KanbanBoardsController#show] #{e.class}: #{e.message}")
    Rails.logger.error("[KanbanBoardsController#show] Backtrace: #{e.backtrace.first(10).join("\n")}")
    render json: { error: e.message }, status: :internal_server_error
  end

  def create
    @kanban_board = Current.account.kanban_boards.build(permitted_params)
    @kanban_board.created_by = Current.user
    
    unless @kanban_board.save
      render json: { error: @kanban_board.errors.full_messages.join(', ') }, status: :unprocessable_entity
      return
    end

    # Aplicar template se for um tipo pré-configurado e houver intenção de usar template
    apply_template_value = @kanban_board.settings&.dig('apply_template')
    should_apply = @kanban_board.board_type != 'custom' && 
                   (apply_template_value.nil? || ActiveModel::Type::Boolean.new.cast(apply_template_value))
    
    if should_apply
      begin
        Kanban::Templates.apply!(@kanban_board)
      rescue StandardError => e
        Rails.logger.error("[KanbanBoardsController#create] Template apply failed: #{e.class} - #{e.message}")
        Rails.logger.error("[KanbanBoardsController#create] Backtrace: #{e.backtrace.first(10).join("\n")}")
        render json: { error: "Falha ao aplicar template: #{e.message}" }, status: :unprocessable_entity
        return
      end
    end
    
    # Recarregar para incluir colunas criadas
    @kanban_board.reload
  rescue StandardError => e
    Rails.logger.error("[KanbanBoardsController#create] Error: #{e.class} - #{e.message}")
    Rails.logger.error("[KanbanBoardsController#create] Backtrace: #{e.backtrace.first(10).join("\n")}")
    render json: { error: e.message }, status: :internal_server_error
  end

  def update
    @kanban_board.update!(permitted_params)
  end

  def destroy
    @kanban_board.destroy!
    head :ok
  end

  def archive
    @kanban_board.archive!
    render json: { success: true, archived_at: @kanban_board.archived_at }
  rescue StandardError => e
    Rails.logger.error("[KanbanBoardsController#archive] #{e.class}: #{e.message}")
    Rails.logger.error("[KanbanBoardsController#archive] Backtrace: #{e.backtrace.first(5).join("\n")}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def unarchive
    @kanban_board.unarchive!
    render json: { success: true, archived_at: @kanban_board.archived_at }
  rescue StandardError => e
    Rails.logger.error("[KanbanBoardsController#unarchive] #{e.class}: #{e.message}")
    Rails.logger.error("[KanbanBoardsController#unarchive] Backtrace: #{e.backtrace.first(5).join("\n")}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.includes(:created_by, kanban_columns: []).find(params[:id])
  end

  def permitted_params
    params.require(:kanban_board).permit(:name, :description, :board_type, :position, :card_entity_type, settings: {})
  end

  def check_authorization
    authorize(@kanban_board || KanbanBoard)
  end
end

