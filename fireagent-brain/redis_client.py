"""Redis client for memory management."""
import redis
import json
from typing import List, Dict, Any, Optional
from config import settings
import logging

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis client for conversation context."""
    
    def __init__(self):
        """Initialize Redis connection."""
        self.client: Optional[redis.Redis] = None
    
    def _connect(self):
        """Connect to Redis."""
        try:
            self.client = redis.from_url(
                settings.redis_url,
                password=settings.redis_password,
                decode_responses=True
            )
            self.client.ping()
            logger.info("Redis connection established")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            raise
    
    def get_context(self, conversation_id: int) -> List[Dict[str, Any]]:
        """Get conversation context from Redis."""
        if not self.client:
            try:
                self._connect()
            except:
                return []
        
        try:
            key = f"conversation:{conversation_id}:context"
            data = self.client.get(key)
            if data:
                return json.loads(data)
            return []
        except Exception as e:
            logger.error(f"Error getting context from Redis: {e}")
            return []
    
    def save_context(
        self, 
        conversation_id: int, 
        messages: List[Dict[str, Any]],
        ttl: Optional[int] = None
    ):
        """Save conversation context to Redis."""
        if not self.client:
            try:
                self._connect()
            except:
                return
        
        try:
            key = f"conversation:{conversation_id}:context"
            self.client.setex(
                key,
                ttl or settings.redis_ttl,
                json.dumps(messages)
            )
        except Exception as e:
            logger.error(f"Error saving context to Redis: {e}")
    
    def append_message(
        self, 
        conversation_id: int, 
        message: Dict[str, Any],
        max_messages: int = 10
    ):
        """Append message to context and maintain window size."""
        context = self.get_context(conversation_id)
        context.append(message)
        
        # Keep only last N messages
        if len(context) > max_messages:
            context = context[-max_messages:]
        
        self.save_context(conversation_id, context)
    
    def clear_context(self, conversation_id: int):
        """Clear conversation context."""
        if not self.client:
            try:
                self._connect()
            except:
                return
        
        try:
            key = f"conversation:{conversation_id}:context"
            self.client.delete(key)
        except Exception as e:
            logger.error(f"Error clearing context: {e}")


# Global Redis client
redis_client = RedisClient()
