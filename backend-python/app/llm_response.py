import torch
from transformers import (
    AutoTokenizer, AutoModelForSequenceClassification,
    AutoModelForCausalLM, pipeline
)
import logging
from typing import Dict, Any, Optional, List
import asyncio
import re

logger = logging.getLogger(__name__)

class LLMResponseGenerator:
    """LLM-based intent classification and response generation"""
    
    def __init__(self):
        # Intent classification model
        self.intent_tokenizer = None
        self.intent_model = None
        
        # Response generation model  
        self.response_generator = None
        
        # Predefined intents
        self.intent_labels = [
            'greeting', 'question', 'complaint', 'compliment', 
            'request', 'order_inquiry', 'technical_support',
            'billing', 'account', 'product_info', 'general'
        ]
        
    async def load_models(self):
        """Load intent classification and response generation models"""
        try:
            # Load intent classification model (DistilBERT)
            intent_model_name = "distilbert-base-uncased"
            self.intent_tokenizer = AutoTokenizer.from_pretrained(intent_model_name)
            self.intent_model = AutoModelForSequenceClassification.from_pretrained(
                intent_model_name,
                num_labels=len(self.intent_labels)
            )
            
            # Load response generation model (GPT-2 based)
            response_model_name = "microsoft/DialoGPT-medium"
            self.response_generator = pipeline(
                "conversational",
                model=response_model_name,
                tokenizer=response_model_name,
                device=0 if torch.cuda.is_available() else -1
            )
            
            logger.info("LLM models loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load LLM models: {e}")
            # Fallback to a simpler model
            await self._load_fallback_models()
    
    async def _load_fallback_models(self):
        """Load simpler fallback models"""
        try:
            # Use a lighter model as fallback
            self.response_generator = pipeline(
                "text-generation",
                model="distilgpt2",
                device=-1  # Force CPU
            )
            logger.info("Fallback models loaded")
        except Exception as e:
            logger.error(f"Failed to load fallback models: {e}")
    
    async def generate_response(self, user_message: str, faq_context: Optional[Dict] = None) -> Dict[str, Any]:
        """Generate response using LLM"""
        try:
            # Classify intent
            intent = await self._classify_intent(user_message)
            
            # Generate response
            response = await self._generate_contextual_response(
                user_message, intent, faq_context
            )
            
            # Calculate confidence based on various factors
            confidence = self._calculate_confidence(user_message, intent, response)
            
            return {
                'intent': intent,
                'response': response,
                'confidence': confidence,
                'method': 'llm'
            }
            
        except Exception as e:
            logger.error(f"Error in LLM response generation: {e}")
            return await self._fallback_response(user_message)
    
    async def _classify_intent(self, user_message: str) -> str:
        """Classify user intent using DistilBERT"""
        try:
            if not self.intent_model:
                return self._rule_based_intent(user_message)
                
            inputs = self.intent_tokenizer(
                user_message,
                return_tensors="pt",
                truncation=True,
                max_length=512,
                padding=True
            )
            
            with torch.no_grad():
                outputs = self.intent_model(**inputs)
                predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
                predicted_class_id = predictions.argmax().item()
                
            return self.intent_labels[predicted_class_id]
            
        except Exception as e:
            logger.warning(f"Intent classification failed: {e}")
            return self._rule_based_intent(user_message)
    
    def _rule_based_intent(self, user_message: str) -> str:
        """Simple rule-based intent classification as fallback"""
        message_lower = user_message.lower()
        
        greeting_words = ['hello', 'hi', 'hey', 'good morning', 'good afternoon']
        question_words = ['what', 'how', 'when', 'where', 'why', 'can', 'could', 'would']
        complaint_words = ['problem', 'issue', 'wrong', 'broken', 'not working', 'error']
        order_words = ['order', 'purchase', 'buy', 'track', 'delivery', 'shipping']
        
        if any(word in message_lower for word in greeting_words):
            return 'greeting'
        elif any(word in message_lower for word in complaint_words):
            return 'complaint'
        elif any(word in message_lower for word in order_words):
            return 'order_inquiry'
        elif any(message_lower.startswith(word) for word in question_words):
            return 'question'
        else:
            return 'general'
    
    async def _generate_contextual_response(self, user_message: str, intent: str, faq_context: Optional[Dict]) -> str:
        """Generate contextual response"""
        try:
            # Create context-aware prompt
            context_prompt = self._build_context_prompt(user_message, intent, faq_context)
            
            if self.response_generator:
                # Use conversation model if available
                if hasattr(self.response_generator, 'model') and 'DialoGPT' in str(type(self.response_generator.model)):
                    from transformers import Conversation
                    conversation = Conversation(context_prompt)
                    response = self.response_generator(conversation)
                    return response.generated_responses[-1]
                else:
                    # Use text generation
                    response = self.response_generator(
                        context_prompt,
                        max_length=150,
                        num_return_sequences=1,
                        temperature=0.7,
                        pad_token_id=self.response_generator.tokenizer.eos_token_id
                    )
                    generated_text = response[0]['generated_text']
                    # Extract just the response part
                    return self._extract_response(generated_text, context_prompt)
            else:
                return self._template_based_response(user_message, intent)
                
        except Exception as e:
            logger.warning(f"Contextual response generation failed: {e}")
            return self._template_based_response(user_message, intent)
    
    def _build_context_prompt(self, user_message: str, intent: str, faq_context: Optional[Dict]) -> str:
        """Build context-aware prompt for response generation"""
        prompt = "You are a helpful customer support assistant. "
        
        if faq_context:
            prompt += f"Related FAQ: {faq_context.get('question', '')} - {faq_context.get('response', '')}. "
        
        prompt += f"User ({intent}): {user_message}\nAssistant:"
        return prompt
    
    def _extract_response(self, generated_text: str, original_prompt: str) -> str:
        """Extract the response from generated text"""
        if "Assistant:" in generated_text:
            response = generated_text.split("Assistant:")[-1].strip()
        else:
            response = generated_text.replace(original_prompt, "").strip()
        
        # Clean up response
        response = re.sub(r'\n+', ' ', response)  # Replace newlines with spaces
        response = response.split('.')[0] + '.' if '.' in response else response
        
        return response[:200]  # Limit response length
    
    def _template_based_response(self, user_message: str, intent: str) -> str:
        """Generate template-based responses as fallback"""
        templates = {
            'greeting': "Hello! How can I assist you today?",
            'question': "I'd be happy to help answer your question. Could you provide more details?",
            'complaint': "I apologize for the inconvenience. Let me help resolve this issue for you.",
            'compliment': "Thank you for your kind words! Is there anything else I can help you with?",
            'order_inquiry': "I can help you with your order. Could you please provide your order number?",
            'technical_support': "I'll help you with this technical issue. Let's troubleshoot step by step.",
            'billing': "I can assist with billing inquiries. What specific information do you need?",
            'account': "I'm here to help with your account. What would you like to know?",
            'product_info': "I'd be happy to provide product information. What would you like to know?",
            'general': "Thank you for contacting us. How can I assist you today?"
        }
        
        return templates.get(intent, templates['general'])
    
    def _calculate_confidence(self, user_message: str, intent: str, response: str) -> float:
        """Calculate confidence score for LLM response"""
        confidence = 0.6  # Base confidence for LLM
        
        # Adjust based on message clarity
        if len(user_message.split()) > 3:
            confidence += 0.1
            
        # Adjust based on response length
        if 10 <= len(response.split()) <= 50:
            confidence += 0.1
            
        # Adjust based on intent certainty
        if intent in ['greeting', 'compliment']:
            confidence += 0.1
            
        return min(confidence, 0.95)  # Cap at 95%
    
    async def _fallback_response(self, user_message: str) -> Dict[str, Any]:
        """Ultimate fallback response"""
        return {
            'intent': 'general',
            'response': "I'm here to help! Could you please rephrase your question or provide more details?",
            'confidence': 0.5,
            'method': 'fallback'
        }
