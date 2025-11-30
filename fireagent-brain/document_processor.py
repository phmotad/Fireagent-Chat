"""Document processor for various file types."""
import io
import logging
from typing import Optional
from PyPDF2 import PdfReader

logger = logging.getLogger(__name__)


class DocumentProcessor:
    """Process different document types and extract text."""

    @staticmethod
    def extract_text(content: bytes, file_path: str) -> str:
        """
        Extract text from document based on file type.

        Args:
            content: Document content as bytes
            file_path: Path to file (used to determine type)

        Returns:
            Extracted text content
        """
        # Determine file type from extension
        file_path_lower = file_path.lower()

        if file_path_lower.endswith('.pdf'):
            return DocumentProcessor._extract_from_pdf(content)
        elif file_path_lower.endswith(('.txt', '.md', '.markdown')):
            return DocumentProcessor._extract_from_text(content)
        else:
            # Try to decode as text
            try:
                return content.decode('utf-8')
            except UnicodeDecodeError:
                logger.warning(f"Unable to decode file: {file_path}. Trying latin-1.")
                try:
                    return content.decode('latin-1')
                except Exception as e:
                    raise ValueError(f"Unsupported file type or encoding: {file_path}") from e

    @staticmethod
    def _extract_from_pdf(content: bytes) -> str:
        """
        Extract text from PDF.

        Args:
            content: PDF content as bytes

        Returns:
            Extracted text
        """
        try:
            pdf_file = io.BytesIO(content)
            reader = PdfReader(pdf_file)

            text_parts = []
            for page_num, page in enumerate(reader.pages):
                try:
                    text = page.extract_text()
                    if text.strip():
                        text_parts.append(text)
                except Exception as e:
                    logger.warning(f"Error extracting text from page {page_num}: {e}")
                    continue

            extracted_text = "\n\n".join(text_parts)

            if not extracted_text.strip():
                raise ValueError("No text could be extracted from PDF")

            logger.info(f"Extracted {len(extracted_text)} characters from PDF with {len(reader.pages)} pages")
            return extracted_text

        except Exception as e:
            logger.error(f"Error processing PDF: {e}")
            raise ValueError(f"Failed to extract text from PDF: {str(e)}") from e

    @staticmethod
    def _extract_from_text(content: bytes) -> str:
        """
        Extract text from plain text file.

        Args:
            content: Text file content as bytes

        Returns:
            Decoded text
        """
        try:
            return content.decode('utf-8')
        except UnicodeDecodeError:
            try:
                return content.decode('latin-1')
            except Exception as e:
                raise ValueError(f"Failed to decode text file") from e


# Global instance
document_processor = DocumentProcessor()
