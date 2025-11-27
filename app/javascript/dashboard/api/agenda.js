import ApiClient from './ApiClient';

class AgendaAPI extends ApiClient {
  constructor() {
    super('agenda', { accountScoped: true });
  }

  getAgendaData(params = {}) {
    return this.get('', { params });
  }
}

export default new AgendaAPI();

