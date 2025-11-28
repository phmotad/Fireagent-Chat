class AiAgentPolicy < ApplicationPolicy
  def index?
    true  # Permite todos os usuários autenticados
  end

  def show?
    true
  end

  def create?
    @account_user.administrator?  # Apenas admins podem criar
  end

  def update?
    @account_user.administrator?  # Apenas admins podem editar
  end

  def destroy?
    @account_user.administrator?  # Apenas admins podem deletar
  end
end
