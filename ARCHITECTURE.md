# OpenDevAgent Architecture Guide

## System Design Document

### Overview

OpenDevAgent is a **Kilo-inspired AI Software Engineer** platform that implements a sophisticated **Plan-Act-Observe-Fix (PAOF) loop** using a multi-agent architecture. The system autonomously decomposes development tasks into specialized phases, with each phase handled by a role-specific LLM agent.

## Core Design Principles

### 1. **Separation of Concerns**
Each agent focuses on a single responsibility:
- **Architect**: Strategic planning and design
- **Coder**: Implementation and code generation
- **Debugger**: Error analysis and correction

### 2. **Secure API Key Handling**
- Frontend transmits key securely to backend
- Backend maintains key in-memory only
- Key never stored or logged
- Per-request isolation using FastAPI context

### 3. **Sandboxed Code Execution**
- Docker containers with resource isolation
- Automatic cleanup after execution
- Network disabled for security
- Timeout protection for infinite loops

### 4. **Self-Correcting Loop**
- Failed execution automatically triggers debugging
- Debugger generates targeted fixes
- System re-executes automatically
- Progress tracked through status dashboard

## Detailed Architecture

### Layer 1: Presentation (Frontend)

**Technology**: Next.js 14 + React 18 + TypeScript + Tailwind CSS

**Components**:

1. **ApiKeyInputForm.tsx**
   - Secure OpenRouter API key input
   - Backend health verification
   - State: `apiKey`, `loading`, `error`
   - Action: Sets `isApiKeySet` flag

2. **TaskSubmissionForm.tsx**
   - Rich task description input
   - Language/framework selection
   - Form validation
   - Submits to `/api/submit_task` endpoint
   - Response: `{ task_id, status, message }`

3. **AgentStatusDashboard.tsx**
   - Real-time status polling (2s interval)
   - Phase visualization (planning → coding → testing → debugging)
   - Progress bar with percentage
   - Live execution logs
   - Result/error display

4. **TaskListPanel.tsx**
   - Task queue with status indicators
   - Click to switch between tasks
   - Status color coding
   - Progress mini-display

**Data Flow**:
```
User Input → Form Submission → Backend API Call → Status Polling → UI Update (2s interval)
```

### Layer 2: Business Logic (Backend)

**Technology**: FastAPI + Python 3.11 + CrewAI + LangChain

**Main Application** (`main.py`):

```python
FastAPI Application
├── POST /api/submit_task
│   ├── Receive: { task_description, target_language, framework, openrouter_api_key }
│   ├── Generate: task_id (UUID)
│   ├── Store: Initial task status (pending)
│   ├── Queue: Background task execution
│   └── Return: { task_id, status: "accepted" }
│
├── GET /api/task_status/{task_id}
│   ├── Retrieve: Current task status from in-memory store
│   ├── Return: { status, phase, progress, logs, result, error }
│   └── Updates: Live as task progresses
│
├── GET /api/tasks
│   ├── List all tasks
│   ├── Summary statistics
│   └── Return: { total, tasks[], status_summary }
│
└── GET /health
    └── System health check
```

**Task Status Structure**:
```python
task_status[task_id] = {
    "status": "pending|running|completed|failed",
    "phase": "planning|coding|testing|debugging|complete",
    "progress": 0-100,
    "logs": [...],
    "result": {...} or None,
    "error": "..." or None
}
```

### Layer 3: Agent Orchestration

**File**: `backend/agent_logic/software_engineer_crew.py`

**Class**: `SoftwareEngineerCrew`

**Multi-Agent System**:

1. **Initialization Phase**
   ```python
   __init__(openrouter_api_key)
   ├── Create ChatOpenAI clients (3 instances)
   ├── Architect: model="openai/gpt-4o", temperature=0.3
   ├── Coder: model="mistral/codestral-22b", temperature=0.2
   ├── Debugger: model="anthropic/claude-3-5-sonnet", temperature=0.2
   └── Initialize CrewAI agents with LLM clients
   ```

