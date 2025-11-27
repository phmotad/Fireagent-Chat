import ApiClient from './ApiClient';

class KanbanLocationsAPI extends ApiClient {
  constructor() {
    super('kanban_locations', { accountScoped: true });
  }

  getLocations() {
    return this.get('');
  }

  createLocation(payload) {
    return this.post('', { kanban_location: payload });
  }

  updateLocation(id, payload) {
    return this.patch(`/${id}`, { kanban_location: payload });
  }

  deleteLocation(id) {
    return this.delete(`/${id}`);
  }
}

class KanbanScheduleRulesAPI extends ApiClient {
  constructor() {
    super('kanban_schedule_rules', { accountScoped: true });
  }

  getRules() {
    return this.get('');
  }

  createRule(payload) {
    return this.post('', { kanban_schedule_rule: payload });
  }

  updateRule(id, payload) {
    return this.patch(`/${id}`, { kanban_schedule_rule: payload });
  }

  deleteRule(id) {
    return this.delete(`/${id}`);
  }
}

class KanbanBookingsAPI extends ApiClient {
  constructor() {
    super('kanban_schedules', { accountScoped: true });
  }

  getBookings(params = {}) {
    return this.get('/bookings', { params });
  }

  getAvailability(params = {}) {
    return this.get('/availability', { params });
  }

  createBooking(payload) {
    return this.post('/bookings', { booking: payload });
  }

  updateBooking(id, payload) {
    return this.patch(`/bookings/${id}`, { booking: payload });
  }

  cancelBooking(id) {
    return this.delete(`/bookings/${id}`);
  }
}

export const kanbanLocationsAPI = new KanbanLocationsAPI();
export const kanbanScheduleRulesAPI = new KanbanScheduleRulesAPI();
export const kanbanBookingsAPI = new KanbanBookingsAPI();


