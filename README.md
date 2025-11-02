# OpenDevAgent - Kilo-Inspired AI Software Engineer Platform

A robust, open-source AI Software Engineer platform that operates using a **Plan-Act-Observe-Fix loop** (Kilo-inspired agentic loop). It autonomously handles task breakdown, multi-role planning, code execution, and self-correction, utilizing OpenRouter API for secure LLM access.

## 🎯 Architecture Overview

### Multi-Agent System (Kilo-Inspired Modes)

The system implements three specialized agent roles that work together in a coordinated loop:

1. **Architect Agent** (Planning Phase)
   - Model: `openai/gpt-4o`
   - Responsibility: High-level system design, dependency mapping, architecture planning
   - Output: Detailed architecture plan and implementation strategy

2. **Coder Agent** (Acting Phase)
   - Model: `mistral/codestral-22b`
   - Responsibility: Pure code generation and implementation
   - Output: Production-ready source code

3. **Debugger Agent** (Fixing Phase)
   - Model: `anthropic/claude-3-5-sonnet`
   - Responsibility: Error analysis, test failure diagnosis, bug fixes
   - Output: Corrected and optimized code

### Execution Flow: Plan-Act-Observe-Fix Loop

```
┌─────────────────────────────────────────────────────────────┐
│  1. PLAN: Architect analyzes task and creates architecture  │
├─────────────────────────────────────────────────────────────┤
│  2. ACT: Coder generates implementation based on plan       │
├─────────────────────────────────────────────────────────────┤
│  3. OBSERVE: Sandbox executes code and captures results    │
├─────────────────────────────────────────────────────────────┤
│  4. FIX: Debugger analyzes failures and generates fixes    │
├─────────────────────────────────────────────────────────────┤
│  5. RE-OBSERVE: Sandbox re-executes fixed code            │
└─────────────────────────────────────────────────────────────┘
```

## 🏗️ System Architecture

### Frontend (Next.js/React)
- **Port**: 3000
- **Components**:
  - API Key Input Form (Secure OpenRouter key submission)
  - Task Submission Form (Feature description, language, framework)
  - Agent Status Dashboard (Real-time execution monitoring)
  - Task List Panel (Queue management)

### Backend (FastAPI)
- **Port**: 8000
- **Endpoints**:
  - `POST /api/submit_task` - Submit development task with OpenRouter API key
  - `GET /api/task_status/{task_id}` - Monitor task execution progress
  - `GET /api/tasks` - List all tasks and summary
  - `GET /health` - Health check

### Secure Sandbox Executor (Docker)
- **Isolation**: Disposable Docker container per task
- **Resource Limits**: 2 CPU cores, 2GB RAM, 60s timeout
- **Network Access**: Disabled (no external network)
- **Terminal Command Execution**: 
  - File read/write operations
  - Python: `pytest`, `python`, package installation
  - JavaScript/TypeScript: `npm`, `npx`, `tsc`

## 📋 Prerequisites

