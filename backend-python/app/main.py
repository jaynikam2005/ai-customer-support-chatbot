from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
import logging
from contextlib import asynccontextmanager
import uvicorn
import os
import time
import hashlib
import json
from collections import OrderedDict
import threading

from .faq_matcher import FAQMatcher
from .gemini_response import GeminiResponseGenerator  # Use Gemini instead

from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for models
faq_matcher = None
llm_generator = None

# Simple LRU Cache for /analyze endpoint
class ResponseCache:
    def __init__(self, max_size=100, ttl_seconds=3600):
        self.cache = OrderedDict()
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self.lock = threading.RLock()
        
    def get(self, key):
        """Get item from cache if it exists and is not expired"""
        with self.lock:
            if key not in self.cache:
                return None
                
            value, timestamp = self.cache[key]
            
            # Check if expired
            if time.time() - timestamp > self.ttl_seconds:
                del self.cache[key]
                return None
                
            # Move to end to mark as recently used
            self.cache.move_to_end(key)
            return value
            
    def put(self, key, value):
        """Add item to cache with current timestamp"""
        with self.lock:
            if key in self.cache:
                del self.cache[key]
                
            # If cache is full, remove oldest item
            if len(self.cache) >= self.max_size:
                self.cache.popitem(last=False)
                
            self.cache[key] = (value, time.time())
            
    def create_key(self, request_data):
        """Create cache key from request data"""
        # For simplicity, we only cache requests with no conversation history
        # or with very short conversation history
        if len(request_data.conversation_history or []) > 2:
            return None
            
        key_str = request_data.message.lower().strip()
        return hashlib.md5(key_str.encode('utf-8')).hexdigest()
            
# Initialize response cache with configurable settings from environment variables
cache_enabled = os.getenv("RESPONSE_CACHE_ENABLED", "true").lower() == "true"
cache_max_size = int(os.getenv("MAX_CACHE_ITEMS", "200"))
cache_ttl = int(os.getenv("RESPONSE_CACHE_TTL", "3600"))  # Default 1 hour TTL

response_cache = ResponseCache(max_size=cache_max_size, ttl_seconds=cache_ttl)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize models on startup and cleanup on shutdown"""
    global faq_matcher, llm_generator
    
    logger.info("Loading AI models...")
    try:
        # Initialize FAQ matcher
        faq_matcher = FAQMatcher()
        await faq_matcher.load_knowledge_base()
        
        # Initialize Gemini response generator
        llm_generator = GeminiResponseGenerator()
        await llm_generator.load_models()
        
        logger.info("All models loaded successfully!")
        yield
        
    except Exception as e:
        logger.error(f"Failed to load models: {e}")
        raise
    finally:
        logger.info("Shutting down AI service...")

# FastAPI app with lifespan management
app = FastAPI(
    title="AI Customer Support Service",
    description="Intent classification and response generation for customer support chatbot",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware after app is created
# Get allowed origins from environment variable, fallback to all (*) for development
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",") if os.getenv("ALLOWED_ORIGINS") else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response models
class ConversationMessage(BaseModel):
    role: str = Field(..., description="Message role: 'user' or 'assistant'")
    content: str = Field(..., description="Message content")

class AnalyzeRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000, description="User message to analyze")
    conversation_history: Optional[list[ConversationMessage]] = Field(default=[], description="Recent conversation history for context")

class AnalyzeResponse(BaseModel):
    intent: str = Field(..., description="Detected intent category")
    reply: str = Field(..., description="Generated response")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    source: str = Field(..., description="Response source: 'faq' or 'gemini'")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "healthy", "service": "AI Customer Support", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "models_loaded": faq_matcher is not None and llm_generator is not None,
        "faq_entries": len(faq_matcher.knowledge_base) if faq_matcher else 0,
        "gemini_api_configured": os.getenv('GOOGLE_API_KEY') is not None
    }

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze_message(request: AnalyzeRequest):
    """
    Analyze user message and generate appropriate response with conversation context
    
    First tries FAQ matching, falls back to Gemini if no good match found
    """
    try:
        user_message = request.message.strip()
        conversation_history = request.conversation_history or []
        
        if not user_message:
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        # Try to get from cache first if it's a simple question
        cache_key = response_cache.create_key(request)
        if cache_key:
            cached_response = response_cache.get(cache_key)
            if cached_response:
                logger.info(f"Cache hit for message: {user_message[:30]}...")
                return cached_response
        
        logger.info(f"Analyzing message: {user_message[:50]}... (with {len(conversation_history)} history messages)")
        
        # Step 1: Try FAQ matching
        faq_result = await faq_matcher.find_best_match(user_message)
        
        if faq_result and faq_result['confidence'] >= 0.7:  # High confidence FAQ match
            logger.info(f"FAQ match found with confidence: {faq_result['confidence']:.2f}")
            response = AnalyzeResponse(
                intent=faq_result['intent'],
                reply=faq_result['response'],
                confidence=faq_result['confidence'],
                source="faq"
            )
            
            # Cache the response if appropriate
            if cache_key:
                response_cache.put(cache_key, response)
                
            return response
        
        # Step 2: Fall back to Gemini with conversation context
        logger.info("No high-confidence FAQ match, using Gemini with context...")
        gemini_result = await llm_generator.generate_response(
            user_message, 
            faq_context=faq_result if faq_result else None,
            conversation_history=conversation_history
        )
        
        response = AnalyzeResponse(
            intent=gemini_result['intent'],
            reply=gemini_result['response'],
            confidence=gemini_result['confidence'],
            source="gemini"
        )
        
        # Cache the response if appropriate
        if cache_key:
            response_cache.put(cache_key, response)
            
        return response
        
    except Exception as e:
        logger.error(f"Error analyzing message: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during message analysis")

if __name__ == "__main__":
    # Get host and port from environment variables with fallbacks
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "5000"))
    
    # Determine if we're in development mode for auto-reload feature
    dev_mode = os.getenv("ENVIRONMENT", "development").lower() == "development"
    
    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=dev_mode,
        log_level="info"
    )