import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import KanbanAPI from '../../api/kanban';
import { kanbanLocationsAPI, kanbanScheduleRulesAPI, kanbanBookingsAPI } from '../../api/kanbanScheduling';

export const state = {
  boards: [],
  currentBoard: null,
  columns: [],
  cards: [],
  archivedCards: [],
  locations: [],
  rules: [],
  bookings: [],
  filters: {
    search: '',
    assignedTo: null,
    contact: null,
    label: null,
    column: null,
  },
  uiFlags: {
    isFetchingBoards: false,
    isFetchingBoard: false,
    isCreatingBoard: false,
    isUpdatingBoard: false,
    isDeletingBoard: false,
    isFetchingColumns: false,
    isCreatingColumn: false,
    isUpdatingColumn: false,
    isDeletingColumn: false,
    isFetchingCards: false,
    isCreatingCard: false,
    isUpdatingCard: false,
    isMovingCard: false,
    isDeletingCard: false,
    isArchivingCard: false,
    isUnarchivingCard: false,
    isFetchingArchivedCards: false,
    isFetchingLocations: false,
    isCreatingLocation: false,
    isUpdatingLocation: false,
    isDeletingLocation: false,
    isFetchingRules: false,
    isCreatingRule: false,
    isUpdatingRule: false,
    isDeletingRule: false,
    isFetchingBookings: false,
    isCreatingBooking: false,
    isUpdatingBooking: false,
    isCancellingBooking: false,
  },
};

export const getters = {
  getBoards: _state => _state.boards,
  getCurrentBoard: _state => _state.currentBoard,
  getColumns: _state => _state.columns,
  getCards: _state => _state.cards,
  getArchivedCards: _state => _state.archivedCards,
  getLocations: _state => _state.locations,
  getRules: _state => _state.rules,
  getBookings: _state => _state.bookings,
  getFilters: _state => _state.filters,
  getUIFlags: _state => _state.uiFlags,
  getCardsByColumn: _state => columnId => {
    return _state.cards.filter(card => card.kanban_column_id === columnId);
  },
  getFilteredCards: (_state, _getters) => {
    let filtered = [..._state.cards];
    const { filters } = _state;

    if (filters.search) {
      const searchLower = filters.search.toLowerCase();
      filtered = filtered.filter(
        card =>
          card.title?.toLowerCase().includes(searchLower) ||
          card.description?.toLowerCase().includes(searchLower)
      );
    }

    if (filters.assignedTo) {
      filtered = filtered.filter(
        card => card.assigned_to_id === filters.assignedTo
      );
    }

    if (filters.contact) {
      filtered = filtered.filter(card => card.contact_id === filters.contact);
    }

    if (filters.label) {
      filtered = filtered.filter(card => {
        const labelList = card.label_list || [];
        return labelList.includes(filters.label);
      });
    }

    if (filters.column) {
      filtered = filtered.filter(
        card => card.kanban_column_id === filters.column
      );
    }

    return filtered;
  },
  getBoardById: _state => id => {
    return _state.boards.find(board => board.id === Number(id));
  },
  getColumnById: _state => id => {
    return _state.columns.find(column => column.id === Number(id));
  },
  getCardById: _state => id => {
    return _state.cards.find(card => card.id === Number(id));
  },
};

