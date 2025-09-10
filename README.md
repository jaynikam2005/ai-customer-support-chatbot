# 🤖 AI Customer Support ChatBot

[![React](https://img.shields.io/badge/React-18.3.1-61DAFB?style=flat&logo=react&logoColor=white)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8.3-3178C6?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.116.1-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Java Spring](https://img.shields.io/badge/Spring-Boot-6DB33F?style=flat&logo=spring&logoColor=white)](https://spring.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

A cutting-edge, **multimodal AI-powered customer support chatbot** featuring advanced conversational AI, image generation, video creation, and visual analysis capabilities. Built with modern technologies and enterprise-grade architecture.

## ✨ Features

### 🧠 **Intelligent Conversational AI**
- **Smart Intent Recognition** - Understands customer needs automatically
- **FAQ Matching** - Instant answers from knowledge base
- **Context-Aware Responses** - Maintains conversation context
- **Multi-language Support** - Global customer support
- **Conversation History** - Persistent chat sessions

###   **Multimodal Capabilities**
- **Image Generation** - Create custom visuals from text descriptions
- **Video Creation** - Generate engaging video content
- **Image Analysis** - AI-powered visual understanding
- **Document Processing** - Handle various file formats
- **Media Library** - Organized content management

### 🚀 **Advanced Technologies**
- **Google Gemini AI** - State-of-the-art language models
- **Stability AI** - Professional image generation
- **OpenAI Integration** - Enhanced AI capabilities
- **Real-time Processing** - Instant responses and generation
- **Enterprise Security** - JWT authentication and secure APIs

## 📁 Project Architecture

```
AI ChatBot/
├── 🎨 frontend/                    # React + TypeScript UI
│   ├── src/
│   │   ├── components/             # Reusable UI components
│   │   ├── context/               # React Context providers
│   │   ├── hooks/                 # Custom React hooks
│   │   ├── services/              # API communication
│   │   └── pages/                 # Application pages
│   └── public/                    # Static assets
├── 🐍 backend-python/              # FastAPI AI Service
│   ├── app/
│   │   ├── models/                # Pydantic data models
│   │   ├── routes/                # API route handlers
│   │   ├── services/              # Business logic
│   │   ├── media_generator.py     # Image/Video generation
│   │   ├── multimodal_service.py  # Multimodal AI processing
│   │   └── main.py                # FastAPI application
│   └── generated_content/         # AI-generated media
├── ☕ backend-java/                # Spring Boot API Gateway
│   ├── src/main/java/
│   │   └── com/example/chatbot/
│   │       ├── config/            # Configuration classes
│   │       ├── controller/        # REST controllers
│   │       ├── model/             # JPA entities
│   │       ├── repository/        # Data repositories
│   │       ├── security/          # JWT security
│   │       └── service/           # Business services
│   └── src/main/resources/
├── 🗄️ database/                    # Database scripts
│   ├── migrations/                # Database migrations
│   └── seeds/                     # Sample data
├── 🐳 docker-compose.yml          # Container orchestration
└── 📋 db-schema.sql               # Database schema
```

## 🛠️ Technology Stack

### **Frontend**
- **React 18.3.1** - Modern UI framework with hooks
- **TypeScript 5.8.3** - Type-safe development
- **Vite** - Lightning-fast build tool
- **Tailwind CSS** - Utility-first styling
- **Radix UI** - Accessible component primitives
- **React Query** - Server state management
- **React Router** - Client-side routing

### **Backend - Python AI Service**
- **FastAPI 0.116.1** - High-performance async API
- **Google Generative AI** - Advanced language models
- **Stability AI SDK** - Professional image generation
- **OpenAI API** - Additional AI capabilities
- **Pillow & OpenCV** - Image processing
- **MoviePy** - Video processing
- **Transformers** - Hugging Face models

### **Backend - Java API Gateway**
- **Spring Boot** - Enterprise Java framework
- **Spring Security** - JWT authentication
- **Spring Data JPA** - Database abstraction
- **PostgreSQL 16** - Robust database
- **Maven** - Dependency management

### **DevOps & Infrastructure**
- **Docker Compose** - Container orchestration
- **PostgreSQL** - Primary database
- **Nginx** - Reverse proxy (optional)
- **Health Checks** - Service monitoring

## 🚀 Quick Start

### Prerequisites
- **Node.js** 18+ and npm
- **Python** 3.11+
- **Java** 17+
- **Docker** and Docker Compose
- **Git**

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/ai-chatbot.git
cd ai-chatbot
```

### 2. Environment Setup
```bash
# Frontend dependencies
cd frontend && npm install

# Python dependencies
cd ../backend-python && pip install -r requirements.txt

# Java dependencies (Maven will auto-download)
cd ../backend-java && ./mvnw install
```

### 3. Configure Environment Variables
```bash
# backend-python/.env
GOOGLE_API_KEY=your_google_api_key
OPENAI_API_KEY=your_openai_api_key
STABILITY_API_KEY=your_stability_api_key
DATABASE_URL=postgresql://chatbot_user:chatbot_password@localhost:5432/chatbot
```

### 4. Start with Docker (Recommended)
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 5. Manual Development Setup
```bash
# Terminal 1: Database
docker run --name postgres -e POSTGRES_DB=chatbot -e POSTGRES_USER=chatbot_user -e POSTGRES_PASSWORD=chatbot_password -p 5432:5432 -d postgres:16

# Terminal 2: Python AI Service
cd backend-python && uvicorn app.main:app --reload --port 5000

# Terminal 3: Java Backend
cd backend-java && ./mvnw spring-boot:run

# Terminal 4: Frontend
cd frontend && npm run dev
```

## 📊 API Documentation

### **Authentication**
```bash
POST /api/auth/login
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password"
}
```

### **Chat Endpoints**
```bash
# Send message
POST /api/chat/message
Authorization: Bearer <token>

{
  "message": "How can I reset my password?",
  "sessionId": "uuid"
}

# Get chat history
GET /api/chat/history/{sessionId}
Authorization: Bearer <token>
```

### **Multimodal AI Endpoints**

#### 🎨 **Image Generation**
```bash
POST /api/ai/generate-image
Content-Type: application/json

{
  "prompt": "A futuristic cityscape at sunset",
  "style": "realistic",
  "size": "1024x1024"
}

# Response
{
  "success": true,
  "image_url": "/generated/images/ai_image_abc123.png",
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "description": "A stunning futuristic cityscape...",
  "generation_details": {
    "style": "realistic",
    "size": "1024x1024",
    "generation_time": 2.34
  }
}
```

#### 🎬 **Video Generation**
```bash
POST /api/ai/generate-video
Content-Type: application/json

{
  "prompt": "A time-lapse of a flower blooming",
  "duration": 5,
  "fps": 24
}

# Response
{
  "success": true,
  "video_url": "/generated/videos/ai_video_def456.mp4",
  "concept": "Detailed storyboard and concept...",
  "generation_details": {
    "duration": 5,
    "fps": 24,
    "frame_count": 120
  }
}
```

#### 🔍 **Image Analysis**
```bash
POST /api/ai/analyze-image
Content-Type: multipart/form-data

image: <file>
question: "What objects are in this image?"

# Response
{
  "success": true,
  "analysis": "This image contains a laptop, coffee cup...",
  "technical_info": {
    "dimensions": "1920x1080",
    "format": "JPEG",
    "mode": "RGB"
  }
}
```

## 🎯 Key Features Breakdown

### **Smart Conversation Management**
- **Session Persistence** - Conversations saved across browser sessions
- **Context Awareness** - AI remembers conversation history
- **Intent Classification** - Automatic categorization of user requests
- **FAQ Integration** - Instant access to knowledge base
- **Escalation Handling** - Seamless handoff to human agents

### **Multimodal AI Capabilities**
- **Text-to-Image** - Generate custom visuals for explanations
- **Text-to-Video** - Create engaging video content
- **Image Understanding** - Analyze user-uploaded images
- **Document Processing** - Handle PDFs, images, and documents
- **Visual Search** - Find similar images and content

### **Enterprise Features**
- **User Authentication** - Secure JWT-based login system
- **Role-Based Access** - Admin, agent, and customer roles
- **Analytics Dashboard** - Conversation insights and metrics
- **API Rate Limiting** - Protect against abuse
- **Audit Logging** - Complete interaction history

## 🔧 Development

### **Frontend Development**
```bash
cd frontend

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

### **Backend Development**
```bash
# Python service
cd backend-python
uvicorn app.main:app --reload --port 5000

# Java service
cd backend-java
./mvnw spring-boot:run

# Run tests
./mvnw test
```

### **Database Management**
```bash
# Connect to database
docker exec -it chatbot-postgres psql -U chatbot_user -d chatbot

# Run migrations
cd database
psql -U chatbot_user -d chatbot -f migrations/001_initial.sql

# Seed data
psql -U chatbot_user -d chatbot -f seeds/sample_data.sql
```

## 📈 Performance & Scalability

- **Async Processing** - Non-blocking I/O for high concurrency
- **Connection Pooling** - Efficient database connections
- **Caching Layer** - Redis for session and response caching
- **Load Balancing** - Multiple backend instances
- **CDN Integration** - Fast media delivery
- **Horizontal Scaling** - Kubernetes ready

## 🔒 Security

- **JWT Authentication** - Secure token-based auth
- **HTTPS Enforcement** - Encrypted communication
- **Input Validation** - Comprehensive data sanitization
- **Rate Limiting** - DDoS protection
- **CORS Configuration** - Secure cross-origin requests
- **Environment Variables** - Secure configuration management

## 🧪 Testing

```bash
# Frontend tests
cd frontend && npm test

# Python tests
cd backend-python && pytest

# Java tests
cd backend-java && ./mvnw test

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## 📦 Deployment

### **Docker Deployment**
```bash
# Production build
docker-compose -f docker-compose.prod.yml up -d

# Health check
curl http://localhost:3000/health
curl http://localhost:8080/actuator/health
curl http://localhost:5000/health
```

### **Cloud Deployment**
- **AWS ECS** - Container orchestration
- **Azure Container Instances** - Managed containers
- **Google Cloud Run** - Serverless containers
- **Kubernetes** - Enterprise orchestration

## 📋 Environment Variables

### **Frontend (.env)**
```env
VITE_API_URL=http://localhost:8080
VITE_AI_SERVICE_URL=http://localhost:5000
VITE_ENABLE_ANALYTICS=true
```

### **Python Backend (.env)**
```env
GOOGLE_API_KEY=your_google_api_key
OPENAI_API_KEY=your_openai_api_key
STABILITY_API_KEY=your_stability_api_key
DATABASE_URL=postgresql://user:pass@localhost:5432/chatbot
REDIS_URL=redis://localhost:6379
```

### **Java Backend (application.properties)**
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/chatbot
spring.datasource.username=chatbot_user
spring.datasource.password=chatbot_password
ai.service.url=http://localhost:5000
jwt.secret=your_jwt_secret
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation** - [Full docs](https://docs.example.com)
- **Issues** - [GitHub Issues](https://github.com/yourusername/ai-chatbot/issues)
- **Discussions** - [GitHub Discussions](https://github.com/yourusername/ai-chatbot/discussions)
- **Email** - support@example.com

## 🚀 What's Next?

### **Upcoming Features**
- [ ] **Voice Integration** - Speech-to-text and text-to-speech
- [ ] **Mobile App** - React Native implementation
- [ ] **Advanced Analytics** - Machine learning insights
- [ ] **Plugin System** - Third-party integrations
- [ ] **Multi-tenant Support** - Enterprise SaaS features
- [ ] **Real-time Collaboration** - Live agent assistance

### **Recent Updates**
- ✅ **Multimodal AI** - Image and video generation
- ✅ **Visual Analysis** - Image understanding capabilities
- ✅ **Mobile Responsive** - Optimized mobile experience
- ✅ **Dark Mode** - Theme switching support
- ✅ **Docker Support** - Complete containerization

---

<div align="center">

**Built with ❤️ by the AI ChatBot Team**

[⭐ Star this repo](https://github.com/yourusername/ai-chatbot) | [🐛 Report Bug](https://github.com/yourusername/ai-chatbot/issues) | [✨ Request Feature](https://github.com/yourusername/ai-chatbot/issues)

</div>