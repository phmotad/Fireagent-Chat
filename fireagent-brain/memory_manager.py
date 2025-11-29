"""Memory manager combining Redis and Postgres."""
from typing import List, Dict, Any
from database import db
from redis_client import redis_client
from models import Message
import logging

logger = logging.getLogger(__name__)


class MemoryManager:
    """Manage conversation memory from Redis and Postgres."""
    
    def get_conversation_history(
        self, 
        conversation_id: int,
        window_size: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get conversation history combining Redis (short-term) and Postgres (long-term).
        
        Args:
            conversation_id: Conversation ID
            window_size: Number of messages to retrieve
            
        Returns:
            List of messages in chronological order
        """
        # Try Redis first (faster)
        redis_messages = redis_client.get_context(conversation_id)
        
        if redis_messages and len(redis_messages) >= window_size:
            # Redis has enough messages
            return redis_messages[-window_size:]
        
        # Fallback to Postgres for full history
        db_messages = db.get_conversation_messages(conversation_id, window_size)
        
        # Update Redis cache
        if db_messages:
            redis_client.save_context(conversation_id, db_messages)
        
        return db_messages[-window_size:] if db_messages else []
    
    def add_message(
        self, 
        conversation_id: int,
        content: str,
        message_type: int,  # 0=incoming, 1=outgoing
        sender_type: str = "User",
        max_window: int = 10
    ):
        """
        Add message to memory.
        
        Args:
            conversation_id: Conversation ID
            content: Message content
            message_type: 0 for incoming, 1 for outgoing
            sender_type: Type of sender
            max_window: Maximum messages to keep in Redis
        """
        message = {
            "content": content,
            "message_type": message_type,
            "sender_type": sender_type,
            "created_at": None  # Will be set by Chatwoot
        }
        
        redis_client.append_message(conversation_id, message, max_window)
    
    def format_for_gemini(
        self, 
        messages: List[Dict[str, Any]]
    ) -> List[Dict[str, str]]:
        """
        Format messages for Gemini API.
        
        Args:
            messages: List of message dicts
            
        Returns:
            List formatted for Gemini (role + parts)
        """
        formatted = []
        
        for msg in messages:
            # message_type: 0=incoming (user), 1=outgoing (model)
            role = "user" if msg.get("message_type") == 0 else "model"
            
            formatted.append({
                "role": role,
                "parts": [{"text": msg.get("content", "")}]
            })
        
        return formatted
    
    def clear_memory(self, conversation_id: int):
        """Clear conversation memory from Redis."""
        redis_client.clear_context(conversation_id)

    def get_test_conversation_history(
        self,
        conversation_id: str,
        window_size: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get conversation history for test conversations (uses only Redis, no DB).

        Args:
            conversation_id: Test conversation ID (can be a string)
            window_size: Number of messages to retrieve

        Returns:
            List of messages in chronological order
        """
        # For test conversations, use only Redis and treat ID as string
        redis_messages = redis_client.get_context(conversation_id)

        if redis_messages:
            return redis_messages[-window_size:]

        return []

    def add_test_message(
        self,
        conversation_id: str,
        content: str,
        message_type: int,  # 0=incoming, 1=outgoing
        max_window: int = 10
    ):
        """
        Add message to test conversation memory (Redis only).

        Args:
            conversation_id: Test conversation ID (string)
            content: Message content
            message_type: 0 for incoming, 1 for outgoing
            max_window: Maximum messages to keep in Redis
        """
        message = {
            "content": content,
            "message_type": message_type,
            "sender_type": "User" if message_type == 0 else "Agent",
            "created_at": None
        }

        redis_client.append_message(conversation_id, message, max_window)


# Global memory manager
memory_manager = MemoryManager()