export const actions = {
  fetchBoards: async ({ commit }, { includeArchived = false } = {}) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingBoards: true });
    try {
      const response = await KanbanAPI.getBoards(includeArchived);
      
      // O jbuilder retorna { payload: [...] }
      let boards = [];
      if (response?.data?.payload) {
        boards = response.data.payload;
      } else if (Array.isArray(response?.data)) {
        boards = response.data;
      } else if (response?.data?.boards && Array.isArray(response.data.boards)) {
        boards = response.data.boards;
      }
      
      commit(types.SET_KANBAN_BOARDS, Array.isArray(boards) ? boards : []);
    } catch (error) {
      console.error('Error fetching kanban boards:', error);
      if (error.response) {
        console.error('Response status:', error.response.status);
        console.error('Response data:', error.response.data);
      }
      commit(types.SET_KANBAN_BOARDS, []);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingBoards: false });
    }
  },

  fetchBoard: async ({ commit, dispatch }, boardId) => {
    if (!boardId) {
      console.error('[Kanban] fetchBoard called without boardId');
      return;
    }
    
    // Garantir que boardId é um número válido
    const id = Number(boardId);
    if (isNaN(id) || id <= 0) {
      console.error('[Kanban] Invalid boardId:', boardId);
      return;
    }
    
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingBoard: true });
    try {
      const response = await KanbanAPI.getBoard(id);
      console.log('FetchBoard response:', response.data);
      console.log('Columns in response:', response.data.kanban_columns);
      commit(types.SET_CURRENT_KANBAN_BOARD, response.data);
      const columns = response.data.kanban_columns || [];
      console.log('Setting columns:', columns);
      commit(types.SET_KANBAN_COLUMNS, columns);
      
      // Fetch cards
      await dispatch('fetchCards', { boardId: id });
    } catch (error) {
      console.error('Error fetching board:', error);
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingBoard: false });
    }
  },

  createBoard: async ({ commit, dispatch }, boardData) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingBoard: true });
    try {
      const response = await KanbanAPI.createBoard(boardData);
      const board = response.data;
      commit(types.ADD_KANBAN_BOARD, board);
      // Recarregar boards para garantir sincronização
      await dispatch('fetchBoards');
      return board;
    } catch (error) {
      console.error('Error creating kanban board:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingBoard: false });
    }
  },

  updateBoard: async ({ commit }, { id, ...updateData }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: true });
    try {
      const response = await KanbanAPI.updateBoard(id, updateData);
      commit(types.EDIT_KANBAN_BOARD, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: false });
    }
  },

  deleteBoard: async ({ commit }, id) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingBoard: true });
    try {
      await KanbanAPI.deleteBoard(id);
      commit(types.DELETE_KANBAN_BOARD, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingBoard: false });
    }
  },

  archiveBoard: async ({ dispatch, commit }, id) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: true });
    try {
      await KanbanAPI.archiveBoard(id);
      // Recarrega boards ativos
      await dispatch('fetchBoards');
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: false });
    }
  },

  unarchiveBoard: async ({ dispatch, commit }, id) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: true });
    try {
      await KanbanAPI.unarchiveBoard(id);
      // Recarrega boards ativos
      await dispatch('fetchBoards');
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingBoard: false });
    }
  },

  createColumn: async ({ commit, dispatch }, { boardId, ...columnData }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingColumn: true });
    try {
      const response = await KanbanAPI.createColumn(boardId, columnData);
      console.log('CreateColumn response:', response.data);
      const column = response.data;
      commit(types.ADD_KANBAN_COLUMN, column);
      // Recarregar board para garantir sincronização
      await dispatch('fetchBoard', boardId);
      console.log('Board reloaded after column creation');
      return column;
    } catch (error) {
      console.error('Error creating kanban column:', error);
      if (error.response) {
        console.error('Response status:', error.response.status);
        console.error('Response data:', error.response.data);
      }
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingColumn: false });
    }
  },

  updateColumn: async ({ commit, dispatch }, { boardId, id, ...updateData }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingColumn: true });
    try {
      const response = await KanbanAPI.updateColumn(boardId, id, updateData);
      commit(types.EDIT_KANBAN_COLUMN, response.data);
      // Recarregar board para garantir sincronização
      await dispatch('fetchBoard', boardId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingColumn: false });
    }
  },

  deleteColumn: async ({ commit }, { boardId, id }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingColumn: true });
    try {
      await KanbanAPI.deleteColumn(boardId, id);
      commit(types.DELETE_KANBAN_COLUMN, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingColumn: false });
    }
  },

  fetchCards: async ({ commit }, { boardId, params = {} }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingCards: true });
    try {
      const response = await KanbanAPI.getCards(boardId, params);
      commit(types.SET_KANBAN_CARDS, response.data.payload || response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingCards: false });
    }
  },

  createCard: async ({ commit, dispatch }, { boardId, kanban_card }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingCard: true });
    try {
      const response = await KanbanAPI.createCard(boardId, kanban_card);
      const card = response.data;
      commit(types.ADD_KANBAN_CARD, card);
      // Recarregar cards para garantir sincronização
      await dispatch('fetchCards', { boardId });
      return card;
    } catch (error) {
      console.error('Error creating kanban card:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingCard: false });
    }
  },

  updateCard: async ({ commit, dispatch }, { boardId, id, kanban_card }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingCard: true });
    try {
      const response = await KanbanAPI.updateCard(boardId, id, kanban_card);
      commit(types.EDIT_KANBAN_CARD, response.data);
      // Recarregar cards para garantir sincronização
      await dispatch('fetchCards', { boardId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingCard: false });
    }
  },

  moveCard: async ({ commit, dispatch }, { boardId, id, kanban_card }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isMovingCard: true });
    try {
      const response = await KanbanAPI.moveCard(boardId, id, kanban_card);
      commit(types.MOVE_KANBAN_CARD, response.data);
      // Recarregar cards para garantir sincronização
      await dispatch('fetchCards', { boardId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isMovingCard: false });
    }
  },

  deleteCard: async ({ commit }, { boardId, id }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingCard: true });
    try {
      await KanbanAPI.deleteCard(boardId, id);
      commit(types.DELETE_KANBAN_CARD, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingCard: false });
    }
  },

  archiveCard: async ({ commit }, { boardId, id }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isArchivingCard: true });
    try {
      await KanbanAPI.archiveCard(boardId, id);
      commit(types.DELETE_KANBAN_CARD, id); // Remove da lista ativa
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isArchivingCard: false });
    }
  },

  unarchiveCard: async ({ commit, dispatch }, { boardId, id }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUnarchivingCard: true });
    try {
      await KanbanAPI.unarchiveCard(boardId, id);
      // Remover dos arquivados
      commit(types.DELETE_KANBAN_ARCHIVED_CARD, id);
      // Recarregar cards para incluir o desarquivado
      await dispatch('fetchCards', { boardId, includeArchived: false });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUnarchivingCard: false });
    }
  },

  fetchArchivedCards: async ({ commit }, { boardId }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingArchivedCards: true });
    try {
      const response = await KanbanAPI.getCards(boardId, { include_archived: 'true' });
      const cards = response?.data?.payload || response?.data || [];
      const archivedCards = Array.isArray(cards) ? cards.filter(c => c.archived_at) : [];
      commit(types.SET_KANBAN_ARCHIVED_CARDS, archivedCards);
      return archivedCards;
    } catch (error) {
      console.error('Error fetching archived cards:', error);
      commit(types.SET_KANBAN_ARCHIVED_CARDS, []);
      throw new Error(error);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingArchivedCards: false });
    }
  },

  // Locations
  fetchLocations: async ({ commit }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingLocations: true });
    try {
      const response = await kanbanLocationsAPI.getLocations();
      const locations = response?.data?.payload || response?.data || [];
      commit(types.SET_KANBAN_LOCATIONS, Array.isArray(locations) ? locations : []);
    } catch (error) {
      console.error('Error fetching kanban locations:', error);
      commit(types.SET_KANBAN_LOCATIONS, []);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingLocations: false });
    }
  },

  createLocation: async ({ commit }, payload) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingLocation: true });
    try {
      const response = await kanbanLocationsAPI.createLocation(payload);
      commit(types.ADD_KANBAN_LOCATION, response.data);
      return response.data;
    } catch (error) {
      console.error('Error creating kanban location:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingLocation: false });
    }
  },

  updateLocation: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingLocation: true });
    try {
      const response = await kanbanLocationsAPI.updateLocation(id, payload);
      commit(types.EDIT_KANBAN_LOCATION, response.data);
      return response.data;
    } catch (error) {
      console.error('Error updating kanban location:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingLocation: false });
    }
  },

  deleteLocation: async ({ commit }, id) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingLocation: true });
    try {
      await kanbanLocationsAPI.deleteLocation(id);
      commit(types.DELETE_KANBAN_LOCATION, id);
    } catch (error) {
      console.error('Error deleting kanban location:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingLocation: false });
    }
  },

  // Rules
  fetchRules: async ({ commit }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingRules: true });
    try {
      const response = await kanbanScheduleRulesAPI.getRules();
      const rules = response?.data?.payload || response?.data || [];
      commit(types.SET_KANBAN_RULES, Array.isArray(rules) ? rules : []);
    } catch (error) {
      console.error('Error fetching kanban schedule rules:', error);
      commit(types.SET_KANBAN_RULES, []);
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isFetchingRules: false });
    }
  },

  createRule: async ({ commit }, payload) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingRule: true });
    try {
      const response = await kanbanScheduleRulesAPI.createRule(payload);
      commit(types.ADD_KANBAN_RULE, response.data);
      return response.data;
    } catch (error) {
      console.error('Error creating kanban schedule rule:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isCreatingRule: false });
    }
  },

  updateRule: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingRule: true });
    try {
      const response = await kanbanScheduleRulesAPI.updateRule(id, payload);
      commit(types.EDIT_KANBAN_RULE, response.data);
      return response.data;
    } catch (error) {
      console.error('Error updating kanban schedule rule:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isUpdatingRule: false });
    }
  },

  deleteRule: async ({ commit }, id) => {
    commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingRule: true });
    try {
      await kanbanScheduleRulesAPI.deleteRule(id);
      commit(types.DELETE_KANBAN_RULE, id);
    } catch (error) {
      console.error('Error deleting kanban schedule rule:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOARD_UI_FLAG, { isDeletingRule: false });
    }
  },

  // Bookings
  fetchBookings: async ({ commit }, params = {}) => {
    commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isFetchingBookings: true });
    try {
      const response = await kanbanBookingsAPI.getBookings(params);
      const bookings = response?.data?.payload || response?.data || [];
      commit(types.SET_KANBAN_BOOKINGS, Array.isArray(bookings) ? bookings : []);
    } catch (error) {
      console.error('Error fetching kanban bookings:', error);
      commit(types.SET_KANBAN_BOOKINGS, []);
    } finally {
      commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isFetchingBookings: false });
    }
  },

  getAvailability: async ({ commit }, params = {}) => {
    try {
      const response = await kanbanBookingsAPI.getAvailability(params);
      return response?.data || {};
    } catch (error) {
      console.error('Error fetching availability:', error);
      throw error;
    }
  },

  createBooking: async ({ commit }, payload) => {
    commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isCreatingBooking: true });
    try {
      const response = await kanbanBookingsAPI.createBooking(payload);
      commit(types.ADD_KANBAN_BOOKING, response.data);
      return response.data;
    } catch (error) {
      console.error('Error creating kanban booking:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isCreatingBooking: false });
    }
  },

  updateBooking: async ({ commit }, { id, payload }) => {
    commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isUpdatingBooking: true });
    try {
      const response = await kanbanBookingsAPI.updateBooking(id, payload);
      commit(types.EDIT_KANBAN_BOOKING, response.data);
      return response.data;
    } catch (error) {
      console.error('Error updating kanban booking:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isUpdatingBooking: false });
    }
  },

  cancelBooking: async ({ commit }, id) => {
    commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isCancellingBooking: true });
    try {
      await kanbanBookingsAPI.cancelBooking(id);
      commit(types.DELETE_KANBAN_BOOKING, id);
    } catch (error) {
      console.error('Error cancelling kanban booking:', error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_BOOKING_UI_FLAG, { isCancellingBooking: false });
    }
  },

  setFilters: ({ commit }, filters) => {
    commit('SET_KANBAN_FILTERS', filters);
  },
};

