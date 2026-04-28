import africastalking
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class SMSService:
    def __init__(self):
        africastalking.initialize(
            username=settings.AFRICASTALKING_USERNAME,
            api_key=settings.AFRICASTALKING_API_KEY
        )
        self.sms = africastalking.SMS

    def send_sms(self, phone_number: str, message: str) -> bool:
        """
        Send an SMS via Africa's Talking.
        Returns True on success, raises exception on failure.
        """
        try:
            response = self.sms.send(
                message=message,
                recipients=[phone_number],
                sender_id=settings.AFRICASTALKING_SENDER_ID
            )
            recipients = response.get('SMSMessageData', {}).get('Recipients', [])
            if recipients and recipients[0].get('status') == 'Success':
                logger.info(f"SMS sent successfully to {phone_number}")
                return True
            else:
                logger.warning(f"SMS send returned non-success for {phone_number}: {response}")
                return False
        except Exception as e:
            logger.error(f"Africa's Talking SMS error for {phone_number}: {e}")
            raise
