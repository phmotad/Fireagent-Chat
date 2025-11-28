class CreateAiAgentKnowledgeSources < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_knowledge_sources do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.string :file_path
      t.string :content_type
      t.string :status, default: 'pending'
      t.jsonb :metadata, default: {}
      t.vector :embedding, limit: 768  # Gemini embedding dimension

      t.timestamps
    end

    # Add index for vector similarity search
    add_index :ai_agent_knowledge_sources, :embedding,
              using: :ivfflat,
              opclass: :vector_cosine_ops
  end
end
