"""Handover tool - transfer conversation to human agent."""
from .base import BaseTool
from typing import Dict, Any
import httpx
from config import settings
import logging

logger = logging.getLogger(__name__)


class HandoverTool(BaseTool):
    """Tool to hand over conversation to a human agent."""
    
    @property
    def name(self) -> str:
        return "handover_to_human"
    
    @property
    def description(self) -> str:
        return "Transfer the conversation to a human agent when the AI cannot help or user requests human assistance"
    
    def get_parameters(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "reason": {
                    "type": "string",
                    "description": "Reason for handover"
                },
                "agent_id": {
                    "type": "integer",
                    "description": "Optional: Specific agent ID to assign to",
                    "nullable": True
                }
            },
            "required": ["reason"]
        }
    
    async def execute(self, conversation_id: int, reason: str, agent_id: int = None, **kwargs) -> Dict[str, Any]:
        """
        Execute handover.
        
        Args:
            conversation_id: Conversation ID
            reason: Reason for handover
            agent_id: Optional agent to assign to
            
        Returns:
            Result with success status
        """
        try:
            async with httpx.AsyncClient() as client:
                # Update conversation status to open
                url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}"
                headers = {"api_access_token": settings.chatwoot_api_key}
                
                payload = {
                    "status": "open",
                }
                
                if agent_id:
                    payload["assignee_id"] = agent_id
                
                response = await client.patch(url, json=payload, headers=headers)
                response.raise_for_status()
                
                # Send handover message
                message_url = f"{url}/messages"
                await client.post(
                    message_url,
                    json={
                        "content": f"🤝 Transferindo para um atendente humano.\nMotivo: {reason}",
                        "message_type": "outgoing",
                        "private": False
                    },
                    headers=headers
                )
                
                logger.info(f"Handover executed for conversation {conversation_id}")
                return {
                    "success": True,
                    "message": "Conversation handed over to human agent"
                }
                
        except Exception as e:
            logger.error(f"Error executing handover: {e}")
            return {
                "success": False,
                "error": str(e)
            }
