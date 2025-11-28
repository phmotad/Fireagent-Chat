"""Scheduling tool - schedule appointments."""
from .base import BaseTool
from typing import Dict, Any
import httpx
from config import settings
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class SchedulingTool(BaseTool):
    """Tool to schedule appointments."""
    
    @property
    def name(self) -> str:
        return "schedule_appointment"
    
    @property
    def description(self) -> str:
        return "Schedule an appointment for the customer"
    
    def get_parameters(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "date": {
                    "type": "string",
                    "description": "Appointment date (YYYY-MM-DD)"
                },
                "time": {
                    "type": "string",
                    "description": "Appointment time (HH:MM)"
                },
                "service": {
                    "type": "string",
                    "description": "Service or reason for appointment"
                },
                "notes": {
                    "type": "string",
                    "description": "Additional notes",
                    "nullable": True
                }
            },
            "required": ["date", "time", "service"]
        }
    
    async def execute(
        self,
        conversation_id: int,
        date: str,
        time: str,
        service: str,
        account_id: int = None,
        notes: str = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Schedule appointment with vacancy control.

        Args:
            conversation_id: Conversation ID
            date: Appointment date (YYYY-MM-DD)
            time: Appointment time (HH:MM)
            service: Service type
            account_id: Account ID (passed from main.py)
            notes: Additional notes

        Returns:
            Result with success status
        """
        try:
            if not account_id:
                return {
                    "success": False,
                    "error": "Account ID is required for scheduling"
                }

            # 1. Validate date/time format
            try:
                datetime.strptime(date, "%Y-%m-%d")
                datetime.strptime(time, "%H:%M")
            except ValueError:
                return {
                    "success": False,
                    "error": "Data inválida. Use formato YYYY-MM-DD para data e HH:MM para hora"
                }

            # 2. Check availability
            async with httpx.AsyncClient() as client:
                headers = {"api_access_token": settings.chatwoot_api_key}

                # Check if Chatwoot Agenda/Calendar system has availability endpoint
                # This assumes you have a custom calendar API endpoint
                availability_url = f"{settings.chatwoot_url}/api/v1/accounts/{account_id}/agenda/availability"

                try:
                    availability_response = await client.get(
                        availability_url,
                        params={"date": date, "time": time, "service": service},
                        headers=headers
                    )

                    if availability_response.status_code == 200:
                        availability = availability_response.json()

                        if not availability.get("available", True):
                            available_slots = availability.get("available_slots", [])
                            return {
                                "success": False,
                                "error": f"Horário indisponível. Vagas esgotadas.",
                                "available_slots": available_slots,
                                "message": f"Este horário já está lotado. Horários disponíveis: {', '.join(available_slots) if available_slots else 'Nenhum disponível hoje'}"
                            }
                except httpx.HTTPStatusError as e:
                    # If endpoint doesn't exist, continue without vacancy check
                    if e.response.status_code != 404:
                        logger.warning(f"Availability check failed: {e}")

                # 3. Create appointment
                create_url = f"{settings.chatwoot_url}/api/v1/accounts/{account_id}/agenda/appointments"

                appointment_data = {
                    "date": date,
                    "time": time,
                    "service": service,
                    "conversation_id": conversation_id,
                    "notes": notes or ""
                }

                try:
                    create_response = await client.post(
                        create_url,
                        json=appointment_data,
                        headers=headers
                    )

                    if create_response.status_code in [200, 201]:
                        appointment = create_response.json()

                        logger.info(f"Appointment created: {date} {time} - {service}")

                        return {
                            "success": True,
                            "message": f"✅ Agendamento confirmado para {date} às {time}",
                            "appointment": {
                                "id": appointment.get("id"),
                                "date": date,
                                "time": time,
                                "service": service,
                                "notes": notes
                            }
                        }
                except httpx.HTTPStatusError as e:
                    if e.response.status_code == 404:
                        # Fallback: Create custom attribute on conversation
                        logger.info("Calendar API not available, storing as conversation attribute")

                        # Store appointment in conversation custom attributes
                        conv_url = f"{settings.chatwoot_url}/api/v1/conversations/{conversation_id}"
                        await client.patch(
                            conv_url,
                            json={
                                "custom_attributes": {
                                    "appointment_date": date,
                                    "appointment_time": time,
                                    "appointment_service": service,
                                    "appointment_notes": notes
                                }
                            },
                            headers=headers
                        )

                        logger.info(f"Appointment stored as conversation attribute: {date} {time}")

                        return {
                            "success": True,
                            "message": f"✅ Agendamento confirmado para {date} às {time}",
                            "appointment": {
                                "date": date,
                                "time": time,
                                "service": service,
                                "notes": notes
                            }
                        }

        except Exception as e:
            logger.error(f"Error scheduling appointment: {e}")
            return {
                "success": False,
                "error": str(e)
            }
