# API Specification - OpenDevAgent

## Base URL

```
Local Development: http://localhost:8000
Production: https://api.opendevagent.io (example)
API Version: v1
```

## Authentication

### API Key Submission

The OpenRouter API key is submitted with each task request. It is **not** used as a bearer token for authentication but rather as credentials to initialize the LLM client.

**Security Notes**:
- Keys should be transmitted over HTTPS
- Keys are used only in-memory
- Keys are never logged or persisted
- Keys are scoped to individual task execution

## Endpoints

### 1. Health Check

**Endpoint**: `GET /health`

**Description**: System health check and connectivity verification

**Request**:
```bash
curl -X GET http://localhost:8000/health
```

**Response** (200 OK):
```json
{
  "status": "healthy",
  "service": "OpenDevAgent Backend"
}
```

**Use Case**: Frontend health verification before accepting API key

---

### 2. Submit Task

**Endpoint**: `POST /api/submit_task`

**Description**: Submit a development task for the AI agents to process

**Request Headers**:
```
Content-Type: application/json
```

**Request Body** (Pydantic Model):
```python
{
  "task_description": "string",        # Required: Detailed task description
  "target_language": "string",         # Required: python, javascript, typescript, java, csharp
  "target_framework": "string | null", # Optional: Django, FastAPI, React, Vue, etc.
  "openrouter_api_key": "string"       # Required: OpenRouter API key (sk-or-v1-...)
}
```

**Example Request**:
```bash
curl -X POST http://localhost:8000/api/submit_task \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Create a Python REST API using FastAPI with user authentication, CRUD operations for blog posts, and comprehensive unit tests",
    "target_language": "python",
    "target_framework": "FastAPI",
    "openrouter_api_key": "sk-or-v1-..."
  }'
```

**Response** (202 Accepted):
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "accepted",
  "message": "Task submitted for processing"
}
```

**Response Codes**:
| Code | Description |
|------|-------------|
| 202 | Task accepted and queued |
| 400 | Invalid request body |
| 422 | Validation error in task parameters |
| 500 | Server error |

**Task Description Best Practices**:
```
✓ Include specific requirements
✓ Mention edge cases to handle
✓ Specify desired testing approach
✓ Mention performance expectations

✗ Avoid overly vague descriptions
✗ Don't include implementation details
✗ Don't specify exact variable names (agent decides)
```

**Example Task Descriptions**:

1. **Simple Function**
   ```
   "Create a Python function that implements binary search on a sorted list.
   Include docstring, type hints, and handle edge cases like empty list.
   Write unit tests for boundary conditions."
   ```

2. **Web API**
   ```
   "Build a FastAPI REST API for a TODO application with:
   - GET /todos (list all)
   - POST /todos (create)
   - GET /todos/{id} (retrieve)
   - PUT /todos/{id} (update)
   - DELETE /todos/{id} (delete)
   Include Pydantic models, input validation, error handling, and unit tests."
   ```

3. **Data Processing**
   ```
   "Write a Python script that reads a CSV file, performs data cleaning
   (handle missing values with mean/median imputation), calculates
   descriptive statistics, and exports results to a new CSV.
   Include proper error handling and logging."
   ```

---

### 3. Get Task Status

**Endpoint**: `GET /api/task_status/{task_id}`

**Description**: Retrieve current status and progress of a task

**Parameters**:
- `task_id` (path parameter): UUID of the task

**Request**:
```bash
curl -X GET http://localhost:8000/api/task_status/550e8400-e29b-41d4-a716-446655440000
```

**Response** (200 OK):
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "phase": "coding",
  "progress": 45,
  "logs": [
    "Task queued for processing",
    "[PHASE 1: PLANNING] Architect analyzing task...",
    "✓ Plan created: 3 components identified",
    "[PHASE 2: ACTING] Coder generating implementation...",
    "✓ Code generated: 2 files created"
  ],
  "result": null,
  "error": null
}
```

**Status Values**:
```
"pending"   → Task queued, waiting to start
"running"   → Task currently executing
"completed" → Task finished successfully
"failed"    → Task execution failed
```

**Phase Values**:
```
"planning"   → Architect designing system
"coding"     → Coder implementing solution
"testing"    → Sandbox executing code
"debugging"  → Debugger fixing errors
"complete"   → Task finished
```

**Progress Values**:
```
0-14%   → Planning phase
15-39%  → Coding phase
40-64%  → Testing phase (observing)
65-79%  → Debugging phase (if errors)
80-100% → Fixing/completion
```

**Response Codes**:
| Code | Description |
|------|-------------|
| 200 | Task status retrieved |
| 404 | Task ID not found |
| 500 | Server error |

**Polling Recommendation**: 2-3 second intervals for real-time updates

---

### 4. List All Tasks

**Endpoint**: `GET /api/tasks`

**Description**: Retrieve summary of all tasks and system statistics

**Request**:
```bash
curl -X GET http://localhost:8000/api/tasks
```

**Response** (200 OK):
```json
{
  "total": 5,
  "tasks": [
    "550e8400-e29b-41d4-a716-446655440000",
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002",
    "550e8400-e29b-41d4-a716-446655440003",
    "550e8400-e29b-41d4-a716-446655440004"
  ],
  "status_summary": {
    "pending": 1,
    "running": 2,
    "completed": 1,
    "failed": 1
  }
}
```

**Response Codes**:
| Code | Description |
|------|-------------|
| 200 | Task list retrieved |
| 500 | Server error |

---

## Response Models

### TaskResponse