2. **Plan-Act-Observe-Fix Execution**
   ```python
   execute_plan_act_observe_fix(task_id, description, language, framework)
   │
   ├─ PHASE 1: PLANNING (15% progress)
   │  ├── Architect receives task description
   │  ├── Creates detailed architecture plan
   │  ├── Identifies components and dependencies
   │  └── Returns: { components, plan_text, target_language }
   │
   ├─ PHASE 2: ACTING (40% progress)
   │  ├── Coder receives Architect's plan
   │  ├── Generates production-ready code
   │  ├── Includes error handling and tests
   │  └── Returns: { files: {filename: code}, code_text }
   │
   ├─ PHASE 3: OBSERVING (65% progress)
   │  ├── Sandbox Executor runs code
   │  ├── Captures stdout/stderr/exit_code
   │  ├── If success: return { status: "success" }
   │  └── If failure: proceed to Phase 4
   │
   └─ PHASE 4: FIXING (80-100% progress)
      ├── Check if execution failed
      ├── Debugger analyzes error output
      ├── Generates fixes
      ├── Re-execute in sandbox
      └── Return final results
   ```

3. **Agent Specialization**

   **Architect Agent**:
   - Input: Raw task description
   - Process: Strategic decomposition
   - Output: Architecture plan with components
   - Tools: CrewAI Task execution

   **Coder Agent**:
   - Input: Architecture plan from Architect
   - Process: Code generation with language idioms
   - Output: Complete source code with tests
   - Constraints: Follow target language best practices

   **Debugger Agent**:
   - Input: Error logs and execution output
   - Process: Root cause analysis
   - Output: Corrected source code
   - Focus: Minimal changes to fix issues

### Layer 4: Execution Engine

**File**: `backend/agent_logic/tools/sandbox_executor.py`

**Class**: `SandboxExecutor`

**Docker Execution Flow**:

1. **Pre-Execution**
   - Create task-specific directory
   - Write generated files to directory
   - Prepare Docker volume mount

2. **Execution**
   ```python
   execute(code_artifacts, language, timeout, task_id)
   │
   ├── File Writing Phase
   │   ├── Parse code_artifacts
   │   ├── Write each file to task directory
   │   └── Ensure directory structure
   │
   ├── Container Launch Phase
   │   ├── Select appropriate Docker image
   │   ├── Mount task directory
   │   ├── Set resource limits:
   │   │   ├── Memory: 2GB
   │   │   ├── CPU: 2 cores
   │   │   └── Timeout: 60 seconds
   │   └── Disable network access
   │
   ├── Command Execution Phase
   │   ├── Python: "cd /sandbox && pytest tests.py -v || python main.py"
   │   ├── JavaScript: "cd /sandbox && npm install && npm test"
   │   └── TypeScript: "cd /sandbox && npm install && npx tsc && npm test"
   │
   └── Result Capture Phase
       ├── Capture STDOUT (successful output)
       ├── Capture STDERR (error output)
       ├── Record exit code
       └── Return: { status, stdout, stderr, exit_code }
   ```

3. **Post-Execution**
   - Cleanup task directory
   - Remove temporary files
   - Release container resources

**Error Handling**:
```python
try:
    container = docker_client.containers.run(...)
except docker.errors.ContainerError:
    return { status: "error", exit_code, stdout, stderr }
except docker.errors.APIError:
    return { status: "error", message }
```

### Layer 5: Code Analysis

**File**: `backend/agent_logic/tools/code_analyzer.py`

**Class**: `CodeAnalyzer`

**Capabilities**:
- Extract imports/functions/classes
- Detect potential issues (bare except, wildcard imports)
- Analyze code metrics (lines, complexity)
- Language-specific pattern detection

## Data Flow Diagrams

### Task Submission Flow

```
┌─────────────┐
│   Frontend  │
│  Task Form  │
└──────┬──────┘
       │ POST /api/submit_task
       │ { task_desc, language, framework, api_key }
       ↓
┌─────────────────────────────┐
│       FastAPI Backend       │
│  - Generate task_id (UUID)  │
│  - Initialize task_status   │
│  - Queue background task    │
│  - Return task_id           │
└──────┬──────────────────────┘
       │ Response: { task_id }
       ↓
┌─────────────┐
│   Frontend  │
│  Start Poll │
│  Status API │
└─────────────┘
```

### Execution Loop Flow

```
┌─────────────────────────────────────┐
│  SoftwareEngineerCrew.execute()      │
└──────────────────┬──────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   PHASE 1: PLAN         PHASE 2: ACT
        │                     │
   Architect Agent        Coder Agent
   - Analyze task        - Generate code
   - Design system       - Implement features
   - Map dependencies    - Include tests
        │                     │
        └──────────────┬──────┘
                       │
                  PHASE 3: OBSERVE
                       │
              ┌────────┴────────┐
              │                 │
         Success!           Error?
              │                 │
              │            PHASE 4: FIX
              │                 │
              │           Debugger Agent
              │           - Analyze errors
              │           - Generate fixes
              │           - Return corrected code
              │                 │
              └─────────┬───────┘
                        │
                  Re-Execute & Return
```

