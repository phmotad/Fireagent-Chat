"""Tests for RAG engine."""
import pytest
from unittest.mock import patch, MagicMock
from rag_engine import RAGEngine

@pytest.fixture
def rag_engine():
    return RAGEngine()

def test_chunk_text(rag_engine):
    """Test text chunking."""
    text = "1234567890" * 20  # 200 chars
    chunks = rag_engine.chunk_text(text, chunk_size=50, overlap=10)
    
    assert len(chunks) > 0
    assert len(chunks[0]) == 50
    # Check overlap
    assert chunks[1].startswith(chunks[0][-10:])

@patch('rag_engine.gemini_client')
@patch('rag_engine.db')
def test_search_knowledge(mock_db, mock_gemini, rag_engine):
    """Test knowledge search."""
    mock_gemini.generate_embedding.return_value = [0.1, 0.2, 0.3]
    mock_db.search_knowledge_base.return_value = [
        {
            "metadata": {"content": "Relevant info"},
            "file_path": "doc.txt",
            "similarity": 0.9
        }
    ]
    
    result = rag_engine.search_knowledge(1, "query")
    
    assert "Relevant info" in result
    assert "doc.txt" in result
    mock_gemini.generate_embedding.assert_called_with("query")
    mock_db.search_knowledge_base.assert_called_once()
