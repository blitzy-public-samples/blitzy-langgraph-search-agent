# LangGraph Search Agent

A full-stack AI-powered search agent application using LangGraph, deployed on AWS with CI/CD.

## Features

- 🤖 LangGraph agent with web search capabilities
- 🔍 Real-time search using Tavily API
- 💬 Conversational interface with session memory
- 🚀 Automated CI/CD pipeline with GitHub Actions
- ☁️ AWS deployment (ECS Fargate + S3 + CloudFront)

## Prerequisites

- Python 3.11+
- Node.js 18+
- Docker
- AWS Account
- OpenAI API Key
- Tavily API Key

## Quick Start

### 1. Set up environment variables

```bash
# Backend
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys
```

### 2. Run with Docker Compose (Recommended)

```bash
docker-compose up
```

The backend will be available at http://localhost:8000
The frontend will be available at http://localhost:3000

### 3. Or run separately

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## API Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `POST /query` - Process search query

## Testing

```bash
# Test backend health
curl http://localhost:8000/health

# Test query endpoint
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is LangGraph?"}'
```

## AWS Deployment

See the deployment documentation for full AWS setup with Terraform and CI/CD.

## Project Structure

```
langgraph-search-agent/
├── backend/              # FastAPI backend
├── frontend/             # React frontend
├── .github/workflows/    # CI/CD pipelines
├── infrastructure/       # Terraform IaC
└── docker-compose.yml    # Local development
```

## License

MIT
