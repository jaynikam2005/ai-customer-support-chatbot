import json
import csv
import aiofiles
import numpy as np
from typing import Dict, List, Optional, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from transformers import AutoTokenizer, AutoModel
import torch
import logging

logger = logging.getLogger(__name__)

class FAQMatcher:
    """FAQ matching using both TF-IDF and semantic embeddings"""
    
    def __init__(self, knowledge_base_path: str = "app/knowledge_base.json"):
        self.knowledge_base_path = knowledge_base_path
        self.knowledge_base: List[Dict] = []
        self.tfidf_vectorizer = TfidfVectorizer(
            stop_words='english',
            ngram_range=(1, 2),
            max_features=1000,
            lowercase=True
        )
        self.tfidf_matrix = None
        
        # Semantic similarity model
        self.semantic_tokenizer = None
        self.semantic_model = None
        self.semantic_embeddings = None
        
    async def load_knowledge_base(self):
        """Load FAQ knowledge base from JSON or CSV"""
        try:
            # Try JSON first
            async with aiofiles.open(self.knowledge_base_path, 'r') as f:
                content = await f.read()
                self.knowledge_base = json.loads(content)
                
        except (FileNotFoundError, json.JSONDecodeError):
            # Fall back to creating default knowledge base
            logger.info("Creating default knowledge base...")
            await self._create_default_knowledge_base()
            
        # Prepare TF-IDF vectors
        questions = [faq['question'] for faq in self.knowledge_base]
        self.tfidf_matrix = self.tfidf_vectorizer.fit_transform(questions)
        
        # Load semantic model
        await self._load_semantic_model()
        
        logger.info(f"Loaded {len(self.knowledge_base)} FAQ entries")
        
    async def _create_default_knowledge_base(self):
        """Create a default knowledge base for demonstration"""
        default_faqs = [
            {
                "question": "What are your business hours?",
                "response": "Our business hours are Monday to Friday, 9 AM to 6 PM EST. We're closed on weekends and major holidays.",
                "intent": "business_hours",
                "keywords": ["hours", "open", "closed", "time", "schedule"]
            },
            {
                "question": "How can I contact customer support?",
                "response": "You can reach our customer support team via email at support@company.com, phone at 1-800-123-4567, or through this chat system 24/7.",
                "intent": "contact_support",
                "keywords": ["contact", "support", "help", "phone", "email"]
            },
            {
                "question": "What is your return policy?",
                "response": "We offer a 30-day return policy for all products. Items must be in original condition with tags attached. Contact support to initiate a return.",
                "intent": "return_policy",
                "keywords": ["return", "refund", "exchange", "policy", "money back"]
            },
            {
                "question": "How do I track my order?",
                "response": "You can track your order using the tracking number sent to your email, or log into your account and view order status in the 'My Orders' section.",
                "intent": "order_tracking",
                "keywords": ["track", "order", "shipping", "status", "delivery"]
            },
            {
                "question": "Do you offer international shipping?",
                "response": "Yes, we ship internationally to over 50 countries. Shipping costs and delivery times vary by location. Check our shipping page for details.",
                "intent": "shipping_info",
                "keywords": ["international", "shipping", "delivery", "worldwide", "countries"]
            },
            {
                "question": "How do I reset my password?",
                "response": "To reset your password, click 'Forgot Password' on the login page, enter your email address, and follow the instructions sent to your email.",
                "intent": "password_reset",
                "keywords": ["password", "reset", "forgot", "login", "account"]
            }
        ]
        
        self.knowledge_base = default_faqs
        
        # Save to file
        async with aiofiles.open(self.knowledge_base_path, 'w') as f:
            await f.write(json.dumps(default_faqs, indent=2))
            
    async def _load_semantic_model(self):
        """Load semantic similarity model for better matching"""
        try:
            model_name = "sentence-transformers/all-MiniLM-L6-v2"
            self.semantic_tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.semantic_model = AutoModel.from_pretrained(model_name)
            
            # Pre-compute embeddings for all FAQ questions
            questions = [faq['question'] for faq in self.knowledge_base]
            self.semantic_embeddings = await self._compute_embeddings(questions)
            
            logger.info("Semantic similarity model loaded successfully")
            
        except Exception as e:
            logger.warning(f"Failed to load semantic model: {e}")
            
    async def _compute_embeddings(self, texts: List[str]) -> torch.Tensor:
        """Compute semantic embeddings for texts"""
        if not self.semantic_model:
            return None
            
        embeddings = []
        
        for text in texts:
            inputs = self.semantic_tokenizer(
                text, 
                return_tensors='pt', 
                truncation=True, 
                max_length=512,
                padding=True
            )
            
            with torch.no_grad():
                outputs = self.semantic_model(**inputs)
                # Mean pooling
                embeddings.append(outputs.last_hidden_state.mean(dim=1).squeeze())
                
        return torch.stack(embeddings)
    
    async def find_best_match(self, user_message: str) -> Optional[Dict[str, Any]]:
        """Find best matching FAQ using combined TF-IDF and semantic similarity"""
        if not self.knowledge_base:
            return None
            
        user_message = user_message.lower().strip()
        
        # Method 1: TF-IDF similarity
        tfidf_scores = self._compute_tfidf_similarity(user_message)
        
        # Method 2: Semantic similarity (if available)
        semantic_scores = None
        if self.semantic_embeddings is not None:
            semantic_scores = await self._compute_semantic_similarity(user_message)
        
        # Combine scores
        combined_scores = []
        for i in range(len(self.knowledge_base)):
            tfidf_score = tfidf_scores[i]
            semantic_score = semantic_scores[i] if semantic_scores is not None else 0.0
            
            # Weighted combination (60% semantic, 40% TF-IDF)
            if semantic_scores is not None:
                combined_score = 0.6 * semantic_score + 0.4 * tfidf_score
            else:
                combined_score = tfidf_score
                
            combined_scores.append(combined_score)
        
        # Find best match
        best_idx = np.argmax(combined_scores)
        best_score = combined_scores[best_idx]
        
        if best_score < 0.3:  # Minimum threshold
            return None
            
        best_faq = self.knowledge_base[best_idx]
        
        return {
            'question': best_faq['question'],
            'response': best_faq['response'],
            'intent': best_faq['intent'],
            'confidence': float(best_score),
            'match_type': 'combined' if semantic_scores is not None else 'tfidf'
        }
    
    def _compute_tfidf_similarity(self, user_message: str) -> List[float]:
        """Compute TF-IDF cosine similarity"""
        user_vector = self.tfidf_vectorizer.transform([user_message])
        similarities = cosine_similarity(user_vector, self.tfidf_matrix).flatten()
        return similarities.tolist()
    
    async def _compute_semantic_similarity(self, user_message: str) -> List[float]:
        """Compute semantic similarity using embeddings"""
        if not self.semantic_model:
            return None
            
        # Compute user message embedding
        user_embedding = await self._compute_embeddings([user_message])
        
        # Compute cosine similarity
        user_embedding = user_embedding[0].unsqueeze(0)  # Add batch dimension
        similarities = torch.nn.functional.cosine_similarity(
            user_embedding, 
            self.semantic_embeddings, 
            dim=1
        )
        
        return similarities.tolist()
