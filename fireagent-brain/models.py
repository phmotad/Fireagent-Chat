"""Pydantic models for data validation."""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class Message(BaseModel):
    """Message model."""
    id: int
    content: str
    message_type: int  # 0=incoming, 1=outgoing
    created_at: datetime
    sender_type: str
    sender_id: Optional[int] = None


class Conversation(BaseModel):
    """Conversation model."""
    id: int
    account_id: int
    inbox_id: int
    contact_id: int
    status: str
    messages: List[Message] = []


class AiAgent(BaseModel):
    """AI Agent configuration."""
    id: int
    name: str
    description: Optional[str] = None
    model: str = "gemini-2.0-flash-exp"
    temperature: float = 0.7
    memory_window_size: int = 10
    system_prompt: Optional[str] = None
    api_key: Optional[str] = None
    settings: Dict[str, Any] = {}


class AiAgentTool(BaseModel):
    """AI Agent Tool configuration."""
    id: int
    ai_agent_id: int
    name: str
    description: Optional[str] = None
    tool_type: str  # 'native', 'http', 'https', 'mcp'
    configuration: Dict[str, Any] = {}
    conditions: Dict[str, Any] = {}
    enabled: bool = True


class WebhookPayload(BaseModel):
    """Chatwoot webhook payload."""
    event: str
    account: Dict[str, Any]
    conversation: Dict[str, Any]
    message: Optional[Dict[str, Any]] = None
    sender: Optional[Dict[str, Any]] = None
    inbox: Optional[Dict[str, Any]] = None


class ToolCall(BaseModel):
    """Tool call from Gemini."""
    name: str
    arguments: Dict[str, Any]


class AgentResponse(BaseModel):
    """Agent response."""
    content: str
    tool_calls: List[ToolCall] = []
    should_handover: bool = False
