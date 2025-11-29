"""RAG engine with pgvector."""
from typing import List, Dict, Any, Optional
from database import db
from gemini_client import gemini_client
from config import settings
import logging
import json

logger = logging.getLogger(__name__)


class RAGEngine:
    """Retrieval Augmented Generation engine."""
    
    def search_knowledge(
        self, 
        agent_id: int,
        query: str,
        limit: int = None
    ) -> str:
        """
        Search knowledge base and return relevant context.
        
        Args:
            agent_id: AI Agent ID
            query: Search query
            limit: Maximum results
            
        Returns:
            Formatted context string
        """
        try:
            # Generate embedding for query
            query_embedding = gemini_client.generate_embedding(query)
            
            if not query_embedding:
                return ""
            
            # Search in pgvector
            results = db.search_knowledge_base(
                agent_id,
                query_embedding,
                limit or settings.max_rag_results
            )
            
            if not results:
                return ""
            
            # Format context
            context_parts = []
            for i, result in enumerate(results, 1):
                metadata = result.get('metadata', {})
                content = metadata.get('content', '')
                source = result.get('file_path', 'Unknown')
                similarity = result.get('similarity', 0)
                
                context_parts.append(
                    f"[Source {i}: {source} (relevance: {similarity:.2f})]\n{content}"
                )
            
            return "\n\n".join(context_parts)
            
        except Exception as e:
            logger.error(f"Error searching knowledge base: {e}")
            return ""
    
    async def ingest_document(
        self,
        agent_id: int,
        file_path: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Ingest document into knowledge base.
        
        Args:
            agent_id: AI Agent ID
            file_path: Path to file
            content: Document content
            metadata: Additional metadata
            
        Returns:
            Success status
        """
        try:
            # Generate embedding
            embedding = gemini_client.generate_embedding(content)
            
            if not embedding:
                logger.error(f"Failed to generate embedding for {file_path}")
                return False
            
            # Store in database
            conn = db.get_connection()
            try:
                with conn.cursor() as cur:
                    # Update or insert
                    cur.execute("""
                        INSERT INTO ai_agent_knowledge_sources 
                        (ai_agent_id, file_path, status, metadata, embedding)
                        VALUES (%s, %s, 'ready', %s, %s::vector)
                        ON CONFLICT (ai_agent_id, file_path) 
                        DO UPDATE SET 
                            status = 'ready',
                            metadata = EXCLUDED.metadata,
                            embedding = EXCLUDED.embedding,
                            updated_at = NOW()
                    """, (
                        agent_id,
                        file_path,
                        json.dumps({**(metadata or {}), "content": content}),
                        str(embedding)
                    ))
                conn.commit()
                logger.info(f"Document ingested: {file_path}")
                return True
            finally:
                db.return_connection(conn)
                
        except Exception as e:
            logger.error(f"Error ingesting document: {e}")
            return False
    
    def chunk_text(
        self, 
        text: str, 
        chunk_size: int = 1000,
        overlap: int = 200
    ) -> List[str]:
        """
        Split text into overlapping chunks.
        
        Args:
            text: Text to chunk
            chunk_size: Size of each chunk
            overlap: Overlap between chunks
            
        Returns:
            List of text chunks
        """
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + chunk_size
            chunk = text[start:end]
            chunks.append(chunk)
            start = end - overlap
        
        return chunks


# Global RAG engine
rag_engine = RAGEngine()
