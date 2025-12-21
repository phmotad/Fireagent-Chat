# frozen_string_literal: true

# == Schema Information
#
# Table name: llm_providers
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE)
#  api_base_url  :string
#  api_key       :string
#  config        :jsonb
#  name          :string           not null
#  provider_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  index_llm_providers_on_account_id              (account_id)
#  index_llm_providers_uniqueness                 (account_id,provider_type,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class LlmProvider < ApplicationRecord
  belongs_to :account

  has_many :ai_agents_as_conversation, class_name: 'AiAgent', foreign_key: 'llm_provider_conversation_id', dependent: :nullify
  has_many :ai_agents_as_supervisor, class_name: 'AiAgent', foreign_key: 'llm_provider_supervisor_id', dependent: :nullify
  has_many :ai_agents_as_embedding, class_name: 'AiAgent', foreign_key: 'llm_provider_embedding_id', dependent: :nullify

  # Provider types supported by Google ADK
  PROVIDER_TYPES = %w[
    gemini
    openai
    anthropic
    ollama
    litellm
    vertex_ai
  ].freeze

  validates :name, presence: true
  validates :provider_type, presence: true, inclusion: { in: PROVIDER_TYPES }
  validates :name, uniqueness: { scope: [:account_id, :provider_type] }

  # Config structure examples:
  # Gemini: { model: "gemini-2.0-flash", temperature: 0.7, max_tokens: 2048 }
  # OpenAI: { model: "gpt-4o", temperature: 0.7, max_tokens: 2048 }
  # Anthropic: { model: "claude-3-7-sonnet-latest", temperature: 0.7, max_tokens: 4096 }
  # Ollama: { model: "mistral-small3.1", temperature: 0.7 }
  # LiteLLM: { model: "openai/gpt-4o", temperature: 0.7 }

  def masked_api_key
    return nil if api_key.blank?
    "#{api_key[0..7]}...#{api_key[-4..]}"
  end

  def to_adk_config
    {
      provider: provider_type,
      model: config['model'],
      api_key: api_key,
      api_base: api_base_url,
      **config.except('model')
    }.compact
  end
end
