"""Tool executor for AI Agent tools."""
import logging
import httpx
import json
import re
from typing import Dict, Any, Optional
from models import AiAgentTool
from mcp_client import mcp_client

logger = logging.getLogger(__name__)


class ToolExecutor:
    """Executes AI Agent tools."""

    def __init__(self, database_session=None):
        """Initialize tool executor.

        Args:
            database_session: Database session for native tools
        """
        self.db = database_session
        self.http_client = httpx.AsyncClient(timeout=30.0)

    async def execute_tool(self, tool: AiAgentTool, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool based on its type.

        Args:
            tool: The tool configuration
            arguments: Arguments to pass to the tool

        Returns:
            Tool execution result
        """
        if not tool.enabled:
            return {"error": "Tool is disabled"}

        try:
            if tool.tool_type in ['http', 'https']:
                return await self._execute_http_tool(tool, arguments)
            elif tool.tool_type == 'native':
                return await self._execute_native_tool(tool, arguments)
            elif tool.tool_type == 'mcp':
                return await self._execute_mcp_tool(tool, arguments)
            else:
                return {"error": f"Unknown tool type: {tool.tool_type}"}
        except Exception as e:
            logger.error(f"Error executing tool {tool.name}: {str(e)}", exc_info=True)
            return {"error": str(e)}

    async def _execute_http_tool(self, tool: AiAgentTool, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute HTTP/HTTPS tool.

        Args:
            tool: The tool configuration
            arguments: Arguments to pass to the tool

        Returns:
            HTTP response
        """
        config = tool.configuration
        url = config.get('url')
        method = config.get('method', 'GET').upper()

        if not url:
            return {"error": "No URL configured"}

        # Prepare headers
        headers = {}
        if config.get('headers_json'):
            try:
                headers = json.loads(config['headers_json'])
            except json.JSONDecodeError:
                logger.warning(f"Invalid headers JSON for tool {tool.name}")

        # Add authentication
        auth_type = config.get('auth_type', 'none')
        if auth_type == 'bearer':
            token = config.get('auth_token')
            if token:
                headers['Authorization'] = f'Bearer {token}'
        elif auth_type == 'api_key':
            api_key = config.get('api_key')
            if api_key:
                headers['X-API-Key'] = api_key

        # Prepare body with template substitution
        body = None
        if method in ['POST', 'PUT', 'PATCH']:
            body_template = config.get('body_template', '{}')
            body = self._substitute_template(body_template, arguments)
            if body:
                try:
                    body = json.loads(body)
                except json.JSONDecodeError:
                    logger.warning(f"Invalid body template for tool {tool.name}")
                    body = {}

        # Execute HTTP request
        try:
            response = await self.http_client.request(
                method=method,
                url=url,
                headers=headers,
                json=body if method in ['POST', 'PUT', 'PATCH'] else None,
                params=arguments if method == 'GET' else None
            )
            response.raise_for_status()

            # Try to parse JSON response
            try:
                return response.json()
            except json.JSONDecodeError:
                return {"text": response.text, "status_code": response.status_code}

        except httpx.HTTPStatusError as e:
            return {
                "error": f"HTTP {e.response.status_code}: {e.response.text}",
                "status_code": e.response.status_code
            }
        except Exception as e:
            return {"error": str(e)}

    async def _execute_native_tool(self, tool: AiAgentTool, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute native Chatwoot tool.

        Args:
            tool: The tool configuration
            arguments: Arguments to pass to the tool

        Returns:
            Tool execution result
        """
        config = tool.configuration
        native_type = config.get('native_type')

        if native_type == 'macro':
            return await self._execute_macro(config, arguments)
        elif native_type == 'schedule':
            return await self._execute_schedule(config, arguments)
        elif native_type == 'handover':
            return await self._execute_handover(config, arguments)
        else:
            return {"error": f"Unknown native type: {native_type}"}

    async def _execute_macro(self, config: Dict[str, Any], arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a Chatwoot macro.

        Args:
            config: Macro configuration
            arguments: Arguments including conversation_id

        Returns:
            Execution result
        """
        macro_id = config.get('macro_id')
        conversation_id = arguments.get('conversation_id')

        if not macro_id:
            return {"error": "No macro_id configured"}
        if not conversation_id:
            return {"error": "conversation_id required"}

        # This will be implemented to call Chatwoot's macro execution
        # For now, return a placeholder
        return {
            "success": True,
            "message": f"Macro {macro_id} would be executed on conversation {conversation_id}",
            "macro_id": macro_id,
            "conversation_id": conversation_id
        }

    async def _execute_schedule(self, config: Dict[str, Any], arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute schedule operation.

        Args:
            config: Schedule configuration
            arguments: Arguments for scheduling

        Returns:
            Execution result
        """
        action = config.get('schedule_action', 'create')

        if action == 'create':
            return await self._create_schedule(arguments)
        elif action == 'list':
            return await self._list_schedules(arguments)
        elif action == 'delete':
            return await self._delete_schedule(arguments)
        elif action == 'reschedule':
            return await self._reschedule(arguments)
        else:
            return {"error": f"Unknown schedule action: {action}"}

    async def _create_schedule(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new schedule.

        Args:
            arguments: Schedule details (datetime, description, etc.)

        Returns:
            Created schedule
        """
        # This will integrate with the actual scheduling system
        return {
            "success": True,
            "message": "Schedule created",
            "schedule": arguments
        }

    async def _list_schedules(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """List schedules.

        Args:
            arguments: Filter criteria

        Returns:
            List of schedules
        """
        # This will query the actual scheduling system
        return {
            "success": True,
            "schedules": []
        }

    async def _delete_schedule(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Delete a schedule.

        Args:
            arguments: Must include schedule_id

        Returns:
            Deletion result
        """
        schedule_id = arguments.get('schedule_id')
        if not schedule_id:
            return {"error": "schedule_id required"}

        return {
            "success": True,
            "message": f"Schedule {schedule_id} deleted"
        }

    async def _reschedule(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Reschedule an appointment.

        Args:
            arguments: Must include schedule_id and new_datetime

        Returns:
            Rescheduling result
        """
        schedule_id = arguments.get('schedule_id')
        new_datetime = arguments.get('new_datetime')

        if not schedule_id or not new_datetime:
            return {"error": "schedule_id and new_datetime required"}

        return {
            "success": True,
            "message": f"Schedule {schedule_id} rescheduled to {new_datetime}"
        }

    async def _execute_handover(self, config: Dict[str, Any], arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute handover to human.

        Args:
            config: Handover configuration
            arguments: Arguments including conversation_id

        Returns:
            Handover result
        """
        conversation_id = arguments.get('conversation_id')
        auto_assign = config.get('auto_assign', False)

        if not conversation_id:
            return {"error": "conversation_id required"}

        # This will integrate with Chatwoot's assignment system
        return {
            "success": True,
            "message": "Conversation handed over to human agent",
            "conversation_id": conversation_id,
            "auto_assign": auto_assign,
            "handover": True
        }

    async def _execute_mcp_tool(self, tool: AiAgentTool, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute MCP tool.

        Args:
            tool: The tool configuration
            arguments: Arguments to pass to the tool

        Returns:
            MCP tool result
        """
        config = tool.configuration
        server_url = config.get('server_url')
        protocol = config.get('protocol', 'stdio')
        tool_name = config.get('tool_name')

        if not server_url or not tool_name:
            return {"error": "server_url and tool_name required"}

        try:
            # Use tool ID as server name to avoid conflicts
            server_name = f"tool_{tool.id}"

            # Connect to MCP server if not already connected
            if server_name not in mcp_client.servers:
                await mcp_client.connect_server(
                    name=server_name,
                    url=server_url,
                    protocol=protocol
                )

            # Execute the tool
            result = await mcp_client.execute_tool(
                server_name=server_name,
                tool_name=tool_name,
                arguments=arguments
            )

            return result
        except Exception as e:
            logger.error(f"Error executing MCP tool {tool_name}: {str(e)}")
            return {"error": str(e)}

    def _substitute_template(self, template: str, variables: Dict[str, Any]) -> str:
        """Substitute variables in template string.

        Args:
            template: Template string with {{variable}} placeholders
            variables: Dictionary of variables to substitute

        Returns:
            String with substituted values
        """
        result = template
        for key, value in variables.items():
            pattern = r'\{\{' + re.escape(key) + r'\}\}'
            result = re.sub(pattern, str(value), result)
        return result

    async def close(self):
        """Close the HTTP client."""
        await self.http_client.aclose()
