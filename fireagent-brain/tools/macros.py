"""Run macro tool - execute Chatwoot macros."""
from .base import BaseTool
from typing import Dict, Any
import httpx
from config import settings
import logging

logger = logging.getLogger(__name__)


class RunMacroTool(BaseTool):
    """Tool to execute Chatwoot macros."""

    @property
    def name(self) -> str:
        return "run_macro"

    @property
    def description(self) -> str:
        return "Execute a predefined macro (automated actions) on the conversation"

    def get_parameters(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "macro_name": {
                    "type": "string",
                    "description": "Name of the macro to execute (e.g., 'escalate_to_manager', 'send_pricing_info')"
                },
                "reason": {
                    "type": "string",
                    "description": "Reason for executing this macro",
                    "nullable": True
                }
            },
            "required": ["macro_name"]
        }

    async def execute(
        self,
        conversation_id: int,
        macro_name: str,
        account_id: int = None,
        reason: str = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Execute a macro on the conversation.

        Args:
            conversation_id: Conversation ID
            macro_name: Name of the macro to execute
            account_id: Account ID (passed from main.py)
            reason: Optional reason for execution

        Returns:
            Result with success status
        """
        try:
            if not account_id:
                return {
                    "success": False,
                    "error": "Account ID is required to execute macros"
                }

            async with httpx.AsyncClient() as client:
                # 1. Get all macros for this account
                macros_url = f"{settings.chatwoot_url}/api/v1/accounts/{account_id}/macros"
                headers = {"api_access_token": settings.chatwoot_api_key}

                macros_response = await client.get(macros_url, headers=headers)
                macros_response.raise_for_status()
                macros = macros_response.json()

                # 2. Find macro by name (case-insensitive)
                macro_id = None
                macro_found = None

                for macro in macros:
                    if macro.get("name", "").lower() == macro_name.lower():
                        macro_id = macro.get("id")
                        macro_found = macro
                        break

                if not macro_id:
                    return {
                        "success": False,
                        "error": f"Macro '{macro_name}' not found. Available macros: {', '.join([m.get('name', '') for m in macros])}"
                    }

                # 3. Execute macro
                execute_url = f"{settings.chatwoot_url}/api/v1/accounts/{account_id}/conversations/{conversation_id}/macros/{macro_id}"

                execute_response = await client.post(execute_url, headers=headers)
                execute_response.raise_for_status()

                logger.info(f"Macro '{macro_name}' (ID: {macro_id}) executed on conversation {conversation_id}")

                # 4. Log reason if provided
                if reason:
                    message_url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}/messages"
                    await client.post(
                        message_url,
                        json={
                            "content": f"🔧 Macro '{macro_name}' executada.\nMotivo: {reason}",
                            "message_type": "outgoing",
                            "private": True  # Internal note
                        },
                        headers=headers
                    )

                return {
                    "success": True,
                    "message": f"Macro '{macro_name}' executed successfully",
                    "macro_id": macro_id,
                    "actions": macro_found.get("actions", [])
                }

        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error executing macro: {e.response.status_code} - {e.response.text}")
            return {
                "success": False,
                "error": f"Failed to execute macro: {e.response.status_code}"
            }
        except Exception as e:
            logger.error(f"Error executing macro: {e}")
            return {
                "success": False,
                "error": str(e)
            }
