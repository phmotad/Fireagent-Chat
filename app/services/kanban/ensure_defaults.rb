module Kanban
  class EnsureDefaults
    def initialize(account, preferred_board: nil)
      @account = account
      @preferred_board = preferred_board
    end

    def call
      return unless account

      ActiveRecord::Base.transaction do
        ensure_default_location
        ensure_default_rule
      end
    end

    private

    attr_reader :account, :preferred_board

    def ensure_default_location
      @default_location ||= account.kanban_locations.find_by(is_default: true) ||
                            account.kanban_locations.create!(
                              name: I18n.t('kanban.defaults.location_name', default: 'Local padrão'),
                              description: I18n.t('kanban.defaults.location_description',
                                                  default: 'Local padrão utilizado pelos agendamentos'),
                              is_default: true
                            )
    end

    def ensure_default_rule
      return if account.kanban_schedule_rules.exists?(is_default: true)

      board = preferred_board || account.kanban_boards.order(:created_at).first
      return unless board

      account.kanban_schedule_rules.create!(
        title: I18n.t('kanban.defaults.rule_title', default: 'Regra padrão'),
        description: I18n.t('kanban.defaults.rule_description',
                            default: 'Regra inicial para agendamentos'),
        kanban_board: board,
        kanban_location: ensure_default_location,
        rule_type: 'once',
        active: true,
        is_default: true
      )
    end
  end
end

