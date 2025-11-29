"""Local embeddings using Sentence Transformers."""
from sentence_transformers import SentenceTransformer
from typing import List
import logging
import os

logger = logging.getLogger(__name__)


class EmbeddingModel:
    """Local embedding model using Sentence Transformers."""

    def __init__(self, model_name: str = "paraphrase-multilingual-mpnet-base-v2"):
        """
        Initialize the embedding model.

        Args:
            model_name: Name of the sentence-transformers model to use
                       Default: paraphrase-multilingual-mpnet-base-v2 (supports Portuguese)
        """
        self.model_name = model_name
        self.model = None
        self._load_model()

    def _load_model(self):
        """Load the embedding model (lazy loading)."""
        try:
            logger.info(f"Loading embedding model: {self.model_name}")

            # Create cache directory if it doesn't exist
            cache_dir = os.path.join("/app", ".cache", "sentence-transformers")
            os.makedirs(cache_dir, exist_ok=True)

            self.model = SentenceTransformer(
                self.model_name,
                cache_folder=cache_dir
            )

            # Get embedding dimension
            self.dimension = self.model.get_sentence_embedding_dimension()
            logger.info(f"Embedding model loaded successfully. Dimension: {self.dimension}")

        except Exception as e:
            logger.error(f"Error loading embedding model: {e}")
            raise

    def encode(self, text: str) -> List[float]:
        """
        Generate embedding for text.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        if not self.model:
            self._load_model()

        try:
            # Generate embedding
            embedding = self.model.encode(
                text,
                convert_to_numpy=True,
                normalize_embeddings=True  # Normalize for cosine similarity
            )

            return embedding.tolist()

        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []

    def encode_batch(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for multiple texts (more efficient).

        Args:
            texts: List of texts to embed

        Returns:
            List of embedding vectors
        """
        if not self.model:
            self._load_model()

        try:
            embeddings = self.model.encode(
                texts,
                convert_to_numpy=True,
                normalize_embeddings=True,
                batch_size=32,
                show_progress_bar=False
            )

            return embeddings.tolist()

        except Exception as e:
            logger.error(f"Error generating batch embeddings: {e}")
            return []


# Global embedding model instance
embedding_model = EmbeddingModel()
