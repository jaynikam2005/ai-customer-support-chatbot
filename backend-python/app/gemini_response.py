import os
import google.generativeai as genai
import logging
from typing import Dict, Any, Optional, Tuple
import hashlib
import time
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

class GeminiResponseGenerator:
    """Google Gemini-based response generation"""
    
    def __init__(self):
        self.model = None
        self.api_key = os.getenv('GOOGLE_API_KEY')
        self.model_name = os.getenv('GEMINI_MODEL', 'gemini-1.5-flash')
        
        # Predefined intents
        self.intent_labels = [
            'greeting', 'question', 'complaint', 'compliment', 
            'request', 'order_inquiry', 'technical_support',
            'billing', 'account', 'product_info', 'general'
        ]
        
        # Response cache to speed up repeated queries
        self.response_cache = {}
        self.cache_ttl = 3600  # Cache TTL in seconds (1 hour)
        self.max_cache_size = 500  # Max number of entries in the cache
        
    async def load_models(self):
        """Initialize Gemini model"""
        try:
            if not self.api_key:
                raise ValueError("GOOGLE_API_KEY not found in environment variables")
                
            # Configure Gemini
            genai.configure(api_key=self.api_key)
            
            # Initialize the model
            self.model = genai.GenerativeModel(self.model_name)
            
            logger.info(f"Gemini model {self.model_name} loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load Gemini model: {e}")
            raise
    
    async def generate_response(self, user_message: str, faq_context: Optional[Dict] = None, conversation_history: Optional[list] = None) -> Dict[str, Any]:
        """Generate response using Gemini with conversation context"""
        try:
            if not self.model:
                await self.load_models()
            
            # Use simple caching to speed up responses for identical questions
            # Only use cache for messages without conversation history
            context_info = ""
            if faq_context:
                context_info = faq_context.get('question', '') + faq_context.get('response', '')
            
            # Only use cache for simple queries without extensive conversation history
            should_use_cache = not conversation_history or len(conversation_history) <= 2
            
            if should_use_cache:
                cache_key = self._create_cache_key(user_message, context_info)
                cached_response = self._get_from_cache(cache_key)
                
                if cached_response:
                    logger.info(f"Cache hit for message: {user_message[:30]}...")
                    return cached_response
            
            # If no cache hit, generate a new response
            # Classify intent
            intent = await self._classify_intent(user_message)
            
            # Generate response with conversation context
            response = await self._generate_contextual_response(
                user_message, intent, faq_context, conversation_history or []
            )
            
            # Calculate confidence
            confidence = self._calculate_confidence(user_message, intent, response)
            
            result = {
                'intent': intent,
                'response': response,
                'confidence': confidence,
                'method': 'gemini'
            }
            
            # Cache the response if appropriate
            if should_use_cache:
                self._add_to_cache(cache_key, result)
            
            return result
            
        except Exception as e:
            logger.error(f"Error in Gemini response generation: {e}")
            return await self._fallback_response(user_message)
    
    async def _classify_intent(self, user_message: str) -> str:
        """Classify user intent using Gemini"""
        try:
            intent_prompt = f"""
            Classify the following customer support message into one of these intents:
            {', '.join(self.intent_labels)}
            
            Message: "{user_message}"
            
            Respond with only the intent name (no explanation):
            """
            
            response = self.model.generate_content(intent_prompt)
            intent = response.text.strip().lower()
            
            # Validate intent
            if intent in self.intent_labels:
                return intent
            else:
                return self._rule_based_intent(user_message)
                
        except Exception as e:
            logger.warning(f"Gemini intent classification failed: {e}")
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
    
    async def _generate_contextual_response(self, user_message: str, intent: str, faq_context: Optional[Dict], conversation_history: list = None) -> str:
        """Generate contextual response using Gemini with conversation history"""
        try:
            if conversation_history is None:
                conversation_history = []
                
            # Build context-aware prompt with dynamic response length
            if any(keyword in user_message.lower() for keyword in ['code', 'program', 'write', 'script', 'function', 'algorithm', 'example']):
                # For programming/technical requests, allow longer responses
                system_prompt = """You are a helpful customer support assistant with technical expertise. 
                Provide detailed, complete, and helpful responses to customer inquiries. 
                For code requests, provide complete working examples with explanations.
                For complex questions, provide thorough step-by-step guidance.
                Maintain a professional, friendly tone."""
            else:
                # For general support, keep responses concise
                system_prompt = """You are a helpful customer support assistant. 
                Provide clear, helpful responses to customer inquiries. 
                Keep responses appropriate to the question complexity.
                Maintain a professional, friendly tone."""
            
            # Build conversation context
            context_lines = []
            if faq_context:
                context_lines.append(f"Related FAQ: {faq_context.get('question', '')} - {faq_context.get('response', '')}")
            
            if conversation_history:
                context_lines.append("\nRecent conversation:")
                for msg in conversation_history[-6:]:  # Last 6 messages for context
                    # Handle both dictionary and object formats
                    if hasattr(msg, 'role') and hasattr(msg, 'content'):
                        # ConversationMessage object
                        role = "Customer" if msg.role == 'user' else "Assistant"
                        content = msg.content[:100] if msg.content else ''  # Truncate long messages
                    else:
                        # Dictionary format
                        role = "Customer" if msg.get('role') == 'user' else "Assistant"
                        content = msg.get('content', '')[:100]  # Truncate long messages
                    context_lines.append(f"{role}: {content}")
            
            context = "\n".join(context_lines) if context_lines else ""
            
            prompt = f"""{system_prompt}
            
            Customer Intent: {intent}
            {context}
            
            Current Customer Message: "{user_message}"
            
            Assistant Response:"""
            
            response = self.model.generate_content(prompt)
            generated_text = response.text.strip()
            
            # Clean response without aggressive truncation
            return self._clean_response(generated_text, user_message)
            
        except Exception as e:
            logger.warning(f"Gemini response generation failed: {e}")
            return self._template_based_response(user_message, intent)
    
    def _clean_response(self, response: str, user_message: str = "") -> str:
        """Clean and format the response"""
        # Remove any unwanted prefixes
        response = response.replace("Assistant Response:", "").strip()
        response = response.replace("Response:", "").strip()
        
        # Check if this is a programming/technical question
        is_technical = any(keyword in user_message.lower() for keyword in 
                          ['code', 'program', 'write', 'script', 'function', 'algorithm', 'example', 'how to'])
        
        # Apply different length limits based on question type
        if is_technical:
            # Allow much longer responses for technical questions (up to 2000 characters)
            if len(response) > 2000:
                # For technical responses, try to keep complete code blocks
                sentences = response.split('.')
                response = '. '.join(sentences[:10]) + '.' if len(sentences) > 10 else response
        else:
            # For general support, moderate limit (up to 500 characters)
            if len(response) > 500:
                sentences = response.split('.')
                response = '. '.join(sentences[:3]) + '.' if len(sentences) > 3 else response
        
        return response
    
    def _template_based_response(self, user_message: str, intent: str) -> str:
        """Generate intelligent template-based responses as fallback"""
        message_lower = user_message.lower()
        
        # Programming/Technical questions
        if any(keyword in message_lower for keyword in ['python', 'code', 'program', 'function', 'algorithm', 'machine learning', 'ai', 'script', 'data', 'variable', 'loop', 'class', 'import']):
            if 'machine learning' in message_lower or 'ml' in message_lower:
                return """Machine learning is a subset of artificial intelligence (AI) that enables computers to learn and make decisions from data without being explicitly programmed for every task. Here's a simple Python example:

```python
from sklearn.linear_model import LinearRegression
import numpy as np

# Sample data
X = np.array([[1], [2], [3], [4], [5]])  # Features
y = np.array([2, 4, 6, 8, 10])  # Target values

# Create and train model
model = LinearRegression()
model.fit(X, y)

# Make predictions
prediction = model.predict([[6]])
print(f"Prediction for input 6: {prediction[0]}")
```

This demonstrates supervised learning where the model learns from input-output pairs to predict new values."""

            elif 'python' in message_lower:
                return """Python is a high-level, interpreted programming language known for its simplicity and readability. Here's a basic example:

```python
# Basic Python concepts
def greet(name):
    return f"Hello, {name}!"

# Variables and data types
numbers = [1, 2, 3, 4, 5]
message = "Python is awesome!"

# List comprehension
squares = [x**2 for x in numbers]

# Function call
greeting = greet("World")
print(greeting)
print(f"Squares: {squares}")
```

Python is widely used for web development, data science, machine learning, automation, and more."""

            elif 'code' in message_lower or 'program' in message_lower:
                return """I'd be happy to help with programming! Here's a general structure for most programming problems:

```python
# 1. Define the problem clearly
# 2. Break it into smaller steps
# 3. Write the solution

def solve_problem(input_data):
    # Process the input
    result = process_data(input_data)
    
    # Return the solution
    return result

def process_data(data):
    # Your logic here
    processed = data * 2  # Example operation
    return processed

# Example usage
input_value = 5
output = solve_problem(input_value)
print(f"Result: {output}")
```

Could you provide more specific details about what you'd like to code?"""

            else:
                return "I can help with technical questions! Could you be more specific about what programming concept, language feature, or technical topic you'd like to learn about?"
        
        # General questions with specific keywords
        elif 'what is' in message_lower or 'what are' in message_lower:
            return f"Great question! You're asking about a specific topic. While I'd love to provide a detailed explanation, I'm currently experiencing some technical limitations. Could you try rephrasing your question or being more specific about what aspect of '{user_message.replace('what is', '').replace('what are', '').strip()}' you'd like to know about?"
        
        elif 'how to' in message_lower or 'how do' in message_lower:
            return f"I can help with step-by-step instructions! For the topic you're asking about, here's a general approach:\n\n1. First, understand the requirements\n2. Break the task into smaller steps\n3. Work through each step methodically\n4. Test and verify your solution\n\nCould you provide more specific details about what you're trying to accomplish?"
        
        # Intent-based templates with more context
        templates = {
            'greeting': "Hello! I'm here to help you with questions, coding problems, technical support, and more. What can I assist you with today?",
            'question': f"I'd be happy to help answer your question about: {user_message[:50]}{'...' if len(user_message) > 50 else ''}. Could you provide more specific details or context?",
            'complaint': "I apologize for any inconvenience you're experiencing. I'm here to help resolve this issue. Could you describe the specific problem you're encountering?",
            'compliment': "Thank you for your kind words! I'm glad I could help. Is there anything else you'd like to know or work on?",
            'order_inquiry': "I can help you with order-related questions. Could you please provide more details about what you need assistance with?",
            'technical_support': f"I'll help you troubleshoot this technical issue: {user_message[:50]}{'...' if len(user_message) > 50 else ''}. Let's work through this step by step. What specific problem are you experiencing?",
            'billing': "I can assist with billing and account questions. What specific information do you need help with?",
            'account': "I'm here to help with your account. What would you like to know or what issue can I help resolve?",
            'product_info': f"I'd be happy to provide information about the topic you're asking about. Based on your question: '{user_message[:50]}{'...' if len(user_message) > 50 else ''}', what specific details would you like to know?",
            'general': f"Thank you for contacting me! I see you're asking about: '{user_message[:50]}{'...' if len(user_message) > 50 else ''}'. How can I best assist you with this?"
        }
        
        return templates.get(intent, templates['general'])
    
    def _calculate_confidence(self, user_message: str, intent: str, response: str) -> float:
        """Calculate confidence score for Gemini response"""
        confidence = 0.8  # Base confidence for Gemini (higher than local models)
        
        # Adjust based on message clarity
        if len(user_message.split()) > 3:
            confidence += 0.05
            
        # Adjust based on response length
        if 10 <= len(response.split()) <= 50:
            confidence += 0.05
            
        # Adjust based on intent certainty
        if intent in ['greeting', 'compliment']:
            confidence += 0.05
            
        return min(confidence, 0.95)  # Cap at 95%
    
    async def _fallback_response(self, user_message: str) -> Dict[str, Any]:
        """Ultimate fallback response"""
        return {
            'intent': 'general',
            'response': "I'm here to help! Could you please rephrase your question or provide more details?",
            'confidence': min(0.5, 1.0),  # Ensure confidence is at most 1.0
            'method': 'fallback'
        }
        
    def _create_cache_key(self, user_message: str, context_info: str = "") -> str:
        """Create a cache key from the user message and context"""
        # Normalize the input text
        normalized_message = user_message.lower().strip()
        combined_str = f"{normalized_message}|{context_info}"
        
        # Create a hash of the message
        return hashlib.md5(combined_str.encode('utf-8')).hexdigest()
    
    def _get_from_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """Get a response from cache if it exists and is not expired"""
        if cache_key not in self.response_cache:
            return None
        
        cached_item = self.response_cache[cache_key]
        timestamp, response = cached_item
        
        # Check if the cache entry has expired
        if time.time() - timestamp > self.cache_ttl:
            del self.response_cache[cache_key]
            return None
            
        return response
    
    def _add_to_cache(self, cache_key: str, response: Dict[str, Any]) -> None:
        """Add a response to the cache"""
        # If cache is full, remove the oldest entry
        if len(self.response_cache) >= self.max_cache_size:
            oldest_key = min(self.response_cache.keys(), 
                           key=lambda k: self.response_cache[k][0])
            del self.response_cache[oldest_key]
        
        # Add the new entry with current timestamp
        self.response_cache[cache_key] = (time.time(), response)