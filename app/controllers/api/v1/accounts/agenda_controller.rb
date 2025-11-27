class Api::V1::Accounts::AgendaController < Api::V1::Accounts::BaseController
  before_action :current_account

  def index
    # Agenda é acessível para todos os usuários autenticados
    # Não requer permissões especiais, apenas autenticação
    # Buscar agendamentos (sempre retornar, independente de board_ids)
    bookings = fetch_bookings
    
    # Buscar cards com data dos boards selecionados (apenas se board_ids for fornecido)
    cards = fetch_cards
    
    render json: {
      bookings: bookings || [],
      cards: cards || []
    }
  end

  private

  def fetch_bookings
    scope = Current.account.kanban_bookings
      .includes(:contact, :kanban_location, :kanban_schedule_rule)
      .order(:start_time)
    
    # Filtrar por data se fornecido
    if params[:start_date].present? && params[:end_date].present?
      start_date = Time.zone.parse(params[:start_date])
      end_date = Time.zone.parse(params[:end_date])
      scope = scope.where('start_time >= ? AND start_time <= ?', start_date, end_date)
    end
    
    scope.map do |booking|
      {
        id: booking.id,
        title: booking.contact&.name || booking.kanban_schedule_rule&.title || 'Agendamento',
        start_time: booking.start_time&.iso8601,
        end_time: booking.end_time&.iso8601,
        contact: {
          id: booking.contact_id,
          name: booking.contact&.name,
          email: booking.contact&.email,
        },
        kanban_location: {
          id: booking.kanban_location_id,
          name: booking.kanban_location&.name,
        },
        kanban_schedule_rule: {
          id: booking.kanban_schedule_rule_id,
          title: booking.kanban_schedule_rule&.title,
        },
        status: booking.status,
        source: booking.source,
      }
    end
  end

  def fetch_cards
    return [] unless params[:board_ids].present?
    
    board_ids = Array(params[:board_ids]).map(&:to_i).reject(&:zero?)
    return [] if board_ids.empty?
    
    scope = Current.account.kanban_cards
      .joins(:kanban_column)
      .where(kanban_columns: { kanban_board_id: board_ids })
      .includes(:kanban_column, :kanban_board, :contact)
      .where.not(due_date: nil) # Apenas cards com data
      .order(:due_date)
    
    # Filtrar por data se fornecido
    if params[:start_date].present? && params[:end_date].present?
      start_date = Time.zone.parse(params[:start_date])
      end_date = Time.zone.parse(params[:end_date])
      scope = scope.where('due_date >= ? AND due_date <= ?', start_date, end_date)
    end
    
    scope.map do |card|
      {
        id: card.id,
        title: card.title,
        description: card.description,
        due_date: card.due_date&.iso8601,
        start_date: card.start_date&.iso8601,
        end_date: card.end_date&.iso8601,
        kanban_board: {
          id: card.kanban_board&.id,
          name: card.kanban_board&.name,
        },
        kanban_column: {
          id: card.kanban_column_id,
          name: card.kanban_column&.name,
        },
        contact: card.contact ? {
          id: card.contact_id,
          name: card.contact.name,
        } : nil,
      }
    end
  end
end

