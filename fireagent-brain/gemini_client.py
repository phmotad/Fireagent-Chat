"""Gemini API client."""
import google.generativeai as genai
from typing import List, Dict, Any, Optional
from config import settings
from models import AiAgent, AgentResponse, ToolCall, AiAgentTool
from embeddings import embedding_model
import logging
import json

logger = logging.getLogger(__name__)


class GeminiClient:
    """Client for Google Gemini API."""
    
    def __init__(self):
        """Initialize Gemini client."""
        self.configured = False
    
    def configure(self, api_key: Optional[str] = None):
        """Configure Gemini with API key."""
        key = api_key or settings.gemini_api_key
        if not key:
            raise ValueError("Gemini API key not provided")
        
        genai.configure(api_key=key)
        self.configured = True
        logger.info("Gemini API configured")
    
    def create_model(
        self, 
        agent: AiAgent,
        tools: Optional[List[Dict[str, Any]]] = None
    ):
        """
        Create Gemini model with agent configuration.
        
        Args:
            agent: AI Agent configuration
            tools: List of tool schemas for function calling
            
        Returns:
            Configured GenerativeModel
        """
        if not self.configured:
            self.configure(agent.api_key)
        
        generation_config = {
            "temperature": agent.temperature,
            "max_output_tokens": settings.max_tokens,
        }
        
        # System instruction
        system_instruction = agent.system_prompt or "You are a helpful assistant."
        
        model_config = {
            "model_name": agent.model,
            "generation_config": generation_config,
            "system_instruction": system_instruction,
        }
        
        # Add tools if provided
        if tools:
            model_config["tools"] = tools
        
        return genai.GenerativeModel(**model_config)
    
    async def generate_response(
        self,
        agent: AiAgent,
        history: List[Dict[str, Any]],
        message: str,
        tools: Optional[List[Dict[str, Any]]] = None,
        context: Optional[str] = None,
        multimodal_parts: Optional[List[Dict[str, Any]]] = None
    ) -> AgentResponse:
        """
        Generate response from Gemini.
        
        Args:
            agent: AI Agent configuration
            history: Conversation history
            message: Current message
            tools: Available tools
            context: Additional context from RAG
            
        Returns:
            AgentResponse with content and tool calls
        """
        try:
            model = self.create_model(agent, tools)
            
            # Start chat with history
            chat = model.start_chat(history=history)
            
            # Prepare message content
            message_parts = []

            # Add context if available
            if context:
                message_parts.append(f"Context:\n{context}\n\n")

            # Add text message
            message_parts.append(f"User message: {message}")

            # Add multimodal parts if available
            content = []
            if multimodal_parts:
                # First add text
                content.append({"text": "".join(message_parts)})
                # Then add multimodal content (images, audio, docs)
                content.extend(multimodal_parts)
            else:
                # Text only
                content = "".join(message_parts)

            # Generate response
            response = chat.send_message(content)
            
            # Parse response
            content = ""
            tool_calls = []
            
            if response.candidates:
                candidate = response.candidates[0]
                
                # Extract text content
                if candidate.content.parts:
                    for part in candidate.content.parts:
                        if hasattr(part, 'text'):
                            content += part.text
                        elif hasattr(part, 'function_call'):
                            # Tool call detected
                            fc = part.function_call
                            tool_calls.append(ToolCall(
                                name=fc.name,
                                arguments=dict(fc.args)
                            ))
            
            return AgentResponse(
                content=content,
                tool_calls=tool_calls
            )
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return AgentResponse(
                content="Desculpe, ocorreu um erro ao processar sua mensagem.",
                tool_calls=[]
            )
    
    def generate_embedding(self, text: str) -> List[float]:
        """
        Generate embedding for text using local Sentence Transformers model.

        Args:
            text: Text to embed

        Returns:
            Embedding vector
        """
        try:
            # Use local embedding model (no API calls, no quota limits)
            return embedding_model.encode(text)
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []

    def convert_tools_to_gemini_format(self, tools: List[AiAgentTool]) -> List[Dict[str, Any]]:
        """
        Convert AI Agent tools to Gemini function calling format.

        Args:
            tools: List of AI Agent tools

        Returns:
            List of tool declarations in Gemini format
        """
        gemini_tools = []

        for tool in tools:
            if not tool.enabled:
                continue

            try:
                tool_declaration = {
                    "name": tool.name,
                    "description": tool.description or f"Execute {tool.name}",
                    "parameters": self._get_tool_parameters(tool)
                }
                gemini_tools.append(tool_declaration)
            except Exception as e:
                logger.error(f"Error converting tool {tool.name}: {str(e)}")

        return gemini_tools

    def _get_tool_parameters(self, tool: AiAgentTool) -> Dict[str, Any]:
        """
        Get parameter schema for a tool.

        Args:
            tool: AI Agent tool

        Returns:
            Parameter schema in JSON Schema format
        """
        config = tool.configuration

        if tool.tool_type in ['http', 'https']:
            # HTTP tools can accept dynamic parameters
            return {
                "type": "object",
                "properties": {
                    "params": {
                        "type": "object",
                        "description": "Parameters to pass to the HTTP endpoint"
                    }
                },
                "required": []
            }

        elif tool.tool_type == 'native':
            native_type = config.get('native_type')

            if native_type == 'macro':
                return {
                    "type": "object",
                    "properties": {
                        "conversation_id": {
                            "type": "integer",
                            "description": "ID of the conversation"
                        }
                    },
                    "required": ["conversation_id"]
                }

            elif native_type == 'schedule':
                schedule_action = config.get('schedule_action', 'create')

                if schedule_action == 'create':
                    return {
                        "type": "object",
                        "properties": {
                            "datetime": {
                                "type": "string",
                                "description": "ISO format datetime for the appointment"
                            },
                            "description": {
                                "type": "string",
                                "description": "Description of the appointment"
                            }
                        },
                        "required": ["datetime", "description"]
                    }
                elif schedule_action == 'list':
                    return {
                        "type": "object",
                        "properties": {},
                        "required": []
                    }
                elif schedule_action == 'delete':
                    return {
                        "type": "object",
                        "properties": {
                            "schedule_id": {
                                "type": "integer",
                                "description": "ID of the schedule to delete"
                            }
                        },
                        "required": ["schedule_id"]
                    }
                elif schedule_action == 'reschedule':
                    return {
                        "type": "object",
                        "properties": {
                            "schedule_id": {
                                "type": "integer",
                                "description": "ID of the schedule"
                            },
                            "new_datetime": {
                                "type": "string",
                                "description": "New ISO format datetime"
                            }
                        },
                        "required": ["schedule_id", "new_datetime"]
                    }

            elif native_type == 'handover':
                return {
                    "type": "object",
                    "properties": {
                        "conversation_id": {
                            "type": "integer",
                            "description": "ID of the conversation to hand over"
                        },
                        "reason": {
                            "type": "string",
                            "description": "Reason for handover"
                        }
                    },
                    "required": ["conversation_id"]
                }

        elif tool.tool_type == 'mcp':
            # MCP tools may have custom argument schemas
            arguments_schema = config.get('arguments_schema')
            if arguments_schema:
                try:
                    if isinstance(arguments_schema, str):
                        return json.loads(arguments_schema)
                    return arguments_schema
                except json.JSONDecodeError:
                    logger.warning(f"Invalid arguments_schema for MCP tool {tool.name}")

            # Default MCP parameters
            return {
                "type": "object",
                "properties": {},
                "required": []
            }

        # Default fallback
        return {
            "type": "object",
            "properties": {},
            "required": []
        }


# Global Gemini client
gemini_client = GeminiClient()