```python
{
  "task_id": str,           # UUID
  "status": str,            # Status enum
  "message": str            # Status message
}
```

### TaskStatusResponse

```python
{
  "task_id": str,           # UUID
  "status": str,            # Status enum
  "phase": str,             # Phase enum
  "progress": int,          # 0-100
  "logs": list[str],        # Execution logs
  "result": dict | null,    # Task result (if completed)
  "error": str | null       # Error message (if failed)
}
```

### Result Structure (On Completion)

```json
{
  "status": "success",
  "plan": {
    "components": ["component_1", "component_2"],
    "plan_text": "Architecture plan details...",
    "target_language": "python",
    "framework": "FastAPI"
  },
  "code": {
    "files": {
      "main.py": "#!/usr/bin/env python3\n...",
      "tests.py": "import pytest\n...",
      "requirements.txt": "fastapi==0.104.1\n..."
    },
    "code_text": "Full source code..."
  },
  "execution": {
    "status": "success",
    "stdout": "Test execution output...",
    "stderr": "",
    "exit_code": 0
  }
}
```

---

## Error Handling

### Error Response Format

```json
{
  "detail": "Error message description"
}
```

### Common Errors

#### 400 Bad Request
```json
{
  "detail": "Invalid task_description: must be non-empty string"
}
```

#### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "target_language"],
      "msg": "value is not a valid enumeration member",
      "type": "type_error.enum"
    }
  ]
}
```

#### 404 Not Found
```json
{
  "detail": "Task not found"
}
```

#### 500 Internal Server Error
```json
{
  "detail": "Internal server error: OpenRouter API connection failed"
}
```

---

## Rate Limiting

**Current**: No rate limiting (can be added for production)

**Recommended for Production**:
```
- 100 requests per minute per IP
- 10 concurrent tasks per user
- 5GB monthly storage for task artifacts
```

---

## Pagination (Future)

**Planned for v2**:
```bash
GET /api/tasks?limit=20&offset=0&status=completed
```

---

## WebSocket Support (Future)

**Planned for v2** - Real-time task updates:
```
ws://localhost:8000/ws/task/{task_id}
```

---

## Example Workflows

### Workflow 1: Simple Task Submission

```bash
# 1. Check backend health
curl http://localhost:8000/health

# 2. Submit task
TASK_ID=$(curl -X POST http://localhost:8000/api/submit_task \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Build a Python calculator with add, subtract, multiply, divide functions and unit tests",
    "target_language": "python",
    "target_framework": null,
    "openrouter_api_key": "sk-or-v1-..."
  }' | jq -r '.task_id')

# 3. Poll for status
for i in {1..60}; do
  curl http://localhost:8000/api/task_status/$TASK_ID | jq '.'
  sleep 2
done
```

### Workflow 2: Full Development Cycle

```javascript
// JavaScript example
const BASE_URL = 'http://localhost:8000';

async function submitAndMonitorTask(description, language, framework, apiKey) {
  // Submit task
  const taskResponse = await fetch(`${BASE_URL}/api/submit_task`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      task_description: description,
      target_language: language,
      target_framework: framework,
      openrouter_api_key: apiKey
    })
  });

  const { task_id } = await taskResponse.json();
  console.log('Task ID:', task_id);

  // Poll for completion
  let taskStatus = null;
  while (!taskStatus || taskStatus.status === 'running') {
    const response = await fetch(`${BASE_URL}/api/task_status/${task_id}`);
    taskStatus = await response.json();
    
    console.log(`[${taskStatus.phase.toUpperCase()}] ${taskStatus.progress}%`);
    
    if (taskStatus.status === 'running') {
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  return taskStatus;
}

// Usage
const result = await submitAndMonitorTask(
  'Create a Node.js Express server with /api/users endpoint',
  'javascript',
  'Express',
  'sk-or-v1-...'
);

console.log('Result:', result);
```

---

## API Versioning

**Current Version**: v1

**Versioning Strategy**:
- URL-based: `/api/v1/`, `/api/v2/`
- Backward compatibility maintained for at least 2 versions
- Deprecation warnings provided 6 months in advance

---

## CORS Policy

**Allowed Origins** (Development):
```
- http://localhost:3000
- http://localhost:8000
- http://localhost:*
```

**Allowed Methods**:
```
GET, POST, PUT, DELETE, OPTIONS
```

**Allowed Headers**:
```
Content-Type, Authorization, X-API-Key
```

---

## Rate Limiting & Quotas (Production Recommendations)

| Resource | Limit | Period |
|----------|-------|--------|
| Requests | 100 | 1 minute |
| Concurrent Tasks | 10 | Per user |
| Task Duration | 300 | Seconds |
| Monthly API Calls | 10,000 | 30 days |
| Storage | 5GB | Per month |

---

## Webhook Support (Future Feature)

**Planned webhooks** for task completion notifications:

```bash
POST /api/webhooks/subscribe
{
  "url": "https://your-domain.com/callback",
  "events": ["task.completed", "task.failed"]
}
```

---

## API Documentation UI

### Swagger UI
```
http://localhost:8000/docs
```

### ReDoc
```
http://localhost:8000/redoc
```

### OpenAPI Schema
```
http://localhost:8000/openapi.json
```

---

## Support & Issues

**API Support**: For API-related issues, check:
1. OpenRouter API status: https://status.openrouter.ai
2. Backend logs: `docker-compose logs backend`
3. Network connectivity: `curl -v http://localhost:8000/health`

---

**API Specification Version**: 1.0
**Last Updated**: 2024
**Status**: Complete
