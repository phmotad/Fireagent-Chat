"""Criteria evaluator for conditional tool execution."""
from typing import Dict, Any, Optional
import logging
import re

logger = logging.getLogger(__name__)


class CriteriaEvaluator:
    """Evaluates conditions to determine if a tool should be executed."""

    @staticmethod
    def evaluate(
        conditions: Dict[str, Any],
        context: Dict[str, Any]
    ) -> tuple[bool, Optional[str]]:
        """
        Evaluate if conditions are met.

        Args:
            conditions: Tool conditions from database
            context: Current context (message, history, etc.)

        Returns:
            Tuple of (should_execute: bool, reason: Optional[str])
        """
        if not conditions:
            return True, None

        message = context.get("message", "").lower()
        history = context.get("history", [])
        sentiment = context.get("sentiment")

        # 1. Check keywords
        keywords = conditions.get("keywords", [])
        if keywords:
            if not any(kw.lower() in message for kw in keywords):
                return False, f"Keywords not matched. Required one of: {', '.join(keywords)}"

        # 2. Check sentiment
        required_sentiment = conditions.get("sentiment")
        if required_sentiment and sentiment:
            if sentiment.lower() != required_sentiment.lower():
                return False, f"Sentiment mismatch. Required: {required_sentiment}, Got: {sentiment}"

        # 3. Check unanswered messages threshold
        unanswered_threshold = conditions.get("unanswered_messages")
        if unanswered_threshold:
            # Count consecutive user messages without bot response
            unanswered_count = 0
            for msg in reversed(history[-10:]):  # Last 10 messages
                if msg.get("role") == "user":
                    unanswered_count += 1
                else:
                    break

            if unanswered_count < unanswered_threshold:
                return False, f"Not enough unanswered messages. Need {unanswered_threshold}, got {unanswered_count}"

        # 4. Check regex pattern
        regex_pattern = conditions.get("regex")
        if regex_pattern:
            try:
                if not re.search(regex_pattern, message, re.IGNORECASE):
                    return False, f"Regex pattern not matched: {regex_pattern}"
            except re.error as e:
                logger.error(f"Invalid regex pattern: {regex_pattern} - {e}")
                return False, f"Invalid regex pattern"

        # 5. Check time-based conditions
        time_condition = conditions.get("time")
        if time_condition:
            # Check if current time matches condition (e.g., business hours)
            from datetime import datetime
            now = datetime.now()
            hour = now.hour

            start_hour = time_condition.get("start_hour", 0)
            end_hour = time_condition.get("end_hour", 24)

            if not (start_hour <= hour < end_hour):
                return False, f"Outside operating hours ({start_hour}:00-{end_hour}:00)"

        # 6. Check conversation status
        required_status = conditions.get("conversation_status")
        if required_status:
            current_status = context.get("conversation_status")
            if current_status and current_status != required_status:
                return False, f"Conversation status mismatch. Required: {required_status}, Got: {current_status}"

        # 7. Check message count
        min_messages = conditions.get("min_messages")
        if min_messages:
            message_count = len(history)
            if message_count < min_messages:
                return False, f"Not enough messages in conversation. Need {min_messages}, got {message_count}"

        # 8. Check custom condition (JavaScript-like expression)
        custom_expr = conditions.get("custom")
        if custom_expr:
            # Simple expression evaluation (extend as needed)
            # Example: "message_length > 100"
            try:
                message_length = len(context.get("message", ""))
                local_vars = {
                    "message_length": message_length,
                    "message_count": len(history),
                }

                # Basic eval (be careful with this in production)
                # For now, support simple comparisons
                if "message_length" in custom_expr:
                    if not eval(custom_expr.replace("message_length", str(message_length))):
                        return False, f"Custom condition not met: {custom_expr}"
            except Exception as e:
                logger.error(f"Error evaluating custom condition: {custom_expr} - {e}")
                return False, f"Invalid custom condition"

        # All conditions met
        return True, None

    @staticmethod
    def analyze_sentiment(text: str) -> str:
        """
        Simple sentiment analysis (can be enhanced with ML models).

        Args:
            text: Text to analyze

        Returns:
            Sentiment: "positive", "negative", or "neutral"
        """
        # Simple keyword-based sentiment
        negative_words = [
            "problema", "ruim", "péssimo", "horrível", "não funciona",
            "erro", "bug", "irritado", "furioso", "cancelar", "reclamar"
        ]

        positive_words = [
            "ótimo", "excelente", "perfeito", "obrigado", "agradeço",
            "bom", "legal", "maravilhoso", "satisfeito", "feliz"
        ]

        text_lower = text.lower()

        negative_count = sum(1 for word in negative_words if word in text_lower)
        positive_count = sum(1 for word in positive_words if word in text_lower)

        if negative_count > positive_count:
            return "negative"
        elif positive_count > negative_count:
            return "positive"
        else:
            return "neutral"


# Global instance
criteria_evaluator = CriteriaEvaluator()
