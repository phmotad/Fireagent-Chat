"""Tests for memory manager."""
import pytest
from unittest.mock import Mock, patch
from memory_manager import MemoryManager

@pytest.fixture
def memory_manager():
    return MemoryManager()

@pytest.fixture
def mock_redis():
    with patch('memory_manager.redis_client') as mock:
        yield mock

@pytest.fixture
def mock_db():
    with patch('memory_manager.db') as mock:
        yield mock

def test_get_conversation_history_redis_hit(memory_manager, mock_redis, mock_db):
    """Test getting history when Redis has data."""
    mock_redis.get_context.return_value = [
        {"content": "Hello", "message_type": 0},
        {"content": "Hi", "message_type": 1},
        {"content": "3", "message_type": 0},
        {"content": "4", "message_type": 1},
        {"content": "5", "message_type": 0}
    ]
    
    history = memory_manager.get_conversation_history(1, window_size=5)
    
    assert len(history) == 5
    assert history[0]["content"] == "Hello"
    mock_redis.get_context.assert_called_once_with(1)
    mock_db.get_conversation_messages.assert_not_called()

def test_get_conversation_history_redis_miss(memory_manager, mock_redis, mock_db):
    """Test getting history when Redis is empty (fallback to DB)."""
    mock_redis.get_context.return_value = []
    mock_db.get_conversation_messages.return_value = [
        {"content": "Old", "message_type": 0},
        {"content": "New", "message_type": 1}
    ]
    
    history = memory_manager.get_conversation_history(1, window_size=5)
    
    assert len(history) == 2
    assert history[0]["content"] == "Old"
    mock_db.get_conversation_messages.assert_called_once_with(1, 5)
    mock_redis.save_context.assert_called_once()

def test_add_message(memory_manager, mock_redis):
    """Test adding a message."""
    memory_manager.add_message(1, "Test", 0)
    
    mock_redis.append_message.assert_called_once()
    args = mock_redis.append_message.call_args
    assert args[0][0] == 1
    assert args[0][1]["content"] == "Test"
    assert args[0][1]["message_type"] == 0

def test_format_for_gemini(memory_manager):
    """Test formatting messages for Gemini."""
    messages = [
        {"content": "User msg", "message_type": 0},
        {"content": "AI msg", "message_type": 1}
    ]
    
    formatted = memory_manager.format_for_gemini(messages)
    
    assert len(formatted) == 2
    assert formatted[0]["role"] == "user"
    assert formatted[0]["parts"][0]["text"] == "User msg"
    assert formatted[1]["role"] == "model"
    assert formatted[1]["parts"][0]["text"] == "AI msg"
