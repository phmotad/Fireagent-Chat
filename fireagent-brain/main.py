"""FireAgent Brain - AI Service for Chatwoot."""
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import httpx

# Local imports
from config import settings
from models import WebhookPayload, AiAgent
from database import db
from memory_manager import memory_manager
from gemini_client import gemini_client
from rag_engine import rag_engine
from tools import HandoverTool, AddLabelTool, SchedulingTool, WhatsAppButtonsTool, RunMacroTool
from multimodal_processor import multimodal_processor
from criteria_evaluator import criteria_evaluator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="FireAgent Brain",
    description="AI Service for Chatwoot with Gemini integration",
    version="1.0.0"
)


# Tool registry
TOOLS = {
    "handover_to_human": HandoverTool(),
    "add_label": AddLabelTool(),
    "schedule_appointment": SchedulingTool(),
    "send_whatsapp_buttons": WhatsAppButtonsTool(),
    "run_macro": RunMacroTool(),
}


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "fireagent-brain"}


@app.post("/webhook")
async def webhook(payload: WebhookPayload, background_tasks: BackgroundTasks):
    """
    Process Chatwoot webhooks.
    
    Handles message_created events and generates AI responses.
    """
    try:
        # Only process message_created events
        if payload.event != "message_created":
            return {"status": "ignored", "reason": "not a message_created event"}
        
        # Ignore outgoing messages (from bot itself)
        message = payload.message
        if not message or message.get("message_type") != 0:  # 0 = incoming
            return {"status": "ignored", "reason": "not an incoming message"}
        
        # Process in background
        background_tasks.add_task(process_message, payload)
        
        return {"status": "processing"}
        
    except Exception as e:
        logger.error(f"Error in webhook: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def process_message(payload: WebhookPayload):
    """Process incoming message and generate response."""
    try:
        conversation = payload.conversation
        message = payload.message
        inbox = payload.inbox
        account = payload.account

        conversation_id = conversation.get("id")
        inbox_id = inbox.get("id")
        account_id = account.get("id") if account else None
        message_content = message.get("content", "")
        attachments = message.get("attachments", [])

        logger.info(f"Processing message from conversation {conversation_id}, account {account_id}")

        # 1. Get AI Agent configuration
        agent_data = db.get_agent_by_inbox(inbox_id)
        if not agent_data:
            logger.info(f"No AI agent configured for inbox {inbox_id}")
            return

        agent = AiAgent(**agent_data)
        logger.info(f"Using agent: {agent.name}")

        # 2. Process attachments (multimodal)
        multimodal_parts = []
        if attachments:
            logger.info(f"Processing {len(attachments)} attachments")
            multimodal_parts = await multimodal_processor.process_attachments(attachments)
            if multimodal_parts:
                logger.info(f"Processed {len(multimodal_parts)} multimodal parts")

        # 3. Get agent tools
        tools_data = db.get_agent_tools(agent.id)
        available_tools = []
        tool_schemas = []
        tools_with_conditions = []  # Store tools with conditions for evaluation

        for tool_data in tools_data:
            # Check if tool is enabled
            if not tool_data.get("enabled", True):
                continue

            tool_name = tool_data.get("name")
            if tool_name in TOOLS:
                tool = TOOLS[tool_name]
                available_tools.append(tool)
                tool_schemas.append(tool.get_schema())
                tools_with_conditions.append({
                    "tool": tool,
                    "data": tool_data
                })
        
        # 4. Get conversation history (memory)
        history = memory_manager.get_conversation_history(
            conversation_id,
            agent.memory_window_size
        )
        formatted_history = memory_manager.format_for_gemini(history)

        # 5. Analyze sentiment
        sentiment = criteria_evaluator.analyze_sentiment(message_content)
        logger.info(f"Message sentiment: {sentiment}")

        # 6. Search knowledge base (RAG)
        context = rag_engine.search_knowledge(agent.id, message_content)

        # 7. Generate response with Gemini
        response = await gemini_client.generate_response(
            agent=agent,
            history=formatted_history,
            message=message_content,
            tools=tool_schemas if tool_schemas else None,
            context=context if context else None,
            multimodal_parts=multimodal_parts if multimodal_parts else None
        )
        
        # 8. Execute tool calls if any (with criteria evaluation)
        if response.tool_calls:
            for tool_call in response.tool_calls:
                # Find tool data with conditions
                tool_data = next(
                    (t["data"] for t in tools_with_conditions if t["tool"].name == tool_call.name),
                    None
                )

                # Evaluate conditions if present
                if tool_data and tool_data.get("conditions"):
                    context_for_eval = {
                        "message": message_content,
                        "history": history,
                        "sentiment": sentiment,
                        "conversation_status": conversation.get("status")
                    }

                    should_execute, reason = criteria_evaluator.evaluate(
                        tool_data.get("conditions", {}),
                        context_for_eval
                    )

                    if not should_execute:
                        logger.info(f"Tool {tool_call.name} NOT executed. Reason: {reason}")
                        continue

                # Execute tool
                tool = TOOLS.get(tool_call.name)
                if tool:
                    logger.info(f"Executing tool: {tool_call.name}")

                    # Pass account_id to tools that need it
                    tool_args = {
                        "conversation_id": conversation_id,
                        "account_id": account_id,
                        **tool_call.arguments
                    }

                    result = await tool.execute(**tool_args)
                    logger.info(f"Tool result: {result}")

                    # If handover, stop processing
                    if tool_call.name == "handover_to_human":
                        return
        
        # 7. Send response to Chatwoot
        if response.content:
            await send_message_to_chatwoot(
                conversation_id,
                response.content
            )
            
            # 8. Update memory
            memory_manager.add_message(
                conversation_id,
                message_content,
                message_type=0,  # incoming
                max_window=agent.memory_window_size
            )
            memory_manager.add_message(
                conversation_id,
                response.content,
                message_type=1,  # outgoing
                max_window=agent.memory_window_size
            )
            
            # 9. Log interaction
            db.log_interaction(
                agent_id=agent.id,
                conversation_id=conversation_id,
                user_message=message_content,
                ai_response=response.content,
                action_taken="reply",
                metadata={"model": agent.model, "tools_used": [t.name for t in response.tool_calls] if response.tool_calls else []}
            )
        
        logger.info(f"Message processed successfully for conversation {conversation_id}")
        
    except Exception as e:
        logger.error(f"Error processing message: {e}", exc_info=True)


async def send_message_to_chatwoot(conversation_id: int, content: str):
    """Send message back to Chatwoot."""
    try:
        async with httpx.AsyncClient() as client:
            url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}/messages"
            headers = {"api_access_token": settings.chatwoot_api_key}
            
            payload = {
                "content": content,
                "message_type": "outgoing",
                "private": False
            }
            
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            
            logger.info(f"Message sent to conversation {conversation_id}")
            
    except Exception as e:
        logger.error(f"Error sending message to Chatwoot: {e}")


