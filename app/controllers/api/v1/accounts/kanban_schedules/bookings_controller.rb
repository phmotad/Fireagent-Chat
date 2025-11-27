class Api::V1::Accounts::KanbanSchedules::BookingsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :set_booking, only: [:show, :update, :destroy]

  def index
    @bookings = base_scope
    @bookings = @bookings.where(kanban_location_id: params[:location_id]) if params[:location_id].present?
    @bookings = @bookings.where(kanban_schedule_rule_id: params[:rule_id]) if params[:rule_id].present?
    @bookings = @bookings.where(contact_id: params[:contact_id]) if params[:contact_id].present?

    if params[:date_from].present? && params[:date_to].present?
      from = Time.zone.parse(params[:date_from])
      to   = Time.zone.parse(params[:date_to])
      @bookings = @bookings.between_dates(from, to)
    end

    @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    @bookings = @bookings.order(:start_time)
    
    # Calcular ocupação para cada booking
    @occupancy_data = calculate_occupancy_data(@bookings)
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[KanbanSchedules::BookingsController#index] #{e.class}: #{e.message}")
    Rails.logger.error("[KanbanSchedules::BookingsController#index] Backtrace: #{e.backtrace.first(10).join("\n")}")
    render json: { error: e.message }, status: :internal_server_error
  end

  def show
    # Calcular ocupação para este booking específico
    @occupancy_data = calculate_occupancy_for_booking(@booking)
  end

  def create
    rule = Current.account.kanban_schedule_rules.find(booking_params[:kanban_schedule_rule_id])
    location = rule.kanban_location
    contact = Current.account.contacts.find(booking_params[:contact_id])

    unless rule.active?
      render json: { error: I18n.t('kanban.errors.rule_inactive', default: 'Esta regra está desativada.') }, status: :unprocessable_entity
      return
    end

    start_time = Time.zone.parse(booking_params[:start_time])
    end_time = booking_params[:end_time].present? ? Time.zone.parse(booking_params[:end_time]) : nil

    # verificar capacidade (capacidade é do local, não da regra)
    capacity = location.max_capacity.to_i
    capacity = rule.capacity.to_i if capacity.zero?
    
    booked_count = Current.account.kanban_bookings
                               .where(kanban_location_id: location.id,
                                      start_time: start_time,
                                      status: 'booked')
                               .count

    if capacity.positive? && booked_count >= capacity
      render json: { error: 'Horário indisponível (sem vagas).' }, status: :unprocessable_entity
      return
    end

    booking = Current.account.kanban_bookings.create!(
      kanban_schedule_rule: rule,
      kanban_location: location,
      kanban_board: rule.kanban_board,
      contact: contact,
      start_time: start_time,
      end_time: end_time,
      status: 'booked',
      source: booking_params[:source] || 'api',
      metadata: booking_params[:metadata] || {}
    )

    # Cards não são mais criados automaticamente - apenas visualizados na Agenda
    @booking = booking
    # Calcular ocupação após criar
    @occupancy_data = calculate_occupancy_for_booking(@booking)
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def update
    rule = if booking_params[:kanban_schedule_rule_id].present?
             Current.account.kanban_schedule_rules.find(booking_params[:kanban_schedule_rule_id])
           else
             @booking.kanban_schedule_rule
           end

    location = rule.kanban_location
    contact = if booking_params[:contact_id].present?
                Current.account.contacts.find(booking_params[:contact_id])
              else
                @booking.contact
              end

    start_time = if booking_params[:start_time].present?
                   Time.zone.parse(booking_params[:start_time])
                 else
                   @booking.start_time
                 end

    end_time = if booking_params.key?(:end_time) && booking_params[:end_time].present?
                 Time.zone.parse(booking_params[:end_time])
               elsif booking_params.key?(:end_time)
                 nil
               else
                 @booking.end_time
               end

    # verificar capacidade (capacidade é do local, não da regra)
    capacity = location.max_capacity.to_i
    capacity = rule.capacity.to_i if capacity.zero?
    
    booked_count = Current.account.kanban_bookings
                               .where(kanban_location_id: location.id,
                                      start_time: start_time,
                                      status: 'booked')
                               .where.not(id: @booking.id)
                               .count

    if capacity.positive? && booked_count >= capacity
      render json: { error: 'Horário indisponível (sem vagas).' }, status: :unprocessable_entity
      return
    end

    metadata = if params[:booking]&.key?(:metadata)
                 booking_params[:metadata]
               else
                 @booking.metadata
               end

    @booking.assign_attributes(
      kanban_schedule_rule: rule,
      kanban_location: location,
      kanban_board: rule.kanban_board,
      contact: contact,
      start_time: start_time,
      end_time: end_time,
      metadata: metadata || {}
    )

    ActiveRecord::Base.transaction do
      @booking.save!
      # Cards não são mais atualizados automaticamente - apenas visualizados na Agenda
    end
    
    # Calcular ocupação após atualizar
    @occupancy_data = calculate_occupancy_for_booking(@booking)
    render :create
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    @booking.update!(status: 'cancelled')
    head :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  def set_booking
    @booking = base_scope.find(params[:id])
  end

  def base_scope
    Current.account.kanban_bookings.includes(:kanban_schedule_rule, :kanban_location, :contact)
  end

  def calculate_occupancy_data(bookings)
    occupancy = {}
    
    bookings.each do |booking|
      key = "#{booking.kanban_location_id}_#{booking.start_time.iso8601}"
      next if occupancy[key]
      
      occupancy[key] = calculate_occupancy_for_booking(booking)
    end
    
    occupancy
  end

  def calculate_occupancy_for_booking(booking)
    location = booking.kanban_location
    rule = booking.kanban_schedule_rule
    start_time = booking.start_time
    
    # Capacidade máxima do local (prioridade: local > regra)
    max_capacity = location.max_capacity.to_i
    max_capacity = rule.capacity.to_i if max_capacity.zero?
    
    # Contar quantos bookings já existem para este local/horário (independente da regra)
    # A capacidade é do local, então contamos todos os bookings do local no mesmo horário
    booked_count = Current.account.kanban_bookings
                           .where(
                             kanban_location_id: location.id,
                             start_time: start_time,
                             status: 'booked'
                           )
                           .count
    
    {
      max_capacity: max_capacity,
      booked_count: booked_count,
      available_slots: max_capacity.positive? ? [max_capacity - booked_count, 0].max : nil,
      is_full: max_capacity.positive? && booked_count >= max_capacity
    }
  end

  def booking_params
    params.require(:booking).permit(
      :kanban_schedule_rule_id,
      :contact_id,
      :start_time,
      :end_time,
      :source,
      metadata: {}
    )
  end

  # Cria um KanbanCard representando o booking, se houver board/coluna configurados
  def create_or_link_card_for_booking!(booking, rule:, contact:, location:)
    board = rule.kanban_board
    unless board
      Rails.logger.warn("[KanbanSchedules::BookingsController] create_or_link_card_for_booking! - Board not found for rule #{rule.id}")
      return nil
    end

    column = rule.kanban_column || board.kanban_columns.ordered.first
    unless column
      Rails.logger.warn("[KanbanSchedules::BookingsController] create_or_link_card_for_booking! - No columns found for board #{board.id}")
      return nil
    end

    title = contact.name.presence || contact.email.presence || contact.phone_number.presence || rule.title
    created_by_user = Current.user || board.account.users.first
    
    unless created_by_user
      Rails.logger.error("[KanbanSchedules::BookingsController] create_or_link_card_for_booking! - No user found to create card")
      return nil
    end

    card_attrs = {
      kanban_column: column,
      title: title,
      description: rule.description,
      due_date: booking.start_time,
      start_date: booking.start_time,
      end_date: booking.end_time,
      contact: contact,
      created_by: created_by_user,
      custom_attributes: {
        booking_id: booking.id,
        booking_location_id: location.id,
        booking_location_name: location.name,
        booking_source: booking.source,
        is_booking: true
      }
    }
    
    Rails.logger.info("[KanbanSchedules::BookingsController] Creating card with attrs: #{card_attrs.except(:created_by, :kanban_column, :contact).inspect}")
    
    card = board.kanban_cards.create!(card_attrs)
    
    Rails.logger.info("[KanbanSchedules::BookingsController] Successfully created card #{card.id} for booking #{booking.id}")
    card
  rescue StandardError => e
    Rails.logger.error("[KanbanSchedules::BookingsController] create_or_link_card_for_booking! failed: #{e.class} - #{e.message}")
    Rails.logger.error("[KanbanSchedules::BookingsController] Backtrace: #{e.backtrace.first(10).join("\n")}")
    nil
  end

  def update_linked_card!(booking, rule:, contact:, location:)
    board = rule.kanban_board
    return unless board

    column = rule.kanban_column || board.kanban_columns.ordered.first
    return unless column

    title = contact.name.presence || contact.email.presence || contact.phone_number.presence || rule.title

    card = booking.kanban_card
    attrs = {
      kanban_column: column,
      title: title,
      description: rule.description,
      due_date: booking.start_time,
      start_date: booking.start_time,
      end_date: booking.end_time,
      contact: contact,
      custom_attributes: (card&.custom_attributes || {}).merge(
        booking_id: booking.id,
        booking_location_id: location.id,
        booking_location_name: location.name,
        booking_source: booking.source,
        is_booking: true
      )
    }

    if card
      card.update!(attrs)
    else
      new_card = board.kanban_cards.create!(attrs.merge(created_by: Current.user || board.account.users.first))
      booking.update!(kanban_card: new_card)
    end
  rescue StandardError => e
    Rails.logger.error("[KanbanSchedules::BookingsController] update_linked_card! failed: #{e.class} - #{e.message}")
  end
end


