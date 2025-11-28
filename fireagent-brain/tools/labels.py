"""Add label tool."""
from .base import BaseTool
from typing import Dict, Any
import httpx
from config import settings
import logging

logger = logging.getLogger(__name__)


class AddLabelTool(BaseTool):
    """Tool to add labels to conversations."""
    
    @property
    def name(self) -> str:
        return "add_label"
    
    @property
    def description(self) -> str:
        return "Add a label/tag to the current conversation for categorization"
    
    def get_parameters(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "label": {
                    "type": "string",
                    "description": "Label name to add (e.g., 'urgent', 'sales', 'support')"
                }
            },
            "required": ["label"]
        }
    
    async def execute(self, conversation_id: int, label: str, **kwargs) -> Dict[str, Any]:
        """
        Add label to conversation.
        
        Args:
            conversation_id: Conversation ID
            label: Label to add
            
        Returns:
            Result with success status
        """
        try:
            async with httpx.AsyncClient() as client:
                url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}/labels"
                headers = {"api_access_token": settings.chatwoot_api_key}
                
                response = await client.post(
                    url,
                    json={"labels": [label.lower()]},
                    headers=headers
                )
                response.raise_for_status()
                
                logger.info(f"Label '{label}' added to conversation {conversation_id}")
                return {
                    "success": True,
                    "message": f"Label '{label}' added successfully"
                }
                
        except Exception as e:
            logger.error(f"Error adding label: {e}")
            return {
                "success": False,
                "error": str(e)
            }