class IngestRequest(BaseModel):
    """Request model for document ingestion."""
    agent_id: int
    file_path: str
    content: str
    metadata: Optional[Dict[str, Any]] = None


@app.post("/ingest")
async def ingest_document(request: IngestRequest):
    """
    Ingest document into knowledge base.
    
    Generates embeddings and stores in pgvector.
    """
    try:
        # Chunk large documents
        chunks = rag_engine.chunk_text(request.content)
        
        success_count = 0
        for i, chunk in enumerate(chunks):
            chunk_path = f"{request.file_path}#chunk{i}"
            success = await rag_engine.ingest_document(
                agent_id=request.agent_id,
                file_path=chunk_path,
                content=chunk,
                metadata={
                    **(request.metadata or {}),
                    "chunk_index": i,
                    "total_chunks": len(chunks)
                }
            )
            if success:
                success_count += 1
        
        return {
            "status": "success",
            "chunks_processed": success_count,
            "total_chunks": len(chunks)
        }
        
    except Exception as e:
        logger.error(f"Error ingesting document: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/test")
async def test_agent(request: dict):
    """
    Test endpoint for agent interaction.

    Used by the UI to test agents without creating real conversations.
    """
    try:
        agent_id = request.get("agent_id")
        conversation_id = request.get("conversation_id")  # Test conversation ID (string)
        message = request.get("message")

        # Get agent configuration
        agent_data = db.get_agent_by_id(agent_id)
        if not agent_data:
            raise HTTPException(status_code=404, detail="Agent not found")

        agent = AiAgent(**agent_data)

        # Get tools
        tools_data = db.get_agent_tools(agent.id)
        tool_schemas = []
        for tool_data in tools_data:
            tool_name = tool_data.get("name")
            if tool_name in TOOLS:
                tool = TOOLS[tool_name]
                tool_schemas.append(tool.get_schema())

        # Get history for test conversation (uses only Redis, no DB lookup)
        history = memory_manager.get_test_conversation_history(
            conversation_id,
            agent.memory_window_size
        )
        formatted_history = memory_manager.format_for_gemini(history)

        # Search knowledge base
        context = rag_engine.search_knowledge(agent.id, message)

        # Generate response
        response = await gemini_client.generate_response(
            agent=agent,
            history=formatted_history,
            message=message,
            tools=tool_schemas if tool_schemas else None,
            context=context if context else None
        )

        # Update memory (uses only Redis for test conversations)
        memory_manager.add_test_message(
            conversation_id,
            message,
            message_type=0,
            max_window=agent.memory_window_size
        )
        memory_manager.add_test_message(
            conversation_id,
            response.content,
            message_type=1,
            max_window=agent.memory_window_size
        )

        return {
            "content": response.content,
            "tool_calls": [{"name": tc.name, "arguments": tc.arguments} for tc in response.tool_calls] if response.tool_calls else [],
            "context_used": bool(context)
        }

    except Exception as e:
        logger.error(f"Error in test endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")

async def root():
    """Root endpoint."""
    return {
        "service": "FireAgent Brain",
        "version": "1.0.0",
        "status": "running"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
