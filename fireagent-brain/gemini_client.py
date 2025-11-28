"""Gemini API client."""
import google.generativeai as genai
from typing import List, Dict, Any, Optional
from config import settings
from models import AiAgent, AgentResponse, ToolCall
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
        Generate embedding for text.
        
        Args:
            text: Text to embed
            
        Returns:
            Embedding vector
        """
        if not self.configured:
            self.configure()
        
        try:
            result = genai.embed_content(
                model=settings.embedding_model,
                content=text,
                task_type="retrieval_document"
            )
            return result['embedding']
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []


# Global Gemini client
gemini_client = GeminiClient()
