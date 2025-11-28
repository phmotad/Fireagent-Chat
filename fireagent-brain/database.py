"""Database connection and queries."""
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool
from typing import Optional, List, Dict, Any
from config import settings
import logging
import json

logger = logging.getLogger(__name__)


class Database:
    """Database connection manager."""
    
    def __init__(self):
        """Initialize connection pool."""
        self.pool: Optional[SimpleConnectionPool] = None
    
    def _connect(self):
        """Create connection pool."""
        if self.pool:
            return
            
        try:
            self.pool = SimpleConnectionPool(
                minconn=1,
                maxconn=10,
                dsn=settings.postgres_url
            )
            logger.info("Database connection pool created")
        except Exception as e:
            logger.error(f"Failed to create database pool: {e}")
            raise
    
    def get_connection(self):
        """Get connection from pool."""
        if not self.pool:
            self._connect()
        return self.pool.getconn()
    
    def return_connection(self, conn):
        """Return connection to pool."""
        if self.pool:
            self.pool.putconn(conn)
    
    def get_agent_by_inbox(self, inbox_id: int) -> Optional[Dict[str, Any]]:
        """Get AI agent configuration by inbox ID."""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT ai_agents.*
                    FROM ai_agents
                    INNER JOIN agent_bots ON ai_agents.agent_bot_id = agent_bots.id
                    INNER JOIN agent_bot_inboxes ON agent_bots.id = agent_bot_inboxes.agent_bot_id
                    WHERE agent_bot_inboxes.inbox_id = %s
                      AND agent_bot_inboxes.status = 0
                    LIMIT 1
                """, (inbox_id,))
                return dict(cur.fetchone()) if cur.rowcount > 0 else None
        finally:
            self.return_connection(conn)
    
    def get_agent_by_id(self, agent_id: int) -> Optional[Dict[str, Any]]:
        """Get AI agent configuration by ID."""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT * FROM ai_agents
                    WHERE id = %s
                """, (agent_id,))
                return dict(cur.fetchone()) if cur.rowcount > 0 else None
        finally:
            self.return_connection(conn)
    
    def get_agent_tools(self, agent_id: int) -> List[Dict[str, Any]]:
        """Get tools for an AI agent."""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT * FROM ai_agent_tools
                    WHERE ai_agent_id = %s
                """, (agent_id,))
                return [dict(row) for row in cur.fetchall()]
        finally:
            self.return_connection(conn)
    
    def get_conversation_messages(
        self, 
        conversation_id: int, 
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent messages from a conversation."""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT id, content, message_type, created_at, 
                           sender_type, sender_id
                    FROM messages
                    WHERE conversation_id = %s
                    ORDER BY created_at DESC
                    LIMIT %s
                """, (conversation_id, limit))
                messages = [dict(row) for row in cur.fetchall()]
                return list(reversed(messages))  # Oldest first
        finally:
            self.return_connection(conn)
    
    def search_knowledge_base(
        self, 
        agent_id: int, 
        query_embedding: List[float],
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Search knowledge base using vector similarity."""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Using pgvector for similarity search
                cur.execute("""
                    SELECT file_path, metadata, 
                           1 - (embedding <=> %s::vector) as similarity
                    FROM ai_agent_knowledge_sources
                    WHERE ai_agent_id = %s 
                      AND status = 'ready'
                      AND 1 - (embedding <=> %s::vector) > %s
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s
                """, (
                    str(query_embedding), 
                    agent_id,
                    str(query_embedding),
                    settings.similarity_threshold,
                    str(query_embedding),
                    limit
                ))
                return [dict(row) for row in cur.fetchall()]
        finally:
            self.return_connection(conn)

    def log_interaction(
        self,
        agent_id: int,
        conversation_id: int,
        user_message: str,
        ai_response: str,
        action_taken: str = "reply",
        metadata: Dict[str, Any] = None
    ):
        """
        Log AI interaction.
        """
        conn = self.get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO ai_agent_logs 
                    (ai_agent_id, conversation_id, user_message, ai_response, action_taken, metadata, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (
                    agent_id,
                    conversation_id,
                    user_message,
                    ai_response,
                    action_taken,
                    json.dumps(metadata or {})
                ))
            conn.commit()
        except Exception as e:
            logger.error(f"Error logging interaction: {e}")
        finally:
            self.return_connection(conn)


# Global database instance
db = Database()
