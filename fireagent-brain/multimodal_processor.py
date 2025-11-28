"""Multimodal content processor - handles images, audio, documents."""
import httpx
import base64
import logging
from typing import List, Dict, Any, Optional
import mimetypes

logger = logging.getLogger(__name__)


class MultimodalProcessor:
    """Process multimodal content (images, audio, documents)."""

    SUPPORTED_IMAGE_TYPES = [
        'image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/heic', 'image/heif'
    ]

    SUPPORTED_AUDIO_TYPES = [
        'audio/wav', 'audio/mp3', 'audio/aiff', 'audio/aac', 'audio/ogg', 'audio/flac'
    ]

    SUPPORTED_DOCUMENT_TYPES = [
        'application/pdf', 'text/plain', 'text/html', 'text/css', 'text/javascript',
        'application/x-javascript', 'text/x-typescript', 'application/x-typescript',
        'text/csv', 'text/markdown', 'text/x-python', 'application/x-python-code',
        'application/json', 'text/xml', 'application/rtf'
    ]

    async def process_attachments(
        self,
        attachments: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Process message attachments for Gemini.

        Args:
            attachments: List of attachment objects from Chatwoot

        Returns:
            List of multimodal parts for Gemini
        """
        parts = []

        for attachment in attachments:
            try:
                file_type = attachment.get('file_type')
                data_url = attachment.get('data_url')
                content_type = attachment.get('content_type', '')

                if not data_url:
                    logger.warning(f"Attachment missing data_url: {attachment}")
                    continue

                # Download attachment
                file_data = await self._download_file(data_url)

                if not file_data:
                    continue

                # Process based on type
                if file_type == 'image' or content_type in self.SUPPORTED_IMAGE_TYPES:
                    part = self._process_image(file_data, content_type)
                    if part:
                        parts.append(part)

                elif file_type == 'audio' or content_type in self.SUPPORTED_AUDIO_TYPES:
                    part = self._process_audio(file_data, content_type)
                    if part:
                        parts.append(part)

                elif file_type == 'file' or content_type in self.SUPPORTED_DOCUMENT_TYPES:
                    part = self._process_document(file_data, content_type)
                    if part:
                        parts.append(part)

                else:
                    logger.warning(f"Unsupported file type: {file_type} / {content_type}")

            except Exception as e:
                logger.error(f"Error processing attachment: {e}")
                continue

        return parts

    async def _download_file(self, url: str) -> Optional[bytes]:
        """Download file from URL."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, follow_redirects=True)
                response.raise_for_status()
                return response.content
        except Exception as e:
            logger.error(f"Error downloading file from {url}: {e}")
            return None

    def _process_image(self, data: bytes, mime_type: str) -> Optional[Dict[str, Any]]:
        """Process image attachment."""
        try:
            # Encode to base64
            encoded = base64.b64encode(data).decode('utf-8')

            return {
                "inline_data": {
                    "mime_type": mime_type or "image/jpeg",
                    "data": encoded
                }
            }
        except Exception as e:
            logger.error(f"Error processing image: {e}")
            return None

    def _process_audio(self, data: bytes, mime_type: str) -> Optional[Dict[str, Any]]:
        """Process audio attachment."""
        try:
            # Encode to base64
            encoded = base64.b64encode(data).decode('utf-8')

            return {
                "inline_data": {
                    "mime_type": mime_type or "audio/wav",
                    "data": encoded
                }
            }
        except Exception as e:
            logger.error(f"Error processing audio: {e}")
            return None

    def _process_document(self, data: bytes, mime_type: str) -> Optional[Dict[str, Any]]:
        """Process document attachment."""
        try:
            # For text documents, can include as text
            if mime_type.startswith('text/'):
                try:
                    text = data.decode('utf-8')
                    return {"text": f"\n\n[Document content]\n{text}\n[End of document]\n\n"}
                except UnicodeDecodeError:
                    pass

            # For binary documents (PDF, etc.), encode as base64
            encoded = base64.b64encode(data).decode('utf-8')

            return {
                "inline_data": {
                    "mime_type": mime_type or "application/pdf",
                    "data": encoded
                }
            }
        except Exception as e:
            logger.error(f"Error processing document: {e}")
            return None


# Global instance
multimodal_processor = MultimodalProcessor()