- Docker & Docker Compose
- Python 3.11+
- Node.js 18+
- OpenRouter API Key (get from https://openrouter.ai)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
cd /project/workspace/OpenDevAgent_KiloInspired
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env and add your OpenRouter API key
```

### 3. Build and Run with Docker Compose

```bash
docker-compose build
docker-compose up
```

The system will:
- Build the sandbox Docker image
- Start the FastAPI backend (port 8000)
- Start the Next.js frontend (port 3000)

### 4. Access the Platform

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

## 💡 Usage Example

1. **Input OpenRouter API Key** on the frontend
2. **Submit Task**:
   ```
   Task: "Build a Python REST API with FastAPI that includes user authentication, CRUD operations for posts, and unit tests"
   Language: Python
   Framework: FastAPI
   ```
3. **Monitor Execution**:
   - Watch the agent progress through Planning → Coding → Testing → (Debugging if needed)
   - View real-time logs in the status dashboard
   - Track progress percentage

4. **View Results**:
   - Generated source code
   - Test execution results
   - Any applied fixes

## 🔐 Security Features

1. **API Key Handling**:
   - Keys transmitted securely to backend
   - Used only in-memory (not persisted)
   - Not exposed to frontend after submission

2. **Sandbox Isolation**:
   - Docker containers with resource limits
   - No network access
   - Automatic cleanup after execution
   - Timeout protection (60 seconds)

3. **Code Execution Safety**:
   - Restricted file system access
   - Resource limits (CPU, memory)
   - Automatic container termination

## 📁 Project Structure

```
OpenDevAgent_KiloInspired/
├── docker-compose.yml              # Service orchestration
├── .env.example                    # Environment template
├── README.md                       # This file
│
├── frontend/                       # Next.js frontend
│   ├── Dockerfile
│   ├── package.json
│   ├── next.config.js
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   ├── postcss.config.js
│   ├── pages/
│   │   ├── _app.tsx              # App wrapper
│   │   └── index.tsx             # Main page
│   ├── components/
│   │   ├── ApiKeyInputForm.tsx
│   │   ├── TaskSubmissionForm.tsx
│   │   ├── AgentStatusDashboard.tsx
│   │   └── TaskListPanel.tsx
│   └── styles/
│       └── globals.css
│
├── backend/                        # FastAPI backend
│   ├── Dockerfile
│   ├── main.py                    # FastAPI application
│   ├── requirements.txt
│   └── agent_logic/
│       ├── __init__.py
│       ├── software_engineer_crew.py  # Multi-agent orchestrator
│       └── tools/
│           ├── __init__.py
│           ├── sandbox_executor.py    # Terminal execution engine
│           └── code_analyzer.py       # Code analysis utility
│
└── sandbox_templates/              # Sandbox environments
    ├── Dockerfile.python
    └── entrypoint.sh
```

## 🛠️ Configuration

### Backend Environment Variables

```python
OPENROUTER_API_KEY         # OpenRouter API key (passed per request)
SANDBOX_DOCKER_SOCKET      # Docker socket path
```

### LLM Models via OpenRouter

The system uses three specialized models accessible through OpenRouter:

- **Planning**: `openai/gpt-4o` - Strategic system design
- **Coding**: `mistral/codestral-22b` - Fast, efficient code generation
- **Debugging**: `anthropic/claude-3-5-sonnet` - Sophisticated error analysis

## 📊 Task Status Phases

- **Pending**: Task queued, waiting to start
- **Planning**: Architect analyzing task
- **Coding**: Coder generating implementation
- **Testing**: Sandbox executing code
- **Debugging**: Debugger fixing errors (if needed)
- **Complete**: Task finished successfully

## 🧪 Testing the System

### Sample Task 1: Python Function

```
"Create a Python function that calculates Fibonacci numbers up to N with memoization. Include unit tests that verify correctness for N=20 and N=50"
```

### Sample Task 2: Data Processing

```
"Build a Python script using pandas that reads a CSV file, performs data cleaning (handling missing values), calculates statistics, and exports results"
```

### Sample Task 3: API Development

```
"Create a FastAPI application with endpoints for GET /items (list), GET /items/{id} (detail), POST /items (create), and include authentication"
```

## 🔄 Retry Logic & Self-Correction

When code execution fails:
1. Debugger analyzes error messages and logs
2. Generates targeted fixes
3. Automatically re-executes in sandbox
4. Updates frontend with results

This self-correction loop enables the system to iteratively improve until successful.

## 📝 API Reference

### Submit Task
```bash
curl -X POST http://localhost:8000/api/submit_task \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Build a Python calculator",
    "target_language": "python",
    "target_framework": null,
    "openrouter_api_key": "sk-or-v1-..."
  }'
```

### Get Task Status
```bash
curl http://localhost:8000/api/task_status/{task_id}
```

### List All Tasks
```bash
curl http://localhost:8000/api/tasks
```

## 🚧 Advanced Configuration

### Adjusting Sandbox Resources

Edit `docker-compose.yml`:
```yaml
backend:
  environment:
    SANDBOX_TIMEOUT: 120  # Seconds
    SANDBOX_MEMORY: 4g    # Memory limit
    SANDBOX_CPUS: 4       # CPU cores
```

### Custom LLM Models

Modify `backend/agent_logic/software_engineer_crew.py`:
```python
self.architect_llm = ChatOpenAI(
    model="your-model-name",  # Change model
    openai_api_base="https://openrouter.ai/api/v1",
)
```

## 📚 Key Technologies

- **Frontend**: Next.js 14, React 18, TypeScript, Tailwind CSS
- **Backend**: FastAPI, Python 3.11, CrewAI
- **LLMs**: OpenRouter API (GPT-4o, Codestral, Claude 3.5 Sonnet)
- **Execution**: Docker, Python subprocess
- **State Management**: In-memory task tracking

## 🤝 Contributing

This is an open-source project. Contributions welcome for:
- Additional agent roles
- Support for more programming languages
- Enhanced error recovery
- Performance optimizations

## 📄 License

MIT License - See LICENSE file

## 🙋 Support

For issues or questions:
1. Check existing documentation
2. Review task execution logs
3. Verify OpenRouter API key validity
4. Check Docker daemon status

## 🎓 Learning Resources

- [OpenRouter Documentation](https://openrouter.ai/docs)
- [CrewAI Documentation](https://docs.crewai.com)
- [FastAPI Tutorial](https://fastapi.tiangolo.com)
- [Next.js Documentation](https://nextjs.org/docs)

---

**OpenDevAgent** - Building tomorrow's software, today.
