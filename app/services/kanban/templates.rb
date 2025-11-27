module Kanban
  module Templates
    module_function

    # Applies a predefined template to a board:
    # - sets default settings (e.g., auto_capture)
    # - creates columns with colors, wip_limit and settings (auto labels/messages, actions placeholders)
    def apply!(board)
      return if board.blank?
      return if board.board_type == 'custom'

      # Avoid double application: if board already has columns, skip
      return if board.kanban_columns.exists?

      # Set suggested board-level settings
      case board.board_type
      when 'sales_funnel'
        board.settings ||= {}
        board.settings['auto_capture'] = true if board.settings['auto_capture'].nil?
        board.save! if board.changed?
      when 'scheduling', 'classes'
        # leave auto_capture false by default
      end

      columns = columns_for(board)
      columns.each_with_index do |col, idx|
        settings_hash = col[:settings] || col['settings'] || {}
        # Garantir que settings seja um hash com chaves string e valores convertidos
        if settings_hash.is_a?(Hash)
          settings_hash = settings_hash.each_with_object({}) do |(k, v), h|
            key = k.is_a?(Symbol) ? k.to_s : k
            # Converter arrays de símbolos para arrays de strings
            value = if v.is_a?(Array)
                      v.map { |item| item.is_a?(Symbol) ? item.to_s : item }
                    else
                      v
                    end
            h[key] = value
          end
        end
        
        column_params = {
          name: col[:name] || col['name'],
          color: col[:color] || col['color'] || '#3B82F6',
          position: col[:position] || col['position'] || idx,
          wip_limit: col[:wip_limit] || col['wip_limit'],
          settings: settings_hash
        }
        
        board.kanban_columns.create!(column_params)
      end
    end

    # Returns an array of column hashes for the given board
    def columns_for(board)
      case board.board_type
      when 'sales_funnel'
        [
          { name: 'Descoberta',    color: '#3B82F6', position: 0, settings: { auto_assign_labels: %w[lead_novo] } },
          { name: 'Qualificação',  color: '#8B5CF6', position: 1, settings: { auto_assign_labels: %w[qualificar] } },
          { name: 'Proposta',      color: '#F59E0B', position: 2, settings: { auto_message: 'Enviamos a proposta. Há algo mais que eu possa esclarecer?' } },
          { name: 'Negociação',    color: '#F59E0B', position: 3, settings: { auto_assign_labels: %w[negociacao] } },
          { name: 'Fechado - Ganhou', color: '#10B981', position: 4, settings: { auto_assign_labels: %w[ganho] } },
          { name: 'Fechado - Perdido', color: '#EF4444', position: 5, settings: { auto_assign_labels: %w[perdido] } }
        ]
      when 'scheduling'
        [
          { name: 'Entrada',       color: '#6B7280', position: 0 },
          { name: 'Agendado',      color: '#3B82F6', position: 1, settings: { auto_message: 'Agendamos sua consulta para a data informada.' } },
          { name: 'Confirmado',    color: '#10B981', position: 2, settings: { auto_assign_labels: %w[confirmado] } },
          { name: 'Realizado',     color: '#065F46', position: 3, settings: { auto_assign_labels: %w[concluido] } },
          { name: 'Reagendar',     color: '#F59E0B', position: 4, settings: { auto_message: 'Precisamos reagendar. Quais horários te atendem?' } }
        ]
      when 'classes'
        [
          { name: 'Segunda-feira', color: '#3B82F6', position: 0 },
          { name: 'Terça-feira',   color: '#8B5CF6', position: 1 },
          { name: 'Quarta-feira',  color: '#EC4899', position: 2 },
          { name: 'Quinta-feira',  color: '#F59E0B', position: 3 },
          { name: 'Sexta-feira',   color: '#10B981', position: 4 },
          { name: 'Sábado',        color: '#6366F1', position: 5 },
          { name: 'Domingo',       color: '#EF4444', position: 6 }
        ]
      else
        []
      end
    end
  end
end


