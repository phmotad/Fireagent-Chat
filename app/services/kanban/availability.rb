module Kanban
  class Availability
    pattr_initialize [:account!, :location!, :from!, :to!, :rule_id]

    # Retorna uma lista de slots com capacidade/disponibilidade para o intervalo solicitado
    def slots
      rules = base_rules
      rules.flat_map { |rule| slots_for_rule(rule) }
    end

    private

    def base_rules
      scope = account.kanban_schedule_rules.where(kanban_location_id: location.id)
      scope = scope.where(id: rule_id) if rule_id.present?
      scope
    end

    def slots_for_rule(rule)
      case rule.rule_type
      when 'once'
        build_single_slot(rule)
      when 'weekly'
        build_weekly_slots(rule)
      else
        []
      end
    end

    def build_single_slot(rule)
      start_time = rule.starts_at
      return [] if start_time < from || start_time > to

      end_time = rule.ends_at || (start_time.change(hour: rule.time_end&.hour, min: rule.time_end&.min) if rule.time_end)
      end_time ||= start_time + 1.hour

      [slot_hash(rule, start_time, end_time)]
    end

    def build_weekly_slots(rule)
      result = []
      range_start = [from, rule.starts_at].max
      range_end = [to, (rule.ends_at || to)].min

      current = range_start.beginning_of_day
      while current <= range_end.end_of_day
        if rule.weekdays.include?(current.wday)
          slot_start = combine_date_time(current, rule.time_start)
          slot_end = rule.time_end ? combine_date_time(current, rule.time_end) : slot_start + 1.hour

          if slot_start >= from && slot_start <= to
            result << slot_hash(rule, slot_start, slot_end)
          end
        end
        current += 1.day
      end

      result
    end

    def combine_date_time(date, time)
      Time.zone.local(date.year, date.month, date.day, time.hour, time.min, 0)
    end

    def slot_hash(rule, start_time, end_time)
      capacity = rule.capacity.to_i

      booked_count = account.kanban_bookings
                            .where(kanban_schedule_rule_id: rule.id,
                                   kanban_location_id: location.id,
                                   start_time: start_time,
                                   status: 'booked')
                            .count

      {
        rule_id: rule.id,
        location_id: location.id,
        start_time: start_time,
        end_time: end_time,
        capacity: capacity,
        booked: booked_count,
        available: [capacity - booked_count, 0].max
      }
    end
  end
end


