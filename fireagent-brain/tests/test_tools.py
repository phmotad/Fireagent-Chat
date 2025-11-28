"""Tests for tools."""
import pytest
from tools.handover import HandoverTool
from tools.labels import AddLabelTool

@pytest.mark.asyncio
async def test_handover_tool_schema():
    """Test handover tool schema generation."""
    tool = HandoverTool()
    schema = tool.get_schema()
    
    assert schema["name"] == "handover_to_human"
    assert "reason" in schema["parameters"]["properties"]
    assert "reason" in schema["parameters"]["required"]

@pytest.mark.asyncio
async def test_add_label_tool_schema():
    """Test add label tool schema generation."""
    tool = AddLabelTool()
    schema = tool.get_schema()
    
    assert schema["name"] == "add_label"
    assert "label" in schema["parameters"]["properties"]
    assert "label" in schema["parameters"]["required"]
