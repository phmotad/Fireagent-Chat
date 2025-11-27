class Api::V1::Accounts::KanbanCardsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_kanban_board
  before_action :fetch_kanban_card, except: [:index, :create]
  before_action :check_authorization, except: [:archive, :unarchive]

  def index
    @kanban_cards = @kanban_board.kanban_cards
                                  .includes(:contact, :conversation, :assigned_to, :created_by, :labels)
                                  .ordered

    # Filtros
    @kanban_cards = @kanban_cards.active unless params[:include_archived] == 'true'
    @kanban_cards = @kanban_cards.where(kanban_column_id: params[:column_id]) if params[:column_id].present?
    @kanban_cards = @kanban_cards.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
    @kanban_cards = @kanban_cards.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    @kanban_cards = @kanban_cards.joins(:labels).where(tags: { name: params[:label] }) if params[:label].present?
    @kanban_cards = @kanban_cards.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?
  end

  def show; end

  def create
           @kanban_card = @kanban_board.kanban_cards.build(permitted_params)
    @kanban_card.created_by = Current.user
    
    unless @kanban_card.save
      render json: { error: @kanban_card.errors.full_messages.join(', ') }, status: :unprocessable_entity
      return
    end

    # Aplicar labels se especificado
    if params[:kanban_card][:label_list].present?
      @kanban_card.update_labels(Array(params[:kanban_card][:label_list]))
    end

           # Criação automática de entidade conforme o tipo do board
           begin
             if @kanban_board.card_entity_type == 'conversation' && @kanban_card.conversation_id.blank?
               create_conversation_for_card!
             elsif @kanban_board.card_entity_type == 'contact' && @kanban_card.contact_id.blank?
               create_contact_for_card!
             end
           rescue => e
             Rails.logger.error("[Kanban] Auto entity creation failed: #{e.message}")
           end
    
    # Recarregar para incluir relacionamentos
    @kanban_card.reload
  end

  def update
    @kanban_card.update!(permitted_params)
    
    # Atualizar labels se especificado
    if params[:kanban_card][:label_list].present?
      @kanban_card.update_labels(Array(params[:kanban_card][:label_list]))
    end

    # Reordenar se necessário
    if params[:kanban_card][:position].present? || params[:kanban_card][:kanban_column_id].present?
      reorder_cards_in_column
    end
  end

  def move
    new_column = @kanban_board.kanban_columns.find(params[:kanban_card][:kanban_column_id])
    new_position = params[:kanban_card][:position].to_i

    old_column = @kanban_card.kanban_column
    
    @kanban_card.update!(
      kanban_column_id: new_column.id,
      position: new_position
    )

    # Reordenar cards nas colunas afetadas
    reorder_cards_in_column(old_column) if old_column
    reorder_cards_in_column(new_column) if new_column != old_column

    # Aplicar labels automáticos da nova coluna
    @kanban_card.apply_column_labels

    # Disparar job de gatilho de movimento (mensagens automáticas, webhooks, etc.)
    Kanban::TriggerOnMoveJob.perform_later(
      board_id: @kanban_board.id,
      card_id: @kanban_card.id,
      from_column_id: old_column&.id,
      to_column_id: new_column.id,
      user_id: Current.user&.id
    )
    
    # Recarregar para incluir relacionamentos
    @kanban_card.reload
  end

  def archive
    authorize @kanban_card, :archive?
    @kanban_card.archive!
    head :ok
  end

  def unarchive
    authorize @kanban_card, :unarchive?
    @kanban_card.unarchive!
    head :ok
  end

  def destroy
    @kanban_card.destroy!
    reorder_cards_in_column
    head :ok
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.find(params[:kanban_board_id])
  end

  def fetch_kanban_card
    @kanban_card = @kanban_board.kanban_cards.find(params[:id])
  end

  def permitted_params
    params.require(:kanban_card).permit(
      :title, :description, :due_date, :start_date, :end_date,
      :position, :kanban_column_id, :contact_id, :conversation_id,
      :assigned_to_id, :label_list, custom_attributes: {}
    )
  end

  def reorder_cards_in_column(column = nil)
    column ||= @kanban_card.kanban_column
    return unless column
    
    column.kanban_cards.ordered.each_with_index do |card, index|
      card.update_column(:position, index) unless card.position == index
    end
  end

  def check_authorization
    authorize(@kanban_card || KanbanCard)
  end

         # Helpers
         def create_conversation_for_card!
           default_inbox_id = @kanban_board.settings&.dig('default_inbox_id')
           raise 'default_inbox_id não configurado no board.settings' if default_inbox_id.blank?

           contact = @kanban_card.contact || Current.account.contacts.create!(
             name: @kanban_card.title,
             email: nil,
             phone_number: nil
           )

           conversation = Current.account.conversations.create!(
             inbox_id: default_inbox_id,
             account_id: Current.account.id,
             contact: contact,
             status: 'open'
           )

           @kanban_card.update!(conversation_id: conversation.id, contact_id: contact.id)

           auto_message = @kanban_card.kanban_column.settings&.dig('auto_message')
           if auto_message.present?
             # Envia uma mensagem inicial na conversa
             conversation.messages.create!(
               account_id: Current.account.id,
               inbox_id: default_inbox_id,
               message_type: :outgoing,
               content: auto_message,
               sender: Current.user
             )
           end
         end

         def create_contact_for_card!
           contact = Current.account.contacts.create!(
             name: @kanban_card.title,
             email: nil,
             phone_number: nil
           )
           @kanban_card.update!(contact_id: contact.id)
         end
end

