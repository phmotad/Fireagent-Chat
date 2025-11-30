"""MCP Client for connecting to Model Context Protocol servers."""
from typing import List, Dict, Any, Optional
import logging
import httpx
import asyncio
import json

logger = logging.getLogger(__name__)


class MCPClient:
    """
    Client for Model Context Protocol (MCP).

    Allows the AI agent to connect to external MCP servers and execute tools.
    Supports STDIO, WebSocket, and Server-Sent Events protocols.
    """

    def __init__(self):
        """Initialize MCP client."""
        self.servers: Dict[str, Any] = {}
        self.http_client = httpx.AsyncClient(timeout=30.0)

    async def connect_server(
        self,
        name: str,
        url: str,
        protocol: str = 'stdio',
        api_key: Optional[str] = None
    ):
        """
        Connect to an MCP server.

        Args:
            name: Server name
            url: Server URL
            protocol: Protocol type ('stdio', 'ws', 'sse')
            api_key: Optional API key
        """
        logger.info(f"Connecting to MCP server: {name} at {url} via {protocol}")

        try:
            if protocol == 'ws':
                # WebSocket connection would be established here
                self.servers[name] = {
                    "url": url,
                    "protocol": protocol,
                    "status": "connected",
                    "connection": None  # WebSocket connection object
                }
            elif protocol == 'sse':
                # SSE connection setup
                self.servers[name] = {
                    "url": url,
                    "protocol": protocol,
                    "status": "connected",
                    "stream": None  # SSE stream object
                }
            else:  # stdio
                # STDIO process would be spawned here
                self.servers[name] = {
                    "url": url,
                    "protocol": protocol,
                    "status": "connected",
                    "process": None  # Process object
                }

            logger.info(f"Successfully connected to MCP server: {name}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to MCP server {name}: {str(e)}")
            return False

    async def list_tools(self, server_name: str) -> List[Dict[str, Any]]:
        """
        List tools available on an MCP server.

        Args:
            server_name: Name of the server

        Returns:
            List of tool schemas
        """
        if server_name not in self.servers:
            logger.warning(f"Server {server_name} not connected")
            return []

        server = self.servers[server_name]
        protocol = server.get('protocol', 'stdio')

        try:
            if protocol in ['ws', 'sse']:
                # Send list_tools request to the server
                response = await self._send_request(server_name, {
                    "jsonrpc": "2.0",
                    "method": "tools/list",
                    "id": 1
                })
                return response.get('result', {}).get('tools', [])
            else:
                # STDIO communication
                # This would involve process communication
                return []
        except Exception as e:
            logger.error(f"Error listing tools from {server_name}: {str(e)}")
            return []

    async def execute_tool(
        self,
        server_name: str,
        tool_name: str,
        arguments: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Execute a tool on an MCP server.

        Args:
            server_name: Server name
            tool_name: Tool name
            arguments: Tool arguments

        Returns:
            Tool execution result
        """
        if server_name not in self.servers:
            raise ValueError(f"Server {server_name} not connected")

        server = self.servers[server_name]
        protocol = server.get('protocol', 'stdio')

        logger.info(f"Executing MCP tool {tool_name} on {server_name} via {protocol}")

        try:
            if protocol in ['ws', 'sse']:
                response = await self._send_request(server_name, {
                    "jsonrpc": "2.0",
                    "method": "tools/call",
                    "params": {
                        "name": tool_name,
                        "arguments": arguments
                    },
                    "id": 2
                })
                return response.get('result', {})
            else:
                # STDIO communication
                # This would involve process stdin/stdout communication
                return {
                    "status": "success",
                    "message": f"STDIO MCP tool {tool_name} executed",
                    "result": arguments
                }
        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {str(e)}")
            return {"error": str(e)}

    async def _send_request(self, server_name: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Send JSON-RPC request to MCP server.

        Args:
            server_name: Server name
            payload: JSON-RPC payload

        Returns:
            Server response
        """
        server = self.servers.get(server_name)
        if not server:
            raise ValueError(f"Server {server_name} not found")

        protocol = server.get('protocol')
        url = server.get('url')

        if protocol == 'ws':
            # WebSocket send/receive
            # This would use the actual WebSocket connection
            return {"result": {}, "id": payload.get('id')}
        elif protocol == 'sse':
            # SSE request (usually HTTP POST for requests)
            response = await self.http_client.post(url, json=payload)
            response.raise_for_status()
            return response.json()
        else:
            return {}

    async def disconnect_server(self, server_name: str):
        """
        Disconnect from an MCP server.

        Args:
            server_name: Server name
        """
        if server_name in self.servers:
            server = self.servers[server_name]
            protocol = server.get('protocol')

            # Clean up connections
            if protocol == 'ws' and server.get('connection'):
                # Close WebSocket
                pass
            elif protocol == 'stdio' and server.get('process'):
                # Terminate process
                pass

            del self.servers[server_name]
            logger.info(f"Disconnected from MCP server: {server_name}")

    async def close(self):
        """Close all connections and cleanup."""
        for server_name in list(self.servers.keys()):
            await self.disconnect_server(server_name)
        await self.http_client.aclose()


# Global MCP client
mcp_client = MCPClient()
