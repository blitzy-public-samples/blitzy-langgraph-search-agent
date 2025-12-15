# Setup Instructions

## Step 1: Get API Keys

1. **OpenAI API Key**: Get from https://platform.openai.com/api-keys
2. **Tavily API Key**: Get from https://tavily.com/

## Step 2: Configure Backend

```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` and add your API keys:
```
OPENAI_API_KEY=sk-your-key-here
TAVILY_API_KEY=tvly-your-key-here
```

## Step 3: Run Locally

### Option A: Docker Compose (Easiest)
```bash
docker-compose up
```

### Option B: Manual Setup

**Terminal 1 - Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Step 4: Test

Open your browser to http://localhost:3000 and start chatting!

## Step 5: Deploy to AWS (Optional)

See the main README and deployment guide for AWS setup instructions.
