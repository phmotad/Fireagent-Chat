"""WhatsApp interactive buttons tool."""
from .base import BaseTool
from typing import Dict, Any, List
import httpx
from config import settings
import logging

logger = logging.getLogger(__name__)


class WhatsAppButtonsTool(BaseTool):
    """Tool to send WhatsApp interactive buttons."""
    
    @property
    def name(self) -> str:
        return "send_whatsapp_buttons"
    
    @property
    def description(self) -> str:
        return "Send interactive buttons in WhatsApp for user to choose from options"
    
    def get_parameters(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "text": {
                    "type": "string",
                    "description": "Message text to display above buttons"
                },
                "buttons": {
                    "type": "array",
                    "description": "List of button labels (max 3)",
                    "items": {
                        "type": "string"
                    },
                    "maxItems": 3
                }
            },
            "required": ["text", "buttons"]
        }
    
    async def execute(
        self, 
        conversation_id: int,
        text: str,
        buttons: List[str],
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send WhatsApp buttons.
        
        Args:
            conversation_id: Conversation ID
            text: Message text
            buttons: List of button labels
            
        Returns:
            Result with success status
        """
        try:
            if len(buttons) > 3:
                buttons = buttons[:3]  # WhatsApp limit
            
            async with httpx.AsyncClient() as client:
                url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}/messages"
                headers = {"api_access_token": settings.chatwoot_api_key}
                
                # Format for WhatsApp interactive message
                payload = {
                    "content": text,
                    "message_type": "outgoing",
                    "private": False,
                    "content_attributes": {
                        "interactive": {
                            "type": "button",
                            "body": {
                                "text": text
                            },
                            "action": {
                                "buttons": [
                                    {
                                        "type": "reply",
                                        "reply": {
                                            "id": f"btn_{i}",
                                            "title": btn[:20]  # WhatsApp limit
                                        }
                                    }
                                    for i, btn in enumerate(buttons)
                                ]
                            }
                        }
                    }
                }
                
                response = await client.post(url, json=payload, headers=headers)
                response.raise_for_status()
                
                logger.info(f"WhatsApp buttons sent to conversation {conversation_id}")
                return {
                    "success": True,
                    "message": "Interactive buttons sent"
                }
                
        except Exception as e:
            logger.error(f"Error sending WhatsApp buttons: {e}")
            return {
                "success": False,
                "error": str(e)
            }
