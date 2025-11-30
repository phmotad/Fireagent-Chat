"""Embeddings using Google Gemini API."""
import google.generativeai as genai
from typing import List
import logging
import os

logger = logging.getLogger(__name__)


class EmbeddingModel:
    """Embedding model using Google Gemini API."""

    def __init__(self):
        """Initialize the embedding model."""
        self.model_name = "models/text-embedding-004"
        self.dimension = 768  # Default dimension for text-embedding-004
        self.configured = False
        logger.info(f"Embedding model initialized: {self.model_name}")

    def _ensure_configured(self):
        """Ensure Gemini API is configured."""
        if not self.configured:
            api_key = os.getenv("GEMINI_API_KEY")
            if not api_key:
                logger.warning("GEMINI_API_KEY not set. Embeddings will fail.")
                return False

            genai.configure(api_key=api_key)
            self.configured = True
            logger.info("Gemini API configured for embeddings")

        return True

    def encode(self, text: str) -> List[float]:
        """
        Generate embedding for text using Gemini API.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        if not self._ensure_configured():
            logger.error("Gemini API not configured. Returning empty embedding.")
            return []

        try:
            # Generate embedding using Gemini API
            result = genai.embed_content(
                model=self.model_name,
                content=text,
                task_type="retrieval_document"  # For RAG use case
            )

            embedding = result['embedding']
            logger.debug(f"Generated embedding with dimension: {len(embedding)}")

            return embedding

        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []

    def encode_batch(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for multiple texts.

        Args:
            texts: List of texts to embed

        Returns:
            List of embedding vectors
        """
        if not self._ensure_configured():
            logger.error("Gemini API not configured. Returning empty embeddings.")
            return []

        try:
            # Gemini API supports batch embedding
            embeddings = []

            # Process in batches of 100 (Gemini API limit)
            batch_size = 100
            for i in range(0, len(texts), batch_size):
                batch = texts[i:i + batch_size]

                result = genai.embed_content(
                    model=self.model_name,
                    content=batch,
                    task_type="retrieval_document"
                )

                # Extract embeddings from result
                if isinstance(result, dict) and 'embedding' in result:
                    # Single embedding
                    embeddings.append(result['embedding'])
                elif isinstance(result, list):
                    # Multiple embeddings
                    embeddings.extend([r['embedding'] for r in result])
                else:
                    logger.warning(f"Unexpected result format: {type(result)}")

            logger.debug(f"Generated {len(embeddings)} embeddings")
            return embeddings

        except Exception as e:
            logger.error(f"Error generating batch embeddings: {e}")
            return []


# Global embedding model instance
embedding_model = EmbeddingModel()
