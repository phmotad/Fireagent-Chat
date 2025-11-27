module Kanban
  class AutoCapture
    def initialize(account, entity_type, entity)
      @account = account
      @entity_type = entity_type # 'conversation' or 'contact'
      @entity = entity
    end

    def perform
      return unless %w[conversation contact].include?(@entity_type)
      return unless @account

      boards = @account.kanban_boards.active.where(card_entity_type: @entity_type)
      boards = boards.select { |b| b.settings&.dig('auto_capture') }
      return if boards.blank?

      boards.each do |board|
        create_card_for_board(board)
      rescue => e
        Rails.logger.error("[Kanban::AutoCapture] board_id=#{board.id} error=#{e.message}")
      end
    end

    private

    def create_card_for_board(board)
      column = find_matching_column(board)
      return unless column

      creator = pick_creator_for(board)
      return unless creator

      attributes = {
        kanban_board_id: board.id,
        kanban_column_id: column.id,
        title: default_title,
        description: nil,
        position: 0,
        created_by_id: creator.id
      }

      if @entity_type == 'conversation'
        attributes[:conversation_id] = @entity.id
        attributes[:contact_id] = @entity.contact_id if @entity.respond_to?(:contact_id)
      else
        attributes[:contact_id] = @entity.id
      end

      ::KanbanCard.create!(attributes)
    end

    def find_matching_column(board)
      columns = board.kanban_columns.ordered
      return columns.first if columns.blank?

      # Busca coluna que tenha critério de etiquetas correspondente
      columns.each do |column|
        criteria_labels = column.settings&.dig('criteria_labels') || []
        next if criteria_labels.blank?

        # Verifica se a entidade tem TODAS as etiquetas do critério
        entity_labels = get_entity_labels
        if criteria_labels.all? { |label| entity_labels.include?(label) }
          return column
        end
      end

      # Se nenhuma coluna corresponder ao critério, usa a primeira
      columns.first
    end

    def get_entity_labels
      # label_list retorna um array de strings (nomes das etiquetas)
      labels = @entity.label_list || []
      # Garante que seja um array de strings
      Array(labels).map(&:to_s)
    end

    def default_title
      if @entity_type == 'conversation'
        "Conversa ##{@entity.display_id || @entity.id}"
      else
        @entity.name.presence || "Contato ##{@entity.id}"
      end
    end

    def pick_creator_for(board)
      # escolhe um usuário do account para ser o criador do card
      # prioridade: Current.user -> primeiro admin -> primeiro usuário
      return Current.user if defined?(Current) && Current.respond_to?(:user) && Current.user.present?

      admin = @account.users.joins(:account_users).where(account_users: { role: :administrator }).first rescue nil
      return admin if admin

      @account.users.first
    end
  end
end


