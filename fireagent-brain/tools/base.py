"""Base class for AI agent tools."""
from abc import ABC, abstractmethod
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)


class BaseTool(ABC):
    """Base class for all tools."""
    
    def __init__(self, config: Dict[str, Any] = None):
        """
        Initialize tool.
        
        Args:
            config: Tool configuration
        """
        self.config = config or {}
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Tool name."""
        pass
    
    @property
    @abstractmethod
    def description(self) -> str:
        """Tool description."""
        pass
    
    @abstractmethod
    async def execute(self, **kwargs) -> Dict[str, Any]:
        """
        Execute tool.
        
        Returns:
            Result dictionary
        """
        pass
    
    def get_schema(self) -> Dict[str, Any]:
        """
        Get tool schema for Gemini function calling.
        
        Returns:
            Function declaration schema
        """
        return {
            "name": self.name,
            "description": self.description,
            "parameters": self.get_parameters()
        }
    
    @abstractmethod
    def get_parameters(self) -> Dict[str, Any]:
        """
        Get parameter schema.
        
        Returns:
            JSON schema for parameters
        """
        pass
