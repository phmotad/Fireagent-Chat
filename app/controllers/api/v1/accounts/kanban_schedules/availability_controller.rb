class Api::V1::Accounts::KanbanSchedules::AvailabilityController < Api::V1::Accounts::BaseController
  before_action :current_account

  def index
    location = Current.account.kanban_locations.find(params.require(:location_id))

    from = Time.zone.parse(params.require(:date_from))
    to   = Time.zone.parse(params.require(:date_to))

    service = Kanban::Availability.new(
      account: Current.account,
      location: location,
      from: from,
      to: to,
      rule_id: params[:rule_id]
    )

    @slots = service.slots
  rescue ArgumentError, KeyError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end