export const mutations = {
  [types.SET_KANBAN_BOARD_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_KANBAN_BOARDS](_state, boards) {
    _state.boards = Array.isArray(boards) ? boards : [];
  },
  [types.ADD_KANBAN_BOARD](_state, board) {
    _state.boards.push(board);
  },
  [types.EDIT_KANBAN_BOARD](_state, board) {
    const index = _state.boards.findIndex(b => b.id === board.id);
    if (index !== -1) {
      _state.boards[index] = board;
    }
  },
  [types.DELETE_KANBAN_BOARD](_state, boardId) {
    const index = _state.boards.findIndex(b => b.id === boardId);
    if (index !== -1) {
      _state.boards.splice(index, 1);
    }
  },

  [types.SET_CURRENT_KANBAN_BOARD](_state, board) {
    _state.currentBoard = board;
  },

  [types.SET_KANBAN_COLUMNS](_state, columns) {
    _state.columns = Array.isArray(columns) ? columns : [];
  },
  [types.ADD_KANBAN_COLUMN](_state, column) {
    _state.columns.push(column);
  },
  [types.EDIT_KANBAN_COLUMN](_state, column) {
    const index = _state.columns.findIndex(c => c.id === column.id);
    if (index !== -1) {
      _state.columns[index] = column;
    }
  },
  [types.DELETE_KANBAN_COLUMN](_state, columnId) {
    const index = _state.columns.findIndex(c => c.id === columnId);
    if (index !== -1) {
      _state.columns.splice(index, 1);
    }
  },

  [types.SET_KANBAN_CARDS](_state, cards) {
    _state.cards = Array.isArray(cards) ? cards : [];
  },
  [types.ADD_KANBAN_CARD](_state, card) {
    _state.cards.push(card);
  },
  [types.EDIT_KANBAN_CARD](_state, card) {
    const index = _state.cards.findIndex(c => c.id === card.id);
    if (index !== -1) {
      _state.cards[index] = card;
    }
  },
  [types.DELETE_KANBAN_CARD](_state, cardId) {
    const index = _state.cards.findIndex(c => c.id === cardId);
    if (index !== -1) {
      _state.cards.splice(index, 1);
    }
  },

  [types.MOVE_KANBAN_CARD](_state, card) {
    const index = _state.cards.findIndex(c => c.id === card.id);
    if (index !== -1) {
      _state.cards.splice(index, 1, card);
    }
  },

  [types.SET_KANBAN_ARCHIVED_CARDS](_state, cards) {
    _state.archivedCards = Array.isArray(cards) ? cards : [];
  },
  [types.DELETE_KANBAN_ARCHIVED_CARD](_state, cardId) {
    const index = _state.archivedCards.findIndex(c => c.id === cardId);
    if (index !== -1) {
      _state.archivedCards.splice(index, 1);
    }
  },

  [types.SET_KANBAN_LOCATIONS](_state, locations) {
    _state.locations = Array.isArray(locations) ? locations : [];
  },
  [types.ADD_KANBAN_LOCATION](_state, location) {
    _state.locations.push(location);
  },
  [types.EDIT_KANBAN_LOCATION](_state, location) {
    const index = _state.locations.findIndex(l => l.id === location.id);
    if (index !== -1) {
      _state.locations[index] = location;
    }
  },
  [types.DELETE_KANBAN_LOCATION](_state, locationId) {
    const index = _state.locations.findIndex(l => l.id === locationId);
    if (index !== -1) {
      _state.locations.splice(index, 1);
    }
  },

  [types.SET_KANBAN_RULES](_state, rules) {
    _state.rules = Array.isArray(rules) ? rules : [];
  },
  [types.ADD_KANBAN_RULE](_state, rule) {
    _state.rules.push(rule);
  },
  [types.EDIT_KANBAN_RULE](_state, rule) {
    const index = _state.rules.findIndex(r => r.id === rule.id);
    if (index !== -1) {
      _state.rules[index] = rule;
    }
  },
  [types.DELETE_KANBAN_RULE](_state, ruleId) {
    const index = _state.rules.findIndex(r => r.id === ruleId);
    if (index !== -1) {
      _state.rules.splice(index, 1);
    }
  },

  [types.SET_KANBAN_BOOKINGS](_state, bookings) {
    _state.bookings = Array.isArray(bookings) ? bookings : [];
  },
  [types.ADD_KANBAN_BOOKING](_state, booking) {
    _state.bookings.push(booking);
  },
  [types.EDIT_KANBAN_BOOKING](_state, booking) {
    const index = _state.bookings.findIndex(b => b.id === booking.id);
    if (index !== -1) {
      _state.bookings[index] = booking;
    }
  },
  [types.DELETE_KANBAN_BOOKING](_state, bookingId) {
    const index = _state.bookings.findIndex(b => b.id === bookingId);
    if (index !== -1) {
      _state.bookings.splice(index, 1);
    }
  },
  [types.SET_KANBAN_BOOKING_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  SET_KANBAN_FILTERS(_state, filters) {
    _state.filters = {
      ..._state.filters,
      ...filters,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};

