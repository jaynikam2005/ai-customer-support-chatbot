from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import logging
from contextlib import asynccontextmanager
import uvicorn
import os

from .faq_matcher import FAQMatcher
from .gemini_response import GeminiResponseGenerator  # Use Gemini instead

from fastapi.middleware.cors import CORSMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for models
faq_matcher = None
llm_generator = None

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
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for dev, allow all
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
        
        logger.info(f"Analyzing message: {user_message[:50]}... (with {len(conversation_history)} history messages)")
        
        # Step 1: Try FAQ matching
        faq_result = await faq_matcher.find_best_match(user_message)
        
        if faq_result and faq_result['confidence'] >= 0.7:  # High confidence FAQ match
            logger.info(f"FAQ match found with confidence: {faq_result['confidence']:.2f}")
            return AnalyzeResponse(
                intent=faq_result['intent'],
                reply=faq_result['response'],
                confidence=faq_result['confidence'],
                source="faq"
            )
        
        # Step 2: Fall back to Gemini with conversation context
        logger.info("No high-confidence FAQ match, using Gemini with context...")
        gemini_result = await llm_generator.generate_response(
            user_message, 
            faq_context=faq_result if faq_result else None,
            conversation_history=conversation_history
        )
        
        return AnalyzeResponse(
            intent=gemini_result['intent'],
            reply=gemini_result['response'],
            confidence=gemini_result['confidence'],
            source="gemini"
        )
        
    except Exception as e:
        logger.error(f"Error analyzing message: {e}")
        raise HTTPException(status_code=500, detail="Internal server error during message analysis")

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=5000,
        reload=True,
        log_level="info"
    )