## Security Architecture

### API Key Security

1. **Transmission**
   - Frontend → HTTPS → Backend
   - Key included in request body
   - Never in URL or headers (recommended)

2. **Storage**
   - Backend: In-memory only
   - Never written to disk
   - Scoped to request context
   - Cleared after request completion

3. **Usage**
   - Used to initialize OpenAI client
   - Client makes API calls directly
   - Backend never logs or inspects key

### Code Execution Security

1. **Isolation**
   - Docker container per task
   - No shared filesystem
   - Resource quotas enforced

2. **Network Security**
   - Network disabled: `network_disabled=True`
   - Cannot reach external services
   - Cannot be reached by external connections

3. **Resource Limits**
   ```
   Memory: 2GB (prevents infinite loops consuming memory)
   CPU: 2 cores (prevents CPU exhaustion)
   Timeout: 60 seconds (terminates hanging processes)
   ```

4. **File System**
   - Read/write limited to `/sandbox` directory
   - Volume mounted read-write
   - Cleaned up after execution

## Performance Considerations

### Optimization Strategies

1. **Concurrent Requests**
   - FastAPI handles async requests
   - Multiple tasks can execute in parallel
   - Docker daemon manages container scheduling

2. **Long-Running Operations**
   - Background task execution
   - Frontend polls status (2s intervals)
   - No blocking requests

3. **Caching Opportunities**
   - LLM response caching (potential future)
   - Code analysis result caching
   - Container image reuse

### Scaling Recommendations

1. **Horizontal Scaling**
   - Run multiple backend instances
   - Load balancer distributes tasks
   - Shared Docker daemon or Docker Swarm

2. **Vertical Scaling**
   - Increase container resource limits
   - Add more CPU cores for parallelism
   - Increase memory for larger workloads

3. **Infrastructure**
   - Container orchestration: Kubernetes
   - Message queue: Redis for task management
   - Database: PostgreSQL for persistent storage

## Error Recovery & Self-Correction

### Retry Logic

1. **Automatic Retry**
   - Failed execution → Debugger analysis
   - Debugger generates fix
   - Automatic re-execution
   - Limited retry attempts (prevents infinite loops)

2. **Manual Retry**
   - User can resubmit task
   - Different parameters possible
   - Full loop re-executed

### Error Categories

| Error Type | Detection | Recovery |
|-----------|-----------|----------|
| Syntax Error | Exit code non-zero | Debugger fixes syntax |
| Runtime Error | Exception in stderr | Debugger fixes logic |
| Test Failure | pytest failed | Debugger fixes implementation |
| Timeout | 60s exceeded | Task marked as failed |
| Container Error | Docker exception | Error logged, task failed |

## Extensibility Points

### Adding New Languages

1. Create new Docker image (e.g., `Dockerfile.golang`)
2. Add command template in `sandbox_executor.py`
3. Add language to frontend dropdown
4. Test with sample code

### Adding New Agent Roles

1. Create new agent in `SoftwareEngineerCrew`
2. Define LLM model and temperature
3. Add task in execution flow
4. Update frontend phases

### Custom Model Selection

Modify LLM models in `setup_llm_clients()`:
```python
self.custom_agent_llm = ChatOpenAI(
    model="your-model-id",
    openai_api_key=self.openrouter_api_key,
    openai_api_base="https://openrouter.ai/api/v1",
)
```

## Monitoring & Logging

### Logging Points

1. **Frontend**
   - Console logs for debugging
   - Status updates displayed in UI

2. **Backend**
   - Task submission logged
   - Phase transitions logged
   - Error messages captured
   - Execution results logged

3. **Sandbox**
   - STDOUT/STDERR captured
   - Exit codes recorded
   - Resource usage tracked

### Metrics to Track

- Task execution time
- Success/failure rates
- LLM API usage
- Sandbox resource utilization
- Error patterns

## Future Enhancements

1. **Persistent Storage**
   - Database for task history
   - Code artifact archival
   - Execution result history

2. **Advanced Debugging**
   - Interactive debugging sessions
   - Variable inspection
   - Code profiling

3. **Collaboration**
   - Multi-user task queue
   - Code review integration
   - Version control integration (Git)

4. **Extended Language Support**
   - Java, C#, Go, Rust
   - Web frameworks (Django, Spring, Nest)
   - Data science stacks

5. **Performance**
   - Result caching
   - Incremental code updates
   - Parallel agent execution

---

**Document Version**: 1.0
**Last Updated**: 2024
**Status**: Implementation Guide Complete
