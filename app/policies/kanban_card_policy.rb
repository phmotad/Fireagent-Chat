class KanbanCardPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator? || @account_user.agent?
  end

  def destroy?
    @account_user.administrator? || @account_user.agent?
  end

  def move?
    @account_user.administrator? || @account_user.agent?
  end

  def archive?
    @account_user.administrator? || @account_user.agent?
  end

  def unarchive?
    @account_user.administrator? || @account_user.agent?
  end
end

