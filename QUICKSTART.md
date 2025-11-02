# Quick Start Guide - OpenDevAgent

## 5-Minute Setup

### Prerequisites
- Docker & Docker Compose installed
- OpenRouter API key (get from https://openrouter.ai)
- Terminal/CLI access

### Step 1: Download & Setup

```bash
cd /project/workspace/OpenDevAgent_KiloInspired

# Configure environment
cp .env.example .env
# Edit .env: Add your OpenRouter API key
nano .env  # or use your editor
```

### Step 2: Build & Start

```bash
# Build all Docker images
docker-compose build

# Start services (daemon mode)
docker-compose up -d

# Monitor startup
docker-compose logs -f --tail=50
```

Wait until you see:
```
backend_1 | Uvicorn running on http://0.0.0.0:8000
frontend_1 | Ready in Xs
```

### Step 3: Access Application

Open in browser: **http://localhost:3000**

---

## First Task Walkthrough

### 1. Input API Key
- Paste your OpenRouter API key in the password field
- Click "Configure & Continue"

### 2. Submit Task

**Example Task 1** (Simple):
```
Create a Python function that calculates the Fibonacci sequence up to N using memoization. 
Include unit tests that verify correctness.
```

**Example Task 2** (API):
```
Build a FastAPI REST API with endpoints for:
- GET /items - list all
- GET /items/{id} - retrieve one
- POST /items - create
- PUT /items/{id} - update
- DELETE /items/{id} - delete
Include input validation and error handling.
```

- Select language: Python
- Select framework: FastAPI (for API example)
- Click "Submit Task"

### 3. Watch Execution

Monitor real-time progress:
- 🔵 **Planning (0-15%)**: Architect designing
- 🟣 **Coding (15-40%)**: Coder implementing
- 🟠 **Testing (40-80%)**: Sandbox running tests
- ✅ **Complete (100%)**: Done!

---

## API Quick Reference

### Submit Task
```bash
curl -X POST http://localhost:8000/api/submit_task \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Build a Python calculator with +, -, *, / and tests",
    "target_language": "python",
    "target_framework": null,
    "openrouter_api_key": "sk-or-v1-YOUR-KEY-HERE"
  }'
```

### Get Status
```bash
curl http://localhost:8000/api/task_status/TASK-ID-HERE
```

### View Docs
- Swagger: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Port 3000/8000 already in use | Change ports in docker-compose.yml |
| API key not working | Verify on openrouter.ai dashboard |
| Backend won't start | `docker-compose logs backend` |
| Sandbox timeout | Task too complex; simplify or increase timeout |
| Connection refused | Ensure `docker-compose up -d` completed |

---

## Next Steps

1. **Try More Tasks**
   - Data processing scripts
   - Web APIs
   - CLI tools
   - Algorithms

2. **Explore Architecture**
   - Read ARCHITECTURE.md for deep dive
   - Review API_SPECIFICATION.md for all endpoints
   - Check IMPLEMENTATION_GUIDE.md for details

3. **Customize**
   - Modify LLM models in backend/agent_logic/software_engineer_crew.py
   - Adjust resource limits in docker-compose.yml
   - Change frontend theme in frontend/styles/globals.css

4. **Deploy to Production**
   - Follow DEPLOYMENT.md
   - Set up database for persistence
   - Configure load balancing
   - Add monitoring

---

## System Architecture at a Glance

```
┌─────────────────────────────────────────┐
│ Frontend (Next.js/React)                │
│ - API key input                         │
│ - Task submission                       │
│ - Real-time status dashboard            │
└──────────────┬──────────────────────────┘
               │ HTTP
┌──────────────▼──────────────────────────┐
│ Backend (FastAPI/Python)                │
│ - Multi-agent orchestrator (CrewAI)    │
│ - Plan-Act-Observe-Fix loop            │
│ - 3 specialized agents                  │
└──────────────┬──────────────────────────┘
               │ Docker SDK
┌──────────────▼──────────────────────────┐
│ Sandbox Executor (Docker)               │
│ - Isolated code execution               │
│ - Terminal command support              │
│ - Resource-limited containers           │
└─────────────────────────────────────────┘
```

---

## Common Task Examples

### Data Science
```
"Write a Python script using pandas that:
1. Loads data from CSV
2. Handles missing values
3. Calculates statistics
4. Exports cleaned data
Include error handling and logging."
```

### Web Development
```
"Create a Node.js Express API with:
- /users endpoint (GET, POST)
- /users/:id endpoint (GET, PUT, DELETE)
- Input validation
- Error handling
- Unit tests"
```

### Algorithms
```
"Implement a sorting algorithm:
- Merge sort with type hints
- Time complexity: O(n log n)
- Space complexity: O(n)
- Include comprehensive tests
- Document with docstrings"
```

### Testing
```
"Write unit tests for a function that:
- Validates email addresses
- Checks password strength
- Formats phone numbers
Include edge cases and error scenarios."
```

---

## Key Features

✅ **Secure API Key Handling** - Never stored or logged
✅ **Multi-Agent System** - Specialized LLMs for each phase
✅ **Self-Correcting** - Debugger fixes errors automatically
✅ **Isolated Execution** - Docker sandbox with resource limits
✅ **Real-Time Monitoring** - Live logs and progress tracking
✅ **Production-Ready** - Full error handling and logging
✅ **Scalable Architecture** - Can be deployed to cloud platforms

---

## Support

- **Backend Logs**: `docker-compose logs backend`
- **Frontend Logs**: `docker-compose logs frontend`
- **API Docs**: http://localhost:8000/docs
- **Health Check**: `curl http://localhost:8000/health`

---

**Ready to build? Navigate to http://localhost:3000 →**
