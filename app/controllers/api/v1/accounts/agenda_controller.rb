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

  # GET /api/v1/accounts/:account_id/agenda/availability
  # Check if a time slot is available
  def availability
    date = params[:date]
    time = params[:time]
    service = params[:service]

    if date.blank? || time.blank?
      render json: { error: 'Date and time are required' }, status: :bad_request
      return
    end

    # Combine date and time
    datetime_str = "#{date} #{time}"
    start_time = Time.zone.parse(datetime_str)

    # Find schedule rules that match the service (if provided)
    schedule_rules = Current.account.kanban_schedule_rules.active
    schedule_rules = schedule_rules.where('title ILIKE ?', "%#{service}%") if service.present?

    # Check availability across all matching rules
    available_slots = []
    is_available = false

    schedule_rules.each do |rule|
      # Count existing bookings for this time slot
      existing_bookings = rule.kanban_bookings
                              .active
                              .where('start_time = ?', start_time)
                              .count

      capacity = rule.capacity || 1

      if existing_bookings < capacity
        is_available = true
        break
      end

      # Find available slots for this rule (next 5 time slots)
      5.times do |i|
        slot_time = start_time + (i + 1).hours
        slot_bookings = rule.kanban_bookings
                            .active
                            .where('start_time = ?', slot_time)
                            .count

        if slot_bookings < capacity
          available_slots << slot_time.strftime('%H:%M')
        end
      end
    end

    render json: {
      available: is_available,
      available_slots: available_slots.uniq.first(5),
      capacity_info: schedule_rules.map { |r| { service: r.title, capacity: r.capacity } }
    }
  end

  # POST /api/v1/accounts/:account_id/agenda/appointments
  # Create a new appointment
  def appointments
    date = params[:date]
    time = params[:time]
    service = params[:service]
    conversation_id = params[:conversation_id]
    notes = params[:notes]

    if date.blank? || time.blank? || service.blank?
      render json: { error: 'Date, time and service are required' }, status: :bad_request
      return
    end

    # Combine date and time
    datetime_str = "#{date} #{time}"
    start_time = Time.zone.parse(datetime_str)

    # Find matching schedule rule
    schedule_rule = Current.account.kanban_schedule_rules
                                   .active
                                   .where('title ILIKE ?', "%#{service}%")
                                   .first

    unless schedule_rule
      render json: { error: "Service '#{service}' not found" }, status: :not_found
      return
    end

    # Check capacity
    existing_bookings = schedule_rule.kanban_bookings
                                     .active
                                     .where('start_time = ?', start_time)
                                     .count

    capacity = schedule_rule.capacity || 1

    if existing_bookings >= capacity
      render json: {
        error: 'Time slot is full',
        message: 'Este horário já está lotado'
      }, status: :unprocessable_entity
      return
    end

    # Find or create contact from conversation
    contact = find_contact_from_conversation(conversation_id)

    unless contact
      render json: { error: 'Contact not found' }, status: :not_found
      return
    end

    # Create booking
    booking = schedule_rule.kanban_bookings.new(
      account: Current.account,
      kanban_location: schedule_rule.kanban_location,
      kanban_board: schedule_rule.kanban_board,
      contact: contact,
      start_time: start_time,
      end_time: start_time + 1.hour, # Default 1 hour duration
      status: 'booked',
      source: 'ai_agent',
      metadata: {
        service: service,
        notes: notes,
        conversation_id: conversation_id
      }
    )

    if booking.save
      render json: {
        id: booking.id,
        start_time: booking.start_time.iso8601,
        end_time: booking.end_time.iso8601,
        service: service,
        status: booking.status,
        contact: {
          id: contact.id,
          name: contact.name
        }
      }, status: :created
    else
      render json: { error: booking.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def find_contact_from_conversation(conversation_id)
    return nil if conversation_id.blank?

    conversation = Current.account.conversations.find_by(id: conversation_id)
    conversation&.contact
  end

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

