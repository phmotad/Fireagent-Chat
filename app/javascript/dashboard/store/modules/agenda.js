import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import agendaAPI from '../../api/agenda';

export const state = {
  agendaData: {
    bookings: [],
    cards: [],
  },
  selectedBoards: [],
  viewMode: 'calendar', // 'calendar' | 'list'
  dateRange: {
    start: null,
    end: null,
  },
  uiFlags: {
    isFetchingAgenda: false,
  },
};

export const getters = {
  getAgendaData: state => state.agendaData,
  getSelectedBoards: state => state.selectedBoards,
  getViewMode: state => state.viewMode,
  getDateRange: state => state.dateRange,
  getUIFlags: state => state.uiFlags,
};

export const actions = {
  async fetchAgendaData({ commit, state }, params = {}) {
    commit(types.SET_AGENDA_UI_FLAG, { isFetchingAgenda: true });
    
    try {
      const queryParams = {
        ...params,
        // Sempre enviar board_ids, mesmo que vazio, para garantir que bookings sejam retornados
        board_ids: state.selectedBoards.length > 0 ? state.selectedBoards : [],
      };
      
      const response = await agendaAPI.getAgendaData(queryParams);
      const data = response.data || { bookings: [], cards: [] };
      
      // Garantir que bookings sempre existam no retorno
      commit(types.SET_AGENDA_DATA, {
        bookings: data.bookings || [],
        cards: data.cards || [],
      });
    } catch (error) {
      console.error('Error fetching agenda data:', error);
      commit(types.SET_AGENDA_DATA, { bookings: [], cards: [] });
    } finally {
      commit(types.SET_AGENDA_UI_FLAG, { isFetchingAgenda: false });
    }
  },

  setSelectedBoards({ commit }, boardIds) {
    commit(types.SET_AGENDA_SELECTED_BOARDS, boardIds);
  },

  setViewMode({ commit }, mode) {
    commit(types.SET_AGENDA_VIEW_MODE, mode);
  },

  setDateRange({ commit }, range) {
    commit(types.SET_AGENDA_DATE_RANGE, range);
  },
};

export const mutations = {
  [types.SET_AGENDA_DATA](state, data) {
    state.agendaData = data;
  },

  [types.SET_AGENDA_SELECTED_BOARDS](state, boardIds) {
    state.selectedBoards = boardIds;
  },

  [types.SET_AGENDA_VIEW_MODE](state, mode) {
    state.viewMode = mode;
  },

  [types.SET_AGENDA_DATE_RANGE](state, range) {
    state.dateRange = range;
  },

  [types.SET_AGENDA_UI_FLAG](state, flags) {
    state.uiFlags = { ...state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};

