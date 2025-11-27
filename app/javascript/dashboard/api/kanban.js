import ApiClient from './ApiClient';

class KanbanAPI extends ApiClient {
  constructor() {
    super('kanban_boards', { accountScoped: true });
  }

  getBoards(includeArchived = false) {
    return this.get('', { params: { include_archived: includeArchived } });
  }

  getBoard(boardId) {
    if (!boardId) {
      return Promise.reject(new Error('Board ID is required'));
    }
    // Garantir que boardId é um número ou string válida
    const id = String(boardId).replace(/[^0-9]/g, '');
    if (!id) {
      return Promise.reject(new Error('Invalid board ID'));
    }
    return this.get(`/${id}`);
  }

  createBoard(boardData) {
    return this.post('', { kanban_board: boardData });
  }

  updateBoard(boardId, boardData) {
    return this.patch(`/${boardId}`, { kanban_board: boardData });
  }

  deleteBoard(boardId) {
    return this.delete(`/${boardId}`);
  }

  archiveBoard(boardId) {
    return this.post(`/${boardId}/archive`);
  }

  unarchiveBoard(boardId) {
    return this.post(`/${boardId}/unarchive`);
  }

  getColumns(boardId) {
    return this.get(`/${boardId}/kanban_columns`);
  }

  createColumn(boardId, columnData) {
    return this.post(`/${boardId}/kanban_columns`, { kanban_column: columnData });
  }

  updateColumn(boardId, columnId, columnData) {
    return this.patch(`/${boardId}/kanban_columns/${columnId}`, { kanban_column: columnData });
  }

  deleteColumn(boardId, columnId) {
    return this.delete(`/${boardId}/kanban_columns/${columnId}`);
  }

  getCards(boardId, params = {}) {
    return this.get(`/${boardId}/kanban_cards`, { params });
  }

  getCard(boardId, cardId) {
    return this.get(`/${boardId}/kanban_cards/${cardId}`);
  }

  createCard(boardId, cardData) {
    return this.post(`/${boardId}/kanban_cards`, { kanban_card: cardData });
  }

  updateCard(boardId, cardId, cardData) {
    return this.patch(`/${boardId}/kanban_cards/${cardId}`, { kanban_card: cardData });
  }

  moveCard(boardId, cardId, cardData) {
    return this.post(`/${boardId}/kanban_cards/${cardId}/move`, { kanban_card: cardData });
  }

  deleteCard(boardId, cardId) {
    return this.delete(`/${boardId}/kanban_cards/${cardId}`);
  }

  archiveCard(boardId, cardId) {
    return this.post(`/${boardId}/kanban_cards/${cardId}/archive`);
  }

  unarchiveCard(boardId, cardId) {
    return this.post(`/${boardId}/kanban_cards/${cardId}/unarchive`);
  }
}

export default new KanbanAPI();

