# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_agent_inboxes
#
#  id           :bigint           not null, primary key
#  status       :integer          default("active"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  ai_agent_id  :bigint           not null
#  inbox_id     :bigint           not null
#
# Indexes
#
#  index_ai_agent_inboxes_on_account_id                  (account_id)
#  index_ai_agent_inboxes_on_ai_agent_id                 (ai_agent_id)
#  index_ai_agent_inboxes_on_ai_agent_id_and_inbox_id    (ai_agent_id,inbox_id) UNIQUE
#  index_ai_agent_inboxes_on_inbox_id                    (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (ai_agent_id => ai_agents.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#

class AiAgentInbox < ApplicationRecord
  belongs_to :account
  belongs_to :ai_agent
  belongs_to :inbox

  enum status: { active: 0, inactive: 1 }

  validates :ai_agent_id, uniqueness: { scope: :inbox_id }
end
